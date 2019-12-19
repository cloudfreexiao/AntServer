#ifndef LROCKSDB_H
#define LROCKSDB_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "lauxlib.h"

#include "rocksdb/c.h"
#include "lrocksdb_helpers.h"
#include "lrocksdb_types.h"
#include "lrocksdb_db.h"
#include "lrocksdb_options.h"
#include "lrocksdb_backup_engine.h"
#include "lrocksdb_writebatch.h"
#include "lrocksdb_iter.h"

#define LROCKSDB_VERSION "lua-rocksdb 0.0.1"
#define LROCKSDB_COPYRIGHT "Copyright (C) 2016, Zaher Marzuq"
#define LROCKSDB_DESCRIPTION "RocksDB binding for Lua"

static const struct luaL_Reg  lrocksdb_db_reg[] = {
  { "put", lrocksdb_put },
  { "get", lrocksdb_get },
  { "close", lrocksdb_close },
  { "delete", lrocksdb_delete },
  { "write", lrocksdb_write },
  { "iterator", lrocksdb_create_iterator },
  { "property_value", lrocksdb_property_value },
  { NULL, NULL }
};

static const struct luaL_Reg  lrocksdb_regs[] = {
  { "db", lrocksdb_reg },
  { "options",  lrocksdb_options_reg },
  { "writeoptions",  lrocksdb_writeoptions_reg },
  { "readoptions",  lrocksdb_readoptions_reg },
  { "backup_engine", lrocksdb_backup_engine_reg },
  { "writebatch", lrocksdb_writebatch_reg },
  { "restoreoptions", lrocksdb_restoreoptions_reg },
  { "iterator", lrocksdb_iter_reg },
  { NULL, NULL }
};

static const struct luaL_Reg lrocksdb_funcs[] = {
  { "open", lrocksdb_open },
  { "open_for_read_only", lrocksdb_open_for_read_only },
  { "options", lrocksdb_options_create },
  { "writeoptions", lrocksdb_writeoptions_create },
  { "readoptions", lrocksdb_readoptions_create },
  { "backup_engine", lrocksdb_backup_engine_open },
  { "writebatch", lrocksdb_writebatch_create },
  { "restoreoptions", lrocksdb_restoreoptions_create },
  { NULL, NULL }
};

#endif
