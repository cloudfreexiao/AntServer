local skynet = require "skynet"
local hash   = require "hash"
local timer = require "timer.timer"

local M = {}

-- mods obj
local _fronts = {}
local _backends = {}
local _hashcodes = {}

local _timers = timer.new(1)

local function do_register_mod(mods, name, pack, data)
    mods[tostring(name)] = require(pack):new(data)
end

local function do_register_fronts(name, pack, data)
    do_register_mod(_fronts, name, pack)
end

local function do_register_backends(name, pack, data)
    do_register_mod(_backends, name, pack, data)
end

function M.reg_profile(handler, session)
    local name = "profile"
    do_register_fronts(name, "mods.profile.profile", handler)
    do_register_backends(name, "mods.profile.profiled", session)
end


function M.get_fronts()
    return _fronts
end

function M.get_backends()
    return _backends
end

function M.get_mod(name)
    return _fronts[tostring(name)], _backends[tostring(name)]
end

function M.get_profile()
    return M.get_mod("profile")
end

function M.reg_mods(handler, data)
    local name = "property"
    do_register_fronts(name, "mods.property.property", handler)
    do_register_backends(name, "mods.property.propertyd", data)
end



function M.synch_msg()
end

function M.load()
end

local function on_mod_save()
    for k, mod in pairs(_backends) do
        local f = mod["save"]
        if f then
            local nhcode = hash.hashcode(mod._data or {})
            local bhashcode = _hashcodes[tostring(k)]
            if (not bhashcode) or (bhashcode ~= nhcode) then
                f(mod)
            end
            _hashcodes[tostring(k)] = nhcode
        end
    end
end

function M.force_save()
    on_mod_save()
end

function M.save()
    -- 启动定时器 检测是否模块属性有变更
    _timers:add_timer(30, function() 
        on_mod_save() 
    end, 
    false,
    0)
end

local function on_mod_update()
end

function M.update()
    _timers:add_timer(1, function() 
        on_mod_update()
    end,
    false,
    0)
end


return M