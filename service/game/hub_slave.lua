local skynet = require "skynet"
require "skynet.manager"

local protocol = ...
local hub = ".hubd"

local CMD = {}

function CMD.connect(...)
    skynet_call(hub, "connect", ...)
end

function CMD.logout(conn)
    skynet_send(hub, "logout", conn)
end

function CMD.kick(data)
    skynet_send(hub, "kick", data)
end

------------------------Auth Client Handshake Logic-------------------------------------------
------------------------Auth Client Handshake Logic-------------------------------------------
local client = require ("service.client_" .. protocol)
local auth = client.handler()
function auth.handshake(args, fd)
    return skynet_call(hub, "handshake", fd, args)
end

------------------------Auth Client Handshake Logic-------------------------------------------
------------------------Auth Client Handshake Logic-------------------------------------------

skynet.start(function()
    client.init()

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
end)