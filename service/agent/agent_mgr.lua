local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

local WS = nil
local TCP = nil

local function init()
    WS = skynet.newservice("agent_slave", "ws")
    TCP = skynet.newservice("agent_slave", "tcp")
end

local function get_addr(protocol)
    assert(protocol)
    local addr = TCP
    if protocol == "ws" then
        addr = WS
    end
    return addr
end

function CMD.get(protocol)
    return skynet.call(get_addr(protocol), "lua", "get")
end

function CMD.recycle(agent, protocol)
    skynet.send(get_addr(protocol), "lua", "recycle", agent)
end

skynet.start(function()
    init()

    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)

    skynet.register('.' .. SERVICE_NAME)
end)