#include "lrocksdb_helpers.h"

#if !defined LUA_VERSION_NUM || LUA_VERSION_NUM==501
LUALIB_API void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
  luaL_checkstack(L, nup+1, "too many upvalues");
  for (; l->name != NULL; l++) {  /* fill the table with given functions */
    int i;
    lua_pushstring(L, l->name);
    for (i = 0; i < nup; i++)  /* copy upvalues to the top */
      lua_pushvalue(L, -(nup+1));
    lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
    lua_settable(L, -(nup + 3));
  }
  lua_pop(L, nup);  /* remove upvalues */
}
#endif

LUALIB_API int lrocksdb_createmeta(lua_State *L, const char *name, const luaL_Reg *methods) {
  if (!luaL_newmetatable(L, name)) {
    return 0;
  }

  lua_pushstring(L, "__index");
  lua_newtable(L);
  lua_pushstring(L, "class");
  lua_pushstring(L, name);
  lua_rawset(L, -3);
  for (; methods->name; methods++) {
    lua_pushstring(L, methods->name);
    lua_pushcfunction(L, methods->func);
    lua_rawset(L, methods->name[0] == '_' ? -5: -3);
  }
  lua_rawset(L, -3);
  lua_pop(L, 1);
  return 1;
}


LUALIB_API void lrocksdb_setmeta(lua_State *L, const char *name) {
  luaL_getmetatable(L, name);
  lua_setmetatable(L, -2);
}


void lrocksdb_assert(lua_State *L, int cond, const char *msg) {
  if(!cond) {
    luaL_error(L, msg);
  }
}

