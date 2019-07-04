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
 *  @file   fixmath_arch.h
 *  @brief  Fixed-point math library - platform-specific definitions.
 */

#ifndef FIXMATH_ARCH_H
#define FIXMATH_ARCH_H

#ifndef FIXMATH_H
#error "Do not include this file directly - use fixmath.h instead!"
#endif /* !FIXMATH_H */

/*
 *  Set GCC-specific built-in functions.
 */
#ifdef __GNUC__
#if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4)
#define fx_clz       __builtin_clz
#define fx_ctz       __builtin_ctz
#define fx_bitcount  __builtin_popcount
#endif /* __GNUC__ > 3 ... */
#endif /* __GNUC__ */

#endif /* FIXMATH_ARCH_H */
