local skynet = require "skynet"
require "skynet.manager"

local protocol, hub = ...

local gateserver = require ("gate.gateserver_" .. protocol )
local gate_name = ""


skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

-----------------------------------------------------
-----------------------------------------------------
local connection = {} -- fd -> { fd , ip, }

local function create_conn_data(fd, ip)
	local conn = {
		fd = fd,
		ip = ip,
		protocol = protocol,
	}

	skynet_call(hub, "connect", skynet.self(), conn)
	return conn
end

-----------------------------------------------------
-----------------------------------------------------

local CMD = {}

function CMD.register(_, data)
	local conn = connection[data.fd]
	if not conn then
		return false
	end
	conn.uid = data.uid
	conn.agent = data.agent
	return true
end

local function close_agent(fd, raw)
	DEBUG("close agent", fd, raw)
	local c = connection[fd]
	if c then
		if not raw then
			skynet_call(hub, "logout", c)
		end
		connection[fd] = nil
		gateserver.closeclient(fd)
	end
	return true
end

function CMD.kick(_, fd, raw)
	return close_agent(fd, raw)
end

-----------------------------------------------------
-----------------------------------------------------

local handler = {}

function handler.open(_, conf)
	gate_name = conf.name
end

function handler.connect(fd, addr)
	connection[fd] = create_conn_data(fd, addr)
	gateserver.openclient(fd)
	DEBUG("New client from:", addr, " fd: ", fd)
end

function handler.message(fd, msg, sz)
	local c = connection[fd]
	local uid = c.uid
	local source = skynet.self()
	if uid then
		--fd为session，特殊用法
		skynet.redirect(c.agent, source, "client", fd, msg, sz)
	else
		skynet.redirect(hub, source, "client", fd, msg, sz)
	end
end

function handler.disconnect(fd)
	return close_agent(fd)
end

function handler.error(fd, msg)
	return handler.disconnect(fd)
end

function handler.warning(fd, size)
	INFO("Gate warning fd:", fd, " size:", size)
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)