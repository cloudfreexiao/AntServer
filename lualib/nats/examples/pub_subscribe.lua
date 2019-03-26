local nats = require 'nats.nats'
local params = {
    host = '127.0.0.1',
    port = 4222,
}

local client = nats.connect(params)
local subscribe_id = client:subscribe('foo.*', function(message, reply)
    ERROR('Received data: ', message, reply)
end)
client:wait(3)
client:unsubscribe(subscribe_id)


client:publish('foo', 'bar A')
client:publish('foo', 'bar B')