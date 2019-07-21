local hprose = require("hprose")

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

local user = User:new()
user.name = "Jerry"
user.age = 30
user.male = true
user.married = true


local person = {
    name = "ALice",
    id = 123,
}

local tick = os.clock();
for i = 1, 10000 do
    hprose.Formatter.unserialize(hprose.Formatter.serialize(person))
end

print(os.clock()-tick)
