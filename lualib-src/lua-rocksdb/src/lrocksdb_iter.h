#ifndef LROCKSDB_ITER_H
#define LROCKSDB_ITER_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "lauxlib.h"
#include "lrocksdb_types.h"
#include "lrocksdb_helpers.h"
#include "lrocksdb_options.h"
#include "lrocksdb_db.h"

lrocksdb_iterator_t *lrocksdb_get_iter(lua_State *L, int index);
LUALIB_API int lrocksdb_iter_reg(lua_State *L);
LUALIB_API int lrocksdb_iter_valid(lua_State *L);
LUALIB_API int lrocksdb_iter_seek_to_first(lua_State *L);
LUALIB_API int lrocksdb_iter_seek_to_last(lua_State *L);
LUALIB_API int lrocksdb_iter_seek(lua_State *L);
LUALIB_API int lrocksdb_iter_next(lua_State *L);
LUALIB_API int lrocksdb_iter_prev(lua_State *L);
LUALIB_API int lrocksdb_iter_key(lua_State *L);
LUALIB_API int lrocksdb_iter_value(lua_State *L);
LUALIB_API int lrocksdb_iter_get_error(lua_State *L);
LUALIB_API int lrocksdb_iter_destroy(lua_State *L);

static const struct luaL_Reg iter_reg[] = {
  { "valid", lrocksdb_iter_valid },
  { "seek_to_first", lrocksdb_iter_seek_to_first },
  { "seek_to_last", lrocksdb_iter_seek_to_last },
  { "seek", lrocksdb_iter_seek },
  { "next", lrocksdb_iter_next },
  { "prev", lrocksdb_iter_prev },
  { "key", lrocksdb_iter_key },
  { "value", lrocksdb_iter_value },
  { "get_error", lrocksdb_iter_get_error },
  { "destroy", lrocksdb_iter_destroy },
  { "__gec", lrocksdb_iter_destroy },
  { NULL, NULL }
};

#endif

