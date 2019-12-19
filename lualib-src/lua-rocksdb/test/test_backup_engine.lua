print("***** start: backup_engine test *****")
local rocksdb = require("rocksdb")
local format = string.format
local db_path = "/tmp/rocksdb.test"

local options = rocksdb.options({
  increase_parallelism = 1,
  create_if_missing = true
})

assert(options.class == "options")
local db = rocksdb.open(options, db_path)
local backup_engine = rocksdb.backup_engine(options, db_path.."-backup")
assert(backup_engine.class == "backup_engine")
assert(backup_engine:create_new_backup(db))
assert(backup_engine:purge_old_backups(1))
local count = backup_engine:get_backup_info_count()
print("count: "..count)
local info = backup_engine:get_backup_info(count)
for k,v in pairs(info) do
  print(k..": "..tostring(v))
end

local restoreoptions = rocksdb.restoreoptions({
  keep_log_files = 1
})
backup_engine:restore_db_from_latest_backup(db_path, db_path, restoreoptions);

backup_engine:close()
print("***** done: backup_engine test *****")

