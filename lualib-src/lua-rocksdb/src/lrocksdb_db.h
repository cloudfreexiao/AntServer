#ifndef LROCKSDB_DB_H
#define LROCKSDB_DB_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "lauxlib.h"

#include "lrocksdb_helpers.h"
#include "lrocksdb_types.h"
#include "lrocksdb_options.h"

lrocksdb_t *lrocksdb_get_db(lua_State *L, int index);
LUALIB_API int lrocksdb_reg(lua_State *L);
LUALIB_API int lrocksdb_open(lua_State *L);
LUALIB_API int lrocksdb_put(lua_State *L);
LUALIB_API int lrocksdb_get(lua_State *L);
LUALIB_API int lrocksdb_close(lua_State *L);
LUALIB_API int lrocksdb_open_for_read_only(lua_State *L);
LUALIB_API int lrocksdb_delete(lua_State *L);
LUALIB_API int lrocksdb_write(lua_State *L);
LUALIB_API int lrocksdb_create_iterator(lua_State *L);
LUALIB_API int lrocksdb_property_value(lua_State *L);

#endif
