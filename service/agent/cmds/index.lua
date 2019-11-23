local skynet = require "skynet"
require "skynet.manager"

local singleton = require("singleton")
local Commands = singleton("Commands")

local sessions = require "globals.sessions.init"
local mods = require "mods.index"
local _handler = require "service.client"


function Commands:initialize(protocol)
	self._protocol = protocol
end

function Commands:start(session)
	sessions.session = session

	_handler.init(self._protocol, session.fd)

	mods.reg_profile(_handler, session)

	--检查是否有角色信息
	local _, profiled = mods.get_profile()
	local data = profiled:load()
	if not data then
		return 0
	end

	self:trigger_mods({
		profile = data,
	})
	return 1
end

function Commands:trigger_mods(data)
	sessions.set_uin(data.profile.uin)

	mods.reg_mods(_handler, data)
	mods.load()
	mods.synch_msg()
	mods.save()
	mods.update()
	skynet.timeout(10, function()
		_handler.push_package("verify", {text = "welcome" })
	end)
end

function Commands:logout()
	mods.force_save()
	--TODO: 不做其他处理是否出现问题? fd 保存定时器
	skynet.send(".agent_mgr", "lua", "recycle", skynet.self(), self._protocol)
end

function Commands:call_front_mod(...)
	return mods.call_front_mod(...)
end

function Commands:send_front_mod(...)
	mods.send_front_mod(...)
end

function Commands:call_backend_mod(...)
	return mods.call_backend_mod(...)
end

function Commands:send_front_mod(...)
	mods.send_front_mod(...)
end


return Commands