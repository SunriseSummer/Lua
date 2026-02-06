/*
** $Id: lparser.c $
** Lua Parser
** See Copyright Notice in lua.h
*/

#define lparser_c
#define LUA_CORE

#include "lprefix.h"


#include <limits.h>
#include <string.h>

#include "lua.h"

#include "lcode.h"
#include "ldebug.h"
#include "ldo.h"
#include "lfunc.h"
#include "llex.h"
#include "lmem.h"
#include "lobject.h"
#include "lopcodes.h"
#include "lparser.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"



/* maximum number of variable declarations per function (must be
   smaller than 250, due to the bytecode format) */
#define MAXVARS		200


#define hasmultret(k)		((k) == VCALL || (k) == VVARARG)


/* because all strings are unified by the scanner, the parser
   can use pointer equality for string equality */
#define eqstr(a,b)	((a) == (b))


/*
** nodes for block list (list of active blocks)
*/
typedef struct BlockCnt {
  struct BlockCnt *previous;  /* chain */
  int firstlabel;  /* index of first label in this block */
  int firstgoto;  /* index of first pending goto in this block */
  short nactvar;  /* number of active declarations at block entry */
  lu_byte upval;  /* true if some variable in the block is an upvalue */
  lu_byte isloop;  /* 1 if 'block' is a loop; 2 if it has pending breaks */
  lu_byte insidetbc;  /* true if inside the scope of a to-be-closed var. */
} BlockCnt;



/*
** prototypes for recursive non-terminal functions
*/
static void statement (LexState *ls);
static void expr (LexState *ls, expdesc *v);


static l_noret error_expected (LexState *ls, int token) {
  luaX_syntaxerror(ls,
      luaO_pushfstring(ls->L, "%s expected", luaX_token2str(ls, token)));
}


static l_noret errorlimit (FuncState *fs, int limit, const char *what) {
  lua_State *L = fs->ls->L;
  const char *msg;
  int line = fs->f->linedefined;
  const char *where = (line == 0)
                      ? "main function"
                      : luaO_pushfstring(L, "function at line %d", line);
  msg = luaO_pushfstring(L, "too many %s (limit is %d) in %s",
                             what, limit, where);
  luaX_syntaxerror(fs->ls, msg);
}


void luaY_checklimit (FuncState *fs, int v, int l, const char *what) {
  if (l_unlikely(v > l)) errorlimit(fs, l, what);
}


/*
** Test whether next token is 'c'; if so, skip it.
*/
static int testnext (LexState *ls, int c) {
  if (ls->t.token == c) {
    luaX_next(ls);
    return 1;
  }
  else return 0;
}


/*
** Check that next token is 'c'.
*/
static void check (LexState *ls, int c) {
  if (ls->t.token != c)
    error_expected(ls, c);
}


/*
** Check that next token is 'c' and skip it.
*/
static void checknext (LexState *ls, int c) {
  check(ls, c);
  luaX_next(ls);
}


#define check_condition(ls,c,msg)	{ if (!(c)) luaX_syntaxerror(ls, msg); }


/*
** Check that next token is 'what' and skip it. In case of error,
** raise an error that the expected 'what' should match a 'who'
** in line 'where' (if that is not the current line).
*/
static void check_match (LexState *ls, int what, int who, int where) {
  if (l_unlikely(!testnext(ls, what))) {
    if (where == ls->linenumber)  /* all in the same line? */
      error_expected(ls, what);  /* do not need a complex message */
    else {
      luaX_syntaxerror(ls, luaO_pushfstring(ls->L,
             "%s expected (to close %s at line %d)",
              luaX_token2str(ls, what), luaX_token2str(ls, who), where));
    }
  }
}


static TString *str_checkname (LexState *ls) {
  TString *ts;
  check(ls, TK_NAME);
  ts = ls->t.seminfo.ts;
  luaX_next(ls);
  return ts;
}


static void init_exp (expdesc *e, expkind k, int i) {
  e->f = e->t = NO_JUMP;
  e->k = k;
  e->u.info = i;
}


static void codestring (expdesc *e, TString *s) {
  e->f = e->t = NO_JUMP;
  e->k = VKSTR;
  e->u.strval = s;
}


static void codename (LexState *ls, expdesc *e) {
  codestring(e, str_checkname(ls));
}


/*
** Register a new local variable in the active 'Proto' (for debug
** information).
*/
static short registerlocalvar (LexState *ls, FuncState *fs,
                               TString *varname) {
  Proto *f = fs->f;
  int oldsize = f->sizelocvars;
  luaM_growvector(ls->L, f->locvars, fs->ndebugvars, f->sizelocvars,
                  LocVar, SHRT_MAX, "local variables");
  while (oldsize < f->sizelocvars)
    f->locvars[oldsize++].varname = NULL;
  f->locvars[fs->ndebugvars].varname = varname;
  f->locvars[fs->ndebugvars].startpc = fs->pc;
  luaC_objbarrier(ls->L, f, varname);
  return fs->ndebugvars++;
}


/*
** Create a new variable with the given 'name' and given 'kind'.
** Return its index in the function.
*/
static int new_varkind (LexState *ls, TString *name, lu_byte kind) {
  lua_State *L = ls->L;
  FuncState *fs = ls->fs;
  Dyndata *dyd = ls->dyd;
  Vardesc *var;
  luaM_growvector(L, dyd->actvar.arr, dyd->actvar.n + 1,
             dyd->actvar.size, Vardesc, SHRT_MAX, "variable declarations");
  var = &dyd->actvar.arr[dyd->actvar.n++];
  var->vd.kind = kind;  /* default */
  var->vd.name = name;
  return dyd->actvar.n - 1 - fs->firstlocal;
}


/*
** Create a new local variable with the given 'name' and regular kind.
*/
static int new_localvar (LexState *ls, TString *name) {
  return new_varkind(ls, name, VDKREG);
}

#define new_localvarliteral(ls,v) \
    new_localvar(ls,  \
      luaX_newstring(ls, "" v, (sizeof(v)/sizeof(char)) - 1));



/*
** Return the "variable description" (Vardesc) of a given variable.
** (Unless noted otherwise, all variables are referred to by their
** compiler indices.)
*/
static Vardesc *getlocalvardesc (FuncState *fs, int vidx) {
  return &fs->ls->dyd->actvar.arr[fs->firstlocal + vidx];
}


/*
** Convert 'nvar', a compiler index level, to its corresponding
** register. For that, search for the highest variable below that level
** that is in a register and uses its register index ('ridx') plus one.
*/
static lu_byte reglevel (FuncState *fs, int nvar) {
  while (nvar-- > 0) {
    Vardesc *vd = getlocalvardesc(fs, nvar);  /* get previous variable */
    if (varinreg(vd))  /* is in a register? */
      return cast_byte(vd->vd.ridx + 1);
  }
  return 0;  /* no variables in registers */
}


/*
** Return the number of variables in the register stack for the given
** function.
*/
lu_byte luaY_nvarstack (FuncState *fs) {
  return reglevel(fs, fs->nactvar);
}


/*
** Get the debug-information entry for current variable 'vidx'.
*/
static LocVar *localdebuginfo (FuncState *fs, int vidx) {
  Vardesc *vd = getlocalvardesc(fs,  vidx);
  if (!varinreg(vd))
    return NULL;  /* no debug info. for constants */
  else {
    int idx = vd->vd.pidx;
    lua_assert(idx < fs->ndebugvars);
    return &fs->f->locvars[idx];
  }
}


/*
** Create an expression representing variable 'vidx'
*/
static void init_var (FuncState *fs, expdesc *e, int vidx) {
  e->f = e->t = NO_JUMP;
  e->k = VLOCAL;
  e->u.var.vidx = cast_short(vidx);
  e->u.var.ridx = getlocalvardesc(fs, vidx)->vd.ridx;
}


/*
** Raises an error if variable described by 'e' is read only; moreover,
** if 'e' is t[exp] where t is the vararg parameter, change it to index
** a real table. (Virtual vararg tables cannot be changed.)
*/
static void check_readonly (LexState *ls, expdesc *e) {
  FuncState *fs = ls->fs;
  TString *varname = NULL;  /* to be set if variable is const */
  switch (e->k) {
    case VCONST: {
      varname = ls->dyd->actvar.arr[e->u.info].vd.name;
      break;
    }
    case VLOCAL: case VVARGVAR: {
      Vardesc *vardesc = getlocalvardesc(fs, e->u.var.vidx);
      if (vardesc->vd.kind != VDKREG)  /* not a regular variable? */
        varname = vardesc->vd.name;
      break;
    }
    case VUPVAL: {
      Upvaldesc *up = &fs->f->upvalues[e->u.info];
      if (up->kind != VDKREG)
        varname = up->name;
      break;
    }
    case VVARGIND: {
      needvatab(fs->f);  /* function will need a vararg table */
      e->k = VINDEXED;
    }  /* FALLTHROUGH */
    case VINDEXUP: case VINDEXSTR: case VINDEXED: {  /* global variable */
      if (e->u.ind.ro)  /* read-only? */
        varname = tsvalue(&fs->f->k[e->u.ind.keystr]);
      break;
    }
    default:
      lua_assert(e->k == VINDEXI);  /* this one doesn't need any check */
      return;  /* integer index cannot be read-only */
  }
  if (varname)
    luaK_semerror(ls, "attempt to assign to const variable '%s'",
                      getstr(varname));
}


/*
** Start the scope for the last 'nvars' created variables.
*/
static void adjustlocalvars (LexState *ls, int nvars) {
  FuncState *fs = ls->fs;
  int reglevel = luaY_nvarstack(fs);
  int i;
  for (i = 0; i < nvars; i++) {
    int vidx = fs->nactvar++;
    Vardesc *var = getlocalvardesc(fs, vidx);
    var->vd.ridx = cast_byte(reglevel++);
    var->vd.pidx = registerlocalvar(ls, fs, var->vd.name);
    luaY_checklimit(fs, reglevel, MAXVARS, "local variables");
  }
}


/*
** Close the scope for all variables up to level 'tolevel'.
** (debug info.)
*/
static void removevars (FuncState *fs, int tolevel) {
  fs->ls->dyd->actvar.n -= (fs->nactvar - tolevel);
  while (fs->nactvar > tolevel) {
    LocVar *var = localdebuginfo(fs, --fs->nactvar);
    if (var)  /* does it have debug information? */
      var->endpc = fs->pc;
  }
}


/*
** Search the upvalues of the function 'fs' for one
** with the given 'name'.
*/
static int searchupvalue (FuncState *fs, TString *name) {
  int i;
  Upvaldesc *up = fs->f->upvalues;
  for (i = 0; i < fs->nups; i++) {
    if (eqstr(up[i].name, name)) return i;
  }
  return -1;  /* not found */
}


static Upvaldesc *allocupvalue (FuncState *fs) {
  Proto *f = fs->f;
  int oldsize = f->sizeupvalues;
  luaY_checklimit(fs, fs->nups + 1, MAXUPVAL, "upvalues");
  luaM_growvector(fs->ls->L, f->upvalues, fs->nups, f->sizeupvalues,
                  Upvaldesc, MAXUPVAL, "upvalues");
  while (oldsize < f->sizeupvalues)
    f->upvalues[oldsize++].name = NULL;
  return &f->upvalues[fs->nups++];
}


static int newupvalue (FuncState *fs, TString *name, expdesc *v) {
  Upvaldesc *up = allocupvalue(fs);
  FuncState *prev = fs->prev;
  if (v->k == VLOCAL) {
    up->instack = 1;
    up->idx = v->u.var.ridx;
    up->kind = getlocalvardesc(prev, v->u.var.vidx)->vd.kind;
    lua_assert(eqstr(name, getlocalvardesc(prev, v->u.var.vidx)->vd.name));
  }
  else {
    up->instack = 0;
    up->idx = cast_byte(v->u.info);
    up->kind = prev->f->upvalues[v->u.info].kind;
    lua_assert(eqstr(name, prev->f->upvalues[v->u.info].name));
  }
  up->name = name;
  luaC_objbarrier(fs->ls->L, fs->f, name);
  return fs->nups - 1;
}


/*
** Look for an active variable with the name 'n' in the
** function 'fs'. If found, initialize 'var' with it and return
** its expression kind; otherwise return -1. While searching,
** var->u.info==-1 means that the preambular global declaration is
** active (the default while there is no other global declaration);
** var->u.info==-2 means there is no active collective declaration
** (some previous global declaration but no collective declaration);
** and var->u.info>=0 points to the inner-most (the first one found)
** collective declaration, if there is one.
*/
static int searchvar (FuncState *fs, TString *n, expdesc *var) {
  int i;
  for (i = cast_int(fs->nactvar) - 1; i >= 0; i--) {
    Vardesc *vd = getlocalvardesc(fs, i);
    if (varglobal(vd)) {  /* global declaration? */
      if (vd->vd.name == NULL) {  /* collective declaration? */
        if (var->u.info < 0)  /* no previous collective declaration? */
          var->u.info = fs->firstlocal + i;  /* this is the first one */
      }
      else {  /* global name */
        if (eqstr(n, vd->vd.name)) {  /* found? */
          init_exp(var, VGLOBAL, fs->firstlocal + i);
          return VGLOBAL;
        }
        else if (var->u.info == -1)  /* active preambular declaration? */
          var->u.info = -2;  /* invalidate preambular declaration */
      }
    }
    else if (eqstr(n, vd->vd.name)) {  /* found? */
      if (vd->vd.kind == RDKCTC)  /* compile-time constant? */
        init_exp(var, VCONST, fs->firstlocal + i);
      else {  /* local variable */
        init_var(fs, var, i);
        if (vd->vd.kind == RDKVAVAR)  /* vararg parameter? */
          var->k = VVARGVAR;
      }
      return cast_int(var->k);
    }
  }
  return -1;  /* not found */
}


/*
** Mark block where variable at given level was defined
** (to emit close instructions later).
*/
static void markupval (FuncState *fs, int level) {
  BlockCnt *bl = fs->bl;
  while (bl->nactvar > level)
    bl = bl->previous;
  bl->upval = 1;
  fs->needclose = 1;
}


/*
** Mark that current block has a to-be-closed variable.
*/
static void marktobeclosed (FuncState *fs) {
  BlockCnt *bl = fs->bl;
  bl->upval = 1;
  bl->insidetbc = 1;
  fs->needclose = 1;
}


/*
** Find a variable with the given name 'n'. If it is an upvalue, add
** this upvalue into all intermediate functions. If it is a global, set
** 'var' as 'void' as a flag.
*/
static void singlevaraux (FuncState *fs, TString *n, expdesc *var, int base) {
  int v = searchvar(fs, n, var);  /* look up variables at current level */
  if (v >= 0) {  /* found? */
    if (!base) {
      if (var->k == VVARGVAR)  /* vararg parameter? */
        luaK_vapar2local(fs, var);  /* change it to a regular local */
      if (var->k == VLOCAL)
        markupval(fs, var->u.var.vidx);  /* will be used as an upvalue */
    }
    /* else nothing else to be done */
  }
  else {  /* not found at current level; try upvalues */
    int idx = searchupvalue(fs, n);  /* try existing upvalues */
    if (idx < 0) {  /* not found? */
      if (fs->prev != NULL)  /* more levels? */
        singlevaraux(fs->prev, n, var, 0);  /* try upper levels */
      if (var->k == VLOCAL || var->k == VUPVAL)  /* local or upvalue? */
        idx  = newupvalue(fs, n, var);  /* will be a new upvalue */
      else  /* it is a global or a constant */
        return;  /* don't need to do anything at this level */
    }
    init_exp(var, VUPVAL, idx);  /* new or old upvalue */
  }
}


static void buildglobal (LexState *ls, TString *varname, expdesc *var) {
  FuncState *fs = ls->fs;
  expdesc key;
  init_exp(var, VGLOBAL, -1);  /* global by default */
  singlevaraux(fs, ls->envn, var, 1);  /* get environment variable */
  if (var->k == VGLOBAL)
    luaK_semerror(ls, "%s is global when accessing variable '%s'",
                      LUA_ENV, getstr(varname));
  luaK_exp2anyregup(fs, var);  /* _ENV could be a constant */
  codestring(&key, varname);  /* key is variable name */
  luaK_indexed(fs, var, &key);  /* 'var' represents _ENV[varname] */
}


/*
** Find a variable with the given name 'n', handling global variables
** too.
*/
static void buildvar (LexState *ls, TString *varname, expdesc *var) {
  FuncState *fs = ls->fs;
  init_exp(var, VGLOBAL, -1);  /* global by default */
  singlevaraux(fs, varname, var, 1);
  if (var->k == VGLOBAL) {  /* global name? */
    int info = var->u.info;
    /* global by default in the scope of a global declaration? */
    if (info == -2)
      luaK_semerror(ls, "variable '%s' not declared", getstr(varname));
    buildglobal(ls, varname, var);
    if (info != -1 && ls->dyd->actvar.arr[info].vd.kind == GDKCONST)
      var->u.ind.ro = 1;  /* mark variable as read-only */
    else  /* anyway must be a global */
      lua_assert(info == -1 || ls->dyd->actvar.arr[info].vd.kind == GDKREG);
  }
}


static void singlevar (LexState *ls, expdesc *var) {
  buildvar(ls, str_checkname(ls), var);
}


/*
** Adjust the number of results from an expression list 'e' with 'nexps'
** expressions to 'nvars' values.
*/
static void adjust_assign (LexState *ls, int nvars, int nexps, expdesc *e) {
  FuncState *fs = ls->fs;
  int needed = nvars - nexps;  /* extra values needed */
  luaK_checkstack(fs, needed);
  if (hasmultret(e->k)) {  /* last expression has multiple returns? */
    int extra = needed + 1;  /* discount last expression itself */
    if (extra < 0)
      extra = 0;
    luaK_setreturns(fs, e, extra);  /* last exp. provides the difference */
  }
  else {
    if (e->k != VVOID)  /* at least one expression? */
      luaK_exp2nextreg(fs, e);  /* close last expression */
    if (needed > 0)  /* missing values? */
      luaK_nil(fs, fs->freereg, needed);  /* complete with nils */
  }
  if (needed > 0)
    luaK_reserveregs(fs, needed);  /* registers for extra values */
  else  /* adding 'needed' is actually a subtraction */
    fs->freereg = cast_byte(fs->freereg + needed);  /* remove extra values */
}


#define enterlevel(ls)	luaE_incCstack(ls->L)


#define leavelevel(ls) ((ls)->L->nCcalls--)


/*
** Generates an error that a goto jumps into the scope of some
** variable declaration.
*/
static l_noret jumpscopeerror (LexState *ls, Labeldesc *gt) {
  TString *tsname = getlocalvardesc(ls->fs, gt->nactvar)->vd.name;
  const char *varname = (tsname != NULL) ? getstr(tsname) : "*";
  luaK_semerror(ls,
     "<goto %s> at line %d jumps into the scope of '%s'",
      getstr(gt->name), gt->line, varname);  /* raise the error */
}


/*
** Closes the goto at index 'g' to given 'label' and removes it
** from the list of pending gotos.
** If it jumps into the scope of some variable, raises an error.
** The goto needs a CLOSE if it jumps out of a block with upvalues,
** or out of the scope of some variable and the block has upvalues
** (signaled by parameter 'bup').
*/
static void closegoto (LexState *ls, int g, Labeldesc *label, int bup) {
  int i;
  FuncState *fs = ls->fs;
  Labellist *gl = &ls->dyd->gt;  /* list of gotos */
  Labeldesc *gt = &gl->arr[g];  /* goto to be resolved */
  lua_assert(eqstr(gt->name, label->name));
  if (l_unlikely(gt->nactvar < label->nactvar))  /* enter some scope? */
    jumpscopeerror(ls, gt);
  if (gt->close ||
      (label->nactvar < gt->nactvar && bup)) {  /* needs close? */
    lu_byte stklevel = reglevel(fs, label->nactvar);
    /* move jump to CLOSE position */
    fs->f->code[gt->pc + 1] = fs->f->code[gt->pc];
    /* put CLOSE instruction at original position */
    fs->f->code[gt->pc] = CREATE_ABCk(OP_CLOSE, stklevel, 0, 0, 0);
    gt->pc++;  /* must point to jump instruction */
  }
  luaK_patchlist(ls->fs, gt->pc, label->pc);  /* goto jumps to label */
  for (i = g; i < gl->n - 1; i++)  /* remove goto from pending list */
    gl->arr[i] = gl->arr[i + 1];
  gl->n--;
}


/*
** Search for an active label with the given name, starting at
** index 'ilb' (so that it can search for all labels in current block
** or all labels in current function).
*/
static Labeldesc *findlabel (LexState *ls, TString *name, int ilb) {
  Dyndata *dyd = ls->dyd;
  for (; ilb < dyd->label.n; ilb++) {
    Labeldesc *lb = &dyd->label.arr[ilb];
    if (eqstr(lb->name, name))  /* correct label? */
      return lb;
  }
  return NULL;  /* label not found */
}


/*
** Adds a new label/goto in the corresponding list.
*/
static int newlabelentry (LexState *ls, Labellist *l, TString *name,
                          int line, int pc) {
  int n = l->n;
  luaM_growvector(ls->L, l->arr, n, l->size,
                  Labeldesc, SHRT_MAX, "labels/gotos");
  l->arr[n].name = name;
  l->arr[n].line = line;
  l->arr[n].nactvar = ls->fs->nactvar;
  l->arr[n].close = 0;
  l->arr[n].pc = pc;
  l->n = n + 1;
  return n;
}


/*
** Create an entry for the goto and the code for it. As it is not known
** at this point whether the goto may need a CLOSE, the code has a jump
** followed by an CLOSE. (As the CLOSE comes after the jump, it is a
** dead instruction; it works as a placeholder.) When the goto is closed
** against a label, if it needs a CLOSE, the two instructions swap
** positions, so that the CLOSE comes before the jump.
*/
static int newgotoentry (LexState *ls, TString *name, int line) {
  FuncState *fs = ls->fs;
  int pc = luaK_jump(fs);  /* create jump */
  luaK_codeABC(fs, OP_CLOSE, 0, 1, 0);  /* spaceholder, marked as dead */
  return newlabelentry(ls, &ls->dyd->gt, name, line, pc);
}


/*
** Create a new label with the given 'name' at the given 'line'.
** 'last' tells whether label is the last non-op statement in its
** block. Solves all pending gotos to this new label and adds
** a close instruction if necessary.
** Returns true iff it added a close instruction.
*/
static void createlabel (LexState *ls, TString *name, int line, int last) {
  FuncState *fs = ls->fs;
  Labellist *ll = &ls->dyd->label;
  int l = newlabelentry(ls, ll, name, line, luaK_getlabel(fs));
  if (last) {  /* label is last no-op statement in the block? */
    /* assume that locals are already out of scope */
    ll->arr[l].nactvar = fs->bl->nactvar;
  }
}


/*
** Traverse the pending gotos of the finishing block checking whether
** each match some label of that block. Those that do not match are
** "exported" to the outer block, to be solved there. In particular,
** its 'nactvar' is updated with the level of the inner block,
** as the variables of the inner block are now out of scope.
*/
static void solvegotos (FuncState *fs, BlockCnt *bl) {
  LexState *ls = fs->ls;
  Labellist *gl = &ls->dyd->gt;
  int outlevel = reglevel(fs, bl->nactvar);  /* level outside the block */
  int igt = bl->firstgoto;  /* first goto in the finishing block */
  while (igt < gl->n) {   /* for each pending goto */
    Labeldesc *gt = &gl->arr[igt];
    /* search for a matching label in the current block */
    Labeldesc *lb = findlabel(ls, gt->name, bl->firstlabel);
    if (lb != NULL)  /* found a match? */
      closegoto(ls, igt, lb, bl->upval);  /* close and remove goto */
    else {  /* adjust 'goto' for outer block */
      /* block has variables to be closed and goto escapes the scope of
         some variable? */
      if (bl->upval && reglevel(fs, gt->nactvar) > outlevel)
        gt->close = 1;  /* jump may need a close */
      gt->nactvar = bl->nactvar;  /* correct level for outer block */
      igt++;  /* go to next goto */
    }
  }
  ls->dyd->label.n = bl->firstlabel;  /* remove local labels */
}


static void enterblock (FuncState *fs, BlockCnt *bl, lu_byte isloop) {
  bl->isloop = isloop;
  bl->nactvar = fs->nactvar;
  bl->firstlabel = fs->ls->dyd->label.n;
  bl->firstgoto = fs->ls->dyd->gt.n;
  bl->upval = 0;
  /* inherit 'insidetbc' from enclosing block */
  bl->insidetbc = (fs->bl != NULL && fs->bl->insidetbc);
  bl->previous = fs->bl;  /* link block in function's block list */
  fs->bl = bl;
  lua_assert(fs->freereg == luaY_nvarstack(fs));
}


/*
** generates an error for an undefined 'goto'.
*/
static l_noret undefgoto (LexState *ls, Labeldesc *gt) {
  /* breaks are checked when created, cannot be undefined */
  lua_assert(!eqstr(gt->name, ls->brkn));
  luaK_semerror(ls, "no visible label '%s' for <goto> at line %d",
                    getstr(gt->name), gt->line);
}


static void leaveblock (FuncState *fs) {
  BlockCnt *bl = fs->bl;
  LexState *ls = fs->ls;
  lu_byte stklevel = reglevel(fs, bl->nactvar);  /* level outside block */
  if (bl->previous && bl->upval)  /* need a 'close'? */
    luaK_codeABC(fs, OP_CLOSE, stklevel, 0, 0);
  fs->freereg = stklevel;  /* free registers */
  removevars(fs, bl->nactvar);  /* remove block locals */
  lua_assert(bl->nactvar == fs->nactvar);  /* back to level on entry */
  if (bl->isloop == 2)  /* has to fix pending breaks? */
    createlabel(ls, ls->brkn, 0, 0);
  solvegotos(fs, bl);
  if (bl->previous == NULL) {  /* was it the last block? */
    if (bl->firstgoto < ls->dyd->gt.n)  /* still pending gotos? */
      undefgoto(ls, &ls->dyd->gt.arr[bl->firstgoto]);  /* error */
  }
  fs->bl = bl->previous;  /* current block now is previous one */
}


/*
** adds a new prototype into list of prototypes
*/
static Proto *addprototype (LexState *ls) {
  Proto *clp;
  lua_State *L = ls->L;
  FuncState *fs = ls->fs;
  Proto *f = fs->f;  /* prototype of current function */
  if (fs->np >= f->sizep) {
    int oldsize = f->sizep;
    luaM_growvector(L, f->p, fs->np, f->sizep, Proto *, MAXARG_Bx, "functions");
    while (oldsize < f->sizep)
      f->p[oldsize++] = NULL;
  }
  f->p[fs->np++] = clp = luaF_newproto(L);
  luaC_objbarrier(L, f, clp);
  return clp;
}


/*
** codes instruction to create new closure in parent function.
** The OP_CLOSURE instruction uses the last available register,
** so that, if it invokes the GC, the GC knows which registers
** are in use at that time.

*/
static void codeclosure (LexState *ls, expdesc *v) {
  FuncState *fs = ls->fs->prev;
  init_exp(v, VRELOC, luaK_codeABx(fs, OP_CLOSURE, 0, fs->np - 1));
  luaK_exp2nextreg(fs, v);  /* fix it at the last register */
}


static void open_func (LexState *ls, FuncState *fs, BlockCnt *bl) {
  lua_State *L = ls->L;
  Proto *f = fs->f;
  fs->prev = ls->fs;  /* linked list of funcstates */
  fs->ls = ls;
  ls->fs = fs;
  fs->pc = 0;
  fs->previousline = f->linedefined;
  fs->iwthabs = 0;
  fs->lasttarget = 0;
  fs->freereg = 0;
  fs->nk = 0;
  fs->nabslineinfo = 0;
  fs->np = 0;
  fs->nups = 0;
  fs->ndebugvars = 0;
  fs->nactvar = 0;
  fs->needclose = 0;
  fs->firstlocal = ls->dyd->actvar.n;
  fs->firstlabel = ls->dyd->label.n;
  fs->bl = NULL;
  f->source = ls->source;
  luaC_objbarrier(L, f, f->source);
  f->maxstacksize = 2;  /* registers 0/1 are always valid */
  fs->kcache = luaH_new(L);  /* create table for function */
  sethvalue2s(L, L->top.p, fs->kcache);  /* anchor it */
  luaD_inctop(L);
  enterblock(fs, bl, 0);
}


static void close_func (LexState *ls) {
  lua_State *L = ls->L;
  FuncState *fs = ls->fs;
  Proto *f = fs->f;
  luaK_ret(fs, luaY_nvarstack(fs), 0);  /* final return */
  leaveblock(fs);
  lua_assert(fs->bl == NULL);
  luaK_finish(fs);
  luaM_shrinkvector(L, f->code, f->sizecode, fs->pc, Instruction);
  luaM_shrinkvector(L, f->lineinfo, f->sizelineinfo, fs->pc, ls_byte);
  luaM_shrinkvector(L, f->abslineinfo, f->sizeabslineinfo,
                       fs->nabslineinfo, AbsLineInfo);
  luaM_shrinkvector(L, f->k, f->sizek, fs->nk, TValue);
  luaM_shrinkvector(L, f->p, f->sizep, fs->np, Proto *);
  luaM_shrinkvector(L, f->locvars, f->sizelocvars, fs->ndebugvars, LocVar);
  luaM_shrinkvector(L, f->upvalues, f->sizeupvalues, fs->nups, Upvaldesc);
  ls->fs = fs->prev;
  L->top.p--;  /* pop kcache table */
  luaC_checkGC(L);
}


/*
** {======================================================================
** GRAMMAR RULES
** =======================================================================
*/


/*
** check whether current token is in the follow set of a block.
** 'until' closes syntactical blocks, but do not close scope,
** so it is handled in separate.
*/
static int block_follow (LexState *ls, int withuntil) {
  switch (ls->t.token) {
    case TK_ELSE:
    case '}': case TK_EOS:
      return 1;
    default:
      (void)withuntil;
      return 0;
  }
}


static void statlist (LexState *ls) {
  /* statlist -> { stat [';'] } */
  while (!block_follow(ls, 1)) {
    if (ls->t.token == TK_RETURN) {
      statement(ls);
      return;  /* 'return' must be last statement */
    }
    statement(ls);
  }
}


static void fieldsel (LexState *ls, expdesc *v) {
  /* fieldsel -> ['.' | ':'] NAME */
  FuncState *fs = ls->fs;
  expdesc key;
  luaK_exp2anyregup(fs, v);
  luaX_next(ls);  /* skip the dot or colon */
  codename(ls, &key);
  luaK_indexed(fs, v, &key);
}


static void yindex (LexState *ls, expdesc *v) {
  /* index -> '[' expr ']' */
  luaX_next(ls);  /* skip the '[' */
  expr(ls, v);
  luaK_exp2val(ls->fs, v);
  checknext(ls, ']');
}


/*
** {======================================================================
** Rules for Constructors
** =======================================================================
*/

typedef struct ConsControl {
  expdesc v;  /* last list item read */
  expdesc *t;  /* table descriptor */
  int nh;  /* total number of 'record' elements */
  int na;  /* number of array elements already stored */
  int tostore;  /* number of array elements pending to be stored */
  int maxtostore;  /* maximum number of pending elements */
} ConsControl;


/*
** Maximum number of elements in a constructor, to control the following:
** * counter overflows;
** * overflows in 'extra' for OP_NEWTABLE and OP_SETLIST;
** * overflows when adding multiple returns in OP_SETLIST.
*/
#define MAX_CNST	(INT_MAX/2)
#if MAX_CNST/(MAXARG_vC + 1) > MAXARG_Ax
#undef MAX_CNST
#define MAX_CNST	(MAXARG_Ax * (MAXARG_vC + 1))
#endif


static void recfield (LexState *ls, ConsControl *cc) {
  /* recfield -> (NAME | '['exp']') = exp */
  FuncState *fs = ls->fs;
  lu_byte reg = ls->fs->freereg;
  expdesc tab, key, val;
  if (ls->t.token == TK_NAME)
    codename(ls, &key);
  else  /* ls->t.token == '[' */
    yindex(ls, &key);
  cc->nh++;
  checknext(ls, '=');
  tab = *cc->t;
  luaK_indexed(fs, &tab, &key);
  expr(ls, &val);
  luaK_storevar(fs, &tab, &val);
  fs->freereg = reg;  /* free registers */
}


static void closelistfield (FuncState *fs, ConsControl *cc) {
  lua_assert(cc->tostore > 0);
  luaK_exp2nextreg(fs, &cc->v);
  cc->v.k = VVOID;
  if (cc->tostore >= cc->maxtostore) {
    luaK_setlist(fs, cc->t->u.info, cc->na, cc->tostore);  /* flush */
    cc->na += cc->tostore;
    cc->tostore = 0;  /* no more items pending */
  }
}


static void lastlistfield (FuncState *fs, ConsControl *cc) {
  if (cc->tostore == 0) return;
  if (hasmultret(cc->v.k)) {
    luaK_setmultret(fs, &cc->v);
    luaK_setlist(fs, cc->t->u.info, cc->na, LUA_MULTRET);
    cc->na--;  /* do not count last expression (unknown number of elements) */
  }
  else {
    if (cc->v.k != VVOID)
      luaK_exp2nextreg(fs, &cc->v);
    luaK_setlist(fs, cc->t->u.info, cc->na, cc->tostore);
  }
  cc->na += cc->tostore;
}


static void listfield (LexState *ls, ConsControl *cc) {
  /* listfield -> exp */
  expr(ls, &cc->v);
  cc->tostore++;
}


static void field (LexState *ls, ConsControl *cc) {
  /* field -> listfield | recfield */
  switch(ls->t.token) {
    case TK_NAME: {  /* may be 'listfield' or 'recfield' */
      if (luaX_lookahead(ls) != '=')  /* expression? */
        listfield(ls, cc);
      else
        recfield(ls, cc);
      break;
    }
    case '[': {
      recfield(ls, cc);
      break;
    }
    default: {
      listfield(ls, cc);
      break;
    }
  }
}


/*
** Compute a limit for how many registers a constructor can use before
** emitting a 'SETLIST' instruction, based on how many registers are
** available.
*/
static int maxtostore (FuncState *fs) {
  int numfreeregs = MAX_FSTACK - fs->freereg;
  if (numfreeregs >= 160)  /* "lots" of registers? */
    return numfreeregs / 5;  /* use up to 1/5 of them */
  else if (numfreeregs >= 80)  /* still "enough" registers? */
    return 10;  /* one 'SETLIST' instruction for each 10 values */
  else  /* save registers for potential more nesting */
    return 1;
}


static void constructor (LexState *ls, expdesc *t) {
  /* constructor -> '{' [ field { sep field } [sep] ] '}'
     sep -> ',' | ';' */
  FuncState *fs = ls->fs;
  int line = ls->linenumber;
  int pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
  ConsControl cc;
  luaK_code(fs, 0);  /* space for extra arg. */
  cc.na = cc.nh = cc.tostore = 0;
  cc.t = t;
  init_exp(t, VNONRELOC, fs->freereg);  /* table will be at stack top */
  luaK_reserveregs(fs, 1);
  init_exp(&cc.v, VVOID, 0);  /* no value (yet) */
  checknext(ls, '{' /*}*/);
  cc.maxtostore = maxtostore(fs);
  do {
    if (ls->t.token == /*{*/ '}') break;
    if (cc.v.k != VVOID)  /* is there a previous list item? */
      closelistfield(fs, &cc);  /* close it */
    field(ls, &cc);
    luaY_checklimit(fs, cc.tostore + cc.na + cc.nh, MAX_CNST,
                    "items in a constructor");
  } while (testnext(ls, ',') || testnext(ls, ';'));
  check_match(ls, /*{*/ '}', '{' /*}*/, line);
  lastlistfield(fs, &cc);
  luaK_settablesize(fs, pc, t->u.info, cc.na, cc.nh);
}

/* }====================================================================== */


static void setvararg (FuncState *fs) {
  fs->f->flag |= PF_VAHID;  /* by default, use hidden vararg arguments */
  luaK_codeABC(fs, OP_VARARGPREP, 0, 0, 0);
}


static void parlist (LexState *ls) {
  /* parlist -> [ {NAME ':' TYPE ','} (NAME ':' TYPE | '...') ] */
  FuncState *fs = ls->fs;
  Proto *f = fs->f;
  int nparams = 0;
  int varargk = 0;
  if (ls->t.token != ')') {  /* is 'parlist' not empty? */
    do {
      switch (ls->t.token) {
        case TK_NAME: {
          new_localvar(ls, str_checkname(ls));
          /* optional type annotation ': Type' - skip it */
          if (testnext(ls, ':')) {
            /* skip type name (possibly generic like Array<Int64>) */
            int depth = 0;
            while (ls->t.token == TK_NAME ||
                   (ls->t.token == '<' ) ||
                   (ls->t.token == '>' && depth > 0) ||
                   (ls->t.token == ',' && depth > 0)) {
              if (ls->t.token == '<') depth++;
              else if (ls->t.token == '>') depth--;
              luaX_next(ls);
            }
          }
          nparams++;
          break;
        }
        case TK_DOTS: {
          varargk = 1;
          luaX_next(ls);  /* skip '...' */
          if (ls->t.token == TK_NAME)
            new_varkind(ls, str_checkname(ls), RDKVAVAR);
          else
            new_localvarliteral(ls, "(vararg table)");
          break;
        }
        default: luaX_syntaxerror(ls, "<name> or '...' expected");
      }
    } while (!varargk && testnext(ls, ','));
  }
  adjustlocalvars(ls, nparams);
  f->numparams = cast_byte(fs->nactvar);
  if (varargk) {
    setvararg(fs);  /* declared vararg */
    adjustlocalvars(ls, 1);  /* vararg parameter */
  }
  /* reserve registers for parameters (plus vararg parameter, if present) */
  luaK_reserveregs(fs, fs->nactvar);
}


static void body (LexState *ls, expdesc *e, int ismethod, int line) {
  /* body ->  '(' parlist ')' [':' type] '{' block '}' */
  FuncState new_fs;
  BlockCnt bl;
  new_fs.f = addprototype(ls);
  new_fs.f->linedefined = line;
  open_func(ls, &new_fs, &bl);
  checknext(ls, '(');
  if (ismethod) {
    new_localvarliteral(ls, "self");  /* create 'self' parameter */
    adjustlocalvars(ls, 1);
  }
  parlist(ls);
  checknext(ls, ')');
  /* optional return type annotation ': Type' - skip it */
  if (testnext(ls, ':')) {
    int depth = 0;
    while (ls->t.token == TK_NAME ||
           (ls->t.token == '<') ||
           (ls->t.token == '>' && depth > 0) ||
           (ls->t.token == ',' && depth > 0)) {
      if (ls->t.token == '<') depth++;
      else if (ls->t.token == '>') depth--;
      luaX_next(ls);
    }
  }
  checknext(ls, '{' /*}*/);
  statlist(ls);
  new_fs.f->lastlinedefined = ls->linenumber;
  check_match(ls, /*{*/ '}', TK_FUNC, line);
  codeclosure(ls, e);
  close_func(ls);
}


/*
** Parse an init constructor body. Same as body() but auto-appends
** 'return self' at the end, so Cangjie constructors don't need
** explicit 'return this'.
*/
static void body_init (LexState *ls, expdesc *e, int line) {
  FuncState new_fs;
  BlockCnt bl;
  new_fs.f = addprototype(ls);
  new_fs.f->linedefined = line;
  open_func(ls, &new_fs, &bl);
  checknext(ls, '(');
  /* init always has 'self' parameter */
  new_localvarliteral(ls, "self");
  adjustlocalvars(ls, 1);
  parlist(ls);
  checknext(ls, ')');
  /* skip optional return type annotation */
  if (testnext(ls, ':')) {
    int depth = 0;
    while (ls->t.token == TK_NAME ||
           (ls->t.token == '<') ||
           (ls->t.token == '>' && depth > 0) ||
           (ls->t.token == ',' && depth > 0)) {
      if (ls->t.token == '<') depth++;
      else if (ls->t.token == '>') depth--;
      luaX_next(ls);
    }
  }
  checknext(ls, '{' /*}*/);
  statlist(ls);
  /* Auto-generate: return self */
  {
    expdesc selfvar;
    TString *selfname = luaS_new(ls->L, "self");
    singlevaraux(ls->fs, selfname, &selfvar, 1);
    luaK_ret(ls->fs, luaK_exp2anyreg(ls->fs, &selfvar), 1);
  }
  new_fs.f->lastlinedefined = ls->linenumber;
  check_match(ls, /*{*/ '}', TK_FUNC, line);
  codeclosure(ls, e);
  close_func(ls);
}


static int explist (LexState *ls, expdesc *v) {
  /* explist -> expr { ',' expr } */
  int n = 1;  /* at least one expression */
  expr(ls, v);
  while (testnext(ls, ',')) {
    luaK_exp2nextreg(ls->fs, v);
    expr(ls, v);
    n++;
  }
  return n;
}


static void funcargs (LexState *ls, expdesc *f) {
  FuncState *fs = ls->fs;
  expdesc args;
  int base, nparams;
  int line = ls->linenumber;
  switch (ls->t.token) {
    case '(': {  /* funcargs -> '(' [ explist ] ')' */
      luaX_next(ls);
      if (ls->t.token == ')')  /* arg list is empty? */
        args.k = VVOID;
      else {
        explist(ls, &args);
        if (hasmultret(args.k))
          luaK_setmultret(fs, &args);
      }
      check_match(ls, ')', '(', line);
      break;
    }
    case '{' /*}*/: {  /* funcargs -> constructor */
      constructor(ls, &args);
      break;
    }
    case TK_STRING: {  /* funcargs -> STRING */
      codestring(&args, ls->t.seminfo.ts);
      luaX_next(ls);  /* must use 'seminfo' before 'next' */
      break;
    }
    default: {
      luaX_syntaxerror(ls, "function arguments expected");
    }
  }
  lua_assert(f->k == VNONRELOC);
  base = f->u.info;  /* base register for call */
  if (hasmultret(args.k))
    nparams = LUA_MULTRET;  /* open call */
  else {
    if (args.k != VVOID)
      luaK_exp2nextreg(fs, &args);  /* close last argument */
    nparams = fs->freereg - (base+1);
  }
  init_exp(f, VCALL, luaK_codeABC(fs, OP_CALL, base, nparams+1, 2));
  luaK_fixline(fs, line);
  /* call removes function and arguments and leaves one result (unless
     changed later) */
  fs->freereg = cast_byte(base + 1);
}




/*
** {======================================================================
** Expression parsing
** =======================================================================
*/


static void lambdabody (LexState *ls, expdesc *e, int line);

static void primaryexp (LexState *ls, expdesc *v) {
  /* primaryexp -> NAME | '(' expr ')' */
  switch (ls->t.token) {
    case '(': {
      int line = ls->linenumber;
      luaX_next(ls);
      if (ls->t.token == ')') {
        /* empty parens () - check for lambda => */
        luaX_next(ls);
        if (ls->t.token == TK_ARROW) {
          lambdabody(ls, v, line);
          return;
        }
        luaX_syntaxerror(ls, "unexpected '()'");
      }
      expr(ls, v);
      check_match(ls, ')', '(', line);
      luaK_dischargevars(ls->fs, v);
      return;
    }
    case TK_NAME: {
      singlevar(ls, v);
      return;
    }
    case TK_THIS: {
      /* 'this' is syntactic sugar for 'self' */
      TString *ts = luaS_new(ls->L, "self");
      luaX_next(ls);  /* skip 'this' */
      singlevaraux(ls->fs, ts, v, 1);
      return;
    }
    default: {
      luaX_syntaxerror(ls, "unexpected symbol");
    }
  }
}


static void suffixedexp (LexState *ls, expdesc *v) {
  /* suffixedexp ->
       primaryexp { '.' NAME | '[' exp ']' | ':' NAME funcargs | funcargs } */
  FuncState *fs = ls->fs;
  primaryexp(ls, v);
  for (;;) {
    switch (ls->t.token) {
      case '.': {  /* fieldsel or method call */
        /* Check for .size -> read __n field (array length) */
        if (luaX_lookahead(ls) == TK_NAME) {
          TString *fname = ls->lookahead.seminfo.ts;
          if (fname != NULL && strcmp(getstr(fname), "size") == 0) {
            luaX_next(ls);  /* skip '.' */
            luaX_next(ls);  /* skip 'size' */
            luaK_exp2anyregup(fs, v);
            {
              expdesc key;
              codestring(&key, luaX_newstring(ls, "__n", 3));
              luaK_indexed(fs, v, &key);
            }
            break;
          }
        }
        /* In Cangjie, obj.method(args) means method call with implicit self.
        ** Detect .NAME( pattern and use luaK_self for method calls.
        ** Otherwise, use regular fieldsel for field access. */
        /* After the .size check, lookahead might be set or not.
        ** If lookahead is set (from .size check that didn't match),
        ** luaX_next will use it. If not, fieldsel handles it. */
        {
          /* We need to check ahead: is this .NAME( ? 
          ** Step 1: Skip '.', get the name
          ** Step 2: Check what follows the name */
          expdesc key;
          TString *fname2;
          luaK_exp2anyregup(fs, v);
          luaX_next(ls);  /* skip '.', using cached lookahead if available */
          check(ls, TK_NAME);
          fname2 = ls->t.seminfo.ts;
          /* Peek at what follows the name */
          if (luaX_lookahead(ls) == '(') {
            /* Method call: obj.method(args) -> obj:method(args) with self */
            codestring(&key, fname2);
            luaK_self(fs, v, &key);
            luaX_next(ls);  /* consume NAME */
            funcargs(ls, v);
          }
          else {
            /* Regular field access */
            codename(ls, &key);  /* reads current NAME and advances */
            luaK_indexed(fs, v, &key);
          }
        }
        break;
      }
      case '[': {  /* '[' exp ']' */
        expdesc key;
        luaK_exp2anyregup(fs, v);
        yindex(ls, &key);
        luaK_indexed(fs, v, &key);
        break;
      }
      case ':': {  /* ':' NAME funcargs */
        expdesc key;
        luaX_next(ls);
        codename(ls, &key);
        luaK_self(fs, v, &key);
        funcargs(ls, v);
        break;
      }
      case '(': {  /* funcargs -> '(' args ')' */
        luaK_exp2nextreg(fs, v);
        funcargs(ls, v);
        break;
      }
      default: return;
    }
  }
}


/*
** Lambda body: => expr or => { block }
** Creates an anonymous function that returns the expression
*/
static void lambdabody (LexState *ls, expdesc *e, int line) {
  /* lambdabody -> '=>' expr | '=>' '{' block '}' */
  FuncState new_fs;
  BlockCnt bl;
  new_fs.f = addprototype(ls);
  new_fs.f->linedefined = line;
  open_func(ls, &new_fs, &bl);
  /* No parameters for () => expr */
  new_fs.f->numparams = 0;
  luaX_next(ls);  /* skip '=>' */
  if (ls->t.token == '{') {
    /* block lambda: => { statements } */
    checknext(ls, '{' /*}*/);
    statlist(ls);
    new_fs.f->lastlinedefined = ls->linenumber;
    checknext(ls, /*{*/ '}');
  }
  else {
    /* expression lambda: => expr (auto return) */
    expdesc ret;
    expr(ls, &ret);
    luaK_ret(&new_fs, luaK_exp2anyreg(&new_fs, &ret), 1);
    new_fs.f->lastlinedefined = ls->linenumber;
  }
  codeclosure(ls, e);
  close_func(ls);
}


static void simpleexp (LexState *ls, expdesc *v) {
  /* simpleexp -> FLT | INT | STRING | NIL | TRUE | FALSE |
                  constructor | FUNC body | suffixedexp */
  switch (ls->t.token) {
    case TK_FLT: {
      init_exp(v, VKFLT, 0);
      v->u.nval = ls->t.seminfo.r;
      break;
    }
    case TK_INT: {
      init_exp(v, VKINT, 0);
      v->u.ival = ls->t.seminfo.i;
      break;
    }
    case TK_STRING: {
      codestring(v, ls->t.seminfo.ts);
      /* Check for string interpolation: if interp_depth > 0, the lexer
         stopped at ${, so we need to parse the expression and concat */
      if (ls->interp_depth > 0) {
        luaX_next(ls);  /* advance to first token of interpolated expr */
        /* Build concatenation: str_part .. tostring(expr) .. rest */
        luaK_exp2nextreg(ls->fs, v);
        while (ls->interp_depth > 0) {
          expdesc v2;
          /* call tostring on the interpolated expression */
          {
            expdesc fn;
            buildvar(ls, luaS_new(ls->L, "tostring"), &fn);
            luaK_exp2nextreg(ls->fs, &fn);
            expr(ls, &v2);
            luaK_exp2nextreg(ls->fs, &v2);
            /* generate call: tostring(expr) */
            {
              int base2 = fn.u.info;
              init_exp(&fn, VCALL,
                luaK_codeABC(ls->fs, OP_CALL, base2, 2, 2));
              ls->fs->freereg = cast_byte(base2 + 1);
            }
          }
          /* Expect '}' to end interpolation */
          if (ls->t.token != '}')
            luaX_syntaxerror(ls, "'}' expected to close string interpolation");
          ls->interp_depth--;
          /* Read the continuation of the string after '}' 
             ls->current is already past '}' since llex consumed it */
          {
            SemInfo si;
            luaZ_resetbuffer(ls->buff);
            luaX_read_interp_string(ls, &si);
            /* emit the continuation string */
            {
              expdesc v3;
              codestring(&v3, si.ts);
              luaK_exp2nextreg(ls->fs, &v3);
            }
          }
          /* If there are more interpolations, read next token for expr */
          if (ls->interp_depth > 0) {
            /* read first token of the next interpolation expression */
            ls->t.token = 0;  /* invalidate */
            luaX_next(ls);
          }
        }
        /* Use OP_CONCAT to concatenate all parts on the stack */
        {
          int from = v->u.info;
          int n = ls->fs->freereg - from;
          if (n > 1) {
            luaK_codeABC(ls->fs, OP_CONCAT, from, n, 0);
            ls->fs->freereg = cast_byte(from + 1);
          }
          init_exp(v, VNONRELOC, from);
        }
        /* Now advance to the next proper token after the string */
        luaX_next(ls);
        return;
      }
      break;
    }
    case TK_NIL: {
      init_exp(v, VNIL, 0);
      break;
    }
    case TK_TRUE: {
      init_exp(v, VTRUE, 0);
      break;
    }
    case TK_FALSE: {
      init_exp(v, VFALSE, 0);
      break;
    }
    case '{' /*}*/: {  /* constructor */
      constructor(ls, v);
      return;
    }
    case '[': {  /* array constructor -> '[' [explist] ']' */
      /* Cangjie arrays are 0-based. We create a table and
      ** explicitly assign: arr[0]=v1, arr[1]=v2, etc.
      ** Also store __n = count for .size support. */
      FuncState *fs2 = ls->fs;
      int line2 = ls->linenumber;
      int pc2 = luaK_codevABCk(fs2, OP_NEWTABLE, 0, 0, 0, 0);
      int tabReg;
      int count = 0;
      luaK_code(fs2, 0);  /* space for extra arg */
      init_exp(v, VNONRELOC, fs2->freereg);
      tabReg = fs2->freereg;
      luaK_reserveregs(fs2, 1);
      luaX_next(ls);  /* skip '[' */
      while (ls->t.token != ']' && ls->t.token != TK_EOS) {
        expdesc key, val;
        /* key = count (0-based index) */
        init_exp(&key, VKINT, 0);
        key.u.ival = count;
        /* Parse value expression */
        expr(ls, &val);
        /* Generate: arr[count] = val */
        {
          expdesc tab2;
          init_exp(&tab2, VNONRELOC, tabReg);
          luaK_exp2anyregup(fs2, &tab2);
          luaK_indexed(fs2, &tab2, &key);
          luaK_storevar(fs2, &tab2, &val);
        }
        count++;
        if (!testnext(ls, ','))
          break;
      }
      check_match(ls, ']', '[', line2);
      /* Store __n = count for .size */
      {
        expdesc tab3, nkey, nval;
        init_exp(&tab3, VNONRELOC, tabReg);
        luaK_exp2anyregup(fs2, &tab3);
        codestring(&nkey, luaX_newstring(ls, "__n", 3));
        luaK_indexed(fs2, &tab3, &nkey);
        init_exp(&nval, VKINT, 0);
        nval.u.ival = count;
        luaK_storevar(fs2, &tab3, &nval);
      }
      luaK_settablesize(fs2, pc2, tabReg, 0, count + 1);
      return;
    }
    case TK_FUNC: {
      luaX_next(ls);
      body(ls, v, 0, ls->linenumber);
      return;
    }
    default: {
      suffixedexp(ls, v);
      return;
    }
  }
  luaX_next(ls);
}


static UnOpr getunopr (int op) {
  switch (op) {
    case TK_NOT: return OPR_NOT;
    case '-': return OPR_MINUS;
    case '~': return OPR_BNOT;
    case '#': return OPR_LEN;
    default: return OPR_NOUNOPR;
  }
}


static BinOpr getbinopr (int op) {
  switch (op) {
    case '+': return OPR_ADD;
    case '-': return OPR_SUB;
    case '*': return OPR_MUL;
    case '%': return OPR_MOD;
    case '^': return OPR_POW;
    case '/': return OPR_DIV;
    case TK_IDIV: return OPR_IDIV;
    case '&': return OPR_BAND;
    case '|': return OPR_BOR;
    case '~': return OPR_BXOR;
    case TK_SHL: return OPR_SHL;
    case TK_SHR: return OPR_SHR;
    case TK_CONCAT: return OPR_CONCAT;
    case TK_NE: return OPR_NE;
    case TK_EQ: return OPR_EQ;
    case '<': return OPR_LT;
    case TK_LE: return OPR_LE;
    case '>': return OPR_GT;
    case TK_GE: return OPR_GE;
    case TK_AND: return OPR_AND;
    case TK_OR: return OPR_OR;
    default: return OPR_NOBINOPR;
  }
}


/*
** Priority table for binary operators.
*/
static const struct {
  lu_byte left;  /* left priority for each binary operator */
  lu_byte right; /* right priority */
} priority[] = {  /* ORDER OPR */
   {10, 10}, {10, 10},           /* '+' '-' */
   {11, 11}, {11, 11},           /* '*' '%' */
   {14, 13},                  /* '^' (right associative) */
   {11, 11}, {11, 11},           /* '/' '//' */
   {6, 6}, {4, 4}, {5, 5},   /* '&' '|' '~' */
   {7, 7}, {7, 7},           /* '<<' '>>' */
   {9, 8},                   /* '..' (right associative) */
   {3, 3}, {3, 3}, {3, 3},   /* ==, <, <= */
   {3, 3}, {3, 3}, {3, 3},   /* ~=, >, >= */
   {2, 2}, {1, 1}            /* and, or */
};

#define UNARY_PRIORITY	12  /* priority for unary operators */


/*
** subexpr -> (simpleexp | unop subexpr) { binop subexpr }
** where 'binop' is any binary operator with a priority higher than 'limit'
*/
static BinOpr subexpr (LexState *ls, expdesc *v, int limit) {
  BinOpr op;
  UnOpr uop;
  enterlevel(ls);
  uop = getunopr(ls->t.token);
  if (uop != OPR_NOUNOPR) {  /* prefix (unary) operator? */
    int line = ls->linenumber;
    luaX_next(ls);  /* skip operator */
    subexpr(ls, v, UNARY_PRIORITY);
    luaK_prefix(ls->fs, uop, v, line);
  }
  else simpleexp(ls, v);
  /* expand while operators have priorities higher than 'limit' */
  op = getbinopr(ls->t.token);
  while (op != OPR_NOBINOPR && priority[op].left > limit) {
    expdesc v2;
    BinOpr nextop;
    int line = ls->linenumber;
    luaX_next(ls);  /* skip operator */
    luaK_infix(ls->fs, op, v);
    /* read sub-expression with higher priority */
    nextop = subexpr(ls, &v2, priority[op].right);
    luaK_posfix(ls->fs, op, v, &v2, line);
    op = nextop;
  }
  leavelevel(ls);
  return op;  /* return first untreated operator */
}


static void expr (LexState *ls, expdesc *v) {
  subexpr(ls, v, 0);
}

/* }==================================================================== */



/*
** {======================================================================
** Rules for Statements
** =======================================================================
*/


static void block (LexState *ls) {
  /* block -> statlist */
  FuncState *fs = ls->fs;
  BlockCnt bl;
  enterblock(fs, &bl, 0);
  statlist(ls);
  leaveblock(fs);
}


/*
** structure to chain all variables in the left-hand side of an
** assignment
*/
struct LHS_assign {
  struct LHS_assign *prev;
  expdesc v;  /* variable (global, local, upvalue, or indexed) */
};


/*
** check whether, in an assignment to an upvalue/local variable, the
** upvalue/local variable is begin used in a previous assignment to a
** table. If so, save original upvalue/local value in a safe place and
** use this safe copy in the previous assignment.
*/
static void check_conflict (LexState *ls, struct LHS_assign *lh, expdesc *v) {
  FuncState *fs = ls->fs;
  lu_byte extra = fs->freereg;  /* eventual position to save local variable */
  int conflict = 0;
  for (; lh; lh = lh->prev) {  /* check all previous assignments */
    if (vkisindexed(lh->v.k)) {  /* assignment to table field? */
      if (lh->v.k == VINDEXUP) {  /* is table an upvalue? */
        if (v->k == VUPVAL && lh->v.u.ind.t == v->u.info) {
          conflict = 1;  /* table is the upvalue being assigned now */
          lh->v.k = VINDEXSTR;
          lh->v.u.ind.t = extra;  /* assignment will use safe copy */
        }
      }
      else {  /* table is a register */
        if (v->k == VLOCAL && lh->v.u.ind.t == v->u.var.ridx) {
          conflict = 1;  /* table is the local being assigned now */
          lh->v.u.ind.t = extra;  /* assignment will use safe copy */
        }
        /* is index the local being assigned? */
        if (lh->v.k == VINDEXED && v->k == VLOCAL &&
            lh->v.u.ind.idx == v->u.var.ridx) {
          conflict = 1;
          lh->v.u.ind.idx = extra;  /* previous assignment will use safe copy */
        }
      }
    }
  }
  if (conflict) {
    /* copy upvalue/local value to a temporary (in position 'extra') */
    if (v->k == VLOCAL)
      luaK_codeABC(fs, OP_MOVE, extra, v->u.var.ridx, 0);
    else
      luaK_codeABC(fs, OP_GETUPVAL, extra, v->u.info, 0);
    luaK_reserveregs(fs, 1);
  }
}


/* Create code to store the "top" register in 'var' */
static void storevartop (FuncState *fs, expdesc *var) {
  expdesc e;
  init_exp(&e, VNONRELOC, fs->freereg - 1);
  luaK_storevar(fs, var, &e);  /* will also free the top register */
}


/*
** Parse and compile a multiple assignment. The first "variable"
** (a 'suffixedexp') was already read by the caller.
**
** assignment -> suffixedexp restassign
** restassign -> ',' suffixedexp restassign | '=' explist
*/
static void restassign (LexState *ls, struct LHS_assign *lh, int nvars) {
  expdesc e;
  check_condition(ls, vkisvar(lh->v.k), "syntax error");
  check_readonly(ls, &lh->v);
  if (testnext(ls, ',')) {  /* restassign -> ',' suffixedexp restassign */
    struct LHS_assign nv;
    nv.prev = lh;
    suffixedexp(ls, &nv.v);
    if (!vkisindexed(nv.v.k))
      check_conflict(ls, lh, &nv.v);
    enterlevel(ls);  /* control recursion depth */
    restassign(ls, &nv, nvars+1);
    leavelevel(ls);
  }
  else {  /* restassign -> '=' explist */
    int nexps;
    checknext(ls, '=');
    nexps = explist(ls, &e);
    if (nexps != nvars)
      adjust_assign(ls, nvars, nexps, &e);
    else {
      luaK_setoneret(ls->fs, &e);  /* close last expression */
      luaK_storevar(ls->fs, &lh->v, &e);
      return;  /* avoid default */
    }
  }
  storevartop(ls->fs, &lh->v);  /* default assignment */
}


static int cond (LexState *ls) {
  /* cond -> exp */
  expdesc v;
  expr(ls, &v);  /* read condition */
  if (v.k == VNIL) v.k = VFALSE;  /* 'falses' are all equal here */
  luaK_goiftrue(ls->fs, &v);
  return v.f;
}


static void gotostat (LexState *ls, int line) {
  TString *name = str_checkname(ls);  /* label's name */
  newgotoentry(ls, name, line);
}


/*
** Break statement. Semantically equivalent to "goto break".
*/
static void breakstat (LexState *ls, int line) {
  BlockCnt *bl;  /* to look for an enclosing loop */
  for (bl = ls->fs->bl; bl != NULL; bl = bl->previous) {
    if (bl->isloop)  /* found one? */
      goto ok;
  }
  luaX_syntaxerror(ls, "break outside loop");
 ok:
  bl->isloop = 2;  /* signal that block has pending breaks */
  luaX_next(ls);  /* skip break */
  newgotoentry(ls, ls->brkn, line);
}


/*
** Check whether there is already a label with the given 'name' at
** current function.
*/
static void checkrepeated (LexState *ls, TString *name) {
  Labeldesc *lb = findlabel(ls, name, ls->fs->firstlabel);
  if (l_unlikely(lb != NULL))  /* already defined? */
    luaK_semerror(ls, "label '%s' already defined on line %d",
                      getstr(name), lb->line);  /* error */
}


static void labelstat (LexState *ls, TString *name, int line) {
  /* label -> '::' NAME '::' */
  checknext(ls, TK_DBCOLON);  /* skip double colon */
  while (ls->t.token == ';' || ls->t.token == TK_DBCOLON)
    statement(ls);  /* skip other no-op statements */
  checkrepeated(ls, name);  /* check for repeated labels */
  createlabel(ls, name, line, block_follow(ls, 0));
}


static void whilestat (LexState *ls, int line) {
  /* whilestat -> WHILE '(' cond ')' '{' block '}' */
  FuncState *fs = ls->fs;
  int whileinit;
  int condexit;
  BlockCnt bl;
  luaX_next(ls);  /* skip WHILE */
  whileinit = luaK_getlabel(fs);
  /* Cangjie requires parentheses around condition */
  checknext(ls, '(');
  condexit = cond(ls);
  checknext(ls, ')');
  enterblock(fs, &bl, 1);
  checknext(ls, '{' /*}*/);
  block(ls);
  luaK_jumpto(fs, whileinit);
  check_match(ls, /*{*/ '}', TK_WHILE, line);
  leaveblock(fs);
  luaK_patchtohere(fs, condexit);  /* false conditions finish the loop */
}


/* repeatstat removed - Cangjie does not have repeat-until */


/*
** Read an expression and generate code to put its results in next
** stack slot.
**
*/
static void exp1 (LexState *ls) {
  expdesc e;
  expr(ls, &e);
  luaK_exp2nextreg(ls->fs, &e);
  lua_assert(e.k == VNONRELOC);
}


/*
** Fix for instruction at position 'pc' to jump to 'dest'.
** (Jump addresses are relative in Lua). 'back' true means
** a back jump.
*/
static void fixforjump (FuncState *fs, int pc, int dest, int back) {
  Instruction *jmp = &fs->f->code[pc];
  int offset = dest - (pc + 1);
  if (back)
    offset = -offset;
  if (l_unlikely(offset > MAXARG_Bx))
    luaX_syntaxerror(fs->ls, "control structure too long");
  SETARG_Bx(*jmp, offset);
}


/*
** Generate code for a 'for' loop.
*/
static void forbody (LexState *ls, int base, int line, int nvars, int isgen) {
  /* forbody -> '{' block '}' */
  static const OpCode forprep[2] = {OP_FORPREP, OP_TFORPREP};
  static const OpCode forloop[2] = {OP_FORLOOP, OP_TFORLOOP};
  BlockCnt bl;
  FuncState *fs = ls->fs;
  int prep, endfor;
  checknext(ls, '{' /*}*/);
  prep = luaK_codeABx(fs, forprep[isgen], base, 0);
  fs->freereg--;  /* both 'forprep' remove one register from the stack */
  enterblock(fs, &bl, 0);  /* scope for declared variables */
  adjustlocalvars(ls, nvars);
  luaK_reserveregs(fs, nvars);
  block(ls);
  leaveblock(fs);  /* end of scope for declared variables */
  check_match(ls, /*{*/ '}', TK_FOR, line);
  fixforjump(fs, prep, luaK_getlabel(fs), 0);
  if (isgen) {  /* generic for? */
    luaK_codeABC(fs, OP_TFORCALL, base, 0, nvars);
    luaK_fixline(fs, line);
  }
  endfor = luaK_codeABx(fs, forloop[isgen], base, 0);
  fixforjump(fs, endfor, prep + 1, 1);
  luaK_fixline(fs, line);
}


/*
** Control whether for-loop control variables are read-only
*/
#if LUA_COMPAT_LOOPVAR
#define LOOPVARKIND	VDKREG
#else  /* by default, these variables are read only */
#define LOOPVARKIND	RDKCONST
#endif

static void fornum (LexState *ls, TString *varname, int line) {
  /* fornum -> NAME = exp,exp[,exp] forbody */
  FuncState *fs = ls->fs;
  int base = fs->freereg;
  new_localvarliteral(ls, "(for state)");
  new_localvarliteral(ls, "(for state)");
  new_varkind(ls, varname, LOOPVARKIND);  /* control variable */
  checknext(ls, '=');
  exp1(ls);  /* initial value */
  checknext(ls, ',');
  exp1(ls);  /* limit */
  if (testnext(ls, ','))
    exp1(ls);  /* optional step */
  else {  /* default step = 1 */
    luaK_int(fs, fs->freereg, 1);
    luaK_reserveregs(fs, 1);
  }
  adjustlocalvars(ls, 2);  /* start scope for internal variables */
  forbody(ls, base, line, 1, 0);
}


static void forlist (LexState *ls, TString *indexname) {
  /* forlist -> NAME {,NAME} IN explist forbody */
  FuncState *fs = ls->fs;
  expdesc e;
  int nvars = 4;  /* function, state, closing, control */
  int line;
  int base = fs->freereg;
  /* create internal variables */
  new_localvarliteral(ls, "(for state)");  /* iterator function */
  new_localvarliteral(ls, "(for state)");  /* state */
  new_localvarliteral(ls, "(for state)");  /* closing var. (after swap) */
  new_varkind(ls, indexname, LOOPVARKIND);  /* control variable */
  /* other declared variables */
  while (testnext(ls, ',')) {
    new_localvar(ls, str_checkname(ls));
    nvars++;
  }
  checknext(ls, TK_IN);
  line = ls->linenumber;
  adjust_assign(ls, 4, explist(ls, &e), &e);
  adjustlocalvars(ls, 3);  /* start scope for internal variables */
  marktobeclosed(fs);  /* last internal var. must be closed */
  luaK_checkstack(fs, 2);  /* extra space to call iterator */
  forbody(ls, base, line, nvars - 3, 1);
}


static void forstat (LexState *ls, int line) {
  /* forstat -> FOR '(' NAME IN range_or_iter ')' '{' block '}'
  ** Cangjie for-in with ranges: for (i in 1..=100) or for (i in 0..10:2)
  ** Also supports generic for: for (k, v in pairs(t))
  ** or simple iteration: for (v in expr)
  */
  FuncState *fs = ls->fs;
  TString *varname;
  BlockCnt bl;
  enterblock(fs, &bl, 1);  /* scope for loop and control variables */
  luaX_next(ls);  /* skip 'for' */
  checknext(ls, '(');
  varname = str_checkname(ls);  /* first variable name */
  if (ls->t.token == ',') {
    /* Multiple variables: for (k, v in pairs(t)) */
    /* Parse like forlist but with ')' before body */
    FuncState *fs2 = ls->fs;
    expdesc e;
    int nvars = 4;
    int fline;
    int base2 = fs->freereg;
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_localvarliteral(ls, "(for state)");
    new_varkind(ls, varname, LOOPVARKIND);
    while (testnext(ls, ',')) {
      new_localvar(ls, str_checkname(ls));
      nvars++;
    }
    checknext(ls, TK_IN);
    fline = ls->linenumber;
    adjust_assign(ls, 4, explist(ls, &e), &e);
    adjustlocalvars(ls, 3);
    marktobeclosed(fs2);
    luaK_checkstack(fs2, 2);
    checknext(ls, ')');
    forbody(ls, base2, fline, nvars - 3, 1);
  }
  else if (ls->t.token == TK_IN) {
    luaX_next(ls);  /* skip 'in' */
    /* Peek ahead to determine if this is a range expression.
    ** Parse the first expression without consuming '..' */
    {
      expdesc start_e;
      int base0 = fs->freereg;  /* save base BEFORE parsing expression */
      subexpr(ls, &start_e, 9);  /* stop before '..' (priority 9) */
      if (ls->t.token == TK_CONCAT || ls->t.token == TK_DOTDOTEQ) {
        /* Range expression: start..end or start..=end */
        int inclusive = (ls->t.token == TK_DOTDOTEQ);
        int base = fs->freereg;
        new_localvarliteral(ls, "(for state)");
        new_localvarliteral(ls, "(for state)");
        new_varkind(ls, varname, LOOPVARKIND);
        /* emit start value */
        luaK_exp2nextreg(fs, &start_e);
        luaX_next(ls);  /* skip '..' or '..=' */
        {
          /* Parse limit, stopping before ':' (step separator) */
          expdesc limit_e;
          subexpr(ls, &limit_e, 9);
          luaK_exp2nextreg(fs, &limit_e);
        }
        if (!inclusive) {
          /* exclusive range: adjust limit by -1 */
          luaK_int(fs, fs->freereg, 1);
          luaK_reserveregs(fs, 1);
          luaK_codeABC(fs, OP_SUB, fs->freereg - 2, fs->freereg - 2, fs->freereg - 1);
          fs->freereg--;
        }
        if (testnext(ls, ':')) {
          exp1(ls);  /* step */
        }
        else {
          luaK_int(fs, fs->freereg, 1);
          luaK_reserveregs(fs, 1);
        }
        adjustlocalvars(ls, 2);
        checknext(ls, ')');
        forbody(ls, base, line, 1, 0);
      }
      else {
        /* Generic for: for (v in iterator_expr) */
        int nvars = 4;
        int base2 = base0;  /* use saved base from before expression */
        /* Reset freereg to base to properly allocate for-loop registers */
        fs->freereg = cast_byte(base0);
        new_localvarliteral(ls, "(for state)");
        new_localvarliteral(ls, "(for state)");
        new_localvarliteral(ls, "(for state)");
        new_varkind(ls, varname, LOOPVARKIND);
        /* Now evaluate the expression and assign to the 4 registers */
        {
          int nexps;
          if (hasmultret(start_e.k)) {
            luaK_setmultret(fs, &start_e);
            nexps = LUA_MULTRET;
          }
          else {
            if (start_e.k != VVOID)
              luaK_exp2nextreg(fs, &start_e);
            nexps = 1;
          }
          adjust_assign(ls, 4, nexps, &start_e);
        }
        adjustlocalvars(ls, 3);
        marktobeclosed(fs);
        luaK_checkstack(fs, 2);
        checknext(ls, ')');
        forbody(ls, base2, line, nvars - 3, 1);
      }
    }
  }
  else {
    luaX_syntaxerror(ls, "'in' expected");
  }
  leaveblock(fs);
}


static void test_then_block (LexState *ls, int *escapelist) {
  /* test_then_block -> [IF | ELSE IF] '(' cond ')' '{' block '}' */
  FuncState *fs = ls->fs;
  int condtrue;
  luaX_next(ls);  /* skip IF */
  /* Cangjie requires parentheses around condition */
  checknext(ls, '(');
  condtrue = cond(ls);
  checknext(ls, ')');
  checknext(ls, '{' /*}*/);
  block(ls);  /* 'then' part */
  checknext(ls, /*{*/ '}');
  if (ls->t.token == TK_ELSE)  /* followed by 'else'? */
    luaK_concat(fs, escapelist, luaK_jump(fs));  /* must jump over it */
  luaK_patchtohere(fs, condtrue);
}


static void ifstat (LexState *ls, int line) {
  /* ifstat -> IF cond '{' block '}' {ELSE IF cond '{' block '}'} [ELSE '{' block '}'] */
  FuncState *fs = ls->fs;
  int escapelist = NO_JUMP;  /* exit list for finished parts */
  test_then_block(ls, &escapelist);  /* IF cond { block } */
  while (ls->t.token == TK_ELSE && luaX_lookahead(ls) == TK_IF) {
    luaX_next(ls);  /* skip 'else' - 'if' will be skipped by test_then_block */
    test_then_block(ls, &escapelist);  /* ELSE IF cond { block } */
  }
  if (testnext(ls, TK_ELSE)) {
    checknext(ls, '{' /*}*/);
    block(ls);  /* 'else' part */
    check_match(ls, /*{*/ '}', TK_IF, line);
  }
  luaK_patchtohere(fs, escapelist);  /* patch escape list to 'if' end */
}


static void localfunc (LexState *ls) {
  expdesc b;
  FuncState *fs = ls->fs;
  int fvar = fs->nactvar;  /* function's variable index */
  new_localvar(ls, str_checkname(ls));  /* new local variable */
  adjustlocalvars(ls, 1);  /* enter its scope */
  body(ls, &b, 0, ls->linenumber);  /* function created in next register */
  /* debug information will only see the variable after this point! */
  localdebuginfo(fs, fvar)->startpc = fs->pc;
}


static lu_byte getvarattribute (LexState *ls, lu_byte df) {
  /* attrib -> ['<' NAME '>'] */
  if (testnext(ls, '<')) {
    TString *ts = str_checkname(ls);
    const char *attr = getstr(ts);
    checknext(ls, '>');
    if (strcmp(attr, "const") == 0)
      return RDKCONST;  /* read-only variable */
    else if (strcmp(attr, "close") == 0)
      return RDKTOCLOSE;  /* to-be-closed variable */
    else
      luaK_semerror(ls, "unknown attribute '%s'", attr);
  }
  return df;  /* return default value */
}


static void checktoclose (FuncState *fs, int level) {
  if (level != -1) {  /* is there a to-be-closed variable? */
    marktobeclosed(fs);
    luaK_codeABC(fs, OP_TBC, reglevel(fs, level), 0, 0);
  }
}


static void letvarstat (LexState *ls, int isconst) {
  /* stat -> LET|VAR NAME [':' type] ['=' explist] */
  FuncState *fs = ls->fs;
  int toclose = -1;
  Vardesc *var;
  int vidx;
  int nvars = 0;
  int nexps;
  expdesc e;
  lu_byte defkind = isconst ? RDKCONST : VDKREG;
  do {
    TString *vname = str_checkname(ls);  /* get variable name */
    /* optional type annotation ': Type' - skip it */
    if (testnext(ls, ':')) {
      int depth = 0;
      while (ls->t.token == TK_NAME ||
             (ls->t.token == '<') ||
             (ls->t.token == '>' && depth > 0) ||
             (ls->t.token == ',' && depth > 0)) {
        if (ls->t.token == '<') depth++;
        else if (ls->t.token == '>') depth--;
        luaX_next(ls);
      }
    }
    vidx = new_varkind(ls, vname, defkind);
    nvars++;
  } while (testnext(ls, ','));
  if (testnext(ls, '='))
    nexps = explist(ls, &e);
  else {
    e.k = VVOID;
    nexps = 0;
  }
  var = getlocalvardesc(fs, vidx);
  if (nvars == nexps &&
      var->vd.kind == RDKCONST &&
      luaK_exp2const(fs, &e, &var->k)) {
    var->vd.kind = RDKCTC;
    adjustlocalvars(ls, nvars - 1);
    fs->nactvar++;
  }
  else {
    adjust_assign(ls, nvars, nexps, &e);
    adjustlocalvars(ls, nvars);
  }
  checktoclose(fs, toclose);
}


/* Cangjie does not have a separate 'global' keyword - 
   all top-level declarations are accessible */


static int funcname (LexState *ls, expdesc *v) {
  /* funcname -> NAME {fieldsel} [':' NAME] */
  int ismethod = 0;
  singlevar(ls, v);
  while (ls->t.token == '.')
    fieldsel(ls, v);
  if (ls->t.token == ':') {
    ismethod = 1;
    fieldsel(ls, v);
  }
  return ismethod;
}


static void funcstat (LexState *ls, int line) {
  /* funcstat -> FUNC NAME ['<' typeparams '>'] body */
  expdesc v, b;
  TString *fname;
  luaX_next(ls);  /* skip FUNC */
  fname = str_checkname(ls);
  /* skip generic type parameters <T, U, ...> if present */
  if (ls->t.token == '<') {
    int depth = 1;
    luaX_next(ls);
    while (depth > 0 && ls->t.token != TK_EOS) {
      if (ls->t.token == '<') depth++;
      else if (ls->t.token == '>') depth--;
      if (depth > 0) luaX_next(ls);
    }
    luaX_next(ls);  /* skip final '>' */
  }
  buildvar(ls, fname, &v);
  check_readonly(ls, &v);
  body(ls, &b, 0, line);
  luaK_storevar(ls->fs, &v, &b);
  luaK_fixline(ls->fs, line);  /* definition "happens" in the first line */
}


/*
** Parse struct/class body members (fields and methods)
** Generates table construction and method definitions
*/
static void skip_type_annotation (LexState *ls) {
  /* skip optional type annotation after ':' */
  if (testnext(ls, ':')) {
    int depth = 0;
    while (ls->t.token == TK_NAME ||
           (ls->t.token == '<') ||
           (ls->t.token == '>' && depth > 0) ||
           (ls->t.token == ',' && depth > 0) ||
           (ls->t.token == '(' ) ||
           (ls->t.token == ')' && depth > 0)) {
      if (ls->t.token == TK_NAME && depth == 0) {
        /* If this NAME is followed by '(' at top level, it's likely
        ** a new member definition (e.g. init(...)), not part of type.
        ** Stop consuming here. */
        if (luaX_lookahead(ls) == '(') break;
      }
      if (ls->t.token == '<' || ls->t.token == '(') depth++;
      else if (ls->t.token == '>' || ls->t.token == ')') depth--;
      luaX_next(ls);
    }
  }
}

static void skip_generic_params (LexState *ls) {
  /* skip <T, U, ...> if present */
  if (ls->t.token == '<') {
    int depth = 1;
    luaX_next(ls);
    while (depth > 0 && ls->t.token != TK_EOS) {
      if (ls->t.token == '<') depth++;
      else if (ls->t.token == '>') depth--;
      if (depth > 0) luaX_next(ls);
    }
    luaX_next(ls);  /* skip final '>' */
  }
}


static void structstat (LexState *ls, int line) {
  /*
  ** struct NAME ['<' typeparams '>'] [':' super] '{' members '}'
  ** Compiles to:
  **   NAME = {}; NAME.__index = NAME
  **   function NAME:method(...) ... end
  */
  FuncState *fs = ls->fs;
  expdesc v, e;
  TString *sname;
  int reg;

  luaX_next(ls);  /* skip 'struct' or 'class' */
  sname = str_checkname(ls);

  /* skip generic type parameters */
  skip_generic_params(ls);

  /* optional super class ':' NAME */
  if (testnext(ls, ':')) {
    /* skip parent type name (for now, just skip it) */
    while (ls->t.token == TK_NAME) luaX_next(ls);
  }
  /* also handle '<:' for interface implementation */
  if (ls->t.token == TK_LE) {
    luaX_next(ls);  /* skip '<=' which is our '<:' approximation */
    while (ls->t.token == TK_NAME || ls->t.token == '&') luaX_next(ls);
  }

  /* Create the class table: NAME = {} */
  buildvar(ls, sname, &v);
  /* Generate: {} */
  {
    int pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
    luaK_code(fs, 0);  /* space for extra arg */
    init_exp(&e, VNONRELOC, fs->freereg);
    luaK_reserveregs(fs, 1);
    luaK_settablesize(fs, pc, e.u.info, 0, 0);
  }
  luaK_storevar(fs, &v, &e);

  /* Generate: NAME.__index = NAME */
  {
    expdesc tab, key, val;
    buildvar(ls, sname, &tab);
    luaK_exp2anyregup(fs, &tab);
    codestring(&key, luaX_newstring(ls, "__index", 7));
    luaK_indexed(fs, &tab, &key);
    buildvar(ls, sname, &val);
    luaK_storevar(fs, &tab, &val);
  }

  checknext(ls, '{' /*}*/);

  /* Parse members */
  while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
    if (ls->t.token == TK_FUNC) {
      /* Method definition: func name(...) { ... } */
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'func' */
      mname = str_checkname(ls);
      /* skip generic type params on method */
      skip_generic_params(ls);
      /* Build NAME.methodname */
      buildvar(ls, sname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse method body (with 'self' parameter) */
      body(ls, &mb, 1, ls->linenumber);
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else if (ls->t.token == TK_NAME &&
             ls->t.seminfo.ts == luaS_new(ls->L, "init")) {
      /* Constructor: init(...) { ... } -- no 'func' keyword needed */
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'init' */
      mname = luaS_new(ls->L, "init");
      /* Build NAME.init */
      buildvar(ls, sname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      /* Parse constructor body (auto-returns self) */
      body_init(ls, &mb, ls->linenumber);
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else if (ls->t.token == TK_LET || ls->t.token == TK_VAR) {
      /* Field declaration - skip it (fields are dynamic in our impl) */
      luaX_next(ls);  /* skip let/var */
      str_checkname(ls);  /* field name */
      skip_type_annotation(ls);
      /* optional default value */
      if (testnext(ls, '=')) {
        expdesc dummy;
        expr(ls, &dummy);  /* skip the expression */
      }
    }
    else {
      luaX_syntaxerror(ls, "expected 'func', 'init', 'let', or 'var' in struct/class body");
    }
    testnext(ls, ';');  /* optional semicolons */
  }

  check_match(ls, /*{*/ '}', TK_STRUCT, line);

  /* Generate: __cangjie_setup_class(NAME) to enable Point(x,y) constructor */
  {
    expdesc fn, arg;
    int base2;
    buildvar(ls, luaX_newstring(ls, "__cangjie_setup_class", 21), &fn);
    luaK_exp2nextreg(fs, &fn);
    base2 = fn.u.info;
    buildvar(ls, sname, &arg);
    luaK_exp2nextreg(fs, &arg);
    init_exp(&fn, VCALL,
             luaK_codeABC(fs, OP_CALL, base2, 2, 1));
    fs->freereg = cast_byte(base2);
  }

  reg = fs->freereg;
  fs->freereg = cast_byte(reg);
}


static void interfacestat (LexState *ls, int line) {
  /*
  ** interface NAME ['<' typeparams '>'] '{' func_decls '}'
  ** Compiles to: NAME = {} (marker table)
  */
  FuncState *fs = ls->fs;
  expdesc v, e;
  TString *iname;

  luaX_next(ls);  /* skip 'interface' */
  iname = str_checkname(ls);
  skip_generic_params(ls);

  /* Create the interface table: NAME = {} */
  buildvar(ls, iname, &v);
  {
    int pc = luaK_codevABCk(fs, OP_NEWTABLE, 0, 0, 0, 0);
    luaK_code(fs, 0);
    init_exp(&e, VNONRELOC, fs->freereg);
    luaK_reserveregs(fs, 1);
    luaK_settablesize(fs, pc, e.u.info, 0, 0);
  }
  luaK_storevar(fs, &v, &e);

  checknext(ls, '{' /*}*/);

  /* Parse interface members (just skip declarations) */
  while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
    if (ls->t.token == TK_FUNC) {
      luaX_next(ls);  /* skip 'func' */
      str_checkname(ls);  /* method name */
      skip_generic_params(ls);
      checknext(ls, '(');
      /* skip parameter list */
      while (ls->t.token != ')' && ls->t.token != TK_EOS) {
        luaX_next(ls);
      }
      checknext(ls, ')');
      skip_type_annotation(ls);
      /* If there's a body, parse it */
      if (ls->t.token == '{') {
        /* skip the body - it's a default implementation */
        int depth = 1;
        luaX_next(ls);
        while (depth > 0 && ls->t.token != TK_EOS) {
          if (ls->t.token == '{') depth++;
          else if (ls->t.token == '}') depth--;
          if (depth > 0) luaX_next(ls);
        }
        luaX_next(ls);  /* skip final '}' */
      }
    }
    else {
      luaX_next(ls);  /* skip unknown tokens */
    }
    testnext(ls, ';');
  }

  check_match(ls, /*{*/ '}', TK_INTERFACE, line);
}


static void extendstat (LexState *ls, int line) {
  /*
  ** extend NAME ['<' typeparams '>'] '{' methods '}'
  ** Adds methods to an existing type
  */
  FuncState *fs = ls->fs;
  TString *tname;

  luaX_next(ls);  /* skip 'extend' */
  skip_generic_params(ls);  /* skip possible generic params before name */
  tname = str_checkname(ls);
  skip_generic_params(ls);  /* skip possible generic params after name */

  /* skip optional interface implementation '<:' */
  if (ls->t.token == TK_LE) {
    luaX_next(ls);
    while (ls->t.token == TK_NAME || ls->t.token == '&') luaX_next(ls);
  }

  checknext(ls, '{' /*}*/);

  /* Parse extension methods */
  while (ls->t.token != /*{*/ '}' && ls->t.token != TK_EOS) {
    if (ls->t.token == TK_FUNC) {
      expdesc mv, mb;
      TString *mname;
      luaX_next(ls);  /* skip 'func' */
      mname = str_checkname(ls);
      skip_generic_params(ls);
      /* Build NAME.methodname */
      buildvar(ls, tname, &mv);
      {
        expdesc mkey;
        luaK_exp2anyregup(fs, &mv);
        codestring(&mkey, mname);
        luaK_indexed(fs, &mv, &mkey);
      }
      body(ls, &mb, 1, ls->linenumber);
      luaK_storevar(fs, &mv, &mb);
      luaK_fixline(fs, line);
    }
    else {
      luaX_next(ls);
    }
    testnext(ls, ';');
  }

  check_match(ls, /*{*/ '}', TK_EXTEND, line);
}


static void exprstat (LexState *ls) {
  /* stat -> func | assignment */
  FuncState *fs = ls->fs;
  struct LHS_assign v;
  suffixedexp(ls, &v.v);
  if (ls->t.token == '=' || ls->t.token == ',') { /* stat -> assignment ? */
    v.prev = NULL;
    restassign(ls, &v, 1);
  }
  else {  /* stat -> func */
    Instruction *inst;
    check_condition(ls, v.v.k == VCALL, "syntax error");
    inst = &getinstruction(fs, &v.v);
    SETARG_C(*inst, 1);  /* call statement uses no results */
  }
}


static void retstat (LexState *ls) {
  /* stat -> RETURN [explist] */
  FuncState *fs = ls->fs;
  expdesc e;
  int nret;  /* number of values being returned */
  int first = luaY_nvarstack(fs);  /* first slot to be returned */
  if (block_follow(ls, 1) || ls->t.token == ';')
    nret = 0;  /* return no values */
  else {
    nret = explist(ls, &e);  /* optional return values */
    if (hasmultret(e.k)) {
      luaK_setmultret(fs, &e);
      if (e.k == VCALL && nret == 1 && !fs->bl->insidetbc) {  /* tail call? */
        SET_OPCODE(getinstruction(fs,&e), OP_TAILCALL);
        lua_assert(GETARG_A(getinstruction(fs,&e)) == luaY_nvarstack(fs));
      }
      nret = LUA_MULTRET;  /* return all values */
    }
    else {
      if (nret == 1)  /* only one single value? */
        first = luaK_exp2anyreg(fs, &e);  /* can use original slot */
      else {  /* values must go to the top of the stack */
        luaK_exp2nextreg(fs, &e);
        lua_assert(nret == fs->freereg - first);
      }
    }
  }
  luaK_ret(fs, first, nret);
  testnext(ls, ';');  /* skip optional semicolon */
}


static void statement (LexState *ls) {
  int line = ls->linenumber;  /* may be needed for error messages */
  enterlevel(ls);
  switch (ls->t.token) {
    case ';': {  /* stat -> ';' (empty statement) */
      luaX_next(ls);  /* skip ';' */
      break;
    }
    case TK_IF: {  /* stat -> ifstat */
      ifstat(ls, line);
      break;
    }
    case TK_WHILE: {  /* stat -> whilestat */
      whilestat(ls, line);
      break;
    }
    case TK_FOR: {  /* stat -> forstat */
      forstat(ls, line);
      break;
    }
    case TK_FUNC: {  /* stat -> funcstat */
      funcstat(ls, line);
      break;
    }
    case TK_LET: {  /* stat -> let declaration (const) */
      luaX_next(ls);  /* skip LET */
      if (ls->t.token == TK_FUNC) {
        luaX_next(ls);  /* skip FUNC */
        localfunc(ls);
      }
      else
        letvarstat(ls, 1);  /* const */
      break;
    }
    case TK_VAR: {  /* stat -> var declaration (mutable) */
      luaX_next(ls);  /* skip VAR */
      letvarstat(ls, 0);  /* mutable */
      break;
    }
    case TK_RETURN: {  /* stat -> retstat */
      luaX_next(ls);  /* skip RETURN */
      retstat(ls);
      break;
    }
    case TK_BREAK: {  /* stat -> breakstat */
      breakstat(ls, line);
      break;
    }
    case TK_STRUCT: case TK_CLASS: {  /* stat -> struct/class definition */
      structstat(ls, line);
      break;
    }
    case TK_INTERFACE: {  /* stat -> interface definition */
      interfacestat(ls, line);
      break;
    }
    case TK_EXTEND: {  /* stat -> extend type */
      extendstat(ls, line);
      break;
    }
    case TK_DBCOLON: {  /* stat -> label */
      luaX_next(ls);  /* skip double colon */
      labelstat(ls, str_checkname(ls), line);
      break;
    }
    default: {  /* stat -> func | assignment */
      exprstat(ls);
      break;
    }
  }
  lua_assert(ls->fs->f->maxstacksize >= ls->fs->freereg &&
             ls->fs->freereg >= luaY_nvarstack(ls->fs));
  ls->fs->freereg = luaY_nvarstack(ls->fs);  /* free registers */
  leavelevel(ls);
}

/* }====================================================================== */

/* }====================================================================== */


/*
** compiles the main function, which is a regular vararg function with an
** upvalue named LUA_ENV
*/
static void mainfunc (LexState *ls, FuncState *fs) {
  BlockCnt bl;
  Upvaldesc *env;
  open_func(ls, fs, &bl);
  setvararg(fs);  /* main function is always vararg */
  env = allocupvalue(fs);  /* ...set environment upvalue */
  env->instack = 1;
  env->idx = 0;
  env->kind = VDKREG;
  env->name = ls->envn;
  luaC_objbarrier(ls->L, fs->f, env->name);
  luaX_next(ls);  /* read first token */
  statlist(ls);  /* parse main body */
  check(ls, TK_EOS);
  close_func(ls);
}


LClosure *luaY_parser (lua_State *L, ZIO *z, Mbuffer *buff,
                       Dyndata *dyd, const char *name, int firstchar) {
  LexState lexstate;
  FuncState funcstate;
  LClosure *cl = luaF_newLclosure(L, 1);  /* create main closure */
  setclLvalue2s(L, L->top.p, cl);  /* anchor it (to avoid being collected) */
  luaD_inctop(L);
  lexstate.h = luaH_new(L);  /* create table for scanner */
  sethvalue2s(L, L->top.p, lexstate.h);  /* anchor it */
  luaD_inctop(L);
  funcstate.f = cl->p = luaF_newproto(L);
  luaC_objbarrier(L, cl, cl->p);
  funcstate.f->source = luaS_new(L, name);  /* create and anchor TString */
  luaC_objbarrier(L, funcstate.f, funcstate.f->source);
  lexstate.buff = buff;
  lexstate.dyd = dyd;
  dyd->actvar.n = dyd->gt.n = dyd->label.n = 0;
  luaX_setinput(L, &lexstate, z, funcstate.f->source, firstchar);
  mainfunc(&lexstate, &funcstate);
  lua_assert(!funcstate.prev && funcstate.nups == 1 && !lexstate.fs);
  /* all scopes should be correctly finished */
  lua_assert(dyd->actvar.n == 0 && dyd->gt.n == 0 && dyd->label.n == 0);
  L->top.p--;  /* remove scanner's table */
  return cl;  /* closure is on the stack, too */
}

