/*
** $Id: lparser_cj_match.c $
** Cangjie pattern matching
** This file is #include'd from lparser.c and shares its static context.
** Requires lparser_cj_exprs.c to be included first (for auto-returning).
**
** Contents:
**   match_case_body              — Parse match case body statements
**   match_bind_enum_params       — Bind enum constructor parameters
**   match_emit_tag_check         — Emit tag check for enum patterns
**   match_emit_type_check        — Emit type check for type patterns
**   match_emit_tuple_check       — Emit tuple pattern check
**   match_bind_tuple_elem        — Bind tuple element variables
**   match_emit_tuple_subpattern  — Emit nested tuple sub-patterns
**   is_match_case_end            — Check for end of match case body
**   matchstat_impl               — Main match statement implementation
**   matchstat                    — Entry point for match statement
**   matchstat_returning          — Match statement with auto-return
**   match_case_body_returning    — Match case with auto-return
**   matchexpr                    — Match expression (produces value)
**
** See Copyright Notice in lua.h
*/

/*
** ============================================================
** Match case body and helpers
** Parse the statements within a match case arm.
** ============================================================
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
** ============================================================
** Pattern check emission helpers
** Each helper emits a runtime call that tests one aspect of the
** match value (tag, type, tuple arity) and returns the conditional
** jump instruction index for the false branch.
** ============================================================
*/

/*
** Emit code for: if __cangjie_match_tag(match_var, tag_str) then ...
** Returns the condjmp (false branch patch point) and sets fs->freereg.
*/
static int match_emit_tag_check (LexState *ls, TString *match_var_name,
                                 TString *tag_str) {
  expdesc arg1, arg2;
  buildvar(ls, match_var_name, &arg1);
  codestring(&arg2, tag_str);
  return emit_runtime_check2(ls, "__cangjie_match_tag", &arg1, &arg2);
}


/*
** Emit code for: if __cangjie_is_instance(match_var, TypeName) then ...
** Returns the condjmp (false branch patch point).
*/
static int match_emit_type_check (LexState *ls, TString *match_var_name,
                                  TString *type_name) {
  expdesc arg1, arg2;
  buildvar(ls, match_var_name, &arg1);
  buildvar(ls, type_name, &arg2);
  return emit_runtime_check2(ls, "__cangjie_is_instance", &arg1, &arg2);
}


/*
** ============================================================
** Tuple pattern helpers
** ============================================================
*/

/*
** Emit code for tuple pattern check:
** if match_var.__tuple and match_var.__n == npatterns then ...
** Returns the condjmp (false branch patch point).
*/
static int match_emit_tuple_check (LexState *ls, TString *match_var_name,
                                   int npatterns) {
  expdesc arg1, arg2;
  buildvar(ls, match_var_name, &arg1);
  init_exp(&arg2, VKINT, 0);
  arg2.u.ival = npatterns;
  return emit_runtime_check2(ls, "__cangjie_match_tuple", &arg1, &arg2);
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

/*
** Check whether current token ends a match case body.
** Returns true if token is 'case', '}', or end-of-stream.
*/
static int is_match_case_end (LexState *ls) {
  return ls->t.token == TK_CASE ||
         ls->t.token == /*{*/ '}' ||
         ls->t.token == TK_EOS;
}

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
    else if (ls->t.token == TK_INT || ls->t.token == TK_UINT ||
             ls->t.token == TK_FLT || ls->t.token == TK_STRING ||
             ls->t.token == TK_TRUE ||
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

/* matchstat — non-returning match statement entry point */
static void matchstat (LexState *ls, int line) {
  matchstat_impl(ls, line, 0);
}

/* matchstat_returning — match statement where each branch auto-returns */
static void matchstat_returning (LexState *ls, int line) {
  matchstat_impl(ls, line, 1);
}


/*
** Match case body with auto-returning: parse statements until next
** 'case' or '}', with the last expression auto-returned.
** Braces-style body delegates to statlist_autoreturning (block context);
** bare-style body uses statlist_autoreturning_ex with match-case end check.
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
    statlist_autoreturning_ex(ls, 1);
  }
}


/*
** Match expression: match (expr) { case ... => expr }
** Wraps in IIFE where each case branch auto-returns its last expression.
** Reuses matchstat_impl with autoreturn=1, same pattern as blockexpr/ifexpr.
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

  /* Reuse matchstat_impl with autoreturn=1 */
  matchstat_impl(ls, line, 1);

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
