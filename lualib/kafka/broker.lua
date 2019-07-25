-- Copyright (C) Dejiang Zhu(doujiang24)

local skynet = require "skynet"
local socket =  require "skynet.socket"
local socketchannel =  require "skynet.socketchannel"

local response = require "kafka.response"
local request = require "kafka.request"


local to_int32 = response.to_int32
local setmetatable = setmetatable


local _M = {}
_M.__index = _M

-- socketchannel 的 dispatch 方法 返回值 第一个值是给 sockchannel 使用的
local function dispatch_resp(sock)
    local header, err = sock:read(4)
    if not header then
        return false, nil, err
    end

    local len = to_int32(header)
    local data, err = sock:read(len)
    if not data then
        return false, nil, err
    end
    return true, response:new(data, request.api_version), nil
end

function _M.connect(host, port, conf, req, cb)
    local obj = {
    }

    obj.__sock = socketchannel.channel {
        host = host or "127.0.0.1",
        port = port or 9092,
        nodelay = true,
        overload = conf.overload,
    }

    setmetatable(obj, _M)
    return obj
end

function _M.send_receive(self, req)
    -- return pcall(self.handle.request, self.handle, req:package(), dispatch_resp)
    return self.__sock:request(req:package(), dispatch_resp)
end


return _M
