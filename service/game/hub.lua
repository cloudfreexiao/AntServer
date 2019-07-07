local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

local User_Map = {}
local subid = 1

function CMD.kick(user)
    --TODO: do kick action
    User_Map[user.uid] = nil
end

function CMD.handshake(token)
    --TODO: 超时处理 长时间 登陆验证成功但是不 进入游戏token
    subid = subid + 1
    User_Map[token.uid] = {token = token, tm = os.time(),}
    return subid
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)

    skynet.register('.' .. SERVICE_NAME)
end)