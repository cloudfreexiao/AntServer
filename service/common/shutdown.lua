local skynet = require "skynet"
require "skynet.manager"

-- 属于哪种节点 关服操作
local name = ...
local CMD = {}


function CMD.shutdown()
    --TODO: 增加其他关服操作 
    DEBUG("do shutdown " .. name)
    if name == "battle" then
    elseif name == "game" then
    end
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
