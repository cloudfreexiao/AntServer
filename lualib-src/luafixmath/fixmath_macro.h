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
 *  @file   fixmath_macro.h
 *  @brief  Fixed-point math library - function-like macros.
 */

#ifndef FIXMATH_MACRO_H
#define FIXMATH_MACRO_H

#ifndef FIXMATH_H
#error "Do not include this file directly - use fixmath.h instead!"
#endif /* !FIXMATH_H */

#include <stdint.h>       /* Fixed-size integers           */
#include "fixmath_arch.h" /* Platform-specific definitions */
#include "fixmath_impl.h" /* Internal implementations      */

/*
 * -------------------------------------------------------------
 *  GCC-specific function-like macros
 * -------------------------------------------------------------
 */

#ifdef __GNUC__
#ifndef fx_clz
#define fx_clz(word)        \
(__extension__ ({           \
    int r__;                \
    FX_IMPL_CLZ(r__, word); \
    r__;                    \
}))
#endif /* !fx_clz */

#ifndef fx_ctz
#define fx_ctz(word)        \
(__extension__ ({           \
    int r__;                \
    FX_IMPL_CTZ(r__, word); \
    r__;                    \
}))
#endif /* !fx_ctz */

#ifndef fx_bitcount
#define fx_bitcount(word)         \
(__extension__ ({                 \
    int r2__;                     \
    FX_IMPL_BITCOUNT(r2__, word); \
    r2__;                         \
}))
#endif /* !fx_bitcount */

#define fx_divx(x1, x2, frac)       \
(__extension__ ({                   \
    fixed_t x1__ = x1;              \
    fixed_t x2__ = x2;              \
    FX_IMPL_DIVX(x1__, x2__, frac); \
}))

#endif /* __GNUC__ */

/*
 * -------------------------------------------------------------
 *  Generic function-like macros
 * -------------------------------------------------------------
 */

#define fx_itox(ival, frac) \
    FX_IMPL_ITOX(ival, frac)

#define fx_ftox(fval, frac) \
    FX_IMPL_FTOX(fval, frac)

#define fx_dtox(fval, frac) \
    FX_IMPL_DTOX(fval, frac)

#define fx_xtox(xval, f1, f2) \
    FX_IMPL_XTOX(xval, f1, f2)

#define fx_xtoi(xval, frac) \
    FX_IMPL_XTOI(xval, frac)

#define fx_xtof(xval, frac) \
    FX_IMPL_XTOF(xval, frac)

#define fx_xtod(xval, frac) \
    FX_IMPL_XTOD(xval, frac)

#define fx_roundx(xval, frac) \
    FX_IMPL_ROUNDX(xval, frac)

#define fx_floorx(xval, frac) \
    FX_IMPL_FLOORX(xval, frac)

#define fx_ceilx(xval, frac) \
    FX_IMPL_CEILX(xval, frac)

#define fx_addx(x1, x2) \
    FX_IMPL_ADDX(x1, x2)

#define fx_subx(x1, x2) \
    FX_IMPL_SUBX(x1, x2)

#define fx_mulx(x1, x2, frac) \
    FX_IMPL_MULX(x1, x2, frac)

#define fx_rdivx(xval, rdiv) \
    FX_IMPL_RDIVX(xval, rdiv)

#endif /* FIXMATH_MACRO_H */
