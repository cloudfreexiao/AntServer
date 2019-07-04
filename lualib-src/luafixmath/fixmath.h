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
 *  @file   fixmath.h
 *  @brief  Fixed-point math library.
 */

/**
 *  @mainpage Fixmath User's Manual
 *
 *  @section Introduction
 *  Fixmath is a library of fixed-point math operations and functions.
 *  It is designed to be portable, flexible and fast on platforms without
 *  floating-point support:
 *
 *    - The library is written in ANSI-C (C89).
 *    - The library is thread-safe.
 *    - There is no hard-coded fixed-point format. The user can set the
 *      binary point freely on a per-operation basis.
 *    - Simple arithmetic operations are inlined.
 *    - Performance is favoured over last-bit precision.
 *
 *  @section format The Fixed-Point Representation
 *  All fixed-point numbers are represented as 32-bit signed integers.
 *  Since the numbers are signed, we think of the most significant bit as
 *  the @e sign @e bit, even though it is not a true sign bit in two's
 *  complement representation. For a fixed-point number, we also have a
 *  @e binary @e point, separating the integer bits from the fraction bits.
 *  If we have @e n integer bits and @e m fraction bits, the format is
 *
 *    <div style="text-align: center"><em>x = s n.m,</em></div>
 *
 *  where @e s is the sign bit, and we have the constraint @e n + @e m = 31.
 *  In this library the fixed-point formats are often written as @e Qn.m or
 *  @e Q.m. The binary point is implicit in the sense that it is not stored
 *  in the number itself. It is up to the user to keep track of the binary
 *  points in different computations.
 *
 *  For clarity, there is a fixed-point type #fixed_t that is always a
 *  32-bit signed integer. Other integers may also be used, but they will
 *  be converted to 32-bits before the operation. There is also a
 *  type for representing reciprocal values, #fx_rdiv_t, see the section
 *  on @ref use_rdiv "reciprocal value division".
 *
 *  @section name Naming Conventions
 *  All functions are prefixed with @c fx_. Otherwise, the names follow
 *  the naming convention of the math library in C99 as much as possible.
 *  This means that functions are named as their floating-point
 *  equivalents, with a suffix @c x for fixed-point.
 *
 *  A fixed-point number is generally specified as a representation
 *  @c xval, and the number of fraction bits (binary point), @c frac.
 *
 *  @section Precision
 *  The error bound is measured in @e ulp, <em>unit in the last place</em>,
 *  which is the smallest representable value. The error for the conversions
 *  and the arithmetic operations is within 0.5 ulp. For the remaining
 *  math functions the error is higher. The error bounds for these functions
 *  are determined empirically using random tests.
 *
 *  Forcing all math functions to be correct to 0.5 ulp would result a
 *  severe performance hit. In normal use cases it is generally acceptable
 *  to loose one or two bits of precision if this makes the operation
 *  several times faster. If a higher precision is needed, choose a
 *  fixed-point format with more fraction bits.
 *
 *  @section nan Special Numbers
 *  There are no special number such as @c NaN and @c Inf in the IEEE-754
 *  floating-point standard. For any fixed-point format, all possible
 *  bit patterns in the 32-bit representation are valid numbers.
 *
 *  @section sat Saturating Arithmetics
 *  There is currently no support for saturating arithmetics. If the computed
 *  result is outside the representable range, it will wrap around.
 *
 *  @section fallback Integer Operations
 *  Some fixed-point operations are independent of the number of fraction
 *  bits. This means that they are the same as in the special case of
 *  zero fraction bits, i.e. integers. Since the fixed-point numbers are
 *  represented as integers, the normal integer operations in C may be
 *  used in these cases. This applies to the following:
 *
 *    - @e Zero: integral @c 0 is always @c 0 in all fixed-point formats.
 *    - @e Tests: @c ==, @c !=, @c &lt;, @c &lt;= @c &gt; and @c &gt;=
 *                can be used if both operands have the same binary point.
 *    - @e Addition: @c +, @c +=, @c -, @c -= can be used if both operands
 *                   have the same binary point.
 *    - @e Sign: unary @c + and @c - always work.
 *
 *  @section error Error Handling
 *  No checks or error handling is performed by the conversions and the
 *  arithmetic operations. In most operations an error condition will just
 *  produce an erroneous result, but fx_divx() and fx_rdivx() may trigger
 *  divide-by-zero and NULL pointer reference errors, respectively.
 *
 *  The math functions check the arguments and sets the @c errno variable
 *  on errors, similar to what the corresponding functions in the C math
 *  library does.
 *
 *  For completeness, fx_addx() and fx_subx() are also provided for
 *  addition and subtraction. They are equal to the integer operations
 *  @c + and @c -, respectively.
 *
 *  @section Performance
 *  @subsection perf_fmt Fixed-Point Formats
 *  For optimal performance, the @c frac arguments should be constants
 *  in all conversions and arithmetic operations.
 *
 *  @subsection Constants
 *  Using fx_ftox() and fx_dtox() with constant arguments will generate
 *  a fixed-point compile-time constant. No run-time floating-point
 *  operations will be performed.
 *
 *  @subsection prof_math Math Functions
 *  Use the base-2 logarithm and exponential functions instead of the
 *  natural or base-10 versions. It is also more efficient to
 *  compute 2<sup>ylog2(x)</sup> instead of using fx_powx(). This is
 *  because of extra overhead imposed by the normalization and the checks
 *  that must be done in order to minimize the loss of precision in
 *  the intermediate results. The user who knows the data range and
 *  fractional format can cut corners here.
 *
 *  @subsection Benchmarks
 *  There is a benchmark application in the @c prof directory. It runs
 *  performance tests for all API functions and some floating-point
 *  equivalents. The result is of course platform-dependent, but for
 *  CPUs without floating-point support in hardware, the fixed-point
 *  arithmetic operations are around 10 times faster than the
 *  corresponding software-emulated floating-point operations.
    For many of the math functions, the speed-up is around 100 times.
 *
 *  @section Implementation
 *  All operations are implemented as functions. This makes it possible to
 *  take the address of the function for all operations. However, some
 *  functions @e may also be implemented as macros, and they @e may evaluate
 *  the @c frac argument twice. For this reason it is an error to call a
 *  function with a @c frac argument that has side effects, e.g. @c frac++.
 *  The conversion operations fx_ftox() and fx_dtox() @e may also evaluate
 *  floating-point argument twice.
 *
 *  @section Portability
 *  The library is written in ANSI-C, but it requires the C99 @c stdint.h
 *  header. The correctness tests require also the C99 @c stdbool.h header
 *  and the @e Check library @ref ref "[1]". The benchmark application,
 *  which is not built by default, requires the POSIX sigaction() and
 *  setitimer() facilities.
 *
 *  @section Contents
 *  The library contain the following functionality:
 *
 *  - @ref fx_clz     "Word operations:"
 *                     Count-leading-zeroes, bitcount etc.
 *  - @ref fx_itox    "Fixed-point conversions:"
 *                     Convert between fixed-point, integer
 *                     and floating-point numbers.
 *  - @ref fx_mulx    "Fixed-point arithmetics:"
 *                     Multiply and divide for fixed-point numbers.
 *  - @ref fx_invx    "Fixed-point algebraic functions:"
 *                     Inverse, square root and inverse
 *                     square root functions.
 *  - @ref fx_expx    "Fixed-point transcendental functions:"
 *                     Exponential, logarithm, power and
 *                     trigonometric functions.
 *
 *  @section Usage
 *  @subsection use_inc Including and Linking
 *  To use the fixmath library, include the header
 *  <code>&lt;fixmath/fixmath.h&gt;</code>, and link the application
 *  with @c -lfixmath, or use @c pkg-config to determine the compiler and
 *  linker flags.
 *
 *  @subsection use_basic Basic Example
 *  Assume that we want to compute the 2-norm of a data vector, i.e.
 *
 *    @f[ \| \mathbf{x} \| = \sqrt{\sum_k{x_k^2}}. @f]
 *
 *  All data points are in the range [0-1]. The floating-point
 *  implementation is shown below.
 *
 *  @code
 *    float norm2(float *buf, int len)
 *    {
 *        float sum = 0.0f;
 *        int   k;
 *        for (k = 0; k < len; k++) {
 *            float val = buf[k];
 *            sum += val*val;
 *        }
 *        return sqrtf(sum);
 *    }
 *  @endcode
 *
 *  When converting the operation to fixed-point, we need to choose a
 *  fixed-point format, i.e. the number of integer and fraction bits.
 *  It is of course dependent on the range of the data set. In this
 *  example, we use 16 bits for the fraction part, i.e. Q.16.
 *
 *  @code
 *    fixed_t norm2(fixed_t *buf, int len)
 *    {
 *        fixed_t sum = 0;
 *        int     k;
 *        for (k = 0; k < len; k++) {
 *            fixed_t val = buf[k];
 *            sum += fx_mulx(val, val, 16);
 *        }
 *        return fx_sqrtx(sum, 16);
 *    }
 *  @endcode
 *
 *  @subsection use_frac Advanced Use
 *  In the previous example, the data array was given in fixed-point
 *  format. Now we want to compute the same result on the original
 *  data that is stored as 8-bit unsigned integers. Since the range of
 *  the input data now is in the range [0-255], we want to normalize
 *  them by dividing with 255.
 *
 *  The implementation below computes the sum of squares as integers.
 *  The normalization is performed at by converting the numerator
 *  and the denominator to the fixed-point format before computing the
 *  normalizing division. Unfortunately, the converted operands are too
 *  large for the Q.16 fixed-point format, and will overflow.
 *
 *  @code
 *    fixed_t norm2(uint8_t *buf, int len)
 *    {
 *        fixed_t num;
 *        fixed_t den;
 *        int     sum = 0;
 *        int     k;
 *        for (k = 0; k < len; k++) {
 *            int val = buf[k];
 *            sum += val*val;
 *        }
 *        den = fx_itox(255*255, 16);
 *        num = fx_itox(sum, 16);
 *        num = fx_divx(num, den, 16);
 *        return fx_sqrtx(num, 16);
 *    }
 *  @endcode
 *
 *  We can solve the problem by performing the fixed-point division
 *  and conversion @e simultaneously. The number of fraction bits of the
 *  division result is @e f<sub>x</sub> - @e f<sub>y</sub> + @c frac,
 *  where @e f<sub>1</sub> and @e f<sub>2</sub> are the number of
 *  fraction bits for the first and second operands, respectively.
 *  In our case, both @e f<sub>1</sub> and @e f<sub>2</sub> are zero.
 *  If we use 16 bits as the @c frac argument, we will get 16 fraction
 *  bits for the result. The complete implementation is shown below.
 *
 *  @code
 *    fixed_t norm2(uint8_t *buf, int len)
 *    {
 *        fixed_t tmp;
 *        int     sum = 0;
 *        int     k;
 *        for (k = 0; k < len; k++) {
 *            int val = buf[k];
 *            sum += val*val;
 *        }
 *        tmp = fx_divx(sum, 255*255, 16);
 *        return fx_sqrtx(tmp, 16);
 *    }
 *  @endcode
 *
 *  @subsection use_rdiv Reciprocal Value Division
 *  We want to normalize the 8-bit data to the range [0-1] and store
 *  it in a Q.16 fixed-point format. To do this, we normalize and convert
 *  the data in one step, as shown in the next code example.
 *
 *  @code
 *    void byte2fix(fixed_t *fix, const uint8_t *byte, int len)
 *    {
 *        int k;
 *        for (k = 0; k < len; k++) {
 *            fix[k] = fx_divx(byte[k], 255, 16);
 *        }
 *    }
 *  @endcode
 *
 *  When benchmarking the above implementation, it turns out to be quite
 *  slow. This caused by the per-data point division in the inner loop.
 *  In a floating-point implementation one would multiply each data point
 *  by the reciprocal value 1/255 instead of dividing by 255. When using
 *  fixed-point arithmetics, the reciprocal value may very well be outside
 *  the representable range. For this reason there is a special data type
 *  for storing reciprocal values, fx_rdiv_t. The functions fx_invx() and
 *  fx_isqrtx() both accept an optional fx_rdiv_t argument that can be
 *  used for performing multiple division by the same value. In the code
 *  below we compute the reciprocal value outside the loop, and then use
 *  the fx_rdivx() operation, which is really a multiplication, instead of
 *  the fx_div() division operation.
 *
 *  @code
 *    void byte2fix(fixed_t *fix, const uint8_t *byte, int len)
 *    {
 *        fx_rdiv_t rdiv;
 *        int       k;
 *
 *        fx_invx(255, 16, &rdiv);
 *        for (k = 0; k < len; k++) {
 *            fix[k] = fx_rdivx(byte[k], &rdiv);
 *        }
 *    }
 *  @endcode
 *
 *  @section ref References
 *  [1] @e Check, @c http://check.sourceforge.net
 */

#ifndef FIXMATH_H
#define FIXMATH_H

#include <stdint.h>         /* Fixed-size integers           */
#include <stdio.h>
#include "fixmath_arch.h"   /* Platform-specific definitions */
#include "fixmath_export.h" /* Win32 DLL function visibility */

#ifdef __cplusplus
extern "C" {
#endif

/*
 * -------------------------------------------------------------
 *  Type definitions
 * -------------------------------------------------------------
 */

/**
 *  The fixed-point data type.
 */

// You can change the FIX_MATH_FRACTIONAL_BIT_COUNT to 16 - 1 before compiling.
#ifndef FIX_MATH_FRACTIONAL_BIT_COUNT
#define FIX_MATH_FRACTIONAL_BIT_COUNT 8
#endif

#define MAX_FRACTIONAL_BIT_COUNT 16

#define FIX_MATH_FRACTIONAL_OFFSET (MAX_FRACTIONAL_BIT_COUNT - FIX_MATH_FRACTIONAL_BIT_COUNT)

typedef int32_t fixed_t;

static const fixed_t fix_maximum  = 0x7FFFFFFF; /*!< the maximum value of fixed_t */
static const fixed_t fix_minimum  = 0x80000000; /*!< the minimum value of fixed_t */

static const fixed_t fix_one = 1 << FIX_MATH_FRACTIONAL_BIT_COUNT;

static const fixed_t fix_pi  = 0x0003243F >> FIX_MATH_FRACTIONAL_OFFSET ;     /*!< fixed_t value of pi */
static const fixed_t fix_pi_div_2 = 0x00019220 >> FIX_MATH_FRACTIONAL_OFFSET ; /*!< fixed_t value of pi/2 */
static const fixed_t PI_DIV_4 = 0x0000C910 >> FIX_MATH_FRACTIONAL_OFFSET ;             /*!< fixed_t value of PI/4 */
static const fixed_t THREE_PI_DIV_4 = 0x00025B30 >> FIX_MATH_FRACTIONAL_OFFSET ;       /*!< fixed_t value of 3PI/4 */
static const fixed_t fix_rad_to_deg_mult = 0x00394BB8 >> FIX_MATH_FRACTIONAL_OFFSET ;
static const fixed_t fix_180_degree = 0x00B40000 >> FIX_MATH_FRACTIONAL_OFFSET ;
static const fixed_t fix_atan2_factor_a = 0x00003241 >> FIX_MATH_FRACTIONAL_OFFSET ;
static const fixed_t fix_atan2_factor_b = 0x0000FB51 >> FIX_MATH_FRACTIONAL_OFFSET ;



/**
 *  The fixed-point reciprocal division multiplier.
 *  This is actually a floating-point number with a 32-bit mantissa.
 */
typedef struct {
    int32_t mant;
    int     expn;
} fx_rdiv_t;


/*
 * -------------------------------------------------------------
 *  Bit manipulation functions
 * -------------------------------------------------------------
 */

/**
 *  Count the number of leading zeros in a 32-bit word.
 *  Note that fx_clz(0) is undefined.
 *
 *  @param   word  The source word.
 *  @return  The number of leading zeros.
 */
#ifndef fx_clz
FX_EXPORT int
fx_clz(uint32_t word);
#endif /* !fx_clz */

/**
 *  Count the number of trailing zeros in a 32-bit word.
 *  Note that fx_ctz(0) is undefined.
 *
 *  @param   word  The source word.
 *  @return  The number of trailing zeros.
 */
#ifndef fx_ctz
FX_EXPORT int
fx_ctz(uint32_t word);
#endif /* !fx_ctz */

/**
 *  Count the number of bits set in a 32-bit word.
 *  @param   word  The source word.
 *  @return  The number of bits set.
 */
#ifndef fx_bitcount
FX_EXPORT int
fx_bitcount(uint32_t word);
#endif /* !fx_bitcount */


/*
 * -------------------------------------------------------------
 *  Fixed-point arithmetic and conversions
 * -------------------------------------------------------------
 */

/**
 *  Integer to fixed-point conversion.
 *
 *  @param ival  Integer value.
 *  @param frac  The number of fixed-point fractional bits desired.
 *  @return      The converted fixed-point number.
 */
FX_EXPORT fixed_t
fx_itox(int32_t ival, unsigned frac);

/**
 *  Single precision float to fixed-point conversion.
 *  The error is within 1 ulp.
 *
 *  @param fval  Single-precision float value.
 *  @param frac  The number of fixed-point fractional bits desired.
 *  @return      The converted fixed-point number.
 *  @note        The @e fval argument may be evaluated twice.
 */
FX_EXPORT fixed_t
fx_ftox(float fval, unsigned frac);

/**
 *  Double precision float to fixed-point conversion.
 *  The error is within 1/2 ulp.
 *
 *  @param dval  Double-precision float value.
 *  @param frac  The number of fixed-point fractional bits desired.
 *  @return      The converted fixed-point number.
 *  @note        The @e dval argument may be evaluated twice.
 */
FX_EXPORT fixed_t
fx_dtox(double dval, unsigned frac);

/**
 *  Fixed-point format conversion. The error is within 1/2 ulp.
 *
 *  @param xval  Fixed-point value with @e frac1 fractional bits.
 *  @param frac1 The number of fractional in original representation.
 *  @param frac2 The number of fractional bits resired.
 *  @return      A fixed-point value with @e frac2 fractional bits.
 *  @note        The @e frac1 and @e frac2 arguments may be  evaluated twice.
 */
FX_EXPORT fixed_t
fx_xtox(fixed_t xval, unsigned frac1, unsigned frac2);

/**
 *  Fixed-point to integer conversion.
 *
 *  This is equal to fx_floorx().
 *  @param xval  Fixed-point value.
 *  @param frac  The number of fractional bits.
 *  @return      The integer part of @e xval, rounded towards -infinity.
 */
FX_EXPORT int32_t
fx_xtoi(fixed_t xval, unsigned frac);

/**
 *  Fixed-point to single precision float conversion.
 *  The error is within 1/2 ulp.
 *
 *  @param xval  Fixed-point value.
 *  @param frac  The number of fractional bits.
 *  @return      The converted floating-point number.
 */
FX_EXPORT float
fx_xtof(fixed_t xval, unsigned frac);

/**
 *  Fixed-point to double precision float conversion.
 *  The error is within 1/2 ulp.
 *
 *  @param xval  Fixed-point value.
 *  @param frac  The number of fractional bits.
 *  @return      The converted double-precision floating-point number.
 */
FX_EXPORT double
fx_xtod(fixed_t xval, unsigned frac);

/**
 *  Round a fixed-point number to the nearest integer.
 *
 *  @param xval  Fixed-point value.
 *  @param frac  The number of fractional bits.
 *  @return      The value rounded to the nearest integer.
 *  @note        The @e frac argument may be evaluated twice.
 */
FX_EXPORT int32_t
fx_roundx(fixed_t xval, unsigned frac);

/**
 *  Round a fixed-point number up to the nearest integer.
 *
 *  @param xval  Fixed-point value.
 *  @param frac  The number of fractional bits in xval.
 *  @return      The value rounded to up to the nearest integer.
 *               The return value is int32_t and therefore
 *               has zero fractional bits.
 *  @note        The @e frac argument may evaluated twice.
 */
FX_EXPORT int32_t
fx_ceilx(fixed_t xval, unsigned frac);

/**
 *  Round a fixed-point number down to the nearest integer.
 *
 *  @param xval  Fixed-point value.
 *  @param frac  The number of fractional bits in xval.
 *  @return      The value rounded down to the nearest integer.
 *               The return value is int32_t and therefore
 *               has zero fractional bits.
 */
FX_EXPORT int32_t
fx_floorx(fixed_t xval, unsigned frac);

/**
 *  Fixed-point addition.
 *  The terms must have the same number of fractional bits.
 *  This operation expands to a regular add operation.
 *
 *  @param x1    First fixed-point term.
 *  @param x2    Second fixed-point term.
 *  @return      The sum with the same number of
 *               fractional bits as the terms.
 */
FX_EXPORT fixed_t
fx_addx(fixed_t x1, fixed_t x2);

/**
 *  Fixed-point subtraction.
 *  The terms must have the same number of fractional bits.
 *  This operation expands to a regular add operation.
 *
 *  @param x1    First fixed-point term.
 *  @param x2    Second fixed-point term.
 *  @return      The difference with the same number of
 *               fractional bits as the terms.
 */
FX_EXPORT fixed_t
fx_subx(fixed_t x1, fixed_t x2);

/**
 *  Fixed-point multiply. The error is within 1/2 ulp.
 *  The number of fraction bits in the result is @e f1 + @e f2 - @e frac,
 *  where @e f1 and @e f2 are the number of fraction bits of @e x1 and
 *  @e x2, respectively. Thus, if both @e f1 and @e f2 are equal to @e frac,
 *  the number of fraction bits in the result will also be @e frac.
 *
 *  @param x1    First fixed-point factor.
 *  @param x2    Second fixed-point factor.
 *  @param frac  Number of fraction bits, see explaination above.
 *  @return      The multiplied result.
 *  @note        The @e frac argument may be evaluated twice.
 */
FX_EXPORT fixed_t
fx_mulx(fixed_t x1, fixed_t x2, unsigned frac);

/**
 *  Fixed-point divide. The error is within 1/2 ulp.
 *  The number of fraction bits in the result is @e f1 - @e f2 + @e frac,
 *  where @e f1 and @e f2 are the number of fraction bits of @e x1 and
 *  @e x2, respectively. Thus, if both @e f1 and @e f2 are equal to @e frac,
 *  the number of fraction bits in the result will also be @e frac.
 *
 *  @param x1    Fixed-point numerator.
 *  @param x2    Fixed-point denominator.
 *  @param frac  Number of fraction bits, see explaination above.
 *  @return      The quotient result.
 */
FX_EXPORT fixed_t
fx_divx(fixed_t x1, fixed_t x2, unsigned frac);

/**
 *  Fixed-point divide by reciprocal multiplication.
 *
 *  @param xval  Fixed-point numerator.
 *  @param rdiv  A reciprocal division factor, obtained from
 *               either fx_invx() or fx_isqrtx().
 *  @return      The quotient, with the same number of
 *               fractional bits as the numerator.
 *  @note        The @e rdiv argument may be evaluated twice.
 */
FX_EXPORT fixed_t
fx_rdivx(fixed_t xval, const fx_rdiv_t *rdiv);


/*
 * -------------------------------------------------------------
 *  String conversion functions
 * -------------------------------------------------------------
 */

/**
 *  Integer to ASCII string conversion.
 *
 *  @param  str  The string buffer to use. It must be long enough to hold
 *               the string value, i.e. at least 12 bytes in the worst case.
 *  @param  val  The integral number to convert.
 *  @return      The length of the converted string. If @e str is
 *               NULL, a negative value is returned and @e errno is
 *               set to EINVAL.
 */
FX_EXPORT int
fx_itoa(char *str, int32_t val);

/**
 *  Fixed-point to ASCII string conversion. The number is converted to
 *                 the format [-]d.ddd[e+00]. If the precision (@e digits)
 *                 is zero, no decimal point appears. If the exponent
 *                 is zero, no exponent appears.
 *
 *  @param  str    The string buffer to use. It must be long enough to
 *                 hold the string value, i.e. at least 8 + @e digits bytes.
 *  @param  xval   The fixed-point number to convert.
 *  @param  frac   The number of fractional bits.
 *  @param  digits The number of digits to the right of the decimal point.
 *  @return        The length of the converted string. If @e str is
 *                 NULL or frac is greater than 31, a negative value is
 *                 returned and @e errno is set to EINVAL.
 */
FX_EXPORT int
fx_xtoa(char *str, fixed_t xval, unsigned frac, unsigned digits);


/*
 * -------------------------------------------------------------
 *  Algebraic functions
 * -------------------------------------------------------------
 */

/**
 *  Fixed-point inverse value. The error is within 4 ulp if
 *  @e frac is less than 31, 7 ulp otherwise.
 *  If the input is out-of-range (zero), then errno is set to EDOM.
 *
 *  @param  xval  A non-zero fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @param  rdiv  Optional reciprocal division multiplier.
 *  @return       The inverse value, i.e. 1/xval.
 */
FX_EXPORT fixed_t
fx_invx(fixed_t xval, unsigned frac, fx_rdiv_t *rdiv);

/**
 *  Fixed-point square root. The error is within 2 ulp if
 *  @e frac is less than 31, and within 4 ulp otherwise.
 *  If the input is out-of-range (negative), then errno is set to EDOM.
 *
 *  @param  xval  A non-zero fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The square root value, i.e. sqrt(xval).
 */
FX_EXPORT fixed_t
fx_sqrtx(fixed_t xval, unsigned frac);

/**
 *  Fixed-point inverse square root. The error is within 2 ulp if
 *  @e frac is less than 31, and within 3 ulp otherwise.
 *  If the input is out-of-range (negative or zero), then errno
 *  is set to EDOM.
 *
 *  @param  xval  A non-zero fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @param  rdiv  Optional reciprocal division multiplier.
 *  @return       The inverse square root value, i.e. 1/sqrt(xval).
 */
FX_EXPORT fixed_t
fx_isqrtx(fixed_t xval, unsigned frac, fx_rdiv_t *rdiv);


/*
 * -------------------------------------------------------------
 *  Transcendental functions
 * -------------------------------------------------------------
 */

/**
 *  Fixed-point natural exponential. The error is within 2 ulp.
 *  If @e frac is greater than 31, then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The natural exponential of xval, i.e. exp(xval).
 */
FX_EXPORT fixed_t
fx_expx(fixed_t xval, unsigned frac);

/**
 *  Fixed-point base-2 exponential. The error is within 2 ulp.
 *  If @e frac is greater than 31, then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The base-2 exponential of xval, i.e. 2**(xval).
 */
FX_EXPORT fixed_t
fx_exp2x(fixed_t xval, unsigned frac);

/**
 *  Fixed-point base-10 exponential. The error is within 2 ulp.
 *  If @e frac is greater than 31, then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The base-10 exponential of xval, i.e. 10**(xval).
 */
FX_EXPORT fixed_t
fx_exp10x(fixed_t xval, unsigned frac);

/**
 *  Fixed-point natural logarithm. The error is within 2 ulp.
 *  If @e xval is negative or zero or @e frac is greater than 31,
 *  then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The natural logarithm of xval, i.e. log(xval).
 */
FX_EXPORT fixed_t
fx_logx(fixed_t xval, unsigned frac);

/**
 *  Fixed-point base-2 logarithm. The error is within 2 ulp.
 *  If @e xval is negative or zero or @e frac is greater than 31,
 *  then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The base-2 logarithm of xval, i.e. log2(xval).
 */
FX_EXPORT fixed_t
fx_log2x(fixed_t xval, unsigned frac);

/**
 *  Fixed-point base-10 logarithm. The error is within 2 ulp.
 *  If @e xval is negative or zero or @e frac is greater than 31,
 *  then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The base-10 logarithm of xval, i.e. log10(xval).
 */
FX_EXPORT fixed_t
fx_log10x(fixed_t xval, unsigned frac);

/**
 *  Fixed-point power function. The error is bounded by
 *  <em>C<sub>1</sub> |yval| xval <sup>yval</sup> + C<sub>2</sub></em>,
 *  where @e C<sub>1</sub> and @e C<sub>2</sub> are approximately
 *  1 and 5 ulp, respectively. If either @e xfrac or @e yfrac is greater
 *  than 31, or @e xval is negative, or @e xval is zero and @e yval is
 *  negative, then errno is set to EDOM.
 *
 *  @param  xval  The base in fixed-point format.
 *  @param  xfrac The number of fractional bits for the base.
 *  @param  yval  The exponent in fixed-point format.
 *  @param  yfrac The number of fractional bits for the exponent.
 *  @return       @e xval raised to the power of @e yval. The number
 *                of fractional bits is @e xfrac.
 */
FX_EXPORT fixed_t
fx_powx(fixed_t xval, unsigned xfrac, fixed_t yval, unsigned yfrac);

/**
 *  Fixed-point sine. The error is within 3 ulp if
 *  @e frac is less than 31, and within 4 ulp otherwise.
 *  If @e frac is greater than 31, then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The sine value of xval, i.e. sin(xval).
 */
FX_EXPORT fixed_t
fx_sinx(fixed_t xval, unsigned frac);

/**
 *  Fixed-point cosine. The error is within 3 ulp if
 *  @e frac is less than 31, and within 4 ulp otherwise.
 *  If @e frac is greater than 31, then errno is set to EDOM.
 *
 *  @param  xval  A fixed-point value.
 *  @param  frac  The number of fractional bits.
 *  @return       The cosine value of xval, i.e. cos(xval).
 */
FX_EXPORT fixed_t
fx_cosx(fixed_t xval, unsigned frac);

// Extended functions for lua.
extern fixed_t fx_asinx(fixed_t x, unsigned frac);
extern fixed_t fx_acosx(fixed_t x, unsigned frac);
extern fixed_t fx_tanx(fixed_t x, unsigned frac);
extern fixed_t fx_atanx(fixed_t x, unsigned frac);
extern fixed_t fx_atan2x(fixed_t x, fixed_t y, unsigned frac);

static inline fixed_t fx_rad_to_deg(fixed_t radians, unsigned frac)
	{ return fx_mulx(radians, fix_rad_to_deg_mult, frac); }

static inline fixed_t fx_deg_to_rad(fixed_t degrees, unsigned frac)
	{ return fx_divx(fx_mulx(degrees, fix_pi, frac), fix_180_degree, frac); }

static inline void output_predefined_values()
{
    double _pi = 3.141592653589793238462643383279502884;
    printf("static const fixed_t fix_pi  = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;     /*!< fixed_t value of pi */\n", fx_dtox(_pi, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t fix_pi_div_2 = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ; /*!< fixed_t value of pi/2 */\n", fx_dtox(_pi/2, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t PI_DIV_4 = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;             /*!< Fix16 value of PI/4 */\n", fx_dtox(_pi/4, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t THREE_PI_DIV_4 = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;       /*!< Fix16 value of 3PI/4 */\n", fx_dtox(3*_pi/4, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t fix_rad_to_deg_mult = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;\n", fx_dtox(180.0/_pi, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t fix_180_degree = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;\n", fx_dtox(180.0, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t fix_atan2_factor_a = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;\n", fx_dtox(0.1963, MAX_FRACTIONAL_BIT_COUNT));
    printf("static const fixed_t fix_atan2_factor_b = 0x%08X >> FIX_MATH_FRACTIONAL_OFFSET ;\n", fx_dtox(0.9817, MAX_FRACTIONAL_BIT_COUNT));
}

#include "fixmath_impl.h"  /* Internal implementations */
#include "fixmath_macro.h" /* Macro overrides          */

#ifdef __cplusplus
};
#endif

#endif /* FIXMATH_H */

