local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
    -- skynet.call(".lobby", "lua", "stopLobby")
    -- pcall(skynet.call, ".world", 'lua', 'stopWorld')
    --TODO: 增加其他关服操作 
end

skynet.start(function()
    skynet.dispatch("lua", function(session, _, cmd, ...)
        local method = CMD[cmd]
        if method then
            if session ~= 0 then
                skynet.ret(skynet.pack(method(...)))
            else
                method(...)
            end
        else
            if session ~= 0 then
                skynet.ret("unknow command : " .. cmd)
            end
        end
    end)

    skynet.register("." .. SERVICE_NAME)
end)
