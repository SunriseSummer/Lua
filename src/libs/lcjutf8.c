/*
** $Id: lcjutf8.c $
** Shared UTF-8 utility functions for Cangjie runtime
** See Copyright Notice in lua.h
*/

#define lcjutf8_c
#define LUA_LIB

#include "lprefix.h"

#include <stddef.h>

#include "lua.h"

#include "lcjutf8.h"
#include "llimits.h"


/*
** Encode a Unicode code point as UTF-8 into buf (forward).
** Returns the number of bytes written (1-4), or 0 if invalid code point.
** buf must have space for at least 4 bytes.
*/
int cjU_utf8encode (char *buf, lua_Integer cp) {
  if (cp < 0 || cp > 0x10FFFF) return 0;
  if (cp >= 0xD800 && cp <= 0xDFFF) return 0;  /* reject surrogates */
  if (cp <= 0x7F) {
    buf[0] = (char)cp;
    return 1;
  } else if (cp <= 0x7FF) {
    buf[0] = (char)(0xC0 | (cp >> 6));
    buf[1] = (char)(0x80 | (cp & 0x3F));
    return 2;
  } else if (cp <= 0xFFFF) {
    buf[0] = (char)(0xE0 | (cp >> 12));
    buf[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
    buf[2] = (char)(0x80 | (cp & 0x3F));
    return 3;
  } else {
    buf[0] = (char)(0xF0 | (cp >> 18));
    buf[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    buf[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    buf[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
  }
}


/*
** Determine UTF-8 byte length from lead byte.
** Returns 1-4 for valid lead bytes, 0 for invalid.
*/
int cjU_charlen (unsigned char c0) {
  if ((c0 & 0x80) == 0) return 1;
  if ((c0 & 0xE0) == 0xC0) return 2;
  if ((c0 & 0xF0) == 0xE0) return 3;
  if ((c0 & 0xF8) == 0xF0) return 4;
  return 0;  /* invalid UTF-8 lead byte */
}


/*
** Decode a single UTF-8 character from a string of exactly 'len' bytes.
** Returns the code point, or -1 if the string is not a valid single
** UTF-8 character.
*/
long cjU_decodesingle (const char *s, size_t len) {
  unsigned long cp;
  int nbytes, i;
  if (len == 0) return -1;
  nbytes = cjU_charlen((unsigned char)s[0]);
  if (nbytes == 0 || (size_t)nbytes != len) return -1;
  cp = (unsigned char)s[0];
  if (nbytes == 1) return (long)cp;
  /* mask off the lead byte prefix bits */
  if (nbytes == 2) cp &= 0x1F;
  else if (nbytes == 3) cp &= 0x0F;
  else cp &= 0x07;
  for (i = 1; i < nbytes; i++) {
    unsigned char ci = (unsigned char)s[i];
    if ((ci & 0xC0) != 0x80) return -1;  /* invalid continuation byte */
    cp = (cp << 6) | (ci & 0x3F);
  }
  return (long)cp;
}


/*
** Decode one UTF-8 sequence starting at 's'.
** Returns pointer to the byte after the sequence, or NULL if invalid.
** The 'limits' array rejects overlong encodings.
*/
const char *cjU_decode (const char *s, l_uint32 *val) {
  /* Minimum code points per byte count to reject overlong encodings.
  ** Indices 4-5 cover hypothetical 5-6 byte sequences (not valid UTF-8
  ** but needed for the loop-based decoder to reject them properly). */
  static const l_uint32 limits[] =
        {~(l_uint32)0, 0x80, 0x800, 0x10000u, 0x200000u, 0x4000000u};
  unsigned int c = (unsigned char)s[0];
  l_uint32 res = 0;
  if (c < 0x80)
    res = c;
  else {
    int count = 0;
    for (; c & 0x40; c <<= 1) {
      unsigned int cc = (unsigned char)s[++count];
      if (!iscont_cj(cc))
        return NULL;
      res = (res << 6) | (cc & 0x3F);
    }
    res |= ((l_uint32)(c & 0x7F) << (count * 5));
    if (count > 5 || res > 0x7FFFFFFFu || res < limits[count])
      return NULL;
    s += count;
  }
  /* check for invalid code points: surrogates */
  if (res > MAXUNICODE_CJ || (0xD800u <= res && res <= 0xDFFFu))
    return NULL;
  if (val) *val = res;
  return s + 1;
}


/*
** Count UTF-8 characters in a string of byte length 'len'.
** Returns character count, or -1 if invalid UTF-8.
*/
lua_Integer cjU_charcount (const char *s, size_t len) {
  lua_Integer n = 0;
  size_t pos = 0;
  while (pos < len) {
    const char *next = cjU_decode(s + pos, NULL);
    if (next == NULL) return -1;  /* invalid UTF-8 */
    pos = (size_t)(next - s);
    n++;
  }
  return n;
}


/*
** Compute byte offset for the character at position 'charIdx'.
** Returns byte offset, or -1 if charIdx is out of range.
*/
lua_Integer cjU_byteoffset (const char *s, size_t len,
                            lua_Integer charIdx) {
  lua_Integer ci = 0;
  size_t pos = 0;
  if (charIdx < 0) return -1;
  while (pos < len) {
    if (ci == charIdx) return (lua_Integer)pos;
    {
      const char *next = cjU_decode(s + pos, NULL);
      if (next == NULL) return -1;
      pos = (size_t)(next - s);
    }
    ci++;
  }
  if (ci == charIdx) return (lua_Integer)pos;
  return -1;
}
