#ifndef LROCKSDB_OPTIONS_H
#define LROCKSDB_OPTIONS_H
#include <string.h>
#include "lauxlib.h"
#include "lrocksdb_types.h"
#include "lrocksdb_helpers.h"

lrocksdb_options_t *lrocksdb_get_options(lua_State *L, int index);
LUALIB_API int lrocksdb_options_reg(lua_State *L);
LUALIB_API int lrocksdb_options_create(lua_State *L);
LUALIB_API int lrocksdb_options_set(lua_State *L);
LUALIB_API int lrocksdb_options_destroy(lua_State *L);

/* read options */
lrocksdb_readoptions_t *lrocksdb_get_readoptions(lua_State *L, int index);
LUALIB_API int lrocksdb_readoptions_reg(lua_State *L);
LUALIB_API int lrocksdb_readoptions_create(lua_State *L);
LUALIB_API int lrocksdb_readoptions_destroy(lua_State *L);

/* write options */
lrocksdb_writeoptions_t *lrocksdb_get_writeoptions(lua_State *L, int index);
LUALIB_API int lrocksdb_writeoptions_reg(lua_State *L);
LUALIB_API int lrocksdb_writeoptions_create(lua_State *L);
LUALIB_API int lrocksdb_writeoptions_destroy(lua_State *L);

/* flush options */
LUALIB_API int lrocksdb_flushoptions_create(lua_State *L);
LUALIB_API int lrocksdb_flushoptions_destroy(lua_State *L);
LUALIB_API int lrocksdb_flushoptions_set_wait(lua_State *L);

/* restore options */
lrocksdb_restoreoptions_t *lrocksdb_get_restoreoptions(lua_State *L, int index);
LUALIB_API int lrocksdb_restoreoptions_reg(lua_State *L);
LUALIB_API int lrocksdb_restoreoptions_create(lua_State *L);
LUALIB_API int lrocksdb_restoreoptions_destroy(lua_State *L);

static const struct luaL_Reg options_reg[] = {
  { "set", lrocksdb_options_set },
  { "destroy", lrocksdb_options_destroy },
  { "__gc", lrocksdb_options_destroy },
  { NULL, NULL }
};

static const struct luaL_Reg writeoptions_reg[] = {
  { "__gc", lrocksdb_writeoptions_destroy },
  { "destroy", lrocksdb_writeoptions_destroy },
  { NULL, NULL }
};

static const struct luaL_Reg readoptions_reg[] = {
  { "__gc", lrocksdb_readoptions_destroy },
  { "destroy", lrocksdb_readoptions_destroy },
  { NULL, NULL }
};

static const struct luaL_Reg restoreoptions_reg[] = {
  { "__gc", lrocksdb_restoreoptions_destroy },
  { "destroy", lrocksdb_restoreoptions_destroy },
  { NULL, NULL }
};

#endif

