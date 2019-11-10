-- @Description: 节点内消息的处理

local skynet = require "skynet"
local class = require "class"

local MessageHandler = class("MessageHandler")

---------------------------------------------------------
-- Private
---------------------------------------------------------
function MessageHandler:initialize(message_dispatch)
	self._message_dispatch = message_dispatch

    self:register()

	--定时查看本服务逻辑是否发生改变
	skynet.fork(function()
		while true do
			skynet.sleep(200)
			self:test()
		end
	end)
end

--注册本服务里的消息
function MessageHandler:register()

	self._message_dispatch:register_cmd_callback('start', handler(self, self.start))
	self._message_dispatch:register_cmd_callback('hotfix_test', handler(self, self.on_hotfix_text))
end

function MessageHandler:test()
	skynet.error("_测试输出____test________")
end


---------------------------------------------------------
-- CMD
---------------------------------------------------------
function MessageHandler:start()
	skynet.error("_____manager_service__start________")
end

function MessageHandler:on_hotfix_text(data)
	skynet.error("______onHotfixText____data:", data)
	-- skynet.debug("__________data________",data)
end



return MessageHandler