local skynet = require "skynet"
local cluster = require "skynet.cluster"
local crypt = require "skynet.crypt"

local settings = require "settings"

local login = require "logind.loginserver"
local login_auth = require "logind.login_auth"
local login_logic = require "logind.login_logic"


local logind = {
	host = "0.0.0.0",
	port = settings.login_conf.login_port_tcp,
	multilogin = false,	-- disallow multilogin
	name = "login_master",
	instance = settings.login_conf.login_slave_cout,
}

function logind.auth_handler(args)
    local args_array = string.split(args, "$")
    local openId = crypt.base64decode(args_array[1])
	local sdk = crypt.base64decode(args_array[2])
	local serverId = crypt.base64decode(args_array[3])
	local pf = crypt.base64decode(args_array[4])
	local protocol = crypt.base64decode(args_array[5])
    local userData = crypt.base64decode(args_array[6])
    
	DEBUG("login auth_handler openId:", openId, " sdk:", sdk, " pf:", pf, " serverId:", serverId, " userData:", userData)
	local ret, newOpenId = login_auth(openId, sdk, userData)
	if not ret then
		error("login auth failed")
    end
    if newOpenId then
        openId = newOpenId
    end
    local uid = login_logic.get_real_openid(openId, sdk, pf)
	return serverId, uid, pf, protocol
end

-- 认证成功后，回调此函数，登录游戏服务器
function logind.login_handler(serverId, uid, pf, protocol, secret)
    local server, host, port = login_logic.get_server(serverId, protocol)
	local hub = ".hub"
	secret = crypt.hexencode(secret)
	-- only one can login, because disallow multilogin
	local last = login_logic.get_user_online(uid)
	if last then
		cluster.send(last.server, hub, "kick", {uid = uid,})
		login_logic.del_user_online(uid)
	end

	-- login_handler会被并发，可能同一用户在另一处中又登录了，所以再次确认是否登录
	if login_logic.get_user_online(uid) then
		ERROR("user %d is already online", uid)
		error(string.format("user %d is already online", uid))
	end

	local ok, subid = pcall(cluster.call, server, hub, "access", {uid = uid, secret = secret, })
	if not ok then
		error("login gameserver error")
    end

    login_logic.get_user_online(uid, { subid = subid, server = server })
	local token = host .. "$" .. port .. "$" .. uid .. "$" .. secret .. "$" .. subid
	DEBUG("Auth Sucess token:", token)
	return token
end

local CMD = {}

function CMD.logout(data)
    login_logic.del_user_online(data.uid)
    DEBUG("uid:", data.uid, " is logouted")
end

function logind.command_handler(command, source, ...)
	local f = assert(CMD[command])
	return f(source, ...)
end

login(logind)	-- 启动登录服务器