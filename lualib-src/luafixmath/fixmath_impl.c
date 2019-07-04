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
 *  @file   fixmath_impl.c
 *  @brief  Fixed-point math library - non-macro implementations.
 */

#define FIXMATH_MACRO_H
#include "fixmath.h" /* Exported API without macros   */

/*
 * -------------------------------------------------------------
 *  Lookup tables
 * -------------------------------------------------------------
 */

/**
 *  Fixed-point to floating-point conversion factor table.
 */
const float fx_xtof_tab[32] =
    {1.0f,             1.0f/(1UL <<  1), 1.0f/(1UL <<  2), 1.0f/(1UL <<  3),
     1.0f/(1UL <<  4), 1.0f/(1UL <<  5), 1.0f/(1UL <<  6), 1.0f/(1UL <<  7),
     1.0f/(1UL <<  8), 1.0f/(1UL <<  9), 1.0f/(1UL << 10), 1.0f/(1UL << 11),
     1.0f/(1UL << 12), 1.0f/(1UL << 13), 1.0f/(1UL << 14), 1.0f/(1UL << 15),
     1.0f/(1UL << 16), 1.0f/(1UL << 17), 1.0f/(1UL << 18), 1.0f/(1UL << 19),
     1.0f/(1UL << 20), 1.0f/(1UL << 21), 1.0f/(1UL << 22), 1.0f/(1UL << 23),
     1.0f/(1UL << 24), 1.0f/(1UL << 25), 1.0f/(1UL << 26), 1.0f/(1UL << 27),
     1.0f/(1UL << 28), 1.0f/(1UL << 29), 1.0f/(1UL << 30), 1.0f/(1UL << 31)};

/**
 *  Fixed-point to double-precision floating-point conversion factor table.
 */
const double fx_xtod_tab[32] =
    {1.0,             1.0/(1UL <<  1), 1.0/(1UL <<  2), 1.0/(1UL <<  3),
     1.0/(1UL <<  4), 1.0/(1UL <<  5), 1.0/(1UL <<  6), 1.0/(1UL <<  7),
     1.0/(1UL <<  8), 1.0/(1UL <<  9), 1.0/(1UL << 10), 1.0/(1UL << 11),
     1.0/(1UL << 12), 1.0/(1UL << 13), 1.0/(1UL << 14), 1.0/(1UL << 15),
     1.0/(1UL << 16), 1.0/(1UL << 17), 1.0/(1UL << 18), 1.0/(1UL << 19),
     1.0/(1UL << 20), 1.0/(1UL << 21), 1.0/(1UL << 22), 1.0/(1UL << 23),
     1.0/(1UL << 24), 1.0/(1UL << 25), 1.0/(1UL << 26), 1.0/(1UL << 27),
     1.0/(1UL << 28), 1.0/(1UL << 29), 1.0/(1UL << 30), 1.0/(1UL << 31)};

/*
 * -------------------------------------------------------------
 *  Bit manipulation functions
 * -------------------------------------------------------------
 */

/**
 *  Count the number of leading zeros in a 32-bit word.
 *  Note that fx_clz(0) is undefined.
 */
#ifndef fx_clz
int
fx_clz(uint32_t word)
{
    int ret;
    FX_IMPL_CLZ(ret, word);
    return ret;
}
#endif /* !fx_clz */

/**
 *  Count the number of trailing zeros in a 32-bit word.
 *  Note that fx_ctz(0) is undefined.
 */
#ifndef fx_ctz
int
fx_ctz(uint32_t word)
{
    int ret;
    FX_IMPL_CTZ(ret, word);
    return ret;
}
#endif /* !fx_ctz */

/**
 *  Count the number of bits set in a 32-bit word.
 */
#ifndef fx_bitcount
int
fx_bitcount(uint32_t word)
{
    int ret;
    FX_IMPL_BITCOUNT(ret, word);
    return ret;
}
#endif /* !fx_bitcount */

/*
 * -------------------------------------------------------------
 *  Fixed-point arithmetic and conversions
 * -------------------------------------------------------------
 */

/**
 *  Integer to fixed-point conversion.
 */
fixed_t
fx_itox(int32_t ival, unsigned frac)
{
    return FX_IMPL_ITOX(ival, frac);
}

/**
 *  Single precision float to fixed-point conversion.
 */
fixed_t
fx_ftox(float fval, unsigned frac)
{
    return FX_IMPL_FTOX(fval, frac);
}

/**
 *  Double precision float to fixed-point conversion.
 */
fixed_t
fx_dtox(double dval, unsigned frac)
{
    return FX_IMPL_DTOX(dval, frac);
}

/**
 *  Fixed-point format conversion.
 */
fixed_t
fx_xtox(fixed_t xval, unsigned f1, unsigned f2)
{
    return FX_IMPL_XTOX(xval, f1, f2);
}

/**
 *  Fixed-point to integer conversion.
 *  This is equal to fx_floorx().
 */
int32_t
fx_xtoi(fixed_t xval, unsigned frac)
{
    return FX_IMPL_XTOI(xval, frac);
}

/**
 *  Fixed-point to single precision float conversion.
 */
float
fx_xtof(fixed_t xval, unsigned frac)
{
    return FX_IMPL_XTOF(xval, frac);
}

/**
 *  Fixed-point to double precision float conversion.
 */
double
fx_xtod(fixed_t xval, unsigned frac)
{
    return FX_IMPL_XTOD(xval, frac);
}

/**
 *  Round a fixed-point value to the nearest integer.
 */
int32_t
fx_roundx(fixed_t xval, unsigned frac)
{
    return FX_IMPL_ROUNDX(xval, frac);
}

/**
 *  Round a fixed-point number up to the nearest integer.
 */
int32_t
fx_ceilx(fixed_t xval, unsigned frac)
{
    return FX_IMPL_CEILX(xval, frac);
}

/**
 *  Round a fixed-point number down to the nearest integer.
 */
int32_t
fx_floorx(fixed_t xval, unsigned frac)
{
    return FX_IMPL_FLOORX(xval, frac);
}

/**
 *  Fixed-point addition.
 */
fixed_t
fx_addx(fixed_t x1, fixed_t x2)
{
    return FX_IMPL_ADDX(x1, x2);
}

/**
 *  Fixed-point subtraction.
 */
fixed_t
fx_subx(fixed_t x1, fixed_t x2)
{
    return FX_IMPL_SUBX(x1, x2);
}

/**
 *  Fixed-point multiply.
 */
fixed_t
fx_mulx(fixed_t x1, fixed_t x2, unsigned frac)
{
    return FX_IMPL_MULX(x1, x2, frac);
}

/**
 *  Fixed-point divide.
 */
fixed_t
fx_divx(fixed_t x1, fixed_t x2, unsigned frac)
{
    return FX_IMPL_DIVX(x1, x2, frac);
}

/**
 *  Fixed-point divide by reciprocal multiplication.
 */
fixed_t
fx_rdivx(fixed_t xval, const fx_rdiv_t *rdiv)
{
    return FX_IMPL_RDIVX(xval, rdiv);
}

