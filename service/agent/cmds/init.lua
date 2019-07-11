local skynet = require "skynet"
require "skynet.manager"


local class = require "class"
local singleton = require "singleton"
local Object = class("SessionSingleton"):include(singleton)

local mods = require "mods.init"


function Object:initialize(handlers)
	self._handlers = handlers
end

function Object:start(session)
	self._handlers.init(session.fd)
	mods.reg_mods(self._handlers, session)

	--检查是否有角色信息
	local _, profiled = mods.get_profile()
	local data = profiled:load()
	if not data then
		return 0
	end

	self:reg_mods()
	return 1
end

function Object:reg_mods()
	mods.reg_mods()
	mods.load()
	mods.synch_msg()
	mods.save()
	mods.update()
	self._handlers.push_package("verify", {text = "welcome" })
end

function Object:logout(conn)
	DEBUG("agent is logout", inspect(conn))
	mods.force_save()

	skynet.timeout(500, function()
		skynet.exit()
	end)
end


return Object