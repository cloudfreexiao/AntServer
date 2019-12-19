#ifndef LROCKSDB_WRITEBATCH_H
#define LROCKSDB_WRITEBATCH_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "lauxlib.h"
#include "lrocksdb_types.h"
#include "lrocksdb_helpers.h"
#include "lrocksdb_options.h"
#include "lrocksdb_db.h"

lrocksdb_writebatch_t *lrocksdb_get_writebatch(lua_State *L, int index);
LUALIB_API int lrocksdb_writebatch_reg(lua_State *L);
LUALIB_API int lrocksdb_writebatch_create(lua_State *L);
LUALIB_API int lrocksdb_writebatch_put(lua_State *L);
LUALIB_API int lrocksdb_writebatch_clear(lua_State *L);
LUALIB_API int lrocksdb_writebatch_count(lua_State *L);
LUALIB_API int lrocksdb_writebatch_merge(lua_State *L);
LUALIB_API int lrocksdb_writebatch_destroy(lua_State *L);

static const struct luaL_Reg writebatch_reg[] = {
  { "put", lrocksdb_writebatch_put },
  { "clear", lrocksdb_writebatch_clear },
  { "count", lrocksdb_writebatch_count },
  { "merge", lrocksdb_writebatch_merge },
  { "destroy", lrocksdb_writebatch_destroy },
  { "__gc", lrocksdb_writebatch_destroy },
  { NULL, NULL }
};

#endif

