
#if __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lauxlib.h>
#include "fixmath.h"

#define __METATABLE_NAME "___FIX_MATATABLE___"
static unsigned fractional_bit_count = FIX_MATH_FRACTIONAL_BIT_COUNT;

static void create_meta(lua_State *L);

static fixed_t lua_tofix(lua_State *L, int idx)
{
	fixed_t* p = luaL_testudata(L, idx, __METATABLE_NAME);
	if(p)
	{
		return *p;
	}
	else
	{
		return fx_dtox(luaL_checknumber(L, idx), fractional_bit_count);
	}
}

static void push_fix(lua_State *L, fixed_t v)
{
	fixed_t* p = lua_newuserdata(L, sizeof(v));
	*p = v;
	create_meta(L);
	lua_setmetatable(L, -2);
}

static int fix_tostring(lua_State *L)
{
	lua_pushnumber(L, fx_xtod(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}

static int fix_rawvalue(lua_State *L)
{
	lua_pushinteger(L, lua_tofix(L, 1));
	return 1;
}

static int fix_add(lua_State *L)
{
	push_fix(L, fx_addx(lua_tofix(L, 1), lua_tofix(L, 2)));
	return 1;
}

static int fix_sub(lua_State *L)
{
	push_fix(L, fx_subx(lua_tofix(L, 1), lua_tofix(L, 2)));
	return 1;
}

static int fix_mul(lua_State *L)
{
	push_fix(L, fx_mulx(lua_tofix(L, 1), lua_tofix(L, 2), fractional_bit_count));
	return 1;
}

static int fix_div(lua_State *L)
{
	push_fix(L, fx_divx(lua_tofix(L, 1), lua_tofix(L, 2), fractional_bit_count));
	return 1;
}

static int fix_mod(lua_State *L)
{
	push_fix(L, lua_tofix(L, 1) % lua_tofix(L, 2));
	return 1;
}

static int fix_pow(lua_State *L)
{

	push_fix(L, fx_powx(lua_tofix(L, 1), fractional_bit_count, lua_tofix(L, 2), fractional_bit_count));
	return 1;
}

static int fix_unm(lua_State *L)
{
	push_fix(L, -lua_tofix(L, 1));
	return 1;
}

static int fix_idiv(lua_State *L)
{
	push_fix(L, fx_floorx(fx_divx(lua_tofix(L, 1), lua_tofix(L, 2), fractional_bit_count), fractional_bit_count));
	return 1;
}

static int fix_lt(lua_State *L)
{
	lua_pushboolean(L, lua_tofix(L, 1) < lua_tofix(L, 2));
	return 1;
}

static int fix_le(lua_State *L)
{
	lua_pushboolean(L, lua_tofix(L, 1) <= lua_tofix(L, 2));
	return 1;
}
static int fix_eq(lua_State *L)
{
	lua_pushboolean(L, lua_tofix(L, 1) == lua_tofix(L, 2));
	return 1;
}

static int l_tofix(lua_State *L)
{
	if(lua_isnumber(L, 1))
	{
		push_fix(L, fx_dtox(lua_tonumber(L, 1), fractional_bit_count));
		return 1;
	}
	else
	{
		return 0;
	}
}

static int fix_abs(lua_State *L)
{
	fixed_t x = lua_tofix(L, 1);
	x = x < 0 ? -x : x;
	push_fix(L, x);
	return 1;
}
static int fix_floor(lua_State *L)
{
	push_fix(L, fx_itox(fx_floorx(lua_tofix(L, 1), fractional_bit_count), fractional_bit_count));
	return 1;
}
static int fix_ceil(lua_State *L)
{
	push_fix(L, fx_itox(fx_ceilx(lua_tofix(L, 1), fractional_bit_count), fractional_bit_count));
	return 1;
}
static int fix_min(lua_State *L)
{
	fixed_t x = lua_tofix(L, 1);
	fixed_t y = lua_tofix(L, 2);
	push_fix(L, x < y ? x : y);
	return 1;	
}
static int fix_max(lua_State *L)
{
	fixed_t x = lua_tofix(L, 1);
	fixed_t y = lua_tofix(L, 2);
	push_fix(L, x > y ? x : y);
	return 1;
}
static int fix_sin(lua_State *L)
{
	push_fix(L, fx_sinx(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}
static int fix_cos(lua_State *L)
{
	push_fix(L, fx_cosx(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}
static int fix_tan(lua_State *L)
{
	push_fix(L, fx_tanx(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}
static int fix_asin(lua_State *L)
{
	push_fix(L, fx_asinx(lua_tofix(L, 1), fractional_bit_count));
	return 1;	
}
static int fix_acos(lua_State *L)
{
	push_fix(L, fx_acosx(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}
static int fix_atan(lua_State *L)
{
	if(lua_isnoneornil(L, 2))
	{
		push_fix(L, fx_atanx(lua_tofix(L, 1), fractional_bit_count));
	}
	else
	{
		push_fix(L, fx_atan2x(lua_tofix(L, 1), lua_tofix(L, 2), fractional_bit_count));
	}
	
	return 1;
}
static int fix_atan2(lua_State *L)
{
	push_fix(L, fx_atan2x(lua_tofix(L, 1), lua_tofix(L, 2), fractional_bit_count));
	return 1;
}
static int fix_deg(lua_State *L)
{
	push_fix(L, fx_rad_to_deg(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}
static int fix_rad(lua_State *L)
{
	push_fix(L, fx_deg_to_rad(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}
static int fix_sqrt(lua_State *L)
{
	push_fix(L, fx_sqrtx(lua_tofix(L, 1), fractional_bit_count));
	return 1;
}

static int fix_exp(lua_State *L)
{
	push_fix(L, fx_expx(lua_tofix(L, 1), fractional_bit_count));
	return 1;	
}
static int fix_log(lua_State *L)
{
	if(lua_isnoneornil(L, 2))
	{
		push_fix(L, fx_logx(lua_tofix(L, 1), fractional_bit_count));
	}
	else
	{
		push_fix(L, fx_divx(fx_logx(lua_tofix(L, 1), fractional_bit_count), fx_logx(lua_tofix(L, 2), fractional_bit_count), fractional_bit_count));
	}
	
	return 1;
}

// For internal use before precompile
/*static int l_output_predefined_values(lua_State *L)
{
	output_predefined_values();
	lua_pushnil(L);
	return 1;
}*/


#ifdef WIN32
#define LUA_LIB_API __declspec(dllexport)
#else
#define LUA_LIB_API
#endif

const luaL_Reg lua_fixmath_meta_methods[] = {
	{"__add",   fix_add},
	{"__sub",   fix_sub},
	{"__mul",   fix_mul},
	{"__div",   fix_div},
	{"__mod",   fix_mod},
	{"__pow",   fix_pow},
	{"__unm",   fix_unm},
	{"__idiv",   fix_idiv},
	{"__lt",   fix_lt},
	{"__le",   fix_le},
	{"__eq",   fix_eq},
	{"__tostring",   fix_tostring},
	{NULL, NULL}
};

const luaL_Reg lua_fixmath_modules[] = {
	{"tofix",   l_tofix},
	{"tostring",   fix_tostring},
	{"tonumber",   fix_tostring},
	{"rawvalue",   fix_rawvalue},
	{"abs",   fix_abs},
	{"floor",   fix_floor},
	{"ceil",   fix_ceil},
	{"min",   fix_min},
	{"max",   fix_max},
	{"sin",   fix_sin},
	{"cos",   fix_cos},
	{"tan",   fix_tan},
	{"asin",   fix_asin},
	{"acos",   fix_acos},
	{"atan",   fix_atan},
	{"atan2",   fix_atan2},
	{"deg",   fix_deg},
	{"rad",   fix_rad},
	{"sqrt",   fix_sqrt},
	{"exp",   fix_exp},
	{"log",   fix_log},
	//{"output_predefined_values", l_output_predefined_values}, // For internal use before precompile
	{NULL, NULL}
};

static void fill_meta(lua_State *L)
{
	luaL_setfuncs(L, lua_fixmath_meta_methods, 0);
	luaL_newlib(L, lua_fixmath_modules);
  	lua_setfield(L, -2, "__index");
}

static void create_meta(lua_State *L)
{
	if(luaL_newmetatable (L, __METATABLE_NAME) != 0)
	{
		fill_meta(L);
	}
}

LUA_LIB_API int luaopen_fixmath(lua_State* L)
{
    	luaL_newlib(L, lua_fixmath_modules);
    	push_fix(L, fix_pi);
  	lua_setfield(L, -2, "pi");
      	push_fix(L, fix_maximum);
  	lua_setfield(L, -2, "maxvalue");
      	push_fix(L, fix_minimum);
  	lua_setfield(L, -2, "minvalue");
	return 1;
}

#if __cplusplus
}
#endif