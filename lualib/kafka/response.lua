-- Copyright (C) Dejiang Zhu(doujiang24)


local request = require "kafka.request"

local setmetatable = setmetatable
local byte = string.byte
local sub = string.sub
local strbyte = string.byte


local _M = {}
local mt = { __index = _M }

local bytes_to_int = {}

local unpack = string.unpack
function bytes_to_int.little(str)
    return (unpack('!1<I' .. string.len(str), str))
end

function bytes_to_int.big(str)
    return (unpack('!1>I' .. string.len(str), str))
end


function _M.read(self, n)
    n = n or self.len
    if n < 0 then 
        return 
    end

    local last_index = n ~= nil and self.offset + n - 1 or -1

    local bytes = sub(self.str, self.offset, last_index)
    self.offset = self.offset + #bytes
    return bytes
end


function _M.new(self, str, api_version)
    api_version = api_version or request.API_VERSION_V0

    local resp = setmetatable({
        str = str,
        offset = 1,
        correlation_id = 0,
        api_version = api_version,
    }, mt)

    resp.correlation_id = resp:int32()

    return resp
end

function _M.int16(self)
    return bytes_to_int.big(self:read(2))
end

local function to_int32(str)
    assert(#str == 4)
    return bytes_to_int.big(str)
end
_M.to_int32 = to_int32


function _M.int32(self)
    return bytes_to_int.big(self:read(4))
end

function _M.int64(self)
    return bytes_to_int.big(self:read(8))
end

function _M.string(self)
    local len = self:int16()

    local offset = self.offset
    self.offset = offset + len

    return sub(self.str, offset, offset + len - 1)
end

function _M.bytes(self)
    local len = self:int32()

    local offset = self.offset
    self.offset = offset + len

    return sub(self.str, offset, offset + len - 1)
end

function _M.correlation_id(self)
    return self.correlation_id
end


return _M
