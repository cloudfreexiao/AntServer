local dbproxyx = require 'dbproxyx'
local account_db_key = require "dbset".account_db_key

local settings = require "settings"

local login_const = require "logind.login_const"


local M = {}


function gen_real_openid(openId, sdk, pf)
    return string.format("%d_%d_%s", pf, sdk, openId)
end

function M.get_real_openid(openId, sdk, pf)
    if sdk == login_const.sdk.debug then
        -- TODO: 写相关操作日志
    end

    local uin = gen_real_openid(openId, sdk, pf)
    local data = dbproxyx.get(account_db_key.tbname, account_db_key.cname, uin)
    if not data then
        data = {
            uin = uin,
            data = {
                openId = openId,
                sdk = sdk,
                pf = pf,
            }
        }

        dbproxyx.set(account_db_key.tbname, account_db_key.cname, uin, data)
    end
    return uin
end

function M.cal_node_name(serverId)
    return 'node' .. serverId
end

function M.cal_protocol(protocol)
    if protocol and protocol == 'ws' then
        return 'ws'
    end
    return 'tcp'
end

function M.get_server(serverId, protocol)
    local node_name = M.cal_node_name(serverId)
    local lobbyInfo = settings.nodes[tostring(node_name)]
    local port = lobbyInfo[tostring('gate_port_' .. M.cal_protocol(protocol))]
    return node_name, lobbyInfo.host, port
end

function M.get_server_cfg(serverId, protocol)
    local node_name = M.cal_node_name(serverId)
    local lobbyInfo = settings.nodes[tostring(node_name)]
    local port = lobbyInfo[tostring('gate_port_' .. M.cal_protocol(protocol))]
    return node_name, lobbyInfo.host, port
end


local user_online = {}	-- 记录玩家所登录的服务器

function M.get_user_online(uid)
    return user_online[uid]
end

function M.del_user_online(uid)
    user_online[uid] = nil
end

function M.add_user_online(uid, user)
    user_online[uid] = user
end


return M