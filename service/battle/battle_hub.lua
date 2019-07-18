local skynet = require "skynet"
require "skynet.manager"
local settings = require "settings"

local skynet_node_name = ...

local CMD = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
    
    skynet.register('.' .. SERVICE_NAME)
end)