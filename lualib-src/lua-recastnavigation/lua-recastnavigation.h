#ifndef LUA_NAVIGATION
#define LUA_NAVIGATION


#ifdef __cplusplus
extern "C" {
#endif

	#include "lua.h"
	#include "lualib.h"
	#include "lauxlib.h"

	extern int luaopen_navigator(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif