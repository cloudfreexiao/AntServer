#include "lrocksdb_options.h"

LUALIB_API int lrocksdb_options_reg(lua_State *L) {
  lrocksdb_createmeta(L, "options", options_reg);
  return 1;
}

LUALIB_API int lrocksdb_writeoptions_reg(lua_State *L) {
  lrocksdb_createmeta(L, "writeoptions", writeoptions_reg);
  return 1;
}

LUALIB_API int lrocksdb_readoptions_reg(lua_State *L) {
  lrocksdb_createmeta(L, "readoptions", readoptions_reg);
  return 1;
}

LUALIB_API int lrocksdb_restoreoptions_reg(lua_State *L) {
  lrocksdb_createmeta(L, "restoreoptions", restoreoptions_reg);
  return 1;
}

void lrocksdb_options_set_from_table(lua_State *L, int index, rocksdb_options_t *opt) {
  int opt_int;
  uint64_t opt_uint64;
  unsigned char opt_bool;

  lua_pushvalue(L, index);
  lua_pushnil(L);
  while (lua_next(L, -2))
  {
    lua_pushvalue(L, -2);
    const char *key = lua_tostring(L, -1);
    /* int options */
    if(strcmp(key, "increase_parallelism") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_increase_parallelism(opt, opt_int);
    }
    else if(strcmp(key, "info_log_level") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_info_log_level(opt, opt_int);
    }
    else if(strcmp(key, "max_open_files") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_max_open_files(opt, opt_int);
    }
    else if(strcmp(key, "num_levels") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_num_levels(opt, opt_int);
    }
    else if(strcmp(key, "level0_file_num_compaction_trigger") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_level0_file_num_compaction_trigger(opt, opt_int);
    }
    else if(strcmp(key, "level0_slowdown_writes_trigger") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_level0_slowdown_writes_trigger(opt, opt_int);
    }
    else if(strcmp(key, "level0_stop_writes_trigger") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_level0_stop_writes_trigger(opt, opt_int);
    }
    else if(strcmp(key, "max_mem_compaction_level") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_max_mem_compaction_level(opt, opt_int);
    }
    else if(strcmp(key, "target_file_size_multiplier") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_target_file_size_multiplier(opt, opt_int);
    }
    else if(strcmp(key, "max_write_buffer_number") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_max_write_buffer_number(opt, opt_int);
    }
    else if(strcmp(key, "min_write_buffer_number_to_merge") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_min_write_buffer_number_to_merge(opt, opt_int);
    }
    else if(strcmp(key, "max_write_buffer_number_to_maintain") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_max_write_buffer_number_to_maintain(opt, opt_int);
    }
    else if(strcmp(key, "max_background_compactions") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_max_background_compactions(opt, opt_int);
    }
    else if(strcmp(key, "max_background_flushes") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_max_background_flushes(opt, opt_int);
    }
    else if(strcmp(key, "table_cache_numshardbits") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_table_cache_numshardbits(opt, opt_int);
    }
    else if(strcmp(key, "table_cache_remove_scan_count_limit") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_table_cache_remove_scan_count_limit(opt, opt_int);
    }
    else if(strcmp(key, "use_fsync") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_use_fsync(opt, opt_int);
    }
    else if(strcmp(key, "access_hint_on_compaction_start") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_access_hint_on_compaction_start(opt, opt_int);
    }
    else if(strcmp(key, "disable_data_sync") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_disable_data_sync(opt, opt_int);
    }
    else if(strcmp(key, "disable_auto_compactions") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_disable_auto_compactions(opt, opt_int);
    }
    else if(strcmp(key, "report_bg_io_stats") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_report_bg_io_stats(opt, opt_int);
    }
    else if(strcmp(key, "compression") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_compression(opt, opt_int);
    }
    else if(strcmp(key, "compaction_style") == 0) {
      opt_int = luaL_checkint(L, -2);
      rocksdb_options_set_compaction_style(opt, opt_int);
    }
    /* bool options */
    else if(strcmp(key, "create_if_missing") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_create_if_missing(opt, opt_bool);
    }
    else if(strcmp(key, "create_missing_column_families") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_create_missing_column_families(opt, opt_bool);
    }
    else if(strcmp(key, "error_if_exists") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_error_if_exists(opt, opt_bool);
    }
    else if(strcmp(key, "paranoid_checks") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_paranoid_checks(opt, opt_bool);
    }
    else if(strcmp(key, "purge_redundant_kvs_while_flush") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_purge_redundant_kvs_while_flush(opt, opt_bool);
    }
    else if(strcmp(key, "allow_os_buffer") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_allow_os_buffer(opt, opt_bool);
    }
    else if(strcmp(key, "allow_mmap_reads") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_allow_mmap_reads(opt, opt_bool);
    }
    else if(strcmp(key, "allow_mmap_writes") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_allow_mmap_writes(opt, opt_bool);
    }
    else if(strcmp(key, "is_fd_close_on_exec") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_is_fd_close_on_exec(opt, opt_bool);
    }
    else if(strcmp(key, "skip_log_error_on_recovery") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_skip_log_error_on_recovery(opt, opt_bool);
    }
    else if(strcmp(key, "advise_random_on_open") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_advise_random_on_open(opt, opt_bool);
    }
    else if(strcmp(key, "use_adaptive_mutex") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_use_adaptive_mutex(opt, opt_bool);
    }
    else if(strcmp(key, "verify_checksums_in_compaction") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_verify_checksums_in_compaction(opt, opt_bool);
    }
    else if(strcmp(key, "inplace_update_support") == 0) {
      opt_bool = lua_toboolean(L, -2);
      rocksdb_options_set_inplace_update_support(opt, opt_bool);
    }
    /* uint64 options */
    else if(strcmp(key, "optimize_for_point_lookup") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_optimize_for_point_lookup(opt, opt_uint64);
    }
    else if(strcmp(key, "optimize_level_style_compaction") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_optimize_level_style_compaction(opt, opt_uint64);
    }
    else if(strcmp(key, "optimize_universal_style_compaction") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_optimize_universal_style_compaction(opt, opt_uint64);
    }
    else if(strcmp(key, "max_total_wal_size") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_max_total_wal_size(opt, opt_uint64);
    }
    else if(strcmp(key, "target_file_size_base") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_target_file_size_base(opt, opt_uint64);
    }
    else if(strcmp(key, "max_bytes_for_level_base") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_max_bytes_for_level_base(opt, opt_uint64);
    }
    else if(strcmp(key, "WAL_ttl_seconds") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_WAL_ttl_seconds(opt, opt_uint64);
    }
    else if(strcmp(key, "WAL_size_limit_MB") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_WAL_size_limit_MB(opt, opt_uint64);
    }
    else if(strcmp(key, "bytes_per_sync") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_bytes_per_sync(opt, opt_uint64);
    }
    else if(strcmp(key, "max_sequential_skip_in_iterations") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_max_sequential_skip_in_iterations(opt, opt_uint64);
    }
    else if(strcmp(key, "delete_obsolete_files_period_micros") == 0) {
      opt_uint64 = luaL_checknumber(L, -2);
      rocksdb_options_set_delete_obsolete_files_period_micros(opt, opt_uint64);
    }
    lua_pop(L, 2);
  }
  lua_pop(L, 1);
}

lrocksdb_options_t *lrocksdb_get_options(lua_State *L, int index) {
  lrocksdb_options_t *o = (lrocksdb_options_t *) luaL_checkudata(L, index, "options");
  luaL_argcheck(L, o != NULL && o->options != NULL, index, "options expected");
  return o;
}

LUALIB_API int lrocksdb_options_create(lua_State *L) {
  lrocksdb_options_t *o = (lrocksdb_options_t *) lua_newuserdata(L, sizeof(lrocksdb_options_t));
  o->options = rocksdb_options_create();
  lrocksdb_setmeta(L, "options");
  if(lua_istable(L, 1)) {
    lrocksdb_options_set_from_table(L, 1, o->options);
  }
  return 1;
}

LUALIB_API int lrocksdb_options_set(lua_State *L) {
  lrocksdb_options_t *o = lrocksdb_get_options(L, 1);
  if(lua_istable(L, 1)) {
    lrocksdb_options_set_from_table(L, 1, o->options);
  }
  return 0;
}

LUALIB_API int lrocksdb_options_destroy(lua_State *L) {
  lrocksdb_options_t *o = lrocksdb_get_options(L, 1);
  if(o->options != NULL) {
    rocksdb_options_destroy(o->options);
    o->options = NULL;
    o = NULL;
  }
  return 0;
}

/* write options */
lrocksdb_writeoptions_t *lrocksdb_get_writeoptions(lua_State *L, int index) {
  lrocksdb_writeoptions_t *o = (lrocksdb_writeoptions_t *) luaL_checkudata(L, index, "writeoptions");
  luaL_argcheck(L, o != NULL && o->writeoptions != NULL, index, "writeoptions expected");
  return o;
}

void lrocksdb_writeoptions_set_from_table(lua_State *L, int index, rocksdb_writeoptions_t *opt) {
  lua_pushvalue(L, index);
  lua_pushnil(L);
  while (lua_next(L, -2))
  {
    lua_pushvalue(L, -2);
    //TODO: const char *key = lua_tostring(L, -1);
    lua_pop(L, 2);
  }
  lua_pop(L, 1);
}

LUALIB_API int lrocksdb_writeoptions_create(lua_State *L) {
  lrocksdb_writeoptions_t *o = (lrocksdb_writeoptions_t *) lua_newuserdata(L, sizeof(lrocksdb_writeoptions_t));
  o->writeoptions = rocksdb_writeoptions_create();
  lrocksdb_setmeta(L, "writeoptions");
  if(lua_istable(L, 1)) {
    lrocksdb_writeoptions_set_from_table(L, 1, o->writeoptions);
  }
  return 1;
}

LUALIB_API int lrocksdb_writeoptions_destroy(lua_State *L) {
  lrocksdb_writeoptions_t *wo = lrocksdb_get_writeoptions(L, 1);
  if(wo != NULL && wo->writeoptions != NULL) {
    rocksdb_writeoptions_destroy(wo->writeoptions);
    wo->writeoptions = NULL;
    wo = NULL;
  }
  return 0;
}
/* read options */
lrocksdb_readoptions_t *lrocksdb_get_readoptions(lua_State *L, int index) {
  lrocksdb_readoptions_t *o = (lrocksdb_readoptions_t *) luaL_checkudata(L, index, "readoptions");
  luaL_argcheck(L, o != NULL && o->readoptions != NULL, index, "readoptions expected");
  return o;
}

void lrocksdb_readoptions_set_from_table(lua_State *L, int index, rocksdb_readoptions_t *opt) {
  lua_pushvalue(L, index);
  lua_pushnil(L);
  while (lua_next(L, -2))
  {
    lua_pushvalue(L, -2);
   //TODO: const char *key = lua_tostring(L, -1);
    lua_pop(L, 2);
  }
  lua_pop(L, 1);
}

LUALIB_API int lrocksdb_readoptions_create(lua_State *L) {
  lrocksdb_readoptions_t *o = (lrocksdb_readoptions_t *) lua_newuserdata(L, sizeof(lrocksdb_readoptions_t));
  o->readoptions = rocksdb_readoptions_create();
  lrocksdb_setmeta(L, "readoptions");
  if(lua_istable(L, 1)) {
    lrocksdb_readoptions_set_from_table(L, 1, o->readoptions);
  }
  return 1;
}

LUALIB_API int lrocksdb_readoptions_destroy(lua_State *L) {
  lrocksdb_readoptions_t *ro = lrocksdb_get_readoptions(L, 1);
  if(ro != NULL && ro->readoptions != NULL) {
    rocksdb_readoptions_destroy(ro->readoptions);
    ro->readoptions = NULL;
    ro = NULL;
  }
  return 1;
}


/* restore options */
lrocksdb_restoreoptions_t *lrocksdb_get_restoreoptions(lua_State *L, int index) {
  lrocksdb_restoreoptions_t *o = (lrocksdb_restoreoptions_t *) luaL_checkudata(L, index, "restoreoptions");
  luaL_argcheck(L, o != NULL && o->restoreoptions != NULL, index, "restoreoptions expected");
  return o;
}

void lrocksdb_restoreoptions_set_from_table(lua_State *L, int index, rocksdb_restore_options_t *opt) {
  lua_pushvalue(L, index);
  lua_pushnil(L);
  while (lua_next(L, -2))
  {
    lua_pushvalue(L, -2);
    const char *key = lua_tostring(L, -1);
    int value = luaL_checkint(L, -2);
    if(strcmp(key, "keep_log_files") == 0) {
      rocksdb_restore_options_set_keep_log_files(opt, value);
    }
    lua_pop(L, 2);
  }
  lua_pop(L, 1);
}

LUALIB_API int lrocksdb_restoreoptions_create(lua_State *L) {
  lrocksdb_restoreoptions_t *o = (lrocksdb_restoreoptions_t*) lua_newuserdata(L,
                                          sizeof(lrocksdb_restoreoptions_t));
  o->restoreoptions = rocksdb_restore_options_create();
  lrocksdb_setmeta(L, "restoreoptions");
  if(lua_istable(L, 1)) {
    lrocksdb_restoreoptions_set_from_table(L, 1, o->restoreoptions);
  }
  return 1;
}

LUALIB_API int lrocksdb_restoreoptions_destroy(lua_State *L) {
  lrocksdb_restoreoptions_t *o = lrocksdb_get_restoreoptions(L, 1);
  if(o != NULL && o->restoreoptions != NULL) {
    rocksdb_restore_options_destroy(o->restoreoptions);
    o->restoreoptions = NULL;
    o = NULL;
  }
  return 1;
}



