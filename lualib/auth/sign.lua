local md5   = require "md5"
local codec = require "codec"

local string_format = string.format
local string_upper  = string.upper
local table_sort    = table.sort
local table_concat  = table.concat

local function encode_uri(s)
    s = string.gsub(s, "([^A-Za-z0-9])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return s
end

local M = {}
-- mark 参数是否加引号
function M.concat_args(args, mark)
    local list = {}
    for k, v in pairs(args) do
        if v ~= '' then
            list[#list+1] = string_format(mark and '%s="%s"' or '%s=%s', k, v)
        end
    end
    assert(#list > 0, "need one arg at least")
    table_sort(list, function(a, b)
        return a < b
    end)
    return table_concat(list, "&")
end

function M.md5_args(args, key, mark)
    local str = M.concat_args(args, mark)
    if key then
        str = str .. "&key=" .. key
    end
    return string_upper(md5.sumhexa(str))
end

function M.rsa_private_sign(args, private_key, mark)
    local str = M.concat_args(args, mark)
    local bs = codec.rsa_private_sign(str, private_key)
    return encode_uri(codec.base64_encode(bs))
end

function M.rsa_sha256_private_sign(args, private_key, mark)
    local str = M.concat_args(args, mark)
    local bs = codec.rsa_sha256_private_sign(str, private_key)
    return encode_uri(codec.base64_encode(bs))
end

return M
