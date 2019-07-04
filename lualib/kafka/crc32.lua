local crc = require "crc"
local CRC = {}

function CRC.crc32(str)
    return  crc.crc32(str)
end

function CRC.crc64(str)
    return  crc.crc64(str)
end

return CRC