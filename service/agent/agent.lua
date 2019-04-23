local skynet = require "skynet"
local service = require "service.service"
-- local client = require "agent.client"

local world = require "agent.world"

local agent = {}
local data = {}
-- local cli = client.handler()

-- function cli:ping()
-- 	assert(self.login)
-- 	DEBUG("cli ping")
-- end

-- function cli:login(args)
-- 	-- TODO:验证 args 是否正确
-- 	assert(not self.login)
-- 	if data.fd then
-- 		DEBUG(string.format("login fail %s fd=%d", data.userid, self.fd))
-- 		return {res = SYSTEM_ERROR.invalid_action}
-- 	end
-- 	data.fd = self.fd
-- 	self.login = true
-- 	DEBUG(string.format("login succ %s fd=%d", data.userid, self.fd))
-- 	client.push(self, "push", { text = "welcome" })	-- push message to client
-- 	return {res = SYSTEM_ERROR.success}
-- end

-- local function new_user(fd)
-- 	local ok, error = pcall(client.dispatch , { fd = fd })
-- 	ERROR("fd=", fd, "is gone. error:", error)
-- 	client.close(fd)
-- 	if data.fd == fd then
-- 		data.fd = nil
-- 		skynet.sleep(1000)	-- exit after 10s
-- 		if data.fd == nil then
-- 			-- double check
-- 			if not data.exit then
-- 				data.exit = true	-- mark exit
-- 				skynet.call(service.manager, "lua", "exit", data.userid)	-- report exit
-- 				DEBUG(string.format("user %s afk", data.userid) )
-- 				skynet.exit()
-- 			end
-- 		end
-- 	end
-- end

-- function agent.assign(fd, userid)
-- 	if data.exit then
-- 		return false
-- 	end
-- 	if data.userid == nil then
-- 		data.userid = userid
-- 	end
-- 	assert(data.userid == userid)
-- 	skynet.fork(new_user, fd)
-- 	return true
-- end


local agent_controller = require "agent.agent_controller":new({})


service.init {
	command = agent,
	info = data,
	world = world,
	init =  function ()
		-- client.init "proto"
		world.start(agent_controller)
	end,
}

