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
 *  @file   fixmath.c
 *  @brief  Fixed-point math library - exported function definitions.
 */

#include <limits.h>
#include <stdlib.h>  /* labs()                   */
#include <errno.h>   /* errno facility, EDOM     */
#include <assert.h>  /* assert() macro           */
#include "fixmath.h" /* Exported API with macros */


/*
 * -------------------------------------------------------------
 *  Macros
 * -------------------------------------------------------------
 */

/**
 *  Signed fixed-point multiply, i.e. s32 x s32 -> s64.
 */
#define FX_SMUL(x1, x2, frac) \
    ((int64_t)(x1)*(int64_t)(x2) >> (frac))

/**
 *  Unsigned fixed-point multiply, i.e. u32 x u32 -> u64.
 */
#define FX_UMUL(x1, x2, frac) \
    ((uint64_t)(x1)*(uint64_t)(x2) >> (frac))

/**
 *  Convert a fixed-point number to a normalized
 *  floating-point number with 32-bit mantissa.
 */
#define FX_NORMALIZE(mant, expn, xval, frac) \
do {                                         \
    int nz__ = fx_clz(xval);                 \
    (mant)   = (uint32_t)(xval) << nz__;     \
    (expn)   = 31 - nz__ - (frac);           \
} while (0)

/**
 *  Compute value * 2**shift.
 */
#define FX_SHIFT(value, shift)                        \
    (fixed_t)((shift) > 0   ? (value) <<  (shift) :   \
              (shift) > -31 ? (value) >> -(shift) : 0)

/**
 *  Newton iteration update for inverse value:
 *  2*est - mant*(est*est).
 *  Two dependent multiplies and one add.
 */
#define FX_INV_UPDATE(est, mant) \
     (((est) << 1) -             \
       (uint32_t)FX_UMUL(mant, (uint32_t)FX_UMUL(est, est, 31), 31))

/**
 *  Newton iteration update for inverse square root:
 *  1.5*est - (mant2*est)*(est*est).
 *  Two independent multiplies, one add and one dependent multiply.
 */
#define FX_ISQRT_UPDATE(est, mant2)                            \
    (((est) + ((est) >> 1)) -                                  \
      (uint32_t)FX_UMUL((uint32_t)FX_UMUL(mant2, est, 31),     \
                        (uint32_t)FX_UMUL(est,   est, 31), 31))

/*
 * -------------------------------------------------------------
 *  Local functions fwd declare
 * -------------------------------------------------------------
 */

static fixed_t
fx_exp_base(fixed_t xval, unsigned frac, int imul, fixed_t fmul);

static fixed_t
fx_log_base(fixed_t xval, unsigned frac, fixed_t scale, unsigned shift);

static fixed_t
fx_sin_phase(uint32_t uval, unsigned frac, int phase);

static uint32_t
fx_core_inv(uint32_t mant);

static uint32_t
fx_core_isqrt(uint32_t mant, int expn, unsigned iter);

static uint32_t
fx_core_exp2(uint32_t fpart32);

static uint32_t
fx_core_log2(uint32_t fpart32);

static uint32_t
fx_core_sin(uint32_t fpart32);

/*
 * -------------------------------------------------------------
 *  Algebraic functions
 * -------------------------------------------------------------
 */

/**
 *  Fixed-point inverse value.
 */
fixed_t
fx_invx(fixed_t xval, unsigned frac, fx_rdiv_t *rdiv)
{
    uint32_t aval = labs(xval); /* Absolute value input    */
    uint32_t est;               /* Estimated value         */
    uint32_t mant;              /* Floating-point mantissa */
    int      expn;              /* Floating-point exponent */

    /* Handle illegal values */
    if (xval == 0 || frac > 31) {
        errno = EDOM;
        return 0;
    }

    /* Convert fixed-point number to floating-point with 32-bit mantissa */
    FX_NORMALIZE(mant, expn, aval, frac);

    /* Call inverse core function */
    est = fx_core_inv(mant);

    /* Save the reciprocal floating-point value */
    if (rdiv) {
        int32_t tmp = (est + 1) >> 1;
        rdiv->mant = xval > 0 ? tmp : -tmp;
        rdiv->expn = 31 + expn - 1;
    }

    /* Convert back to fixed-point */
    est >>= (31 + expn - frac);

    /* Return the signed result */
    return xval > 0 ? (fixed_t)est : -(fixed_t)est;
}

/**
 *  Fixed-point square root.
 */
fixed_t
fx_sqrtx(fixed_t xval, unsigned frac)
{
    const uint8_t iter[] = {0, 1, 2, 2}; /* #result bits to #iter LUT */
    uint32_t      est;                   /* Estimated value           */
    uint32_t      mant;                  /* Floating-point mantissa   */
    int           expn;                  /* Floating-point exponent   */

    /* Handle illegal values */
    if (xval < 0 || frac > 31) {
        errno = EDOM;
        return -1;
    }

    /* Handle the trivial case */
    if (xval == 0) {
        return 0;
    }

    /* Convert fixed-point number to floating-point with 32-bit mantissa */
    FX_NORMALIZE(mant, expn, xval, frac);

    /* Call inverse square root core function */
    est = fx_core_isqrt(mant, expn, iter[((expn >> 1) + frac) >> 3]);

    /* Multiply estimation by mant to produce the square root */
    est = (uint32_t)FX_UMUL(est, mant, 31);

    /* The square root of the exponent */
    expn >>= 1;

    /* Convert back to fixed-point */
    return est >> (31 - expn - frac);
}

/**
 *  Fixed-point inverse square root.
 */
fixed_t
fx_isqrtx(fixed_t xval, unsigned frac, fx_rdiv_t *rdiv)
{
    uint32_t est;   /* Estimated value         */
    uint32_t mant;  /* Floating-point mantissa */
    int      expn;  /* Floating-point exponent */

    /* Handle illegal values */
    if (xval <= 0 || frac > 31) {
        errno = EDOM;
        return -1;
    }

    /* Convert fixed-point number to floating-point with 32-bit mantissa */
    FX_NORMALIZE(mant, expn, xval, frac);

    /* Call inverse square root core function */
    est = fx_core_isqrt(mant, expn, 2);

    /* The square root of the exponent */
    expn = -expn >> 1;


    /* Save the reciprocal floating-point value */
    if (rdiv) {
        rdiv->mant = (est + 1) >> 1;
        rdiv->expn = 31 - expn - 1;
    }

    /* Convert back to fixed-point */
    return est >> (31 - expn - frac);
}


/*
 * -------------------------------------------------------------
 *  Transcendental functions
 * -------------------------------------------------------------
 */

/**
 *  Fixed-point base-2 exponential.
 */
fixed_t
fx_exp2x(fixed_t xval, unsigned frac)
{
    fixed_t  fpart;
    int32_t  ipart;
    uint32_t value;
    int      shift;

    /* Handle illegal values */
    if (frac > 31) {
        errno = EDOM;
        return -1;
    }

    /* Decompose the fixed-point number into integral and fractional parts */
    ipart = fx_floorx(xval, frac);
    fpart = xval - fx_itox(ipart, frac);

    /* Compute the exponential of the fractional part */
    value = fx_core_exp2((uint32_t)fpart << ((32 - frac) & 31));

    /* Compute the fixed-point conversion shift */
    shift = ipart + frac - 31;

    /* Convert back to fixed-point */
    return FX_SHIFT(value, shift);
}

/**
 *  Fixed-point base-10 exponential.
 */
fixed_t
fx_exp10x(fixed_t xval, unsigned frac)
{
    /* exp10(x) = exp2(x * log(10)/log(2)) = exp2(3.321928*x) */
    return fx_exp_base(xval, frac, 3, 0x5269e12fL);
}

/**
 *  Fixed-point natural exponential.
 */
fixed_t
fx_expx(fixed_t xval, unsigned frac)
{
    /* exp(x) = exp2(x / log(2)) = exp2(1.442695*x) */
    return fx_exp_base(xval, frac, 1, 0x71547653L);
}

/**
 *  Fixed-point base-2 logarithm.
 */
fixed_t
fx_log2x(fixed_t xval, unsigned frac)
{
    int      expn;
    uint32_t mant;
    uint32_t fpart;

    /* Handle illegal values */
    if (xval <= 0 || frac > 31) {
        errno = EDOM;
        return 0;
    }

    /* Convert fixed-point number to floating-point with 32-bit mantissa */
    FX_NORMALIZE(mant, expn, xval, frac);

    /* Compute the logarithm of mant = 1.f */
    fpart = fx_core_log2(mant << 1);

    /* Compute the logarithm: log2(1.f * 2**n) = log2(1.f) + n */
    return fx_itox(expn, frac) + (fpart >> (31 - frac));
}

/**
 *  Fixed-point base-10 logarithm.
 */
fixed_t
fx_log10x(fixed_t xval, unsigned frac)
{
    /* log10(x) = log2(x) * log(2)/log(10) = 0.301030*log2(x) */
    return fx_log_base(xval, frac, 0x4d104d42L, 32);
}

/**
 *  Fixed-point natural logarithm.
 */
fixed_t
fx_logx(fixed_t xval, unsigned frac)
{
    /* log(x) = log2(x) * log(2) = 0.693147*log2(x) */
    return fx_log_base(xval, frac, 0x58b90bfcL, 31);
}

/**
 *  Fixed-point power function.
 */
fixed_t
fx_powx(fixed_t xval, unsigned xfrac, fixed_t yval, unsigned yfrac)
{
    int32_t  logx;   /* log2(xval)         Q1.30    */
    int64_t  ylogx;  /* yval*log2(xval)    Q33.30   */
    int64_t  ipart;  /* floor(ylogx)       integral */
    uint32_t fpart;  /* frac(ylogx)        Q.32     */

    uint32_t mant;   /* xval mantissa      Q1.31    */
    int      expn;   /* xval exponent      integral */
    uint32_t value;  /* exp2(fpart)        Q1.31    */
    int64_t  shift;  /* Conversion shift   integral */
    int      sh;     /* Normalizing shift  integral */

    /* Handle illegal values */
    if (xfrac > 31 || yfrac > 31 ||  /* Out-of-range           */
        xval < 0                 ||  /* Negative base          */
        (xval == 0 && yval < 0))     /* Negative power of zero */
    {
        errno = EDOM;
        return 0;
    }

    if (xval == 0) {
        return 0; /* FX_NORMALIZE is undefined for 0 (or rather, clz is) */
    }

    /* Convert fixed-point base and exponent to floating-point */
    FX_NORMALIZE(mant, expn, xval, xfrac);

    /* Compute the logarithm of xm = 1.f */
    mant = fx_core_log2(mant << 1);

    /* Compute the new normalizing shift */
    sh = fx_clz(labs(expn) | 1) - 1;

    /* Compute the logarithm of xval in Q1.30 format */
    logx = (expn << sh) + (((mant >> (30 - sh)) + 1) >> 1);

    /* Perform fixed-point multiply with the exponent yval */
    ylogx = FX_SMUL(logx, yval, yfrac);

    /* Decompose the new exponent into integral and fractional parts */
    ipart = ylogx >> sh;
    fpart = (uint32_t)(ylogx << (32 - sh));

    /* Compute the base-2 exponential of the fractional part */
    value = fx_core_exp2(fpart);

    /* Compute the fixed-point conversion shift */
    shift = ipart + xfrac - 31;

    /* Convert to output fixed-point format */
    return FX_SHIFT(value, shift);
}

/**
 *  Fixed-point sine.
 */
fixed_t
fx_sinx(fixed_t xval, unsigned frac)
{
    /* sin(x) = sign(x)*sin(abs(x)) */
    fixed_t value = fx_sin_phase(labs(xval), frac, 0);
    return xval < 0 ? -value : value;
}

/**
 *  Fixed-point cosine.
 */
fixed_t
fx_cosx(fixed_t xval, unsigned frac)
{
    /* cos(x) = sin(x + pi/2) */
    return fx_sin_phase(labs(xval), frac, 1);
}

fixed_t fx_asinx(fixed_t x, unsigned frac)
{
    if((x > fix_one)
        || (x < -fix_one))
        return 0;
    else if(x == fix_one)
        return fix_pi_div_2;
    else if(x == 0)
        return 0;

    fixed_t out;
    out = (fix_one - fx_mulx(x, x, frac));
    out = fx_divx(x, fx_sqrtx(out, frac), frac);
    out = fx_atanx(out, frac);
    return out;
}

fixed_t fx_acosx(fixed_t x, unsigned frac)
{
    if(x == fix_one)
        return 0;
    else if(x == 0)
        return fix_pi_div_2;
    
    return ((fix_pi >> 1) - fx_asinx(x, frac));
}

fixed_t fx_tanx(fixed_t x, unsigned frac)
{
    return fx_divx(fx_sinx(x, frac), fx_cosx(x, frac), frac);
}
fixed_t fx_atanx(fixed_t x, unsigned frac)
{
    return fx_atan2x(x, fix_one, frac);
}
fixed_t fx_atan2x(fixed_t y, fixed_t x, unsigned frac)
{
    fixed_t abs_inY, mask, angle, r, r_3;

    /* Absolute inY */
    mask = (y >> (sizeof(fixed_t)*CHAR_BIT-1));
    abs_inY = (y + mask) ^ mask;

    if (x >= 0)
    {
        r = fx_divx( (x - abs_inY), (x + abs_inY), frac);
        r_3 = fx_mulx(fx_mulx(r, r, frac),r, frac);
        angle = fx_mulx(fix_atan2_factor_a , r_3, frac) - fx_mulx(fix_atan2_factor_b,r, frac) + PI_DIV_4;
    } else {
        r = fx_divx( (x + abs_inY), (abs_inY - x), frac);
        r_3 = fx_mulx(fx_mulx(r, r, frac),r, frac);
        angle = fx_mulx(fix_atan2_factor_a , r_3, frac)
            - fx_mulx(fix_atan2_factor_b,r, frac)
            + THREE_PI_DIV_4;
    }
    if (y < 0)
    {
        angle = -angle;
    }

    return angle;
}

/*
 * -------------------------------------------------------------
 *  Local functions
 * -------------------------------------------------------------
 */

/**
 *  Arbitrary-base exponential.
 *  Computes exp2(xval * imul.fmul).
 */
static fixed_t
fx_exp_base(fixed_t xval, unsigned frac, int imul, fixed_t fmul)
{
    int64_t  xmod;
    int32_t  ipart;
    uint32_t fpart;
    uint32_t value;
    int      shift;

    /* Handle illegal values */
    if (frac > 31) {
        errno = EDOM;
        return -1;
    }

    /* Multiply argument by imul.fmul and produce a Q31.32 number */
    xmod = FX_SMUL(xval, fmul, frac) +
           (FX_SMUL(xval, imul, 0) << (32 - frac));

    /* Decompose the fixed-point number into integral and fractional parts */
    ipart = (int32_t)(xmod >> 32);
    fpart = (uint32_t)xmod;

    /* Compute the base-2 exponential of the fractional part */
    value = fx_core_exp2(fpart);

    /* Compute the fixed-point conversion shift */
    shift = ipart + frac - 31;

    /* Convert back to fixed-point */
    return FX_SHIFT(value, shift);
}

/**
 *  Arbitrary-base exponential.
 *  Computes log2(xval)*scale.
 */
static fixed_t
fx_log_base(fixed_t xval, unsigned frac, fixed_t scale, unsigned shift)
{
    int      expn;
    uint32_t mant;
    uint32_t fpart;
    int64_t  ipart;

    /* Handle illegal values */
    if (xval <= 0 || frac > 31) {
        errno = EDOM;
        return 0;
    }

    /* Convert fixed-point number to floating-point with 32-bit mantissa */
    FX_NORMALIZE(mant, expn, xval, frac);

    /* Compute the base-2 logarithm of mant = 1.f */
    fpart = fx_core_log2(mant << 1);

    /* Scale the base-2 mantissa logarithm */
    fpart = (uint32_t)FX_UMUL(fpart, scale, shift);

    /* Compute the scaled logarithm of the exponent */
    ipart = FX_SMUL(expn, scale, shift - 31);

    /* Compute the base-x logarithm */
    return (fixed_t)((ipart + (int64_t)fpart) >> (31 - frac));
}

/**
 *  Sine with phase shift.
 *  Computes sin(uval + phase*pi/2).
 */
static fixed_t
fx_sin_phase(uint32_t uval, unsigned frac, int phase)
{
    uint32_t fpart;     /* uval / 2pi fractional       Q.32     */
    uint32_t value = 0; /* abs(sin(uval + phase*pi/2)) Q1.31    */
    int      segm;      /* Segment number (0-3)        integral */

    /* Handle illegal values */
    if (frac > 31) {
        errno = EDOM;
        return 0;
    }

    /* Multiply with 1 / 2pi constant to map the period [0, 2pi] to [0, 1] */
    fpart = (uint32_t)FX_UMUL(uval, 0xa2f9836eUL, frac + 2);

    /* Compute the segment number */
    segm = ((fpart >> 30) + phase) & 3;

    /* Compute the absolute sin value */
    switch (segm) {
        case 0:
        case 2:
            /*  0 <= x <  pi/2 ==> sin(x) =  core(4 * x/2pi) or
             * pi <= x < 3pi/2 ==> sin(x) = -core(4 * x/2pi)
             */
            value = fx_core_sin(fpart << 2);
            break;

        case 1:
        case 3:
            /*  pi/2 <= x <  pi ==> sin(x) =  core(1 - 4 * x/2pi) or
             * 3pi/2 <= x < 2pi ==> sin(x) = -core(1 - 4 * x/2pi)
             */
            value = fx_core_sin(UINT32_MAX - (fpart << 2));
            break;

        default:
            assert(0);
    }

    /* Convert to Q.frac format */
    value >>= (31 - frac);

    /* Add sign */
    return segm > 1 ? -(fixed_t)value : (fixed_t)value;
}

/**
 *  Compute the inverse square root for a normalized mantissa.
 *  iter  error
 *  0      9 bits
 *  1     19 bits
 *  2     31 bits (full precision)
 */
static uint32_t
fx_core_isqrt(uint32_t mant, int expn, unsigned iter)
{
    static const uint8_t isqrt_lut[256] =
        {150,149,148,147,146,145,144,143,142,141,140,139,138,137,136,135,
         134,133,132,131,131,130,129,128,127,126,125,124,124,123,122,121,
         120,119,119,118,117,116,115,114,114,113,112,111,110,110,109,108,
         107,107,106,105,104,104,103,102,101,101,100, 99, 98, 98, 97, 96,
          95, 95, 94, 93, 93, 92, 91, 91, 90, 89, 88, 88, 87, 86, 86, 85,
          84, 84, 83, 82, 82, 81, 80, 80, 79, 79, 78, 77, 77, 76, 75, 75,
          74, 74, 73, 72, 72, 71, 70, 70, 69, 69, 68, 67, 67, 66, 66, 65,
          65, 64, 63, 63, 62, 62, 61, 61, 60, 59, 59, 58, 58, 57, 57, 56,
          56, 55, 54, 54, 53, 53, 52, 52, 51, 51, 50, 50, 49, 49, 48, 48,
          47, 47, 46, 46, 45, 45, 44, 44, 43, 43, 42, 42, 41, 41, 40, 40,
          39, 39, 38, 38, 37, 37, 36, 36, 35, 35, 34, 34, 33, 33, 33, 32,
          32, 31, 31, 30, 30, 29, 29, 28, 28, 28, 27, 27, 26, 26, 25, 25,
          25, 24, 24, 23, 23, 22, 22, 22, 21, 21, 20, 20, 19, 19, 19, 18,
          18, 17, 17, 17, 16, 16, 15, 15, 15, 14, 14, 13, 13, 13, 12, 12,
          11, 11, 11, 10, 10,  9,  9,  9,  8,  8,  8,  7,  7,  6,  6,  6,
           5,  5,  5,  4,  4,  3,  3,  3,  2,  2,  2,  1,  1,  1,  0,  0};

    uint32_t m2 = mant / 2; /* Half mantissa temporary      */
    uint32_t est;           /* Inverse square root estimate */

    /* Look up the initial guess from mantissa MSBs */
    est = (uint32_t)(isqrt_lut[(mant >> 23) & 0xff] + 362) << 22;

    /* Iterate newton step: est = est*(3 - mant*est*est)/2 */
    switch (iter) {
        default:
        case 2:
            est = FX_ISQRT_UPDATE(est, m2);
            /* Fall through */

        case 1:
            est = FX_ISQRT_UPDATE(est, m2);

        case 0:
            ; /* No action */
    }

    /* Adjust estimate by 1/sqrt(2) if exponent is odd */
    if (expn & 1) {
        est = (uint32_t)FX_UMUL(est, 0xb504f334UL, 31);
    }

    return est;
}

/**
 *  Compute the inverse of a normalized mantissa.
 */
static uint32_t
fx_core_inv(uint32_t mant)
{
    static const uint8_t inv_lut[256] =
        {255,254,252,250,248,246,244,242,240,238,236,234,233,231,229,227,
         225,224,222,220,218,217,215,213,212,210,208,207,205,203,202,200,
         199,197,195,194,192,191,189,188,186,185,183,182,180,179,178,176,
         175,173,172,170,169,168,166,165,164,162,161,160,158,157,156,154,
         153,152,151,149,148,147,146,144,143,142,141,139,138,137,136,135,
         134,132,131,130,129,128,127,126,125,123,122,121,120,119,118,117,
         116,115,114,113,112,111,110,109,108,107,106,105,104,103,102,101,
         100, 99, 98, 97, 96, 95, 94, 93, 92, 91, 90, 89, 88, 88, 87, 86,
         85, 84, 83, 82, 81, 80, 80, 79, 78, 77, 76, 75, 74, 74, 73, 72,
         71, 70, 70, 69, 68, 67, 66, 66, 65, 64, 63, 62, 62, 61, 60, 59,
         59, 58, 57, 56, 56, 55, 54, 53, 53, 52, 51, 50, 50, 49, 48, 48,
         47, 46, 46, 45, 44, 43, 43, 42, 41, 41, 40, 39, 39, 38, 37, 37,
         36, 35, 35, 34, 33, 33, 32, 32, 31, 30, 30, 29, 28, 28, 27, 27,
         26, 25, 25, 24, 24, 23, 22, 22, 21, 21, 20, 19, 19, 18, 18, 17,
         17, 16, 15, 15, 14, 14, 13, 13, 12, 12, 11, 10, 10,  9,  9,  8,
          8,  7,  7,  6,  6,  5,  5,  4,  4,  3,  3,  2,  2,  1,  1,  0};

    uint32_t est;                       /* Inverse square root estimate */
    int      idx = (mant >> 23) & 0xff; /* LUT index from mantissa bits */

    /* Look up the initial guess from mantissa MSBs */
    est = (uint32_t)(inv_lut[idx] + 256 + !idx) << 22;

    /* Iterate two newton steps: est = est*(2 - mant*est) */
    est = FX_INV_UPDATE(est, mant);
    est = FX_INV_UPDATE(est, mant);

    return est;
}

#ifdef FX_NO_EXP_LOG_TABLES
/**
 *  Base-2 fractional exponential.
 *  Computes 2**x, where x is an unsigned Q.32 fractional number in
 *  the range [0,1). This yields a Q1.31 result in the [1,2) range.
 *
 *  The exponential is approximated by a polynomial of degree seven,
 *  computed by the Remez' function approximation algorithm:
 *
 *      p(x) = c7 x**7 + c6 x**6 + ... + c0,
 *
 *  where
 *
 *      c7 = 2.166075906e-05 = 0xb5b4203b  2**-47
 *      c6 = 1.429623834e-04 = 0x95e82c2e  2**-44
 *      c5 = 1.343024574e-03 = 0xb0086d3f  2**-41
 *      c4 = 9.613506061e-03 = 0x9d81f788  2**-38
 *      c3 = 5.550530237e-02 = 0xe3598727  2**-36
 *      c2 = 2.402263560e-01 = 0xf5fde5db  2**-34
 *      c1 = 6.931471878e-01 = 0xb1721817  2**-32
 *      c0 = 1.000000000e-01 = 0x80000000  2**-31
 *
 *  The result is an unsigned Q1.31 fixed-point number with an
 *  implicit exponent of one.
 */
static uint32_t
fx_core_exp2(uint32_t fpart32)
{
    int64_t  acc;
    uint32_t x1, x2, x3, x4, x5, x6, x7;

    /* Initialization */
    x1  = fpart32;
    acc = (int64_t)0x80000000UL << 1;           /* acc  = c0    */

    /* Two independent multiplies */
    x2   = FX_UMUL(x1, x1, 32);                 /* x2   = x1*x1 */
    acc += FX_UMUL(x1, 0xb1721817UL, 32);       /* acc += c1*x1 */

    /* Three independent multiplies */
    x3   = FX_UMUL(x1, x2, 32);                 /* x3   = x1*x2 */
    x4   = FX_UMUL(x2, x2, 32);                 /* x4   = x2*x2 */
    acc += FX_UMUL(x2, 0xf5fde5dbUL, 34);       /* acc += c2*x2 */

    /* Five independent multiplies */
    x5   = FX_UMUL(x2, x3, 32);                 /* x5   = x2*x3 */
    x6   = FX_UMUL(x3, x3, 32);                 /* x6   = x3*x3 */
    x7   = FX_UMUL(x3, x4, 32);                 /* x7   = x3*x4 */
    acc += FX_UMUL(x3, 0xe3598727UL, 36);       /* acc += c3*x3 */
    acc += FX_UMUL(x4, 0x9d81f788UL, 38);       /* acc += c4*x4 */

    /* Three independent multiplies */
    acc += FX_UMUL(x5, 0xb0086d3fUL, 41);       /* acc += c5*x5 */
    acc += FX_UMUL(x6, 0x95e82c2eUL, 44);       /* acc += c6*x6 */
    acc += FX_UMUL(x7, 0xb5b4203bUL, 47);       /* acc += c7*x7 */

    return (uint32_t)((acc + 1) >> 1);
}

#else /* !FX_NO_EXP_LOG_TABLES */
/**
 *  Base-2 fractional exponential.
 *  Computes 2**x, where x is an unsigned Q.32 fractional number in
 *  the range [0,1). This yields a Q1.31 result in the [1,2) range.
 *
 *  The exponential is approximated by a per-segment polynomial of degree
 *  three, computed by the Remez' function approximation algorithm. There
 *  are 32 segments, requiring a lookup table of 512 bytes for the
 *  coefficients. The result is an unsigned Q1.31 fixed-point number
 *  with an implicit exponent of one.
 */
static uint32_t
fx_core_exp2(uint32_t fpart32)
{
    /* The 512 bytes large lookup table of polynomial coefficients */
    static const uint32_t table[32][4] =
        {{0x80000000UL, 0x58b90c9bUL, 0x7afd6ab0UL, 0x72e946ceUL},
         {0x82cd8699UL, 0x5aaa6677UL, 0x7daedb8cUL, 0x756d6e58UL},
         {0x85aac368UL, 0x5ca6a450UL, 0x806f652fUL, 0x77ffb0d3UL},
         {0x88980e80UL, 0x5eae0331UL, 0x833f5c39UL, 0x7aa05d42UL},
         {0x8b95c1e4UL, 0x60c0c17eUL, 0x861f1727UL, 0x7d4fc480UL},
         {0x8ea4398bUL, 0x62df1ef7UL, 0x890eee57UL, 0x800e3913UL},
         {0x91c3d373UL, 0x65095cc2UL, 0x8c0f3c19UL, 0x82dc0f68UL},
         {0x94f4efa9UL, 0x673fbd72UL, 0x8f205cb7UL, 0x85b99db0UL},
         {0x9837f051UL, 0x6982850fUL, 0x9242ae7fUL, 0x88a73c0fUL},
         {0x9b8d39baUL, 0x6bd1f91fUL, 0x957691d0UL, 0x8ba54488UL},
         {0x9ef53260UL, 0x6e2e60adUL, 0x98bc6928UL, 0x8eb4131fUL},
         {0xa2704303UL, 0x70980452UL, 0x9c149928UL, 0x91d405e1UL},
         {0xa5fed6a9UL, 0x730f2e40UL, 0x9f7f88aaUL, 0x95057ce1UL},
         {0xa9a15ab5UL, 0x75942a46UL, 0xa2fda0c5UL, 0x9848da4fUL},
         {0xad583eeaUL, 0x782745deUL, 0xa68f4cdfUL, 0x9b9e828aUL},
         {0xb123f582UL, 0x7ac8d034UL, 0xaa34fab9UL, 0x9f06dc16UL},
         {0xb504f334UL, 0x7d791a2fUL, 0xadef1a78UL, 0xa2824fbdUL},
         {0xb8fbaf47UL, 0x8038767cUL, 0xb1be1eb8UL, 0xa6114890UL},
         {0xbd08a39fUL, 0x83073998UL, 0xb5a27c97UL, 0xa9b43406UL},
         {0xc12c4ccaUL, 0x85e5b9d8UL, 0xb99cabc3UL, 0xad6b81deUL},
         {0xc5672a11UL, 0x88d44f77UL, 0xbdad268bUL, 0xb137a476UL},
         {0xc9b9bd86UL, 0x8bd3549eUL, 0xc1d469e8UL, 0xb519107bUL},
         {0xce248c15UL, 0x8ee3256eUL, 0xc612f593UL, 0xb9103d52UL},
         {0xd2a81d92UL, 0x9204200eUL, 0xca694c0fUL, 0xbd1da4daUL},
         {0xd744fccbUL, 0x9536a4b4UL, 0xced7f2bbUL, 0xc141c3d0UL},
         {0xdbfbb798UL, 0x987b15b2UL, 0xd35f71e1UL, 0xc57d1964UL},
         {0xe0ccdeecUL, 0x9bd1d780UL, 0xd80054c9UL, 0xc9d027cdUL},
         {0xe5b906e7UL, 0x9f3b50cbUL, 0xdcbb29c6UL, 0xce3b7407UL},
         {0xeac0c6e8UL, 0xa2b7ea7dUL, 0xe1908249UL, 0xd2bf85e4UL},
         {0xefe4b99cUL, 0xa6480fcfUL, 0xe680f2f3UL, 0xd75ce85aUL},
         {0xf5257d15UL, 0xa9ec2e52UL, 0xeb8d13a6UL, 0xdc142939UL},
         {0xfa83b2dbUL, 0xada4b5fbUL, 0xf0b57f97UL, 0xe0e5d996UL}};

    uint32_t c0, c1, c2, c3; /* Polynomial coefficients   Q.32     */
    uint32_t x1, x2, x3;     /* Fractional powers         Q.32     */
    int64_t  acc;            /* Result accumulation word  Q31.32   */
    int      ix;             /* Lookup table index        integral */

    /* Compute the segment index from the five most significant bits */
    ix = fpart32 >> 27;

    /* Fetch the four polynomial coefficients for this segment */
    c0 = table[ix][0];
    c1 = table[ix][1];
    c2 = table[ix][2];
    c3 = table[ix][3];

    /* Initialize segment fractional x1 and accumulator acc */
    x1  = fpart32 << 5;
    acc = 0;

    /* Two independent multiplies */
    x2   = (uint32_t)FX_UMUL(x1, x1, 32);
    acc += FX_UMUL(c1, x1, 36);

    /* Two independent multiplies */
    x3   = (uint32_t)FX_UMUL(x2, x1, 32);
    acc += FX_UMUL(c2, x2, 43);

    /* Final multiply */
    acc += FX_UMUL(c3, x3, 50);

    /* Add constant term */
    acc += (int64_t)c0 << 1;

    return (uint32_t)((acc + 1) >> 1);
}
#endif /* !FX_NO_EXP_LOG_TABLES */

#ifdef FX_NO_EXP_LOG_TABLES
/**
 *  Base-2 fractional logarithm.
 *  Computes log2(1 + x), where x is an unsigned Q.32 fractional number
 *  in the range [0,1). This yields a Q1.31 result in the [0,1] range.
 *
 *  The logarithm is approximated by a polynomial of degree eleven,
 *  computed by the Remez' function approximation algorithm:
 *
 *      p(x) = c11 x**11 + c10 x**10 + ... + c1 x + c0,
 *
 *  where
 *
 *      c11 =  2.139618e-03 =  0x8c38d46e  2**-40
 *      c10 = -1.511187e-02 = -0xf797c426  2**-38
 *      c9  =  5.008250e-02 =  0xcd234e4d  2**-36
 *      c8  = -1.062771e-01 = -0xd9a7ca61  2**-35
 *      c7  =  1.690153e-01 =  0xad125aa3  2**-34
 *      c6  = -2.271709e-01 = -0xe89f7ebc  2**-34
 *      c5  =  2.852764e-01 =  0x920fbf7a  2**-33
 *      c4  = -3.601523e-01 = -0xb865e2f3  2**-33
 *      c3  =  4.808484e-01 =  0xf631c24e  2**-33
 *      c2  = -7.213450e-01 = -0xb8aa1140  2**-32
 *      c1  =  1.442695e+00 =  0xb8aa3ac0  2**-31.
 *      c0  =  0.0          =  0
 *
 *  The result is an unsigned Q1.31 fixed-point number.
 */
static uint32_t
fx_core_log2(uint32_t fpart32)
{
    int64_t  acc = 0;
    uint32_t x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11;

    /* Initialization */
    x1  = fpart32;

    /* Two independent multiplies */
    x2   = FX_UMUL(x1, x1, 32);                 /* x2   = x1*x1 */
    acc += FX_UMUL(x1, 0xb8aa3ac0UL, 31);       /* acc += c1*x1 */

    /* Three independent multiplies */
    x3   = FX_UMUL(x1, x2, 32);                 /* x3   = x1*x2 */
    x4   = FX_UMUL(x2, x2, 32);                 /* x4   = x2*x2 */
    acc -= FX_UMUL(x2, 0xb8aa1140UL, 32);       /* acc -= c2*x2 */

    /* Six independent multiplies */
    x5   = FX_UMUL(x2, x3, 32);                 /* x5   = x2*x3 */
    x6   = FX_UMUL(x3, x3, 32);                 /* x6   = x3*x3 */
    x7   = FX_UMUL(x3, x4, 32);                 /* x7   = x3*x4 */
    x8   = FX_UMUL(x4, x4, 32);                 /* x8   = x4*x4 */
    acc += FX_UMUL(x3, 0xf631c24eUL, 33);       /* acc += c3*x3 */
    acc -= FX_UMUL(x4, 0xb865e2f3UL, 33);       /* acc -= c4*x4 */

    /* Seven independent multiplies */
    x9   = FX_UMUL(x4, x5, 32);                 /* x9   = x5*x4 */
    x10  = FX_UMUL(x5, x5, 32);                 /* x10  = x5*x5 */
    x11  = FX_UMUL(x6, x5, 32);                 /* x11  = x6*x5 */
    acc += FX_UMUL(x5, 0x920fbf7aUL, 33);       /* acc += c5*x5 */
    acc -= FX_UMUL(x6, 0xe89f7ebcUL, 34);       /* acc -= c6*x6 */
    acc += FX_UMUL(x7, 0xad125aa3UL, 34);       /* acc += c7*x7 */
    acc -= FX_UMUL(x8, 0xd9a7ca61UL, 35);       /* acc -= c8*x8 */

    /* Three independent multiplies */
    acc += FX_UMUL(x9,  0xcd234e4dUL, 36);      /* acc += c9 *x9  */
    acc -= FX_UMUL(x10, 0xf797c426UL, 38);      /* acc -= c10*x10 */
    acc += FX_UMUL(x11, 0x8c38d46eUL, 40);      /* acc += c11*x11 */

    return (uint32_t)((acc + 1) >> 1);
}

#else /* !FX_NO_EXP_LOG_TABLES */
/**
 *  Base-2 fractional logarithm.
 *  Computes log2(1 + x), where x is an unsigned Q.32 fractional number
 *  in the range [0,1). This yields a Q1.31 result in the [0,1] range.
 *
 *  The logarithm is approximated by a per-segment polynomial of degree
 *  four, computed by the Remez' function approximation algorithm. There
 *  are 16 segments, requiring a lookup table of 320 bytes for the
 *  coefficients. The result is an unsigned Q1.31 fixed-point number.
 */
static uint32_t
fx_core_log2(uint32_t fpart32)
{
    /* The 320 bytes large lookup table of polynomial coefficients */
    static const uint32_t table[16][5] =
        {{0000000002UL,0xb8aa3809UL,0xb8a71111UL,0xf5181ba1UL,0xa3741666UL},
         {0x1663f6fcUL,0xadcd6287UL,0xa391c7e9UL,0xcc703403UL,0x8128cedeUL},
         {0x2b803475UL,0xa4258829UL,0x91e6b29dUL,0xac4bac7eUL,0x67680fa0UL},
         {0x3f782d73UL,0x9b81dfa0UL,0x82f2bdb3UL,0x928ce148UL,0x53c3aca5UL},
         {0x5269e130UL,0x93bb617aUL,0x762e71acUL,0x7daff66fUL,0x449294cbUL},
         {0x646eea25UL,0x8cb27563UL,0x6b31ccc5UL,0x6c9a3c9dUL,0x38ac9277UL},
         {0x759d4f81UL,0x864d41a3UL,0x61abe29bUL,0x5e7a6031UL,0x2f3f8599UL},
         {0x86082807UL,0x80766b68UL,0x595cf97fUL,0x52b32231UL,0x27b3f257UL},
         {0x95c01a3aUL,0x7b1c2702UL,0x5212559bUL,0x48ccd634UL,0x219b062aUL},
         {0xa4d3c25fUL,0x762f81acUL,0x4ba32b4eUL,0x406b50e8UL,0x1ca29548UL},
         {0xb3500472UL,0x71a3d559UL,0x45ee5fbaUL,0x3946ce96UL,0x188cf14aUL},
         {0xc1404eaeUL,0x6d6e5bb5UL,0x40d8dba4UL,0x3326de10UL,0x152b42bbUL},
         {0xceaecfebUL,0x6985d876UL,0x3c4c47a5UL,0x2ddeb388UL,0x1259a653UL},
         {0xdba4a47bUL,0x65e25570UL,0x38361502UL,0x294a6f77UL,0x0ffc3eb3UL},
         {0xe829fb69UL,0x627cec35UL,0x3486bf54UL,0x254d2025UL,0x0dfd4de4UL},
         {0xf446359bUL,0x5f4f9a49UL,0x3131385eUL,0x21cf3d01UL,0x0c4bacbdUL}};

    uint32_t c0, c1, c2, c3, c4; /* Polynomial coefficients   Q.32     */
    uint32_t x1, x2, x3, x4;     /* Fractional powers         Q.32     */
    int64_t  acc;                /* Result accumulation word  Q31.32   */
    int      ix;                 /* Lookup table index        integral */

    /* Compute the segment index from the four most significant bits */
    ix = fpart32 >> 28;

    /* Fetch the five polynomial coefficients for this segment */
    c0 = table[ix][0];
    c1 = table[ix][1];
    c2 = table[ix][2];
    c3 = table[ix][3];
    c4 = table[ix][4];

    /* Initialize segment fractional x1 and accumulator acc */
    x1  = fpart32 << 4;
    acc = 0;

    /* Two independent multiplies */
    x2   = (uint32_t)FX_UMUL(x1, x1, 32);
    acc += FX_UMUL(c1, x1, 35);

    /* Three independent multiplies */
    x3   = (uint32_t)FX_UMUL(x2, x1, 32);
    x4   = (uint32_t)FX_UMUL(x2, x2, 32);
    acc -= FX_UMUL(c2, x2, 40);

    /* Two independent multiplies */
    acc += FX_UMUL(c3, x3, 45);
    acc -= FX_UMUL(c4, x4, 49);

    /* Add constant term */
    acc += c0;

    return (uint32_t)((acc + 1) >> 1);
}
#endif /* !FX_NO_EXP_LOG_TABLES */

/**
 *  Fractional sine function.
 *  Computes sin(pi*x/2), where x is an unsigned Q.32 fractional number.
 *  This yields a Q1.31 result in the range [0,1].
 *
 *  The function is approximated by a per-segment polynomial of degree
 *  four, computed by the Remez' function approximation algorithm. There
 *  are 16 segments, requiring a lookup table of 320 bytes for the
 *  coefficients. The result is an unsigned Q1.31 fixed-point number.
 */
static uint32_t
fx_core_sin(uint32_t fpart32)
{
    /* The 320 bytes large lookup table of polynomial coefficients */
    static const uint32_t table[16][5] =
        /*   c0 2**32      c1 2**35  (s)c2 2**38    -c3 2**44     c4 2**49 */
        {{0000000001UL,0xc90fd9a3UL, 0x00003fb0L,0xa58a7e76UL,0x065f386bUL},
         {0x1917a6bdUL,0xc817ffc8UL,-0x07bcf80fL,0xa4be44bcUL,0x130df3a4UL},
         {0x31f17079UL,0xc532d541UL,-0x0f671be3L,0xa25be1b9UL,0x1f8db4a9UL},
         {0x4a5018bcUL,0xc0677d57UL,-0x16eb464bL,0x9e693649UL,0x2bbfaac2UL},
         {0x61f78a9bUL,0xb9c1c9f7UL,-0x1e36ef68L,0x98effe28UL,0x3785c4f8UL},
         {0x78ad74e1UL,0xb1521e87UL,-0x25381aa7L,0x91fdb7ebUL,0x42c2fc45UL},
         {0x8e39d9ceUL,0xa72d4786UL,-0x2bdd8320L,0x89a383c5UL,0x4d5b9b12UL},
         {0xa2679929UL,0x9b6c4741UL,-0x3216c622L,0x7ff5f946UL,0x57358192UL},
         {0xb504f334UL,0x8e2c182bUL,-0x37d48b9eL,0x750cf49dUL,0x60386657UL},
         {0xc5e40359UL,0x7f8d656dUL,-0x3d08abfaL,0x69035bc2UL,0x684e11ddUL},
         {0xd4db3149UL,0x6fb43a5aUL,-0x41a652f5L,0x5bf6dc22UL,0x6f629596UL},
         {0xe1c5978cUL,0x5ec7a990UL,-0x45a21f4aL,0x4e07a17aUL,0x75647cecUL},
         {0xec835e7aUL,0x4cf16ca9UL,-0x48f23ebfL,0x3f580680UL,0x7a44f841UL},
         {0xf4fa0ab6UL,0x3a5d7d55UL,-0x4b8e8659L,0x300c403cUL,0x7df801d6UL},
         {0xfb14be80UL,0x2739a8f5UL,-0x4d708680L,0x204a04aeUL,0x80747a4cUL},
         {0xfec46d1fUL,0x13b51fadUL,-0x4e939ae0L,0x10382e0bUL,0x81b441c8UL}};

    uint32_t c0, c1, c2, c3, c4;  /* Polynomial coefficients   Q.31     */
    uint32_t x1, x2, x3, x4;      /* Fractional powers         Q.32     */
    int64_t  acc;                 /* Result accumulation word  Q32.31   */
    int      ix;                  /* Lookup table index        integral */

    /* Compute the segment index from the four most significant bits */
    ix = fpart32 >> 28;

    /* Fetch the five polynomial coefficients for this segment */
    c0 = table[ix][0];
    c1 = table[ix][1];
    c2 = table[ix][2];
    c3 = table[ix][3];
    c4 = table[ix][4];

    /* Initialize segment fractional x1 and accumulator acc */
    x1  = fpart32 << 4;
    acc = 0;

    /* Two independent multiplies */
    x2   = (uint32_t)FX_UMUL(x1, x1, 32);
    acc += FX_UMUL(c1, x1, 35 - 2);

    /* Three independent multiplies */
    x3   = (uint32_t)FX_UMUL(x2, x1, 32);
    x4   = (uint32_t)FX_UMUL(x2, x2, 32);
    acc += FX_SMUL((int32_t)c2, x2, 38 - 2);

    /* Two independent multiplies */
    acc -= FX_UMUL(c3, x3, 44 - 2);
    acc += FX_UMUL(c4, x4, 49 - 2);

    /* Add constant term */
    acc += (int64_t)c0 << 2;

    return (uint32_t)((acc + 4) >> 3);
}
