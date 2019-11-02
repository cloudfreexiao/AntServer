local class		=  require "class"
local Profile   = class("Profile")

local M = {}

local _profiled = nil
local _handler = nil

function M.heartbeat(args)
end

--创建角色
function M.born(args)
	--TODO: 检查 角色是否是屏蔽字
	-- local ok = skynet.call(".word_crab", "lua", "is_valid", args.name)
	assert(_profiled)
	local data = _profiled:born(args)
	assert(data)

	local cmds = require "cmds.index"
	local g_cmds = cmds:instance()

	g_cmds:trigger_mods({
		profile = data,
		born = {
			name = args.name,
			head = args.head,
			job = args.job,
		}
	})

	_profiled:save()
end

function Profile:initialize(data)
	_handler = data.handler
	_profiled = data.proxy
	_handler.handler().heartbeat = M.heartbeat
	_handler.handler().born = M.born
end


return Profile