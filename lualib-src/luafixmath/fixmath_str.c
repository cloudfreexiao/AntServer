/*  Copyright (C) 2005-2011, Axis Communications AB, LUND, SWEDEN
 *
 *  This file is part of Fixmath.
 *
 *  Fixmath is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  You can use the comments under either the terms of the GNU Lesser General
 *  Public License version 3 as published by the Free Software Foundation,
 *  either version 3 of the License or (at your option) any later version, or
 *  the GNU Free Documentation License version 1.3 or any later version
 *  published by the Free Software Foundation; with no Invariant Sections, no
 *  Front-Cover Texts, and no Back-Cover Texts.
 *  A copy of the license is included in the documentation section entitled
 *  "GNU Free Documentation License".
 *
 *  Fixmath is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License and a copy of the GNU Free Documentation License along
 *  with Fixmath. If not, see <http://www.gnu.org/licenses/>.
 */

/**
 *  @file   fixmath_str.c
 *  @brief  Fixed-point math library - ASCII string conversion functions.
 */

#include <stdlib.h>  /* labs()                   */
#include <errno.h>   /* errno facility, EDOM     */
#include <string.h>  /* memset()                 */
#include <assert.h>  /* assert() macro           */
#include "fixmath.h" /* Exported API with macros */

/*
 * -------------------------------------------------------------
 *  Macros
 * -------------------------------------------------------------
 */

/**
 *  Unsigned fixed-point multiply, i.e. u32 x u32 -> u64.
 */
#define FX_UMUL(x1, x2, frac) \
    ((uint64_t)(x1)*(uint64_t)(x2) >> (frac))

/**
 *  Standard MIN().
 */
#define MIN(a, b) ((a) < (b) ? (a) : (b))

/*
 * -------------------------------------------------------------
 *  Local functions fwd declare
 * -------------------------------------------------------------
 */

static void
fx_round_str(char *str, int end);

static int
fx_utoa32(char *str, uint32_t uval);

static int
fx_utoa64(char *str, uint64_t val);


/*
 * -------------------------------------------------------------
 *  Exported functions
 * -------------------------------------------------------------
 */

/**
 *  Integer to ASCII string conversion.
 */
int
fx_itoa(char *str, int32_t val)
{
    uint32_t uval = (uint32_t)val;

    /* Check for invalid arguments */
    if (!str) {
        errno = EINVAL;
        return -1;
    }

    /* Handle negative values */
    if (val < 0) {
        uval   = (uint32_t)(-val);
        *str++ = '-';
    }

    return fx_utoa32(str, uval) + (val < 0);
}

/**
 *  Fixed-point to ASCII string conversion.
 */
int
fx_xtoa(char *str, fixed_t xval, unsigned frac, unsigned digits)
{
    char *ptr = str;

    /* Handle invalid arguments */
    if (!str || frac > 31) {
        errno = EINVAL;
        return -1;
    }

    /* Handle the zero value */
    if (xval == 0) {
        *ptr++ = '0';
        if (digits) {
            *ptr++ = '.';
            memset(ptr, '0', digits);
        }
        ptr += digits;
    }
    else {
        static const uint8_t etab[32] =
            {0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4,  5,  5,
             5, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10};

        static const uint32_t mtab[11] =
            {1UL, 10UL, 100UL, 1000UL, 10000UL, 100000UL, 1000000UL,
             10000000UL, 100000000UL, 1000000000UL, 0x540BE400UL};

        char     buf[14];
        uint32_t uval;
        uint64_t dec;
        int      e10;
        int      len;
        int      pos;

        /* Handle negative values */
        if (xval < 0) {
            *ptr++ = '-';
        }

        /* Compute the decimal fixed-point number */
        uval = labs(xval);
        e10  = etab[frac];
        dec  = FX_UMUL(uval, mtab[e10], frac);
        if (e10 == 10) {
            dec += (uint64_t)uval << (33 - frac);
        }

        /* Convert decimal integer to string */
        *buf = '0';
        pos  = 1;
        len  = fx_utoa64(&buf[1], dec);
        assert((unsigned)len < sizeof buf - 2);

        /* Round the decimal integer string */
        if ((int)digits < len - 1) {
            fx_round_str(&buf[1], digits + 1);
            pos = *buf == '0';
        }

        /* Compute the base-10 exponent */
        e10  = len + !pos - e10 - 1;

        /* Convert decimal integer to mantissa string */
        *ptr++ = buf[pos];
        if (digits) {
            *ptr++ = '.';
            memset(ptr, '0', digits);
            memcpy(ptr, &buf[pos + 1], MIN((int)digits, len - 1));
            ptr += digits;
        }

        /* Add base-10 exponent string */
        if (e10) {
            *ptr++ = 'e';
            *ptr++ = "+-"[e10 < 0];
            e10 = abs(e10);
            if (e10 < 10) {
                *ptr++ = '0';
                *ptr++ = '0' + e10;
            }
            else {
                *ptr++ = '1';
                *ptr++ = '0';
            }
        }
    }

    /* Add NUL termination */
    *ptr = '\0';

    assert((int)strlen(str) == ptr - str);
    return (int)(ptr - str);
}


/*
 * -------------------------------------------------------------
 *  Local functions
 * -------------------------------------------------------------
 */

static void
fx_round_str(char *str, int end)
{
    unsigned carry = str[end] >= '5';

    while (carry && --end >= -1) {
        int digit = str[end] + carry - '0';
        carry  = digit > 9;
        digit &= carry - 1;
        str[end] = '0' + digit;
    }
}

static int
fx_utoa32(char *str, uint32_t uval)
{
    int pos  = 0;
    int i, j;

    /* Handle the zero value */
    if (uval == 0) {
        *str++ = '0';
        *str++ = '\0';
        return 1;
    }

    /* Compute the decimal digits */
    for (pos = 0; uval; pos++) {
        uint32_t qt, rm;

        /* Compute the quotient and the reminder */
        qt = (uint32_t)FX_UMUL(uval, 0xcccccccdUL, 35);
        rm = uval - (qt << 3) - (qt << 1);
        assert(qt == uval / 10 && rm == uval % 10);

        /* Update digit string and remaining value */
        str[pos]   = (char)('0' + rm);
        uval       = qt;
    }

    /* Reverse the string */
    for (i = 0, j = pos - 1; i < j; i++, j--) {
        int tmp = str[i];
        str[i]  = str[j];
        str[j]  = tmp;
    }

    /* Add NUL termination */
    str[pos] = '\0';

    return pos;
}

static int
fx_utoa64(char *str, uint64_t uval)
{
    uint32_t lo = (uint32_t)uval;
    uint32_t hi = (uint32_t)(uval >> 32);
    int      rm = 0;
    int      len;

    if (hi) {
        rm = (int)(uval % 10);
        lo = (uint32_t)(uval / 10);
    }

    len = fx_utoa32(str, lo);

    if (hi) {
        str[len++] = '0' + rm;
        str[len  ] = '\0';
    }

    return len;
}
