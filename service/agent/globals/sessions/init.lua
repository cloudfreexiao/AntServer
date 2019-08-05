local skynet = require "skynet"
local cluster = require "skynet.cluster"
local settings = require "settings"

local M = {
    session = {},
    proxy_map = {},
}


local function proxy_battle()
    M.proxy_map = {}

    for _, v in pairs(settings.battles) do
        local battle_name = v.battle_name
        local proxy = cluster.proxy(battle_name, v.battled_name)
        assert(proxy)
        M.proxy_map[tostring(v.battled_name)] = proxy
    end
end

function M.get_proxy(name)
    return M.proxy_map[tostring(name)]
end

function M.set_uin(uin)
    assert(uin)
    M.session.uin = uin

    proxy_battle()
end

function M.fill_arena_data(data)
    return {
        session = data.session,
        model = data.model,

        uid = M.session.uin,
        secret = M.session.secret,
        ip = M.session.ip,

        agent = skynet.self(),
        skynet_node_name = M.session.skynet_node_name,
    }
end

return M