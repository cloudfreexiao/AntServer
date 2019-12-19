local rocksdb = require("rocksdb")
local format = string.format

local options = rocksdb.options({
  increase_parallelism = 1,
  create_if_missing = true
})

assert(options.class == "options")

local db = rocksdb.open(options, "/tmp/rocksdb.test")

local readoptions = rocksdb.readoptions()
local writeoptions = rocksdb.writeoptions()

local key, value, expected_value

for i = 0, 1000 do
  key = format("lrocks_db_key:%d", i)
  value = format("lrocks_db_value:%d", i)
  db:put(writeoptions, key, value)
end

local iterator = db:iterator(readoptions)
assert(iterator:valid() == false)
print("error", iterator:get_error())
iterator:seek_to_first()
assert(iterator:valid() == true)

while iterator:valid() do
  key = iterator:key()
  value = iterator:value()
  iterator:next()
end

iterator:destroy()
db:close()
readoptions:destroy()
writeoptions:destroy()
options:destroy()

