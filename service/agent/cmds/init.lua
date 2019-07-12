local skynet = require "skynet"
require "skynet.manager"


local class = require "class"
local singleton = require "singleton"
local Commands = class("Commands"):include(singleton)

local mods = require "mods.init"


function Commands:initialize(_handler)
	self._handler = _handler
end

function Commands:start(session)
	self._handler.init(session.fd)

	mods.reg_profile(self._handler, session)

	--检查是否有角色信息
	local _, profiled = mods.get_profile()
	local data = profiled:load()
	if not data then
		return 0
	end

	self:reg_mods({
		handler = self._handler,
		profile = data,
	})
	return 1
end

function Commands:reg_mods(data)
	mods.reg_mods(data)
	mods.load()
	mods.synch_msg()
	mods.save()
	mods.update()
	self._handlers.push_package("verify", {text = "welcome" })
end

function Commands:logout(conn)
	DEBUG("agent is logout", inspect(conn))
	mods.force_save()

	skynet.timeout(500, function()
		skynet.exit()
	end)
end


return Commands