/*
** $Id: lparser_cj_runtime.c $
** Cangjie runtime call helpers shared by type and match parsing.
** This file is #include'd from lparser.c and shares its static context.
**
** Contents:
**   emit_runtime_call1/emit_runtime_call2 — side-effect runtime calls
**   emit_runtime_check2                   — predicate runtime checks
**
** See Copyright Notice in lua.h
*/

/*
** ============================================================
** Runtime call helpers
** Centralize emission of __cangjie_* runtime calls so match and
** type parsing use the same register allocation strategy.
** ============================================================
*/
static int emit_runtime_call_base (LexState *ls, const char *funcname,
                                   expdesc *args, int nargs, int nret) {
  FuncState *fs = ls->fs;
  expdesc fn;
  int base;
  int i;
  buildvar(ls, luaX_newstring(ls, funcname, strlen(funcname)), &fn);
  luaK_exp2nextreg(fs, &fn);
  base = fn.u.info;
  for (i = 0; i < nargs; i++) {
    luaK_exp2nextreg(fs, &args[i]);
  }
  init_exp(&fn, VCALL,
           luaK_codeABC(fs, OP_CALL, base, nargs + 1, nret + 1));
  return base;
}


/*
** Emit a call to a runtime function with 1 argument (by variable name).
** Generates: funcname(arg)
*/
static void emit_runtime_call1 (LexState *ls, const char *funcname,
                                TString *arg) {
  FuncState *fs = ls->fs;
  expdesc args[1];
  int base;
  buildvar(ls, arg, &args[0]);
  base = emit_runtime_call_base(ls, funcname, args, 1, 0);
  fs->freereg = cast_byte(base);
}


/*
** Emit a call to a runtime function with 2 arguments (by variable name).
** Generates: funcname(arg1, arg2)
*/
static void emit_runtime_call2 (LexState *ls, const char *funcname,
                                TString *arg1, TString *arg2) {
  FuncState *fs = ls->fs;
  expdesc args[2];
  int base;
  buildvar(ls, arg1, &args[0]);
  buildvar(ls, arg2, &args[1]);
  base = emit_runtime_call_base(ls, funcname, args, 2, 0);
  fs->freereg = cast_byte(base);
}


/*
** Emit a predicate runtime call with 2 arguments and return a condjmp.
** Generates: if funcname(arg1, arg2) then ...
*/
static int emit_runtime_check2 (LexState *ls, const char *funcname,
                                expdesc *arg1, expdesc *arg2) {
  FuncState *fs = ls->fs;
  expdesc args[2];
  expdesc cond;
  int base;
  args[0] = *arg1;
  args[1] = *arg2;
  base = emit_runtime_call_base(ls, funcname, args, 2, 1);
  fs->freereg = cast_byte(base + 1);
  init_exp(&cond, VNONRELOC, base);
  luaK_goiftrue(fs, &cond);
  fs->freereg = cast_byte(base);
  return cond.f;
}
