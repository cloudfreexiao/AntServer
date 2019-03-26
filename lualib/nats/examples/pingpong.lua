local nats = require 'nats.nats'
local params = {
    host = '127.0.0.1',
    port = 4222,
}

local client = nats.connect(params)
client:ping()