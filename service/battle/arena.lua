local skynet = require "skynet"
require "skynet.manager"

local client = require "service.client_udp"

local input = require "arena.input"

local CMD = {}

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

local function do_start()
    client.init()
end

skynet.start(function()

    do_start()

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
end)