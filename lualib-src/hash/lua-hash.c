#include <string.h>
#include <stdio.h>
#include <stdint.h>

#include <lua.h>
#include <lauxlib.h>


#define MAX_DEPTH 16

static int
_hash_number(lua_State *L, int index) {
  if (lua_isinteger(L, index)) {
    lua_Integer v = lua_tointeger(L, index);
    if (v != (int32_t)v) {
      uint64_t value = v;
      return (int)(value ^ (value >> 32));
    } else
      return (int)v;
  } else {
    double n = lua_tonumber(L, index);
    uint64_t value;
    memcpy(&value, &n, sizeof(n));
    return (int)(value ^ (value >> 32));
  }
}

static int
_hash_boolean(lua_State *L, int index) {
  int v = lua_toboolean(L, index);
  return v ? 1231 : 1237;
}

static int
_hash_string(lua_State *L, int index) {
  size_t len;
  const char* str = lua_tolstring(L, index, &len);
  int h = 0;
  int i=0;
  for (i=0; i<len; i++) {
    h = 31 * h + str[i];
  }
  return h;
}

static int _hash_table(lua_State *L, int index, int depth);

static int
_hash_one(lua_State *L, int index, int depth) {
  if (depth > MAX_DEPTH) {
    luaL_error(L, "Can't hash too depth table");
  }
  int type = lua_type(L, index);
  switch(type) {
  case LUA_TNUMBER:
    return _hash_number(L, index);
    break;
  case LUA_TBOOLEAN:
    return _hash_boolean(L, index);
    break;
  case LUA_TSTRING:
    return _hash_string(L, index);
    break;
  case LUA_TTABLE:
    return _hash_table(L, index, depth + 1);
    break;
  default:
    luaL_error(L, "Wrong type %s to evaluate hash code", lua_typename(L, type));
  }
}

static int
_hash_table(lua_State *L, int index, int depth) {
  if (index < 0) {
    index = lua_gettop(L) + index + 1;
  }
  if (luaL_getmetafield(L, index, "__pairs") != LUA_TNIL) {
    int h = 0;
    lua_pushvalue(L, index);
    lua_call(L, 1, 3);
    for (;;) {
      lua_pushvalue(L, -2);
      lua_pushvalue(L, -2);
      lua_copy(L, -5, -3);
      lua_call(L, 2, 2);
      int type = lua_type(L, -2);
      if (type == LUA_TNIL) {
        lua_pop(L, 4);
        break;
      }
      int kh = _hash_one(L, -2, depth);
      int vh = _hash_one(L, -1, depth);
      h += (kh ^ vh);
      lua_pop(L, 1);
    }
    return h * depth;
  } else {
    lua_pushnil(L);
    int h = 0;
    while (lua_next(L, index) != 0) {
      int kh = _hash_one(L, -2, depth);
      int vh = _hash_one(L, -1, depth);
      h += (kh ^ vh);
      lua_pop(L, 1);
    }
    return h * depth;
  }
}

static int
lhash_table(lua_State *L) {
  if (!lua_istable(L, 1)) {
    return luaL_error(L, "Argument must be table");
  }
  int h = _hash_table(L, 1, 1);
  lua_pushinteger(L, h);
  return 1;
}

static const struct luaL_Reg funcs[] = {
  { "hashcode", lhash_table },
  { NULL        , NULL }
};

int
luaopen_hash(lua_State *L) {
  luaL_newlib(L, funcs);
  return 1;
}
