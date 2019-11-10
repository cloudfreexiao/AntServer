--
-- @Description: 消息的派发

local skynet = require "skynet"
local queue = require "skynet.queue"


local class = require "class"

local MessageDispatcher = class("MessageDispatcher")
---------------------------------------------------------
-- Private
---------------------------------------------------------
function MessageDispatcher:initialize()
	self._cmd_callback_map = {}
	self._cs = queue()
end

--注册本服务里的消息
function MessageDispatcher:register_cmd_callback(cmd, callback)
	if not callback or type(callback) ~= 'function' then
		skynet.error("注册的函数回调不对___", cmd)
		return
    end
    if self._cmd_callback_map[cmd] then
        skynet.error("已经注册过函数回调", cmd)
        return
    end

	self._cmd_callback_map[cmd] = callback
end

--消息派发
function MessageDispatcher:dispatch_message(session, source, cmd, ... )
	local func = self._cmd_callback_map[cmd] -- gate是否有handler
	if not func then
		skynet.error("cmd:[", cmd "]not found session:[", session, "] source:[", source, "]")
		return
	end

	if func then
		skynet.retpack(xx_pcall(func, ...))
	else
		skynet.retpack(xx_pcall(self._cmd_callback_map, ...))
	end
end


return MessageDispatcher