/*
** $Id: lparser_cj_match.c $
** Cangjie pattern matching and expression forms
** This file is #include'd from lparser.c and shares its static context.
**
** Contents:
**   match_case_body           — Parse match case body statements
**   match_bind_enum_params    — Bind enum constructor parameters
**   match_emit_tag_check      — Emit tag check for enum patterns
**   match_emit_type_check     — Emit type check for type patterns
**   match_emit_tuple_check    — Emit tuple pattern check
**   match_bind_tuple_elem     — Bind tuple element variables
**   match_emit_tuple_subpattern — Emit nested tuple sub-patterns
**   matchstat_impl            — Main match statement implementation
**   matchstat                 — Entry point for match statement
**   matchstat_returning       — Match statement with auto-return
**   statlist_autoreturning    — Statement list with implicit return
**   blockexpr                 — Block expression { stmts; expr }
**   ifexpr                    — If expression (produces value)
**   match_case_body_returning — Match case with auto-return
**   matchexpr                 — Match expression (produces value)
**
** See Copyright Notice in lua.h
*/

/*
** Parse statements in a match case body.
** Stops at: next 'case', closing '}', or end of file.
** Also supports optional '{' ... '}' braces for backward compatibility.
*/
static void match_case_body (LexState *ls) {
  if (ls->t.token == '{') {
    /* Braces-style body (backward compat / ext-features) */
    luaX_next(ls);  /* skip '{' */
    statlist(ls);
    checknext(ls, '}');
  }
  else {
    /* Cangjie-style: statements until next 'case' or '}' */
    while (ls->t.token != TK_CASE &&
           ls->t.token != /*{*/ '}' &&
           ls->t.token != TK_EOS) {
      if (ls->t.token == TK_RETURN) {
        statement(ls);
        return;  /* 'return' must be last statement */
      }
      statement(ls);
    }
  }
}


/*
** Emit code to bind enum destructured parameters from __match_val.
** For each parameter, creates a local variable bound to __match_val[pi+1].
*/
static void match_bind_enum_params (LexState *ls, TString *match_var_name,
                                    TString **param_names, int nparams) {
  FuncState *fs = ls->fs;
  int pi;
  for (pi = 0; pi < nparams; pi++) {
    if (param_names[pi] != NULL) {
      expdesc pval, idx_exp;
      new_varkind(ls, param_names[pi], VDKREG);
      buildvar(ls, match_var_name, &pval);
      luaK_exp2anyregup(fs, &pval);
      init_exp(&idx_exp, VKINT, 0);
      idx_exp.u.ival = pi + 1;
      luaK_indexed(fs, &pval, &idx_exp);
      luaK_exp2nextreg(fs, &pval);
      adjustlocalvars(ls, 1);
    }
    else {
      /* Wildcard binding - create dummy local */
      char dummy_name[16];
      TString *dn;
      expdesc pval, idx_exp;
      snprintf(dummy_name, sizeof(dummy_name), "__wd%d", pi);
      dn = luaX_newstring(ls, dummy_name, (size_t)strlen(dummy_name));
      new_varkind(ls, dn, VDKREG);
      buildvar(ls, match_var_name, &pval);
      luaK_exp2anyregup(fs, &pval);
      init_exp(&idx_exp, VKINT, 0);
      idx_exp.u.ival = pi + 1;
      luaK_indexed(fs, &pval, &idx_exp);
      luaK_exp2nextreg(fs, &pval);
      adjustlocalvars(ls, 1);
    }
  }
}


/*
** Emit code for: if __cangjie_match_tag(match_var, tag_str) then ...
** Returns the condjmp (false branch patch point) and sets fs->freereg.
*/
static int match_emit_tag_check (LexState *ls, TString *match_var_name,
                                 TString *tag_str) {
  FuncState *fs = ls->fs;
  expdesc fn, arg1, arg2, cond;
  int base2;
  int condjmp;

  buildvar(ls, luaX_newstring(ls, "__cangjie_match_tag", 19), &fn);
  luaK_exp2nextreg(fs, &fn);
  base2 = fn.u.info;
  buildvar(ls, match_var_name, &arg1);
  luaK_exp2nextreg(fs, &arg1);
  codestring(&arg2, tag_str);
  luaK_exp2nextreg(fs, &arg2);
  init_exp(&fn, VCALL,
           luaK_codeABC(fs, OP_CALL, base2, 3, 2));
  fs->freereg = cast_byte(base2 + 1);

  init_exp(&cond, VNONRELOC, base2);
  luaK_goiftrue(fs, &cond);
  condjmp = cond.f;
  fs->freereg = cast_byte(base2);
  return condjmp;
}


/*
** Emit code for: if __cangjie_is_instance(match_var, TypeName) then ...
** Returns the condjmp (false branch patch point).
*/
static int match_emit_type_check (LexState *ls, TString *match_var_name,
                                  TString *type_name) {
  FuncState *fs = ls->fs;
  expdesc fn, arg1, arg2, cond;
  int base2;
  int condjmp;

  buildvar(ls, luaX_newstring(ls, "__cangjie_is_instance", 21), &fn);
  luaK_exp2nextreg(fs, &fn);
  base2 = fn.u.info;
  buildvar(ls, match_var_name, &arg1);
  luaK_exp2nextreg(fs, &arg1);
  buildvar(ls, type_name, &arg2);
  luaK_exp2nextreg(fs, &arg2);
  init_exp(&fn, VCALL,
           luaK_codeABC(fs, OP_CALL, base2, 3, 2));
  fs->freereg = cast_byte(base2 + 1);

  init_exp(&cond, VNONRELOC, base2);
  luaK_goiftrue(fs, &cond);
  condjmp = cond.f;
  fs->freereg = cast_byte(base2);
  return condjmp;
}


/*
** Emit code for tuple pattern check:
** if match_var.__tuple and match_var.__n == npatterns then ...
** Returns the condjmp (false branch patch point).
*/
static int match_emit_tuple_check (LexState *ls, TString *match_var_name,
                                   int npatterns) {
  FuncState *fs = ls->fs;
  expdesc fn, arg1, arg2, cond;
  int base2;
  int condjmp;

  buildvar(ls, luaX_newstring(ls, "__cangjie_match_tuple", 21), &fn);
  luaK_exp2nextreg(fs, &fn);
  base2 = fn.u.info;
  buildvar(ls, match_var_name, &arg1);
  luaK_exp2nextreg(fs, &arg1);
  {
    expdesc nval;
    init_exp(&nval, VKINT, 0);
    nval.u.ival = npatterns;
    luaK_exp2nextreg(fs, &nval);
  }
  init_exp(&fn, VCALL,
           luaK_codeABC(fs, OP_CALL, base2, 3, 2));
  fs->freereg = cast_byte(base2 + 1);

  init_exp(&cond, VNONRELOC, base2);
  luaK_goiftrue(fs, &cond);
  condjmp = cond.f;
  fs->freereg = cast_byte(base2);
  return condjmp;
}


/*
** Bind a tuple element to a local variable: local name = match_var[index]
*/
static void match_bind_tuple_elem (LexState *ls, TString *match_var_name,
                                   TString *name, int index) {
  FuncState *fs = ls->fs;
  expdesc pval, idx_exp;
  new_varkind(ls, name, VDKREG);
  buildvar(ls, match_var_name, &pval);
  luaK_exp2anyregup(fs, &pval);
  init_exp(&idx_exp, VKINT, 0);
  idx_exp.u.ival = index;
  luaK_indexed(fs, &pval, &idx_exp);
  luaK_exp2nextreg(fs, &pval);
  adjustlocalvars(ls, 1);
}


/*
** Emit condition for a sub-pattern inside tuple at given index.
** Creates a temp var for match_var[index] and emits tag/type check.
** Returns condjmp for the false branch.
*/
static int match_emit_tuple_subpattern (LexState *ls, TString *match_var_name,
                                        int index, TString *patname) {
  FuncState *fs = ls->fs;
  char tmp_name[32];
  TString *tmp;
  expdesc tv, idx_exp;

  /* Create temp: local __tsub_N = match_var[index] */
  snprintf(tmp_name, sizeof(tmp_name), "__tsub_%d", index);
  tmp = luaX_newstring(ls, tmp_name, (size_t)strlen(tmp_name));
  new_varkind(ls, tmp, VDKREG);
  buildvar(ls, match_var_name, &tv);
  luaK_exp2anyregup(fs, &tv);
  init_exp(&idx_exp, VKINT, 0);
  idx_exp.u.ival = index;
  luaK_indexed(fs, &tv, &idx_exp);
  luaK_exp2nextreg(fs, &tv);
  adjustlocalvars(ls, 1);

  /* Now check tag on the temp var */
  return match_emit_tag_check(ls, tmp, patname);
}


/*
** ============================================================
** Pattern matching (match expression)
** Compiles Cangjie match expressions to if-elseif chains.
** Supports: enum patterns, constant patterns, wildcard,
** type patterns, tuple patterns, nested patterns.
** ============================================================
*/
static void match_case_body_returning (LexState *ls);
static void matchstat_impl (LexState *ls, int line, int autoreturn) {
  /*
  ** match '(' expr ')' '{' case_clauses '}'
  ** Supports:
  **   case CtorName(p1, p2) =>     -- enum destructor pattern
  **   case CtorName =>             -- no-arg enum pattern
  **   case (p1, p2) =>             -- tuple pattern
  **   case x: TypeName =>          -- type pattern
  **   case 42 / "str" / true =>    -- constant pattern
  **   case _ =>                    -- wildcard pattern
  ** Body after => does NOT require braces (Cangjie syntax).
  */
  FuncState *fs = ls->fs;
  expdesc match_val;
  int jmp_to_end[256];
  int njumps = 0;
  TString *match_var_name;

  luaX_next(ls);  /* skip 'match' */
  checknext(ls, '(');
  expr(ls, &match_val);
  checknext(ls, ')');

  /* Store match value in a local variable */
  match_var_name = luaX_newstring(ls, "__match_val", 11);
  {
    new_varkind(ls, match_var_name, VDKREG);
    luaK_exp2nextreg(fs, &match_val);
    adjustlocalvars(ls, 1);
  }

  checknext(ls, '{' /*}*/);

  /* Parse case clauses */
  while (ls->t.token == TK_CASE && ls->t.token != TK_EOS) {
    BlockCnt bl;
    luaX_next(ls);  /* skip 'case' */

    /* === Wildcard pattern: _ => body === */
    if (ls->t.token == TK_NAME &&
        strcmp(getstr(ls->t.seminfo.ts), "_") == 0 &&
        luaX_lookahead(ls) == TK_ARROW) {
      luaX_next(ls);  /* skip '_' */
      checknext(ls, TK_ARROW);
      enterblock(fs, &bl, 0);
      if (autoreturn) match_case_body_returning(ls); else match_case_body(ls);
      leaveblock(fs);
      if (njumps < 256)
        jmp_to_end[njumps++] = luaK_jump(fs);
    }
    /* === Tuple pattern: (p1, p2, ...) => body === */
    else if (ls->t.token == '(') {
      int npatterns = 0;
      /* Each sub-pattern can be: name (binding), _ (wildcard),
      ** or EnumCtor (tag check on element) */
      TString *tpat_names[32];  /* binding name or NULL for wildcard */
      TString *tpat_tags[32];   /* enum tag for sub-pattern or NULL */
      int condjmp;
      int sub_jumps[32];
      int nsub_jumps = 0;

      luaX_next(ls);  /* skip '(' */
      while (ls->t.token != ')' && ls->t.token != TK_EOS) {
        if (ls->t.token == TK_NAME) {
          TString *nm = ls->t.seminfo.ts;
          if (strcmp(getstr(nm), "_") == 0) {
            if (npatterns < 32) {
              tpat_names[npatterns] = NULL;
              tpat_tags[npatterns] = NULL;
              npatterns++;
            }
          }
          else {
            if (npatterns < 32) {
              tpat_names[npatterns] = nm;
              tpat_tags[npatterns] = NULL;
              npatterns++;
            }
          }
          luaX_next(ls);
        }
        if (!testnext(ls, ',')) break;
      }
      checknext(ls, ')');
      checknext(ls, TK_ARROW);

      /* Emit tuple check */
      condjmp = match_emit_tuple_check(ls, match_var_name, npatterns);

      enterblock(fs, &bl, 0);

      /* Bind tuple elements */
      {
        int ti;
        for (ti = 0; ti < npatterns; ti++) {
          if (tpat_names[ti] != NULL) {
            match_bind_tuple_elem(ls, match_var_name, tpat_names[ti], ti);
          }
          else {
            /* Wildcard - skip binding */
            char dn[16];
            TString *dname;
            snprintf(dn, sizeof(dn), "__td%d", ti);
            dname = luaX_newstring(ls, dn, (size_t)strlen(dn));
            match_bind_tuple_elem(ls, match_var_name, dname, ti);
          }
        }
      }

      if (autoreturn) match_case_body_returning(ls); else match_case_body(ls);
      leaveblock(fs);

      if (njumps < 256)
        jmp_to_end[njumps++] = luaK_jump(fs);
      luaK_patchtohere(fs, condjmp);
      {
        int si;
        for (si = 0; si < nsub_jumps; si++)
          luaK_patchtohere(fs, sub_jumps[si]);
      }
    }
    /* === Name-based patterns === */
    else if (ls->t.token == TK_NAME) {
      TString *patname = ls->t.seminfo.ts;
      luaX_next(ls);  /* skip name */

      if (ls->t.token == '(') {
        /* Enum constructor pattern: Ctor(p1, p2, ...) => body */
        int nparams = 0;
        TString *param_names[32];
        int condjmp;

        luaX_next(ls);  /* skip '(' */
        while (ls->t.token != ')' && ls->t.token != TK_EOS) {
          if (ls->t.token == TK_NAME) {
            TString *nm = ls->t.seminfo.ts;
            if (strcmp(getstr(nm), "_") == 0) {
              if (nparams < 32) param_names[nparams++] = NULL;
            }
            else {
              if (nparams < 32) param_names[nparams++] = nm;
            }
            luaX_next(ls);
          }
          if (!testnext(ls, ',')) break;
        }
        checknext(ls, ')');
        checknext(ls, TK_ARROW);

        condjmp = match_emit_tag_check(ls, match_var_name, patname);
        enterblock(fs, &bl, 0);
        match_bind_enum_params(ls, match_var_name, param_names, nparams);
        if (autoreturn) match_case_body_returning(ls); else match_case_body(ls);
        leaveblock(fs);

        if (njumps < 256)
          jmp_to_end[njumps++] = luaK_jump(fs);
        luaK_patchtohere(fs, condjmp);
      }
      else if (ls->t.token == ':') {
        /* Type pattern: name: TypeName => body */
        TString *type_name;
        int condjmp;
        luaX_next(ls);  /* skip ':' */
        type_name = str_checkname(ls);
        checknext(ls, TK_ARROW);

        condjmp = match_emit_type_check(ls, match_var_name, type_name);
        enterblock(fs, &bl, 0);
        /* Bind name to match_val */
        {
          expdesc mv;
          new_varkind(ls, patname, VDKREG);
          buildvar(ls, match_var_name, &mv);
          luaK_exp2nextreg(fs, &mv);
          adjustlocalvars(ls, 1);
        }
        if (autoreturn) match_case_body_returning(ls); else match_case_body(ls);
        leaveblock(fs);

        if (njumps < 256)
          jmp_to_end[njumps++] = luaK_jump(fs);
        luaK_patchtohere(fs, condjmp);
      }
      else {
        /* No-arg enum constructor or binding pattern: Name => body */
        int condjmp;
        checknext(ls, TK_ARROW);

        condjmp = match_emit_tag_check(ls, match_var_name, patname);
        enterblock(fs, &bl, 0);
        if (autoreturn) match_case_body_returning(ls); else match_case_body(ls);
        leaveblock(fs);

        if (njumps < 256)
          jmp_to_end[njumps++] = luaK_jump(fs);
        luaK_patchtohere(fs, condjmp);
      }
    }
    /* === Constant patterns === */
    else if (ls->t.token == TK_INT || ls->t.token == TK_FLT ||
             ls->t.token == TK_STRING || ls->t.token == TK_TRUE ||
             ls->t.token == TK_FALSE || ls->t.token == TK_NIL) {
      expdesc pat_val;
      BlockCnt bl2;
      int condjmp;

      simpleexp(ls, &pat_val);
      checknext(ls, TK_ARROW);

      {
        expdesc lhs;
        buildvar(ls, match_var_name, &lhs);
        luaK_infix(fs, OPR_EQ, &lhs);
        luaK_posfix(fs, OPR_EQ, &lhs, &pat_val, line);
        luaK_goiftrue(fs, &lhs);
        condjmp = lhs.f;
      }

      enterblock(fs, &bl2, 0);
      if (autoreturn) match_case_body_returning(ls); else match_case_body(ls);
      leaveblock(fs);

      if (njumps < 256)
        jmp_to_end[njumps++] = luaK_jump(fs);
      luaK_patchtohere(fs, condjmp);
    }
    else {
      luaX_syntaxerror(ls, "invalid pattern in match expression");
    }
  }

  check_match(ls, /*{*/ '}', TK_MATCH, line);

  /* Patch all jumps to the end */
  {
    int ji;
    for (ji = 0; ji < njumps; ji++) {
      luaK_patchtohere(fs, jmp_to_end[ji]);
    }
  }
}

static void matchstat (LexState *ls, int line) {
  matchstat_impl(ls, line, 0);
}

static void matchstat_returning (LexState *ls, int line) {
  matchstat_impl(ls, line, 1);
}


static void statlist_autoreturning (LexState *ls) {
  while (!block_follow(ls, 1)) {
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
          if (block_follow(ls, 1))
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
            if (block_follow(ls, 1)) {
              /* Last expression before '}' - auto-return */
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
          if (block_follow(ls, 1)) {
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


/*
** Match case body with auto-returning: parse statements until next
** 'case' or '}', with the last expression auto-returned.
*/
static void match_case_body_returning (LexState *ls) {
  if (ls->t.token == '{') {
    /* Braces-style body */
    luaX_next(ls);  /* skip '{' */
    statlist_autoreturning(ls);
    checknext(ls, '}');
  }
  else {
    /* Cangjie-style: statements until next 'case' or '}' */
    while (ls->t.token != TK_CASE &&
           ls->t.token != /*{*/ '}' &&
           ls->t.token != TK_EOS) {
      if (ls->t.token == TK_RETURN) {
        statement(ls);
        return;
      }
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
            if (ls->t.token == TK_CASE ||
                ls->t.token == /*{*/ '}' ||
                ls->t.token == TK_EOS)
              return;  /* was the last statement */
          }
          else {
            statement(ls);
          }
        }
        else {
          FuncState *fs = ls->fs;
          enterlevel(ls);
          if (tok == '(' && luaX_lookahead(ls) == ')') {
            luaX_next(ls);
            luaX_next(ls);
          }
          else if (tok == TK_NAME || tok == TK_THIS) {
            expdesc e;
            suffixedexp(ls, &e);
            if (ls->t.token == '=' || ls->t.token == ',') {
              struct LHS_assign v;
              v.v = e;
              v.prev = NULL;
              restassign(ls, &v, 1);
            }
            else {
              /* Continue parsing binary ops */
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
              if (ls->t.token == TK_CASE ||
                  ls->t.token == /*{*/ '}' ||
                  ls->t.token == TK_EOS) {
                /* Last expression - auto-return */
                luaK_ret(fs, luaK_exp2anyreg(fs, &e), 1);
                lua_assert(fs->f->maxstacksize >= fs->freereg &&
                           fs->freereg >= luaY_nvarstack(fs));
                fs->freereg = luaY_nvarstack(fs);
                leavelevel(ls);
                return;
              }
              else {
                Instruction *inst;
                check_condition(ls, e.k == VCALL, "syntax error");
                inst = &getinstruction(fs, &e);
                SETARG_C(*inst, 1);
              }
            }
          }
          else {
            /* Non-NAME: literal, unary, etc. - parse full expression */
            expdesc e;
            expr(ls, &e);
            if (ls->t.token == TK_CASE ||
                ls->t.token == /*{*/ '}' ||
                ls->t.token == TK_EOS) {
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
}


/*
** Match expression: match (expr) { case ... => expr }
** Wraps in IIFE where each case branch auto-returns its last expression.
*/
static void matchexpr (LexState *ls, expdesc *v, int line) {
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

  /* Parse match expression body - replicates matchstat but with auto-return */
  {
    FuncState *fs = ls->fs;
    expdesc match_val;
    int jmp_to_end[256];
    int njumps = 0;
    TString *match_var_name;

    luaX_next(ls);  /* skip 'match' */
    checknext(ls, '(');
    expr(ls, &match_val);
    checknext(ls, ')');

    match_var_name = luaX_newstring(ls, "__match_val", 11);
    {
      new_varkind(ls, match_var_name, VDKREG);
      luaK_exp2nextreg(fs, &match_val);
      adjustlocalvars(ls, 1);
    }

    checknext(ls, '{' /*}*/);

    while (ls->t.token == TK_CASE && ls->t.token != TK_EOS) {
      BlockCnt bl2;
      luaX_next(ls);  /* skip 'case' */

      /* Wildcard pattern */
      if (ls->t.token == TK_NAME &&
          strcmp(getstr(ls->t.seminfo.ts), "_") == 0 &&
          luaX_lookahead(ls) == TK_ARROW) {
        luaX_next(ls);
        checknext(ls, TK_ARROW);
        enterblock(fs, &bl2, 0);
        match_case_body_returning(ls);
        leaveblock(fs);
        if (njumps < 256)
          jmp_to_end[njumps++] = luaK_jump(fs);
      }
      /* Tuple pattern */
      else if (ls->t.token == '(') {
        int npatterns = 0;
        TString *tpat_names[32];
        TString *tpat_tags[32];
        int condjmp;

        luaX_next(ls);
        while (ls->t.token != ')' && ls->t.token != TK_EOS) {
          if (ls->t.token == TK_NAME) {
            TString *nm = ls->t.seminfo.ts;
            if (strcmp(getstr(nm), "_") == 0) {
              if (npatterns < 32) { tpat_names[npatterns] = NULL; tpat_tags[npatterns] = NULL; npatterns++; }
            } else {
              if (npatterns < 32) { tpat_names[npatterns] = nm; tpat_tags[npatterns] = NULL; npatterns++; }
            }
            luaX_next(ls);
          }
          if (!testnext(ls, ',')) break;
        }
        checknext(ls, ')');
        checknext(ls, TK_ARROW);

        condjmp = match_emit_tuple_check(ls, match_var_name, npatterns);
        enterblock(fs, &bl2, 0);
        {
          int ti;
          for (ti = 0; ti < npatterns; ti++) {
            if (tpat_names[ti] != NULL) {
              match_bind_tuple_elem(ls, match_var_name, tpat_names[ti], ti);
            } else {
              char dn[16]; TString *dname;
              snprintf(dn, sizeof(dn), "__td%d", ti);
              dname = luaX_newstring(ls, dn, (size_t)strlen(dn));
              match_bind_tuple_elem(ls, match_var_name, dname, ti);
            }
          }
        }
        match_case_body_returning(ls);
        leaveblock(fs);
        if (njumps < 256)
          jmp_to_end[njumps++] = luaK_jump(fs);
        luaK_patchtohere(fs, condjmp);
      }
      /* Name-based patterns */
      else if (ls->t.token == TK_NAME) {
        TString *patname = ls->t.seminfo.ts;
        luaX_next(ls);

        if (ls->t.token == '(') {
          /* Enum constructor pattern */
          int nparams = 0;
          TString *param_names[32];
          int condjmp;

          luaX_next(ls);
          while (ls->t.token != ')' && ls->t.token != TK_EOS) {
            if (ls->t.token == TK_NAME) {
              TString *nm = ls->t.seminfo.ts;
              if (strcmp(getstr(nm), "_") == 0) {
                if (nparams < 32) param_names[nparams++] = NULL;
              } else {
                if (nparams < 32) param_names[nparams++] = nm;
              }
              luaX_next(ls);
            }
            if (!testnext(ls, ',')) break;
          }
          checknext(ls, ')');
          checknext(ls, TK_ARROW);

          condjmp = match_emit_tag_check(ls, match_var_name, patname);
          enterblock(fs, &bl2, 0);
          match_bind_enum_params(ls, match_var_name, param_names, nparams);
          match_case_body_returning(ls);
          leaveblock(fs);
          if (njumps < 256)
            jmp_to_end[njumps++] = luaK_jump(fs);
          luaK_patchtohere(fs, condjmp);
        }
        else if (ls->t.token == ':') {
          /* Type pattern */
          TString *type_name;
          int condjmp;
          luaX_next(ls);
          type_name = str_checkname(ls);
          checknext(ls, TK_ARROW);

          condjmp = match_emit_type_check(ls, match_var_name, type_name);
          enterblock(fs, &bl2, 0);
          {
            expdesc mv;
            new_varkind(ls, patname, VDKREG);
            buildvar(ls, match_var_name, &mv);
            luaK_exp2nextreg(fs, &mv);
            adjustlocalvars(ls, 1);
          }
          match_case_body_returning(ls);
          leaveblock(fs);
          if (njumps < 256)
            jmp_to_end[njumps++] = luaK_jump(fs);
          luaK_patchtohere(fs, condjmp);
        }
        else {
          /* No-arg enum constructor pattern */
          int condjmp;
          checknext(ls, TK_ARROW);
          condjmp = match_emit_tag_check(ls, match_var_name, patname);
          enterblock(fs, &bl2, 0);
          match_case_body_returning(ls);
          leaveblock(fs);
          if (njumps < 256)
            jmp_to_end[njumps++] = luaK_jump(fs);
          luaK_patchtohere(fs, condjmp);
        }
      }
      /* Constant patterns */
      else if (ls->t.token == TK_INT || ls->t.token == TK_FLT ||
               ls->t.token == TK_STRING || ls->t.token == TK_TRUE ||
               ls->t.token == TK_FALSE || ls->t.token == TK_NIL) {
        expdesc pat_val;
        BlockCnt bl3;
        int condjmp;

        simpleexp(ls, &pat_val);
        checknext(ls, TK_ARROW);

        {
          expdesc lhs;
          buildvar(ls, match_var_name, &lhs);
          luaK_infix(fs, OPR_EQ, &lhs);
          luaK_posfix(fs, OPR_EQ, &lhs, &pat_val, line);
          luaK_goiftrue(fs, &lhs);
          condjmp = lhs.f;
        }

        enterblock(fs, &bl3, 0);
        match_case_body_returning(ls);
        leaveblock(fs);
        if (njumps < 256)
          jmp_to_end[njumps++] = luaK_jump(fs);
        luaK_patchtohere(fs, condjmp);
      }
      else {
        luaX_syntaxerror(ls, "invalid pattern in match expression");
      }
    }

    check_match(ls, /*{*/ '}', TK_MATCH, line);

    {
      int ji;
      for (ji = 0; ji < njumps; ji++)
        luaK_patchtohere(fs, jmp_to_end[ji]);
    }
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


