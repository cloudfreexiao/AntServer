local class	   =  require "class"
local Battle   = class("Battle")

local M = {}

local _battled = nil
local _handler = nil 

function M.join(args)
    -- local ok, subid = pcall(cluster.call, server, hub, "access", {uid = uid, secret = secret, serverId = tostring(serverId),})
	-- if not ok then
	-- 	error("login gameserver error")
    -- end
end

function Battle:initialize(data)
	_handler = data.handler
	_battled = data.proxy

	_handler.handler().join = M.join
end


return Battle