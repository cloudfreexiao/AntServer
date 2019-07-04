-- Copyright (C) Dejiang Zhu(doujiang24)

local crc32 = require "kafka.crc32".crc64

local setmetatable = setmetatable
local concat = table.concat
local char = string.char
local tonumber = tonumber


local _M = {}
local mt = { __index = _M }

local MESSAGE_VERSION_0 = 0
local MESSAGE_VERSION_1 = 1

_M.API_VERSION_V0 = 0
_M.API_VERSION_V1 = 1
_M.API_VERSION_V2 = 2

_M.ProduceRequest = 0
_M.FetchRequest = 1
_M.OffsetRequest = 2
_M.MetadataRequest = 3
_M.OffsetCommitRequest = 8
_M.OffsetFetchRequest = 9
_M.ConsumerMetadataRequest = 10


local pack = string.pack

local int_to_bytes = {}
function int_to_bytes.little(num, bytes)
    num = math.fmod(num, 2 ^ (8 * bytes))
    return pack('!1<I' .. bytes, num)
end

function int_to_bytes.big(num, bytes)
    num = math.fmod(num, 2 ^ (8 * bytes))
    return pack('!1>I' .. bytes, num)
end


local function str_int8(int)
    return int_to_bytes.big(int, 1)
end

local function str_int16(int)
    return int_to_bytes.big(int, 2)
end

local function str_int32(int)
    return int_to_bytes.big(int, 4)
end

local function str_int64(int)
    return int_to_bytes.big(int, 8)
end

_M.api_version  = _M.API_VERSION_V0



function _M.new(self, apikey, correlation_id, client_id, api_version)
    local c_len = #client_id

    if not _M.api_version then
        _M.api_version = api_version or _M.API_VERSION_V0
    end

    local req = {
        0,   -- request size: int32
        str_int16(apikey),
        str_int16(_M.api_version),
        str_int32(correlation_id),
        str_int16(c_len),
        client_id,
    }
    return setmetatable({
        _req = req,
        api_key = apikey,
        api_version = _M.api_version,
        offset = 7,
        len = c_len + 10,
    }, mt)
end

function _M.int16(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int16(int)

    self.offset = offset + 1
    self.len = self.len + 2
end

function _M.int32(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int32(int)

    self.offset = offset + 1
    self.len = self.len + 4
end

function _M.int64(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int64(int)

    self.offset = offset + 1
    self.len = self.len + 8
end

function _M.string(self, str)
    local req = self._req
    local offset = self.offset
    local str_len = #str

    req[offset] = str_int16(str_len)
    req[offset + 1] = str

    self.offset = offset + 2
    self.len = self.len + 2 + str_len
end

function _M.bytes(self, str)
    local req = self._req
    local offset = self.offset
    local str_len = #str

    req[offset] = str_int32(str_len)
    req[offset + 1] = str

    self.offset = offset + 2
    self.len = self.len + 4 + str_len
end

local function message_package(key, msg, message_version)
    local key = key or ""
    local key_len = #key
    local len = #msg
    message_version = message_version or MESSAGE_VERSION_0

    local req
    local head_len
    if message_version == MESSAGE_VERSION_1 then
        req = {
            -- MagicByte
            str_int8(1),
            -- XX hard code no Compression
            str_int8(0),
            str_int64(tonumber(os.time() * 1000)), -- timestamp
            str_int32(key_len),
            key,
            str_int32(len),
            msg,
        }
        head_len = 22
    else
        req = {
            -- MagicByte
            str_int8(0),
            -- XX hard code no Compression
            str_int8(0),
            str_int32(key_len),
            key,
            str_int32(len),
            msg,
        }
        head_len = 14
    end

    local str = concat(req)
    return crc32(str), str, key_len + len + head_len
end

function _M.message_set(self, messages, index)
    local req = self._req
    local off = self.offset
    local msg_set_size = 0
    local index = index or #messages

    local message_version = MESSAGE_VERSION_0
    if self.api_key == _M.ProduceRequest and self.api_version == _M.API_VERSION_V2 then
        message_version = MESSAGE_VERSION_1
    end

    for i = 1, index, 2 do
        local crc, str, msg_len = message_package(messages[i], messages[i + 1], message_version)

        req[off + 1] = str_int64(0) -- offset
        req[off + 2] = str_int32(msg_len) -- include the crc32 length

        req[off + 3] = str_int32(crc)
        req[off + 4] = str

        off = off + 4
        msg_set_size = msg_set_size + msg_len + 12
    end

    req[self.offset] = str_int32(msg_set_size) -- MessageSetSize

    self.offset = off + 1
    self.len = self.len + 4 + msg_set_size
end

function _M.package(self)
    local req = self._req
    req[1] = str_int32(self.len)

    return req
end


return _M
