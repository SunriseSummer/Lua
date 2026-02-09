/*
** $Id: lparser_cj_exprs.c $
** Cangjie expression forms and auto-returning logic
** This file is #include'd from lparser.c and shares its static context.
**
** Contents:
**   statlist_autoreturning_ex    — Parameterized auto-returning body
**   statlist_autoreturning       — Auto-returning body (block context)
**   blockexpr                    — Block expression { stmts; expr }
**   ifexpr                       — If expression (produces value)
**
** See Copyright Notice in lua.h
*/

/*
** Auto-returning statement list implementation.
** Parses statements until the end of the enclosing block, auto-returning
** the last expression.  When 'in_match_case' is 0, end-of-block is
** determined by block_follow(); when non-zero, by is_match_case_end().
*/
static void statlist_autoreturning_ex (LexState *ls, int in_match_case) {
  while (!(in_match_case ? is_match_case_end(ls) : block_follow(ls, 1))) {
    if (ls->t.token == TK_RETURN) {
      statement(ls);
      return;  /* explicit return */
    }
    /* Check if current token starts a keyword statement */
    {
      int tok = ls->t.token;
      int is_keyword_stat = (tok == TK_LET || tok == TK_VAR || tok == TK_WHILE ||
                             tok == TK_FOR || tok == TK_FUNC || tok == TK_STRUCT ||
                             tok == TK_CLASS || tok == TK_ENUM || tok == TK_INTERFACE ||
                             tok == TK_EXTEND || tok == TK_BREAK || tok == TK_CONTINUE ||
                             tok == ';' || tok == TK_DBCOLON || tok == TK_IF ||
                             tok == TK_MATCH);
      if (is_keyword_stat) {
        /* if/match as last statement: use auto-returning branches */
        if ((tok == TK_IF || tok == TK_MATCH)) {
          int line2 = ls->linenumber;
          if (tok == TK_IF)
            ifstat_returning(ls, line2);
          else
            matchstat_returning(ls, line2);
          if (in_match_case ? is_match_case_end(ls) : block_follow(ls, 1))
            return;  /* was the last statement; branches already auto-return */
        }
        else {
          /* Parse as regular statement */
          statement(ls);
        }
      }
      else {
        /* Potential expression - could be assignment, call, or last expr */
        FuncState *fs = ls->fs;
        int at_end;
        enterlevel(ls);
        /* Check for Unit literal '()' */
        if (tok == '(' && luaX_lookahead(ls) == ')') {
          luaX_next(ls);  /* skip '(' */
          luaX_next(ls);  /* skip ')' */
        }
        else if (tok == TK_NAME || tok == TK_THIS) {
          /* NAME-based: could be assignment, call, or last expression */
          expdesc e;
          suffixedexp(ls, &e);
          if (ls->t.token == '=' || ls->t.token == ',') {
            /* Assignment: name = expr */
            struct LHS_assign v;
            v.v = e;
            v.prev = NULL;
            restassign(ls, &v, 1);
          }
          else if ((ls->t.token == '+' || ls->t.token == '-' ||
                    ls->t.token == '*' || ls->t.token == '/') &&
                   luaX_lookahead(ls) == '=') {
            /* Compound assignment: x += e2  =>  x = x + e2 */
            int op_token = ls->t.token;
            BinOpr opr;
            expdesc lhs_copy, rhs, result;
            int line2 = ls->linenumber;
            switch (op_token) {
              case '+': opr = OPR_ADD; break;
              case '-': opr = OPR_SUB; break;
              case '*': opr = OPR_MUL; break;
              case '/': opr = OPR_DIV; break;
              default: lua_assert(0); opr = OPR_ADD; break;
            }
            luaX_next(ls);  /* skip operator */
            luaX_next(ls);  /* skip '=' */
            lhs_copy = e;
            luaK_exp2nextreg(fs, &lhs_copy);
            expr(ls, &rhs);
            luaK_infix(fs, opr, &lhs_copy);
            luaK_posfix(fs, opr, &lhs_copy, &rhs, line2);
            result = lhs_copy;
            luaK_storevar(fs, &e, &result);
          }
          else {
            /* Continue parsing as full expression (binary ops, ??, etc.) */
            {
              BinOpr op = getbinopr(ls->t.token);
              while (op != OPR_NOBINOPR && priority[op].left > 0) {
                expdesc e2;
                BinOpr nextop;
                int line2 = ls->linenumber;
                luaX_next(ls);
                luaK_infix(fs, op, &e);
                nextop = subexpr(ls, &e2, priority[op].right);
                luaK_posfix(fs, op, &e, &e2, line2);
                op = nextop;
              }
            }
            /* Check what follows */
            at_end = in_match_case ? is_match_case_end(ls)
                                   : block_follow(ls, 1);
            if (at_end) {
              /* Last expression - auto-return */
              luaK_ret(fs, luaK_exp2anyreg(fs, &e), 1);
              lua_assert(fs->f->maxstacksize >= fs->freereg &&
                         fs->freereg >= luaY_nvarstack(fs));
              fs->freereg = luaY_nvarstack(fs);
              leavelevel(ls);
              return;
            }
            else {
              /* Intermediate expression statement - could be function call
              ** or operator expression used for side effects. */
              if (e.k == VCALL) {
                Instruction *inst;
                inst = &getinstruction(fs, &e);
                SETARG_C(*inst, 1);
              }
              else {
                /* Non-call expression used as statement (e.g., operator
                ** invocations like `that << this` for side effects).
                ** Evaluate and discard the result. */
                luaK_exp2nextreg(fs, &e);
                fs->freereg = luaY_nvarstack(fs);
              }
            }
          }
        }
        else {
          /* Non-NAME token: literal, unary op, etc. Parse as full expression */
          expdesc e;
          expr(ls, &e);
          at_end = in_match_case ? is_match_case_end(ls) : block_follow(ls, 1);
          if (at_end) {
            luaK_ret(fs, luaK_exp2anyreg(fs, &e), 1);
            lua_assert(fs->f->maxstacksize >= fs->freereg &&
                       fs->freereg >= luaY_nvarstack(fs));
            fs->freereg = luaY_nvarstack(fs);
            leavelevel(ls);
            return;
          }
          else {
            if (e.k == VCALL) {
              Instruction *inst = &getinstruction(fs, &e);
              SETARG_C(*inst, 1);
            }
          }
        }
        lua_assert(fs->f->maxstacksize >= fs->freereg &&
                   fs->freereg >= luaY_nvarstack(fs));
        fs->freereg = luaY_nvarstack(fs);
        leavelevel(ls);
      }
    }
  }
}

/*
** Auto-returning statement list for block contexts (if, block expressions).
** End-of-block is determined by block_follow().
*/
static void statlist_autoreturning (LexState *ls) {
  statlist_autoreturning_ex(ls, 0);
}


/*
** Block expression: { stmts; last_expr }
** Wraps in IIFE: (function() stmts; return last_expr end)()
*/
static void blockexpr (LexState *ls, expdesc *v, int line) {
  FuncState new_fs;
  FuncState *prev_fs = ls->fs;
  BlockCnt bl;
  expdesc fn_expr;
  int base2;

  /* Create IIFE wrapper function */
  new_fs.f = addprototype(ls);
  new_fs.f->linedefined = line;
  open_func(ls, &new_fs, &bl);
  new_fs.f->numparams = 0;

  checknext(ls, '{' /*}*/);

  /* Parse body with auto-returning last expression */
  statlist_autoreturning(ls);

  new_fs.f->lastlinedefined = ls->linenumber;
  check_match(ls, /*{*/ '}', '{', line);
  codeclosure(ls, &fn_expr);
  close_func(ls);

  /* Generate immediate call: fn() */
  luaK_exp2nextreg(prev_fs, &fn_expr);
  base2 = fn_expr.u.info;
  init_exp(v, VCALL,
           luaK_codeABC(prev_fs, OP_CALL, base2, 1, 2));
  prev_fs->freereg = cast_byte(base2 + 1);
}


/*
** If expression: if (cond) { expr1 } else { expr2 }
** Wraps in IIFE where each branch auto-returns its last expression.
*/
static void ifexpr (LexState *ls, expdesc *v, int line) {
  FuncState new_fs;
  FuncState *prev_fs = ls->fs;
  BlockCnt bl;
  expdesc fn_expr;
  int base2;

  /* Create IIFE wrapper function */
  new_fs.f = addprototype(ls);
  new_fs.f->linedefined = line;
  open_func(ls, &new_fs, &bl);
  new_fs.f->numparams = 0;

  /* Parse if statement with auto-returning branches */
  {
    FuncState *fs = ls->fs;
    int escapelist = NO_JUMP;
    /* Parse IF cond { block } with auto-returning */
    {
      int condtrue;
      luaX_next(ls);  /* skip IF */
      checknext(ls, '(');
      condtrue = cond(ls);
      checknext(ls, ')');
      checknext(ls, '{' /*}*/);
      {
        BlockCnt bl2;
        enterblock(fs, &bl2, 0);
        statlist_autoreturning(ls);
        leaveblock(fs);
      }
      checknext(ls, /*{*/ '}');
      if (ls->t.token == TK_ELSE)
        luaK_concat(fs, &escapelist, luaK_jump(fs));
      luaK_patchtohere(fs, condtrue);
    }
    /* Parse ELSE IF chains */
    while (ls->t.token == TK_ELSE && luaX_lookahead(ls) == TK_IF) {
      int condtrue;
      luaX_next(ls);  /* skip ELSE */
      luaX_next(ls);  /* skip IF */
      checknext(ls, '(');
      condtrue = cond(ls);
      checknext(ls, ')');
      checknext(ls, '{' /*}*/);
      {
        BlockCnt bl2;
        enterblock(fs, &bl2, 0);
        statlist_autoreturning(ls);
        leaveblock(fs);
      }
      checknext(ls, /*{*/ '}');
      if (ls->t.token == TK_ELSE)
        luaK_concat(fs, &escapelist, luaK_jump(fs));
      luaK_patchtohere(fs, condtrue);
    }
    /* Parse ELSE */
    if (testnext(ls, TK_ELSE)) {
      checknext(ls, '{' /*}*/);
      {
        BlockCnt bl2;
        enterblock(fs, &bl2, 0);
        statlist_autoreturning(ls);
        leaveblock(fs);
      }
      check_match(ls, /*{*/ '}', TK_IF, line);
    }
    luaK_patchtohere(fs, escapelist);
  }

  new_fs.f->lastlinedefined = ls->linenumber;
  codeclosure(ls, &fn_expr);
  close_func(ls);

  /* Generate immediate call: fn() */
  luaK_exp2nextreg(prev_fs, &fn_expr);
  base2 = fn_expr.u.info;
  init_exp(v, VCALL,
           luaK_codeABC(prev_fs, OP_CALL, base2, 1, 2));
  prev_fs->freereg = cast_byte(base2 + 1);
}
