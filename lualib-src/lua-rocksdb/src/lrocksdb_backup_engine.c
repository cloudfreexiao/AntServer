#include "lrocksdb_backup_engine.h"

LUALIB_API int lrocksdb_backup_engine_reg(lua_State *L) {
  lrocksdb_createmeta(L, "backup_engine", backup_engine_reg);
  return 1;
}

lrocksdb_backup_engine_t *lrocksdb_get_backup_engine(lua_State *L, int index) {
  lrocksdb_backup_engine_t *o = (lrocksdb_backup_engine_t*)
                                  luaL_checkudata(L, index, "backup_engine");
  luaL_argcheck(L, o != NULL && o->backup_engine!= NULL, index, "backup_engine expected");
  return o;
}

LUALIB_API int lrocksdb_backup_engine_open(lua_State *L) {
  lrocksdb_options_t *o = lrocksdb_get_options(L, 1);
  const char *path = luaL_checkstring(L, 2);
  char *err = NULL;
  lrocksdb_backup_engine_t *b = (lrocksdb_backup_engine_t *)
                                lua_newuserdata(L, sizeof(lrocksdb_backup_engine_t));
  b->backup_engine = rocksdb_backup_engine_open(o->options, path, &err);
  if(err) {
    luaL_error(L, err);
    free(err);
    return 0;
  }
  lrocksdb_setmeta(L, "backup_engine");
  return 1;
}

LUALIB_API int lrocksdb_backup_engine_create_new_backup(lua_State *L) {
  lrocksdb_backup_engine_t *be = lrocksdb_get_backup_engine(L, 1);
  lrocksdb_t *db = lrocksdb_get_db(L, 2);
  char *err = NULL;
  rocksdb_backup_engine_create_new_backup(be->backup_engine, db->db, &err);
  if(err) {
    luaL_error(L, err);
    free(err);
    return 0;
  }
  return 1;
}

LUALIB_API int lrocksdb_backup_engine_purge_old_backups(lua_State *L) {
  lrocksdb_backup_engine_t *be = lrocksdb_get_backup_engine(L, 1);
  uint32_t num_backups_to_keep = luaL_checknumber(L, 2);
  char *err = NULL;
  rocksdb_backup_engine_purge_old_backups(be->backup_engine, num_backups_to_keep, &err);
  if(err) {
    luaL_error(L, err);
    free(err);
    return 0;
  }
  return 1;
}

LUALIB_API int lrocksdb_backup_engine_restore_db_from_latest_backup(lua_State *L) {
  lrocksdb_backup_engine_t *be = lrocksdb_get_backup_engine(L, 1);
  const char* db_dir = luaL_checkstring(L, 2);
  const char* wal_dir = luaL_checkstring(L, 3);
  lrocksdb_restoreoptions_t *ro = lrocksdb_get_restoreoptions(L, 4);
  char *err = NULL;
  rocksdb_backup_engine_restore_db_from_latest_backup(be->backup_engine, db_dir,
                                              wal_dir, ro->restoreoptions, &err);
  if(err != NULL) {
    luaL_error(L, err);
    free(err);
    return 0;
  }
  return 1;
}

LUALIB_API int lrocksdb_backup_engine_get_backup_info_count(lua_State *L) {
  lrocksdb_backup_engine_t *be = lrocksdb_get_backup_engine(L, 1);
  const rocksdb_backup_engine_info_t
    *info = rocksdb_backup_engine_get_backup_info(be->backup_engine);
  if(info) {
    int count = rocksdb_backup_engine_info_count(info);
    lua_pushnumber(L, count);
    rocksdb_backup_engine_info_destroy(info);
  }
  return 1;
}

LUALIB_API int lrocksdb_backup_engine_get_backup_info(lua_State *L) {
  lrocksdb_backup_engine_t *be = lrocksdb_get_backup_engine(L, 1);
  int index = luaL_checkint(L, 2) - 1; //keeping with Lua indices start at 1
  const rocksdb_backup_engine_info_t
    *info = rocksdb_backup_engine_get_backup_info(be->backup_engine);
  int count = rocksdb_backup_engine_info_count(info);
  if(index < 0 || index >= count) {
    luaL_error(L, "index out of range");
    rocksdb_backup_engine_info_destroy(info);
  }
  int64_t timestamp = rocksdb_backup_engine_info_timestamp(info, index);
  uint32_t id = rocksdb_backup_engine_info_backup_id(info, index);
  uint64_t size = rocksdb_backup_engine_info_size(info, index);
  uint32_t number_files = rocksdb_backup_engine_info_number_files(info, index);
  rocksdb_backup_engine_info_destroy(info);
  lua_newtable(L);
  lua_pushnumber(L, timestamp);
  lua_setfield(L, -2, "timestamp");
  lua_pushnumber(L, id);
  lua_setfield(L, -2, "id");
  lua_pushnumber(L, size);
  lua_setfield(L, -2, "size");
  lua_pushnumber(L, number_files);
  lua_setfield(L, -2, "number_files");
  return 1;
}

LUALIB_API int lrocksdb_backup_engine_close(lua_State *L) {
  lrocksdb_backup_engine_t *be = lrocksdb_get_backup_engine(L, 1);
  if(be->backup_engine != NULL) {
    rocksdb_backup_engine_close(be->backup_engine);
    be->backup_engine = NULL;
  }
  return 1;
}

