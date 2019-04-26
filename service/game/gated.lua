

local skynet = require "skynet"

local switch = ...

local gateserver = require ("gate.gateserver_" .. tostring(switch) )
local gate_name = ""

local connection = {} -- fd -> { fd , ip, uid（登录后有）game（登录后有）key（登录后有）}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local handler = {}

function handler.open(_, conf)
	gate_name = conf.name
end

function handler.connect(fd, addr)
	local c = {
		fd = fd,
		ip = addr,
		uid = nil,
		agent = nil,
	}
	connection[fd] = c
	gateserver.openclient(fd)
	DEBUG("New client from: ", addr, " fd: ", fd)
end

function handler.message(fd, msg, sz)
	local c = connection[fd]
	local uid = c.uid
	local source = skynet.self()
	if uid then
		--fd为session，特殊用法
		skynet.redirect(c.agent, source, "client", fd, msg, sz)
	end
end

local CMD = {}

--true/false
function CMD.register(_, data)
	local c = connection[data.fd]
	if not c then
		return false
	end

	c.uid = data.uid
	c.agent = data.agent
	c.key = data.key
	return true
end

local function close_agent(fd)
	local c = connection[fd]
	if c then
		if c.uid then
			-- libcenter.logout(c.uid, c.key)
			-- libagentpool.recycle(c.agent)
		end

		connection[fd] = nil
		gateserver.closeclient(fd)
	end

	return true
end


--true/false
function CMD.kick(_, fd)
	return close_agent(fd)
end

function handler.disconnect(fd)
	return close_agent(fd)
end

function handler.error(fd, msg)
	handler.disconnect(fd)
end

function handler.warning(fd, size)
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)

