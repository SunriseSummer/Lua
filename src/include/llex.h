/*
** $Id: llex.h $
** Lexical Analyzer
** See Copyright Notice in lua.h
*/

#ifndef llex_h
#define llex_h

#include <limits.h>

#include "lobject.h"
#include "lzio.h"


/*
** Single-char tokens (terminal symbols) are represented by their own
** numeric code. Other tokens start at the following value.
*/
#define FIRST_RESERVED	(UCHAR_MAX + 1)


#if !defined(LUA_ENV)
#define LUA_ENV		"_ENV"
#endif


/*
* WARNING: if you change the order of this enumeration,
* grep "ORDER RESERVED"
*/
enum RESERVED {
  /* terminal symbols denoted by reserved words (Cangjie keywords) */
  TK_BREAK = FIRST_RESERVED,
  TK_CASE, TK_CLASS, TK_CONTINUE, TK_ELSE, TK_ENUM, TK_EXTEND,
  TK_FALSE, TK_FOR, TK_FUNC,
  TK_IF, TK_IN, TK_INTERFACE, TK_LET, TK_MATCH, TK_NIL,
  TK_RETURN, TK_STRUCT, TK_SUPER, TK_THIS, TK_TRUE, TK_VAR, TK_WHILE,
  /* other terminal symbols */
  TK_IDIV, TK_CONCAT, TK_DOTS, TK_EQ, TK_GE, TK_LE, TK_NE,
  TK_SHL, TK_SHR,
  TK_DBCOLON, TK_ARROW, TK_DOTDOTEQ,
  TK_AND, TK_OR, TK_NOT, TK_POW,
  TK_EOS,
  TK_FLT, TK_INT, TK_NAME, TK_STRING
};

/* number of reserved words */
#define NUM_RESERVED	(cast_int(TK_WHILE-FIRST_RESERVED + 1))


typedef union {
  lua_Number r;
  lua_Integer i;
  TString *ts;
} SemInfo;  /* semantics information */


typedef struct Token {
  int token;
  SemInfo seminfo;
} Token;


/* state of the scanner plus state of the parser when shared by all
   functions */
typedef struct LexState {
  int current;  /* current character (charint) */
  int linenumber;  /* input line counter */
  int lastline;  /* line of last token 'consumed' */
  Token t;  /* current token */
  Token lookahead;  /* look ahead token */
  struct FuncState *fs;  /* current function (parser) */
  struct lua_State *L;
  ZIO *z;  /* input stream */
  Mbuffer *buff;  /* buffer for tokens */
  Table *h;  /* to avoid collection/reuse strings */
  struct Dyndata *dyd;  /* dynamic structures used by the parser */
  TString *source;  /* current source name */
  TString *envn;  /* environment variable name */
  TString *brkn;  /* "break" name (used as a label) */
  TString *contn;  /* "continue" name (used as a label) */
  TString *glbn;  /* "global" name (when not a reserved word) */
  int interp_depth;  /* depth of string interpolation nesting */
  /* Cangjie struct/class field tracking for implicit 'this' */
  TString *struct_fields[64];  /* field names of current struct/class */
  int nfields;  /* number of fields in current struct/class */
  int in_struct_method;  /* nonzero if parsing inside a struct/class method */
  /* Cangjie type definition tracking for redefinition detection */
  TString *defined_types[128];  /* type names defined at current scope level */
  int ndefined_types;  /* number of defined type names */
} LexState;


LUAI_FUNC void luaX_init (lua_State *L);
LUAI_FUNC void luaX_setinput (lua_State *L, LexState *ls, ZIO *z,
                              TString *source, int firstchar);
LUAI_FUNC TString *luaX_newstring (LexState *ls, const char *str, size_t l);
LUAI_FUNC void luaX_next (LexState *ls);
LUAI_FUNC int luaX_lookahead (LexState *ls);
LUAI_FUNC l_noret luaX_syntaxerror (LexState *ls, const char *s);
LUAI_FUNC const char *luaX_token2str (LexState *ls, int token);
LUAI_FUNC void luaX_read_interp_string (LexState *ls, SemInfo *seminfo);


#endif
