--
-- Description: 服务管理

local skynet = require "skynet"
require "skynet.manager"

local lua_pre_path = "skynet_api."
local Object = require(lua_pre_path .. "object")
local MessageDispatcher = require(lua_pre_path .. "message_dispatcher")
local MessageHandler = require(lua_pre_path .. "message_handler")

local g_objects = Object.new()



local skynet_service = {}

function skynet_service.init(mod)
	if mod.info then
		skynet.info_func(function()
			return mod.info
		end)
    end

	skynet.start(function()
		if mod.require then
			local s = mod.require
			for _, name in ipairs(s) do
				skynet_service[name] = skynet.uniqueservice(name)
			end
		end

		if mod.init then
			mod.init()
		end

        local message_dispatcher = MessageDispatcher.new()
        local message_handler = MessageHandler.new(message_dispatcher)

        g_objects:add(message_handler)
        g_objects:hotfix()

        skynet.dispatch("lua", message_dispatcher:dispatch_message())
	end)
end

return skynet_service
