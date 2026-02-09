/*
** $Id: lcjutf8.h $
** Shared UTF-8 utility functions for Cangjie runtime
** See Copyright Notice in lua.h
*/

#ifndef lcjutf8_h
#define lcjutf8_h


#include "llimits.h"
#include "lua.h"


#define MAXUNICODE_CJ	0x10FFFFu
#define iscont_cj(c)	(((c) & 0xC0) == 0x80)


/*
** Encode a Unicode code point as UTF-8 into buf (forward).
** Returns the number of bytes written (1-4), or 0 if invalid code point.
** buf must have space for at least 4 bytes.
*/
LUAI_FUNC int cjU_utf8encode (char *buf, lua_Integer cp);


/*
** Determine UTF-8 byte length from lead byte.
** Returns 1-4 for valid lead bytes, 0 for invalid.
*/
LUAI_FUNC int cjU_charlen (unsigned char c0);


/*
** Decode a single UTF-8 character from a string of exactly 'len' bytes.
** Returns the code point, or -1 if the string is not a valid single
** UTF-8 character.
*/
LUAI_FUNC long cjU_decodesingle (const char *s, size_t len);


/*
** Decode one UTF-8 sequence starting at 's'.
** Returns pointer to the byte after the sequence, or NULL if invalid.
** If 'val' is not NULL, stores the decoded code point.
*/
LUAI_FUNC const char *cjU_decode (const char *s, l_uint32 *val);


/*
** Count UTF-8 characters in a string of byte length 'len'.
** Returns character count, or -1 if invalid UTF-8.
*/
LUAI_FUNC lua_Integer cjU_charcount (const char *s, size_t len);


/*
** Compute byte offset of the char at character index 'charIdx'
** in string 's' of byte length 'len'.
** Returns byte offset, or -1 if charIdx is out of range.
*/
LUAI_FUNC lua_Integer cjU_byteoffset (const char *s, size_t len,
                                      lua_Integer charIdx);


#endif
