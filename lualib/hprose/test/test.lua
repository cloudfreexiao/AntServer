require("hprose.common")
local date = require('hprose.date')
local str = "你好"
print(str:ulen())
print(str:isutf8())
str = "Hello 中国"
print(str:ulen())
print(str:isutf8())

function var_dump(data, max_level, prefix)
    if type(prefix) ~= "string" then
        prefix = ""
    end
    if type(data) ~= "table" then
        print(prefix .. tostring(data))
    else
        print(data)
        if max_level ~= 0 then
            local prefix_next = prefix .. "    "
            print(prefix .. "{")
            for k,v in pairs(data) do
                io.stdout:write(prefix_next .. k .. " = ")
                if type(v) ~= "table" or (type(max_level) == "number" and max_level <= 1) then
                    print(v)
                else
                    if max_level == nil then
                        var_dump(v, nil, prefix_next)
                    else
                        var_dump(v, max_level - 1, prefix_next)
                    end
                end
            end
            print(prefix .. "}")
        end
    end
end

local InputStream = require("hprose.input_stream")
local istream = InputStream:new("你好i321;")
print(istream:readstring(2))
print(istream:readuntil(';'))
local istream2 = InputStream:new("hi")
print(istream2:getc())
print(istream2:getc())
print(istream2:getc())
print(istream2:getc())
print(istream2:getc())
local OutputStream = require("hprose.output_stream")
local ostream = OutputStream:new()
ostream:write("i", 123, ";")
print(ostream)
ostream:mark()
ostream:write("hello")
print(ostream)
ostream:reset()
print(ostream)
local ClassManager = require("hprose.class_manager")
ClassManager.register(OutputStream, "myOutputStream")
print(ClassManager.getClassAlias(getmetatable(ostream)))
for k, v in pairs(getmetatable(ostream)) do
    if type(v) ~= "function" and k:sub(1, 2) ~= "__" then print(k, v) end
end
for k, v in pairs(ostream) do
    print(k, v)
end
local Writer = require("hprose.writer")
local writer = Writer:new(ostream)
writer:serialize(12345)
writer:serialize(1)
writer:serialize(0)
writer:serialize(-1)
writer:serialize(123.45)
writer:serialize(0/0)
writer:serialize(1/0)
writer:serialize(-1/0)
writer:serialize(true)
writer:serialize(false)
writer:serialize(nil)
writer:serialize("")
writer:serialize("A")
writer:serialize("好")
writer:serialize("Hello 中国！")
writer:serialize(string.char(128, 129, 130, 131, 132, 133))
writer:serialize({1,2,3,4,5,6,7,8,9,10,11,12})
writer:serialize({10, 20, nil, 40})
writer:serialize({true, false, nil, "Hello"})
writer:serialize(date(true):tolocal())
writer:serialize(date(false):toutc())
writer:serialize(date(true):copy())
writer:serialize({year = 1997, month = 18, day = 1})
writer:serialize({year = 1970, month = 1, day = 1, hour = 12, min = 12, sec = 56})
writer:serialize({year = 1969, month = 13, day = 1, hour = 12, min = 12, sec = 56, utc = true})
writer:serialize({year = 1980, month = 1, day = 1, hour = 12, min = 12, sec = 56})
writer:serialize({year = 1980, month = 1, day = 1, hour = 12, min = 12, sec = 56, utc = true})
writer:serialize({name = "Tom", age = 18, male = true, married = false })

local User = {}

function User:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = ""
    o.age = 0
    o.male = false
    o.married = false
    return o;
end

ClassManager.register(User, "User")

local user = User:new()
user.name = "Jerry"
user.age = 30
user.male = true
user.married = true

local user2 = User:new()
user2.name = "张三"
user2.age = 32
user2.male = false
user2.married = false

writer:serialize({user, user2, User:new()})

print(ostream)

local Reader = require("hprose.reader")

local reader = Reader:new(InputStream:new(tostring(ostream)))

var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())
var_dump(reader:unserialize())

local hprose = require("hprose")
local client = hprose.HttpClient:new("http://hprose.com/example/index.php")
local stub = client:useService()
var_dump(stub.hello('world'))
var_dump(stub.sum(1, 2, 3, 4))
var_dump(stub.inc())
var_dump(stub.inc())
var_dump(stub.inc())
var_dump(stub.inc())
var_dump(stub.swapKeyAndValue({hello = "world"}))
var_dump(stub.getUserList())
