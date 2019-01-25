local skynet = require "skynet"
local cluster = require "skynet.cluster"
local crypt = require "skynet.crypt"

local settings = require "settings"

local login = require "logind.loginserver"
local login_auth = require "logind.login_auth"
local login_logic = require "logind.login_logic"


local logind = {
	host = "0.0.0.0",
	port = settings.login_conf.login_port,
	multilogin = false,	-- disallow multilogin
	name = "login_master",
	instance = settings.login_conf.login_slave_cout,
}

function logind.auth_handler(args)
    local args_array = string.split(args, "@")
    local openId = crypt.base64decode(args_array[1])
    local sdk = crypt.base64decode(args_array[2])
    local pf = crypt.base64decode(args_array[3])
    local serverId = crypt.base64decode(args_array[4])
    local userData = crypt.base64decode(args_array[5])
    
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

-- 认证成功后，回调此函数，登录游戏服务器
function logind.login_handler(serverId, uid, pf, secret)
    local server, outerIp = login_logic.get_server(serverId)
    INFO(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	-- only one can login, because disallow multilogin
	local last = login_logic.get_user_online(uid)
	-- 如果该用户已经在某个服务器上登录了，先踢下线
	if last then
		INFO(string.format("call gameserver %s to kick uid=%d subid=%d ...", last.server, uid, last.subid))
		local ok = pcall(cluster.call, last.server, "hub", "kick", {uid = uid, subid = last.subid})
		if not ok then
			login_logic.del_user_online(uid)
		end
	end

	-- login_handler会被并发，可能同一用户在另一处中又登录了，所以再次确认是否登录
	if login_logic.get_user_online(uid) then
		ERROR("user %d is already online", uid)
		error(string.format("user %d is already online", uid))
	end

	INFO(string.format("uid=%s is logging to gameserver %s ...", uid, server))
	local ok, subid = pcall(cluster.call, server, "hub", "signin", {uid = uid, secret = secret})
	if not ok then
		error("login gameserver error")
    end

    login_logic.get_user_online(uid, { subid = subid, server = server })
	return outerIp .. "@" .. uid .. "@" .. subId
end

local CMD = {}

function CMD.logout(data)
    login_logic.del_user_online(data.uid)
    DEBUG("uid:", data.uid, " subid:", data.subid, " is logout")
end


function logind.command_handler(command, source, ...)
	local f = assert(CMD[command])
	return f(source, ...)
end

login(logind)	-- 启动登录服务器