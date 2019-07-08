

local service = require "service.service"
local client = require "service.client"

local fd, ip, protocol, secret = ...
local Session = {
	fd = tonumber(fd),
	ip = tostring(ip),
	protocol = protocol,
	secret = secret,
}

local Data = {}
local CMD = {}

-- local auth = client.handler()

function CMD.start()
	DEBUG("agent is starting")
	-- client:push("push", { text = "welcome" })	-- push message to client
end

service.init {
	command = CMD,
	info =  Data,
	init =  client.init("proto", protocol, true),
}
