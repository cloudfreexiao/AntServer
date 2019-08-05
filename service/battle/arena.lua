local skynet = require "skynet"
require "skynet.manager"

local client = require "service.client_udp"
local input = require "arena.input"

local CMD = {}

function CMD.bind(U)
    client.init(U)
end

function CMD.dispatch(U, msg)
    client.dispatch(U, msg)
end

function CMD.free()
    -- 是否 有足够位置 TODO:
    return true
end

function CMD.ping()
    DEBUG("======ping=====")
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
end)