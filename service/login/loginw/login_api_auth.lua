local skynet = require 'skynet'
local cluster = require 'skynet.cluster'


local login_auth = require "logind.login_auth"
local login_logic = require "logind.login_logic"

local  M = {}



function M.init()
end


function M.auth(parms)
    openId = parms.openId
    local sdk = parms.sdk
    local pf = parms.pf
    local serverId = parms.serverId
    local userData = parms.userData

	DEBUG("login auth_handler openId:", openId, " sdk:", sdk, " pf:", pf, " serverId:", serverId, " userData:", userData)
	local ret, newOpenId = login_auth(openId, sdk, userData)
	if not ret then
		error("login auth failed")
    end
    if newOpenId then
        openId = newOpenId
    end
    local uid = login_logic.get_real_openid(openId, sdk, pf)
	return serverId, uid, pf
end

--TODO: 
function M.gen_secret()
    return tostring(math.random(1, 1000000))
end

function M.login(parms)
    local serverId, uid, pf = M.auth(parms)
    local secret = M.gen_secret()

    local server, gate, port = login_logic.get_server_cfg(serverId)
    INFO(string.format("%s@%s is login, secret is %s", uid, server, secret))
    -- only one can login, because disallow multilogin
    -- TODO:把 此数据 单独 个 服务
	local last = login_logic.get_user_online(uid)
	-- 如果该用户已经在某个服务器上登录了，先踢下线
	if last then
		INFO(string.format("call gameserver %s to kick uid=%d subid=%d ...", last.server, uid, last.subid))
		local ok = pcall(cluster.call, last.server, "hub", "multilogin", {uid = uid, subid = last.subid})
		if not ok then
			login_logic.del_user_online(uid)
		end
	end

	-- login_handler会被并发，可能同一用户在另一处中又登录了，所以再次确认是否登录
	if login_logic.get_user_online(uid) then
		ERROR("user %d is already online", uid)
	end

	-- 登录游戏服务器
    INFO(string.format("uid=%s is logging to gameserver %s ...", uid, server))
	local ok, subid = pcall(cluster.call, server, "hub", "secret", {uid = uid, secret = secret})
    if not ok then
        ERROR("login call gameserver error")
		error("login call gameserver error")
    end

    login_logic.get_user_online(uid, { subid = subid, server = server })
    return LOGIN_ERROR.login_success, {uid = uid, subId = subId, gate = gate, port = port, secret = secret}
end


return M 
