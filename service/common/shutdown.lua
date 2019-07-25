local skynet = require "skynet"
require "skynet.manager"

-- 属于哪种节点 关服操作
local name = ...
local CMD = {}


function CMD.shutdown()
    --TODO: 增加其他关服操作 
    -- https://github.com/cloudwu/skynet/issues/985
    -- 数据库操作相关服务 调用 获取 task 指令 为 0 时  skynet.call(addr, "debug", "TASK")
    DEBUG("do shutdown " .. name)
    -- 先关闭 网关
    -- 有数据的全局服务 强制保存一次
    -- 踢掉玩家
    -- 等待 数据库服务 task 为0 因为它一般是不会有 定时器操作的所以如此处理 会比较简单知道是否已经所有数据都落地保存成功
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
