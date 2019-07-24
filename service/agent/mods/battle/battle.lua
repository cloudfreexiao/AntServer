local skynet = require "skynet"
local settings = require "settings"

local class	   =  require "class"
local Battle   = class("Battle")

local sessions = require "globals.sessions.init"

local M = {}


local _battled = nil
local _handler = nil


function M.join(args)
    for _, v in pairs(settings.battles) do
        local addr = assert(sessions.get_proxy(v.battled_name))
        local ok, session = skynet_timeout_call(5, addr,  "register", sessions.fill_arena_data())
        if ok then
            return SYSTEM_ERROR.success, session
        end
    end
    return SYSTEM_ERROR.arena_forbid
end

function Battle:initialize(data)
	_handler = data.handler
	_battled = data.proxy

	_handler.handler().join = M.join
end


return Battle