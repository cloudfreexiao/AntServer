local hprose = require("hprose")
local client = hprose.HttpClient:new("http://127.0.0.1:4321")
client.timeout = 30000
local stub = client:useService()
print(stub.hello("world"))
print(stub.hello("hprose"))

local foo_service = client:useService(nil, "foo")
print(foo_service.say("foo"))

local bar_service = client:useService("http://127.0.0.1:4321", "bar")
print(bar_service.say("bar"))
