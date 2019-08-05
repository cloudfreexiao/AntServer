local skynet = require "skynet"
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"

local settings = require "settings"

local client = {}
local handler = {}

local _host = nil
local _sender = nil
local _udp_handler = nil


function client.handler()
	return handler
end

function client.sender()
	return _sender
end

-- resp message to client
function client.resp_package(U, pack, ud, response)
    socket.sendto(_udp_handler, U.from, U.secret .. response(pack, ud))
end

-- push message to client
function client.push_package(U, proto_name, data)
    socket.sendto(_udp_handler, U.from, U.secret .. _sender(proto_name, data, 0, skynet.now()))
end


local function do_request(U, name, request, response)
	local f = handler[name]
	if f then
		-- f may block , so fork and run
		skynet.fork(function()
            local ok, errcode, pack = pcall(f, request)
            if ok then
                errcode = errcode or SYSTEM_ERROR.success
                pack = pack or {}
                client.resp_package(U, pack, errcode, response)
            else
                ERROR("do agent udp rpc command[", name, "] error:", errcode)
            end
		end)
	else
		-- unsupported command, disconnected
		error ("agent invalid client handler " .. name)
	end
end

function client.dispatch(U, msg)
    local type, name, request, response = _host:dispatch(msg)
    if type == "REQUEST" then
		local ok, result = pcall(do_request, U, name, request, response)
		if not ok then
			ERROR("agent dispatch client msg error:", result)
		end
	else
		assert(type == "RESPONSE")
		error "udp client doesn't support request client"
	end
end

function client.init(udp_handler)
    _udp_handler = udp_handler

	local protoloader = skynet.uniqueservice "protoloader"
	local battle = settings.sproto.battle
	local slot1 = skynet.call(protoloader, "lua", "index", battle[1])
	_host = sprotoloader.load(slot1):host "package"

	local slot2 = skynet.call(protoloader, "lua", "index", battle[2])
    _sender = _host:attach(sprotoloader.load(slot2))
end


return client