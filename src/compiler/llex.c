/*
** $Id: llex.c $
** Lexical Analyzer
** See Copyright Notice in lua.h
*/

#define llex_c
#define LUA_CORE

#include "lprefix.h"


#include <locale.h>
#include <string.h>

#include "lua.h"

#include "lctype.h"
#include "ldebug.h"
#include "ldo.h"
#include "lgc.h"
#include "llex.h"
#include "lobject.h"
#include "lparser.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"
#include "lzio.h"



#define next(ls)	(ls->current = zgetc(ls->z))


/* minimum size for string buffer */
#if !defined(LUA_MINBUFFER)
#define LUA_MINBUFFER   32
#endif


#define currIsNewline(ls)	(ls->current == '\n' || ls->current == '\r')


/* ORDER RESERVED */
static const char *const luaX_tokens [] = {
    "break",
    "case", "class", "continue", "else", "enum", "extend",
    "false", "for", "func",
    "if", "in", "interface", "let", "match", "nil",
    "return", "struct", "super", "this", "true", "var", "while",
    "//", "..", "...", "==", ">=", "<=", "!=",
    "<<", ">>", "::", "=>", "..=",
    "&&", "||", "!", "**", "??",
    "<eof>",
    "<number>", "<integer>", "<name>", "<string>"
};


/* ============================================================
** Lexer utility functions
** ============================================================ */

#define save_and_next(ls) (save(ls, ls->current), next(ls))


static l_noret lexerror (LexState *ls, const char *msg, int token);


static void save (LexState *ls, int c) {
  Mbuffer *b = ls->buff;
  if (luaZ_bufflen(b) + 1 > luaZ_sizebuffer(b)) {
    size_t newsize = luaZ_sizebuffer(b);  /* get old size */;
    if (newsize >= (MAX_SIZE/3 * 2))  /* larger than MAX_SIZE/1.5 ? */
      lexerror(ls, "lexical element too long", 0);
    newsize += (newsize >> 1);  /* new size is 1.5 times the old one */
    luaZ_resizebuffer(ls->L, b, newsize);
  }
  b->buffer[luaZ_bufflen(b)++] = cast_char(c);
}


void luaX_init (lua_State *L) {
  int i;
  TString *e = luaS_newliteral(L, LUA_ENV);  /* create env name */
  luaC_fix(L, obj2gco(e));  /* never collect this name */
  for (i=0; i<NUM_RESERVED; i++) {
    TString *ts = luaS_new(L, luaX_tokens[i]);
    luaC_fix(L, obj2gco(ts));  /* reserved words are never collected */
    ts->extra = cast_byte(i+1);  /* reserved word */
  }
}


const char *luaX_token2str (LexState *ls, int token) {
  if (token < FIRST_RESERVED) {  /* single-byte symbols? */
    if (lisprint(token))
      return luaO_pushfstring(ls->L, "'%c'", token);
    else  /* control character */
      return luaO_pushfstring(ls->L, "'<\\%d>'", token);
  }
  else {
    const char *s = luaX_tokens[token - FIRST_RESERVED];
    if (token < TK_EOS)  /* fixed format (symbols and reserved words)? */
      return luaO_pushfstring(ls->L, "'%s'", s);
    else  /* names, strings, and numerals */
      return s;
  }
}


static const char *txtToken (LexState *ls, int token) {
  switch (token) {
    case TK_NAME: case TK_STRING:
    case TK_FLT: case TK_INT:
      save(ls, '\0');
      return luaO_pushfstring(ls->L, "'%s'", luaZ_buffer(ls->buff));
    default:
      return luaX_token2str(ls, token);
  }
}


static l_noret lexerror (LexState *ls, const char *msg, int token) {
  msg = luaG_addinfo(ls->L, msg, ls->source, ls->linenumber);
  if (token)
    luaO_pushfstring(ls->L, "%s near %s", msg, txtToken(ls, token));
  luaD_throw(ls->L, LUA_ERRSYNTAX);
}


l_noret luaX_syntaxerror (LexState *ls, const char *msg) {
  lexerror(ls, msg, ls->t.token);
}


/*
** Anchors a string in scanner's table so that it will not be collected
** until the end of the compilation; by that time it should be anchored
** somewhere. It also internalizes long strings, ensuring there is only
** one copy of each unique string.
*/
static TString *anchorstr (LexState *ls, TString *ts) {
  lua_State *L = ls->L;
  TValue oldts;
  int tag = luaH_getstr(ls->h, ts, &oldts);
  if (!tagisempty(tag))  /* string already present? */
    return tsvalue(&oldts);  /* use stored value */
  else {  /* create a new entry */
    TValue *stv = s2v(L->top.p++);  /* reserve stack space for string */
    setsvalue(L, stv, ts);  /* push (anchor) the string on the stack */
    luaH_set(L, ls->h, stv, stv);  /* t[string] = string */
    /* table is not a metatable, so it does not need to invalidate cache */
    luaC_checkGC(L);
    L->top.p--;  /* remove string from stack */
    return ts;
  }
}


/*
** Creates a new string and anchors it in scanner's table.
*/
TString *luaX_newstring (LexState *ls, const char *str, size_t l) {
  return anchorstr(ls, luaS_newlstr(ls->L, str, l));
}


/*
** increment line number and skips newline sequence (any of
** \n, \r, \n\r, or \r\n)
*/
static void inclinenumber (LexState *ls) {
  int old = ls->current;
  lua_assert(currIsNewline(ls));
  next(ls);  /* skip '\n' or '\r' */
  if (currIsNewline(ls) && ls->current != old)
    next(ls);  /* skip '\n\r' or '\r\n' */
  if (++ls->linenumber >= INT_MAX)
    lexerror(ls, "chunk has too many lines", 0);
}


void luaX_setinput (lua_State *L, LexState *ls, ZIO *z, TString *source,
                    int firstchar) {
  ls->t.token = 0;
  ls->L = L;
  ls->current = firstchar;
  ls->lookahead.token = TK_EOS;  /* no look-ahead token */
  ls->z = z;
  ls->fs = NULL;
  ls->linenumber = 1;
  ls->lastline = 1;
  ls->source = source;
  /* all strings here ("_ENV", "break") were fixed,
     so they cannot be collected */
  ls->envn = luaS_newliteral(L, LUA_ENV);  /* get env string */
  ls->brkn = luaS_newliteral(L, "break");  /* get "break" string */
  ls->contn = luaS_newliteral(L, "continue");  /* get "continue" string */
  ls->interp_depth = 0;  /* not inside string interpolation */
  ls->nfields = 0;  /* no struct fields */
  ls->in_struct_method = 0;  /* not inside a struct method */
  ls->current_class_name = NULL;  /* not inside a class */
  ls->nclass_registry = 0;  /* no classes registered */
  ls->in_range_limit = 0;  /* not inside range limit */
#if LUA_COMPAT_GLOBAL
  /* compatibility mode: "global" is not a reserved word */
  ls->glbn = luaS_newliteral(L, "global");  /* get "global" string */
  ls->glbn->extra = 0;  /* mark it as not reserved */
#endif
  luaZ_resizebuffer(ls->L, ls->buff, LUA_MINBUFFER);  /* initialize buffer */
}



/*
** =======================================================
** LEXICAL ANALYZER
** =======================================================
*/


static int check_next1 (LexState *ls, int c) {
  if (ls->current == c) {
    next(ls);
    return 1;
  }
  else return 0;
}


/*
** Check whether current char is in set 'set' (with two chars) and
** saves it
*/
static int check_next2 (LexState *ls, const char *set) {
  lua_assert(set[2] == '\0');
  if (ls->current == set[0] || ls->current == set[1]) {
    save_and_next(ls);
    return 1;
  }
  else return 0;
}


/* LUA_NUMBER */
/*
** This function is quite liberal in what it accepts, as 'luaO_str2num'
** will reject ill-formed numerals. Roughly, it accepts the following
** pattern:
**
**   %d(%x|%.|([Ee][+-]?))* | 0[Xx](%x|%.|([Pp][+-]?))*
**
** The only tricky part is to accept [+-] only after a valid exponent
** mark, to avoid reading '3-4' or '0xe+1' as a single number.
**
** The caller might have already read an initial dot.
*/
static int read_numeral (LexState *ls, SemInfo *seminfo) {
  TValue obj;
  const char *expo = "Ee";
  int first = ls->current;
  int ishex = 0;
  lua_assert(lisdigit(ls->current));
  save_and_next(ls);
  if (first == '0' && check_next2(ls, "xX")) {  /* hexadecimal? */
    expo = "Pp";
    ishex = 1;
  }
  for (;;) {
    if (check_next2(ls, expo))  /* exponent mark? */
      check_next2(ls, "-+");  /* optional exponent sign */
    else if (lisxdigit(ls->current))  /* hex digit */
      save_and_next(ls);
    else if (ls->current == '.') {
      /* Don't consume '.' if next char is also '.' (range operator) */
      if (ls->z->n > 0 && *(ls->z->p) == '.')
        break;  /* stop: this is '..' range operator */
      /* Don't consume '.' if next char starts an identifier (method call).
      ** This allows syntax like 2.pow(10) or 42.double() or 4.even().
      ** In decimal mode: only digits 0-9 are valid after '.'. Letters are
      ** method calls, UNLESS they are an exponent marker (e/E) followed by
      ** a digit or sign (+/-), which is valid scientific notation (e.g., 2.e5).
      ** In hex mode: hex digits a-f/A-F are valid fractional parts, and
      ** p/P starts the exponent. Other letters are method calls. Similarly,
      ** p/P after '.' must be followed by a digit or sign to be valid. */
      if (ls->z->n > 0) {
        int nc = cast_uchar(*(ls->z->p));
        if (lislalpha(nc)) {
          if (ishex) {
            /* Hex mode: allow hex digits after '.' */
            if (!lisxdigit(nc)) {
              /* Check if it's an exponent marker (p/P) followed by digit/sign */
              if ((nc == expo[0] || nc == expo[1]) && ls->z->n > 1) {
                int nc2 = cast_uchar(*(ls->z->p + 1));
                if (!lisdigit(nc2) && nc2 != '+' && nc2 != '-')
                  break;  /* e.g., 0xFF.pow() - method call */
              }
              else
                break;  /* method call on hex number literal */
            }
          }
          else {
            /* Decimal mode: only digits are valid after '.' for the number */
            /* Check if it's an exponent marker (e/E) followed by digit/sign */
            if (nc == expo[0] || nc == expo[1]) {
              if (ls->z->n > 1) {
                int nc2 = cast_uchar(*(ls->z->p + 1));
                if (!lisdigit(nc2) && nc2 != '+' && nc2 != '-')
                  break;  /* e.g., 4.even() - method call */
              }
              else
                break;  /* e/E at end of input - method call */
              /* Otherwise it's valid scientific notation: fall through */
            }
            else
              break;  /* method call on decimal number literal */
          }
        }
      }
      save_and_next(ls);
    }
    else break;
  }
  if (lislalpha(ls->current))  /* is numeral touching a letter? */
    save_and_next(ls);  /* force an error */
  save(ls, '\0');
  if (luaO_str2num(luaZ_buffer(ls->buff), &obj) == 0)  /* format error? */
    lexerror(ls, "malformed number", TK_FLT);
  if (ttisinteger(&obj)) {
    seminfo->i = ivalue(&obj);
    return TK_INT;
  }
  else {
    lua_assert(ttisfloat(&obj));
    seminfo->r = fltvalue(&obj);
    return TK_FLT;
  }
}


/*
** read a sequence '[=*[' or ']=*]', leaving the last bracket. If
** sequence is well formed, return its number of '='s + 2; otherwise,
** return 1 if it is a single bracket (no '='s and no 2nd bracket);
** otherwise (an unfinished '[==...') return 0.
*/
static size_t skip_sep (LexState *ls) {
  size_t count = 0;
  int s = ls->current;
  lua_assert(s == '[' || s == ']');
  save_and_next(ls);
  while (ls->current == '=') {
    save_and_next(ls);
    count++;
  }
  return (ls->current == s) ? count + 2
         : (count == 0) ? 1
         : 0;
}


static void read_long_string (LexState *ls, SemInfo *seminfo, size_t sep) {
  int line = ls->linenumber;  /* initial line (for error message) */
  save_and_next(ls);  /* skip 2nd '[' */
  if (currIsNewline(ls))  /* string starts with a newline? */
    inclinenumber(ls);  /* skip it */
  for (;;) {
    switch (ls->current) {
      case EOZ: {  /* error */
        const char *what = (seminfo ? "string" : "comment");
        const char *msg = luaO_pushfstring(ls->L,
                     "unfinished long %s (starting at line %d)", what, line);
        lexerror(ls, msg, TK_EOS);
        break;  /* to avoid warnings */
      }
      case ']': {
        if (skip_sep(ls) == sep) {
          save_and_next(ls);  /* skip 2nd ']' */
          goto endloop;
        }
        break;
      }
      case '\n': case '\r': {
        save(ls, '\n');
        inclinenumber(ls);
        if (!seminfo) luaZ_resetbuffer(ls->buff);  /* avoid wasting space */
        break;
      }
      default: {
        if (seminfo) save_and_next(ls);
        else next(ls);
      }
    }
  } endloop:
  if (seminfo)
    seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + sep,
                                     luaZ_bufflen(ls->buff) - 2 * sep);
}


static void esccheck (LexState *ls, int c, const char *msg) {
  if (!c) {
    if (ls->current != EOZ)
      save_and_next(ls);  /* add current to buffer for error message */
    lexerror(ls, msg, TK_STRING);
  }
}


static int gethexa (LexState *ls) {
  save_and_next(ls);
  esccheck (ls, lisxdigit(ls->current), "hexadecimal digit expected");
  return luaO_hexavalue(ls->current);
}


static int readhexaesc (LexState *ls) {
  int r = gethexa(ls);
  r = (r << 4) + gethexa(ls);
  luaZ_buffremove(ls->buff, 2);  /* remove saved chars from buffer */
  return r;
}


/*
** When reading a UTF-8 escape sequence, save everything to the buffer
** for error reporting in case of errors; 'i' counts the number of
** saved characters, so that they can be removed if case of success.
*/
static l_uint32 readutf8esc (LexState *ls) {
  l_uint32 r;
  int i = 4;  /* number of chars to be removed: start with #"\u{X" */
  save_and_next(ls);  /* skip 'u' */
  esccheck(ls, ls->current == '{', "missing '{'");
  r = cast_uint(gethexa(ls));  /* must have at least one digit */
  while (cast_void(save_and_next(ls)), lisxdigit(ls->current)) {
    i++;
    esccheck(ls, r <= (0x7FFFFFFFu >> 4), "UTF-8 value too large");
    r = (r << 4) + luaO_hexavalue(ls->current);
  }
  esccheck(ls, ls->current == '}', "missing '}'");
  next(ls);  /* skip '}' */
  luaZ_buffremove(ls->buff, i);  /* remove saved chars from buffer */
  return r;
}


static void utf8esc (LexState *ls) {
  char buff[UTF8BUFFSZ];
  int n = luaO_utf8esc(buff, readutf8esc(ls));
  for (; n > 0; n--)  /* add 'buff' to string */
    save(ls, buff[UTF8BUFFSZ - n]);
}


static int readdecesc (LexState *ls) {
  int i;
  int r = 0;  /* result accumulator */
  for (i = 0; i < 3 && lisdigit(ls->current); i++) {  /* read up to 3 digits */
    r = 10*r + ls->current - '0';
    save_and_next(ls);
  }
  esccheck(ls, r <= UCHAR_MAX, "decimal escape too large");
  luaZ_buffremove(ls->buff, i);  /* remove read digits from buffer */
  return r;
}


/*
** ============================================================
** String reading with interpolation support
** Read a Cangjie/Lua string literal. Supports:
**   - Standard escape sequences (\n, \t, etc.)
**   - String interpolation: ${expr} within double-quoted strings
**   - Unicode escapes: \u{XXXX}
** ============================================================
*/
static void read_string (LexState *ls, int del, SemInfo *seminfo) {
  save_and_next(ls);  /* keep delimiter (for error messages) */
  while (ls->current != del) {
    switch (ls->current) {
      case EOZ:
        lexerror(ls, "unfinished string", TK_EOS);
        break;  /* to avoid warnings */
      case '\n':
      case '\r':
        lexerror(ls, "unfinished string", TK_STRING);
        break;  /* to avoid warnings */
      case '$': {  /* possible string interpolation */
        next(ls);
        if (ls->current == '{') {
          /* string interpolation: save what we have so far as a string part */
          /* remove the opening delimiter from the saved token */
          save(ls, del);  /* add closing delimiter to match the open one */
          seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + 1,
                                           luaZ_bufflen(ls->buff) - 2);
          next(ls);  /* skip '{' */
          ls->interp_depth++;
          return;  /* return with the partial string */
        }
        else {
          save(ls, '$');  /* just a literal '$' */
        }
        break;
      }
      case '\\': {  /* escape sequences */
        int c;  /* final character to be saved */
        save_and_next(ls);  /* keep '\\' for error messages */
        switch (ls->current) {
          case 'a': c = '\a'; goto read_save;
          case 'b': c = '\b'; goto read_save;
          case 'f': c = '\f'; goto read_save;
          case 'n': c = '\n'; goto read_save;
          case 'r': c = '\r'; goto read_save;
          case 't': c = '\t'; goto read_save;
          case 'v': c = '\v'; goto read_save;
          case 'x': c = readhexaesc(ls); goto read_save;
          case 'u': utf8esc(ls);  goto no_save;
          case '\n': case '\r':
            inclinenumber(ls); c = '\n'; goto only_save;
          case '\\': case '\"': case '\'':
            c = ls->current; goto read_save;
          case EOZ: goto no_save;  /* will raise an error next loop */
          case 'z': {  /* zap following span of spaces */
            luaZ_buffremove(ls->buff, 1);  /* remove '\\' */
            next(ls);  /* skip the 'z' */
            while (lisspace(ls->current)) {
              if (currIsNewline(ls)) inclinenumber(ls);
              else next(ls);
            }
            goto no_save;
          }
          default: {
            esccheck(ls, lisdigit(ls->current), "invalid escape sequence");
            c = readdecesc(ls);  /* digital escape '\ddd' */
            goto only_save;
          }
        }
       read_save:
         next(ls);
         /* go through */
       only_save:
         luaZ_buffremove(ls->buff, 1);  /* remove '\\' */
         save(ls, c);
         /* go through */
       no_save: break;
      }
      default:
        save_and_next(ls);
    }
  }
  save_and_next(ls);  /* skip delimiter */
  seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + 1,
                                   luaZ_bufflen(ls->buff) - 2);
}


/*
** Continue reading an interpolated string after '}' closes
** an interpolation expression. Called from the parser when
** it finishes parsing the expression inside ${...}.
*/
void luaX_read_interp_string (LexState *ls, SemInfo *seminfo) {
  luaZ_resetbuffer(ls->buff);
  save(ls, '"');  /* fake opening delimiter for consistency */
  while (ls->current != '"') {
    switch (ls->current) {
      case EOZ:
        lexerror(ls, "unfinished string", TK_EOS);
        break;
      case '\n':
      case '\r':
        lexerror(ls, "unfinished string", TK_STRING);
        break;
      case '$': {
        next(ls);
        if (ls->current == '{') {
          save(ls, '"');  /* closing delimiter */
          seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + 1,
                                           luaZ_bufflen(ls->buff) - 2);
          next(ls);  /* skip '{' */
          /* interp_depth stays the same (or increases for nested) */
          ls->interp_depth++;
          return;
        }
        else {
          save(ls, '$');
        }
        break;
      }
      case '\\': {
        int c;
        save_and_next(ls);
        switch (ls->current) {
          case 'a': c = '\a'; goto is_read_save;
          case 'b': c = '\b'; goto is_read_save;
          case 'f': c = '\f'; goto is_read_save;
          case 'n': c = '\n'; goto is_read_save;
          case 'r': c = '\r'; goto is_read_save;
          case 't': c = '\t'; goto is_read_save;
          case 'v': c = '\v'; goto is_read_save;
          case 'x': c = readhexaesc(ls); goto is_read_save;
          case 'u': utf8esc(ls); goto is_no_save;
          case '\n': case '\r':
            inclinenumber(ls); c = '\n'; goto is_only_save;
          case '\\': case '\"': case '\'':
            c = ls->current; goto is_read_save;
          case EOZ: goto is_no_save;
          default: {
            esccheck(ls, lisdigit(ls->current), "invalid escape sequence");
            c = readdecesc(ls);
            goto is_only_save;
          }
        }
       is_read_save:
         next(ls);
       is_only_save:
         luaZ_buffremove(ls->buff, 1);
         save(ls, c);
       is_no_save: break;
      }
      default:
        save_and_next(ls);
    }
  }
  save_and_next(ls);  /* skip closing '"' */
  seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + 1,
                                   luaZ_bufflen(ls->buff) - 2);
}


/*
** ============================================================
** Main lexer function
** Reads the next token from the input stream.
** Handles Cangjie-specific tokens:
**   - // and block comments (instead of Lua's --)
**   - && || ! operators (instead of Lua's and/or/not)
**   - ** power operator (instead of Lua's ^)
**   - .. and ..= range operators
**   - => arrow for lambda/match
**   - :: scope resolution
** ============================================================
*/
static int llex (LexState *ls, SemInfo *seminfo) {
  luaZ_resetbuffer(ls->buff);
  for (;;) {
    switch (ls->current) {
      case '\n': case '\r': {  /* line breaks */
        inclinenumber(ls);
        break;
      }
      case ' ': case '\f': case '\t': case '\v': {  /* spaces */
        next(ls);
        break;
      }
      case '-': {  /* '-' (no comment with -- in Cangjie) */
        next(ls);
        return '-';
      }
      case '/': {  /* '/', '//' line comment, or block comment */
        next(ls);
        if (ls->current == '/') {
          /* single-line comment (Cangjie style) */
          while (!currIsNewline(ls) && ls->current != EOZ)
            next(ls);  /* skip until end of line (or end of file) */
          break;
        }
        else if (ls->current == '*') {
          /* block comment (Cangjie style) */
          int line = ls->linenumber;
          int depth = 1;
          next(ls);  /* skip '*' */
          while (depth > 0) {
            if (ls->current == EOZ) {
              const char *msg = luaO_pushfstring(ls->L,
                   "unfinished block comment (starting at line %d)", line);
              lexerror(ls, msg, TK_EOS);
            }
            else if (ls->current == '/' && (next(ls), ls->current == '*')) {
              next(ls);
              depth++;
            }
            else if (ls->current == '*' && (next(ls), ls->current == '/')) {
              next(ls);
              depth--;
            }
            else if (currIsNewline(ls)) {
              inclinenumber(ls);
            }
            else {
              next(ls);
            }
          }
          break;
        }
        else return '/';
      }
      case '[': {  /* simply '[' in Cangjie (used for arrays) */
        next(ls);
        return '[';
      }
      case '=': {
        next(ls);
        if (check_next1(ls, '=')) return TK_EQ;  /* '==' */
        else if (check_next1(ls, '>')) return TK_ARROW;  /* '=>' */
        else return '=';
      }
      case '<': {
        next(ls);
        if (check_next1(ls, '=')) return TK_LE;  /* '<=' */
        else if (check_next1(ls, '<')) return TK_SHL;  /* '<<' */
        else return '<';
      }
      case '>': {
        next(ls);
        if (check_next1(ls, '=')) return TK_GE;  /* '>=' */
        else if (check_next1(ls, '>')) return TK_SHR;  /* '>>' */
        else return '>';
      }
      case '!': {  /* '!=' (Cangjie not-equal) or '!' (logical not / bitwise not for integers) */
        next(ls);
        if (check_next1(ls, '=')) return TK_NE;  /* '!=' */
        else return TK_NOT;  /* '!' as unary not */
      }
      case '~': {  /* '~' (unused single char, kept for compat) */
        next(ls);
        return '~';
      }
      case '&': {  /* '&' bitwise AND or '&&' logical AND */
        next(ls);
        if (check_next1(ls, '&')) return TK_AND;  /* '&&' */
        else return '&';
      }
      case '|': {  /* '|' bitwise OR or '||' logical OR */
        next(ls);
        if (check_next1(ls, '|')) return TK_OR;  /* '||' */
        else return '|';
      }
      case '*': {  /* '*' multiply or '**' power */
        next(ls);
        if (check_next1(ls, '*')) return TK_POW;  /* '**' */
        else return '*';
      }
      case '?': {  /* '?' or '??' coalescing */
        next(ls);
        if (check_next1(ls, '?')) return TK_COALESCE;  /* '??' */
        else return '?';
      }
      case '^': {  /* '^' bitwise XOR */
        next(ls);
        return '^';
      }
      case ':': {
        next(ls);
        if (check_next1(ls, ':')) return TK_DBCOLON;  /* '::' */
        else return ':';
      }
      case '"': {  /* strings with interpolation support */
        read_string(ls, ls->current, seminfo);
        return TK_STRING;
      }
      case '\'': {  /* single-char literal r'x' handled elsewhere, or string */
        read_string(ls, ls->current, seminfo);
        return TK_STRING;
      }
      case '.': {  /* '.', '..', '..=', '...', or number */
        save_and_next(ls);
        if (check_next1(ls, '.')) {
          if (check_next1(ls, '='))
            return TK_DOTDOTEQ;  /* '..=' inclusive range */
          else if (check_next1(ls, '.'))
            return TK_DOTS;   /* '...' */
          else return TK_CONCAT;   /* '..' also used as range */
        }
        else if (!lisdigit(ls->current)) return '.';
        else return read_numeral(ls, seminfo);
      }
      case '0': case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9': {
        return read_numeral(ls, seminfo);
      }
      case EOZ: {
        return TK_EOS;
      }
      default: {
        if (lislalpha(ls->current)) {  /* identifier or reserved word? */
          TString *ts;
          do {
            save_and_next(ls);
          } while (lislalnum(ls->current));
          /* find or create string */
          ts = luaS_newlstr(ls->L, luaZ_buffer(ls->buff),
                                   luaZ_bufflen(ls->buff));
          if (isreserved(ts))   /* reserved word? */
            return ts->extra - 1 + FIRST_RESERVED;
          else {
            seminfo->ts = anchorstr(ls, ts);
            return TK_NAME;
          }
        }
        else {  /* single-char tokens ('+', '*', '%', '{', '}', ...) */
          int c = ls->current;
          next(ls);
          return c;
        }
      }
    }
  }
}


/*
** ============================================================
** Public lexer API
** ============================================================
*/
void luaX_next (LexState *ls) {
  ls->lastline = ls->linenumber;
  if (ls->lookahead.token != TK_EOS) {  /* is there a look-ahead token? */
    ls->t = ls->lookahead;  /* use this one */
    ls->lookahead.token = TK_EOS;  /* and discharge it */
  }
  else
    ls->t.token = llex(ls, &ls->t.seminfo);  /* read next token */
}


int luaX_lookahead (LexState *ls) {
  lua_assert(ls->lookahead.token == TK_EOS);
  ls->lookahead.token = llex(ls, &ls->lookahead.seminfo);
  return ls->lookahead.token;
}

