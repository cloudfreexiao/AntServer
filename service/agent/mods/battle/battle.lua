local skynet = require "skynet"
local cluster = require "skynet.cluster"

local settings = require "settings"

local class	   =  require "class"
local Battle   = class("Battle")

local sessions = require "globals.sessions.init"

local M = {}

local _battled = nil
local _handler = nil


function M.join(args)
    for _, _ in pairs(settings.battles) do
        local addr = assert(sessions.get_proxy("battle1d")) --v.battled_name))
        local ok, session, arena = skynet.call(addr, "lua", "register", sessions.fill_arena_data(args))
        if ok then
            cluster.call(arena.battle_node, arena.arena_addr, "ping")
            return SYSTEM_ERROR.success, session
        end
    end
    return SYSTEM_ERROR.arena_forbid
end

function Battle:test()
    assert(false)
end

function Battle:initialize(data)
	_handler = data.handler
	_battled = data.proxy

	_handler.handler().join = M.join
end


return Battle