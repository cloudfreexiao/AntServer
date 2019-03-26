local nats = require 'nats.nats'
local params = {
    host = '127.0.0.1',
    port = 4222,
}

local client = nats.connect(params)

skynet.timeout(500, function()
    client:publish('foo.bar', 'bar A')
    client:publish('foo.aa', 'bar C')
    client:publish('foo.SS', 'bar D')
end)

skynet.timeout(600, function()
    client:publish('foo.bar', 'bar B')
    client:publish('foo.ddd', 'bar E')
end)