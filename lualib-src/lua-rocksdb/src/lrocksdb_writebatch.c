#include "lrocksdb_writebatch.h"

LUALIB_API int lrocksdb_writebatch_reg(lua_State *L) {
  lrocksdb_createmeta(L, "writebatch", writebatch_reg);
  return 1;
}

lrocksdb_writebatch_t *lrocksdb_get_writebatch(lua_State *L, int index) {
  lrocksdb_writebatch_t *o = (lrocksdb_writebatch_t*)
                                  luaL_checkudata(L, index, "writebatch");
  luaL_argcheck(L, o != NULL && o->writebatch!= NULL, index, "writebatch expected");
  return o;
}

LUALIB_API int lrocksdb_writebatch_create(lua_State *L) {
  lrocksdb_writebatch_t *rb =
    (lrocksdb_writebatch_t *) lua_newuserdata(L, sizeof(lrocksdb_writebatch_t));
  rb->writebatch = rocksdb_writebatch_create();
  lrocksdb_setmeta(L, "writebatch");
  return 1;
}

LUALIB_API int lrocksdb_writebatch_destroy(lua_State *L) {
  lrocksdb_writebatch_t *rb = lrocksdb_get_writebatch(L, 1);
  if(rb->writebatch != NULL) {
    rocksdb_writebatch_destroy(rb->writebatch);
    rb->writebatch = NULL;
  }
  return 0;
}

LUALIB_API int lrocksdb_writebatch_clear(lua_State *L) {
  lrocksdb_writebatch_t *rb = lrocksdb_get_writebatch(L, 1);
  rocksdb_writebatch_clear(rb->writebatch);
  return 0;
}

LUALIB_API int lrocksdb_writebatch_count(lua_State *L) {
  lrocksdb_writebatch_t *rb = lrocksdb_get_writebatch(L, 1);
  int count = rocksdb_writebatch_count(rb->writebatch);
  lua_pushnumber(L, count);
  return 1;
}

LUALIB_API int lrocksdb_writebatch_put(lua_State *L) {
  lrocksdb_writebatch_t *rb = lrocksdb_get_writebatch(L, 1);
  size_t klen, vlen;
  const char *key = luaL_checklstring(L, 2, &klen);
  const char *val = luaL_checklstring(L, 3, &vlen);
  rocksdb_writebatch_put(rb->writebatch, key, klen, val, vlen);
  return 0;
}

LUALIB_API int lrocksdb_writebatch_merge(lua_State *L) {
  lrocksdb_writebatch_t *rb = lrocksdb_get_writebatch(L, 1);
  size_t klen, vlen;
  const char *key = luaL_checklstring(L, 2, &klen);
  const char *val = luaL_checklstring(L, 3, &vlen);
  rocksdb_writebatch_merge(rb->writebatch, key, klen, val, vlen);
  return 0;
}
