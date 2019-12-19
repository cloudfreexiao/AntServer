#include "lrocksdb_iter.h"

LUALIB_API int lrocksdb_iter_reg(lua_State *L) {
  lrocksdb_createmeta(L, "iterator", iter_reg);
  return 1;
}

lrocksdb_iterator_t *lrocksdb_get_iter(lua_State *L, int index) {
  lrocksdb_iterator_t *i = (lrocksdb_iterator_t *) luaL_checkudata(L, index, "iterator");
  luaL_argcheck(L, i != NULL && i->iter != NULL, index, "iterator expected");
  return i;
}

LUALIB_API int lrocksdb_iter_valid(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  unsigned char valid = rocksdb_iter_valid(i->iter);
  lua_pushboolean(L, valid);
  return 1;
}

LUALIB_API int lrocksdb_iter_seek_to_first(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  rocksdb_iter_seek_to_first(i->iter);
  return 1;
}

LUALIB_API int lrocksdb_iter_seek_to_last(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  rocksdb_iter_seek_to_last(i->iter);
  return 1;
}

LUALIB_API int lrocksdb_iter_seek(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  size_t klen;
  const char* k = luaL_checklstring(L, 2, &klen);
  rocksdb_iter_seek(i->iter, k, klen);
  return 1;
}

LUALIB_API int lrocksdb_iter_next(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  rocksdb_iter_next(i->iter);
  return 1;
}

LUALIB_API int lrocksdb_iter_prev(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  rocksdb_iter_prev(i->iter);
  return 1;
}
LUALIB_API int lrocksdb_iter_key(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  lrocksdb_assert(L, rocksdb_iter_valid(i->iter), "invalid iterator");
  size_t klen;
  const char* key = rocksdb_iter_key(i->iter, &klen);
  if(key != NULL) {
    lua_pushlstring(L, key, klen);
  }
  else {
    lua_pushnil(L);
  }
  return 1;
}

LUALIB_API int lrocksdb_iter_value(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  lrocksdb_assert(L, rocksdb_iter_valid(i->iter), "invalid iterator");
  size_t vlen;
  const char *value = rocksdb_iter_value(i->iter, &vlen);
  if(value != NULL) {
    lua_pushlstring(L, value, vlen);
  }
  else {
    lua_pushnil(L);
  }
  return 1;
}
LUALIB_API int lrocksdb_iter_get_error(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  char *err = NULL;
  rocksdb_iter_get_error(i->iter, &err);
  if(err != NULL) {
    lua_pushstring(L, err);
    free(err);
  }
  else {
    lua_pushnil(L);
  }
  return 1;
}

LUALIB_API int lrocksdb_iter_destroy(lua_State *L) {
  lrocksdb_iterator_t *i = lrocksdb_get_iter(L, 1);
  if(i->iter != NULL) {
    rocksdb_iter_destroy(i->iter);
    i->iter = NULL;
  }
  return 1;
}
