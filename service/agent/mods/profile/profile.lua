local class		=  require "class"
local Profile   = class("Profile")

local M = {}

function M.heartbeat(args)
	DEBUG("heartbeat", os.time())
end

--创建角色
function M.born(args)
end

function Profile:initialize(data)
	self._handler = data.handler
	self._proxy = data.proxy

	self._handler.heartbeat =  M.heartbeat
	self._handler.born =  M.born
end


return Profile