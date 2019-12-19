print("***** start: writebatch test *****")
local rocksdb = require("rocksdb")
local format = string.format
local db_path = "/tmp/rocksdb.test"

local options = rocksdb.options({
  increase_parallelism = 1,
  create_if_missing = true
})

assert(options.class == "options")
local db = rocksdb.open(options, db_path)
local writeoptions = rocksdb.writeoptions()
local readoptions = rocksdb.readoptions()
local writebatch = rocksdb.writebatch()
local key, val
for i = 1,10 do
  key = format("writebatch:key:%d", i)
  val = format("writebatch:val:%d", i)
  writebatch:put(key, val)
  assert(writebatch:count() == i)
end
db:write(writeoptions, writebatch)
writebatch:clear()
assert(writebatch:count() == 0)
writebatch:destroy()

local dbval = db:get(readoptions, key)
assert(dbval == val)
db:close()
print("***** done: writebatch test *****")

