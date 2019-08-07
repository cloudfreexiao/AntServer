local skynet = require "skynet"
local cluster = require "skynet.cluster"

local settings = require "settings"

local class	   =  require "class"
local Battle   = class("Battle")

local sessions = require "globals.sessions.init"

local M = {}

local _battled = nil
local _handler = nil
local arena = nil


function M.join(args)
    for _, v in pairs(settings.battles) do
        local addr = assert(sessions.get_proxy("battle1d")) --v.battled_name))
        local ok, session, arena = skynet_timeout_call(10, addr,  "register", sessions.fill_arena_data(args))
        if ok then
            cluster.call(arena.battle_node, arena.arena_addr, "ping")
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