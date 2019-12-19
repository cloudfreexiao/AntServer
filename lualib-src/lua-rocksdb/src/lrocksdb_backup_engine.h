#ifndef LROCKSDB_BACKUP_ENGINE_H
#define LROCKSDB_BACKUP_ENGINE_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "lauxlib.h"
#include "lrocksdb_types.h"
#include "lrocksdb_helpers.h"
#include "lrocksdb_options.h"
#include "lrocksdb_db.h"

lrocksdb_backup_engine_t *lrocksdb_get_backup_engine(lua_State *L, int index);
LUALIB_API int lrocksdb_backup_engine_reg(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_open(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_create_new_backup(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_purge_old_backups(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_restore_db_from_latest_backup(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_get_backup_info_count(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_get_backup_info(lua_State *L);
LUALIB_API int lrocksdb_backup_engine_close(lua_State *L);

static const struct luaL_Reg backup_engine_reg[] = {
  { "create_new_backup", lrocksdb_backup_engine_create_new_backup },
  { "purge_old_backups", lrocksdb_backup_engine_purge_old_backups },
  { "restore_db_from_latest_backup", lrocksdb_backup_engine_restore_db_from_latest_backup },
  { "get_backup_info_count", lrocksdb_backup_engine_get_backup_info_count },
  { "get_backup_info", lrocksdb_backup_engine_get_backup_info },
  { "close", lrocksdb_backup_engine_close },
  { "__gc", lrocksdb_backup_engine_close },
  { NULL, NULL }
};

#endif

