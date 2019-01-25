local cjson = require "cjson"
local json_safe = require "cjson.safe"

local function decode(text)
    local status, result = pcall(cjson.decode, text)
    if status then
        return result
    end 

    print(string.format("json.decode failed: text[%s] traceback[%s]", tostring(text), debug.traceback()))
end 

local function encode(text)
    local status, result = pcall(cjson.encode, text)
    if status then
        return result
    end 

    print(string.format("json.encode failed: text[%s] traceback[%s]", tostring(text), debug.traceback()))
end 


return {
    encode = encode,
    decode = decode,
    
    safe_encode = json_safe.encode,
    safe_decode = json_safe.decode,
}
