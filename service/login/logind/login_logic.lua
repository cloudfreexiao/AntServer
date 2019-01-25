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

function M.get_server(serverId)
    local lobbyInfo = settings.lobbys[tostring(serverId)]
    return lobbyInfo.nodeName .. "node", lobbyInfo.gate_host .. "@" .. lobbyInfo.gate_port
end

function M.get_server_cfg(serverId)
    local lobbyInfo = settings.lobbys[tostring(serverId)]
    return lobbyInfo.nodeName .. "node", lobbyInfo.gate_host, lobbyInfo.gate_port
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