local _M = {
  _VERSION = '1.0.0'
}

-- https://github.com/couchbase/memcached/blob/master/docs/BinaryProtocol.md

local bit = require "bit"

local tinsert = table.insert
local assert = assert
local lshift, rshift, band, bor = bit.lshift, bit.rshift, bit.band, bit.bor
local char, byte = string.char, string.byte
local unpack = unpack
local tostring = tostring
local random = math.random
local type = type
local ipairs = ipairs

local c

-- magic

local MAGIC = {
  CLI_REQ  = 0x80, 
  SRV_RESP = 0x81,
  SRV_REQ  = 0x82,
  CLI_RESP = 0x83
}

-- pack/unpack

local function foreachi(tab, f)
  for _,v in ipairs(tab) do f(v) end
end

local function put_i8(i)
   return char(i)
end

local function put_i16(i)
  return char(rshift(band(i, 0xff00), 8)) .. char(band(i, 0x00ff))
end

local function put_i32(i)
  return char(rshift(band(i, 0xff000000), 24)) ..
         char(rshift(band(i, 0x00ff0000), 16)) ..
         char(rshift(band(i, 0x0000ff00), 8))  ..
         char(band(i, 0x000000ff))
end

local function get_i8(buffer)
   local i = byte(buffer.data, buffer.pos, buffer.pos)
   buffer.pos = buffer.pos + 1
   return i
end

local function get_i16(buffer)
  local a0, a1 = byte(buffer.data, buffer.pos, buffer.pos + 1)
  buffer.pos = buffer.pos + 2
  return bor(a1, lshift(a0, 8))
end

local function get_i32(buffer)
  local a0, a1, a2, a3 = byte(buffer.data, buffer.pos, buffer.pos + 3)
  buffer.pos = buffer.pos + 4
  return bor(a3,
             lshift(a2, 8),
             lshift(a1, 16),
             lshift(a0, 24))
end

local function pack_bytes(n, ...)
  local buffer = ""
  foreachi({ ... }, function(b)
    if n > 0 then
      buffer = buffer .. put_i8(b)
      n = n - 1
    end
  end)
  for i=1,n do buffer = buffer .. put_i8(0) end
  return buffer
end

local function unpack_bytes(n, buffer)
  local bytes = {}
  for i=1,n do
    tinsert(bytes, get_i8(buffer))
  end
  return unpack(bytes)
end

local bytes_8 = { 0, 0, 0, 0, 0, 0, 0, 0 }

function _M.encode(op, opts)
  local key, value, expire, extras, opaque, cas, vbucket_id = 
    tostring(opts.key or ""), opts.value or "", opts.expire, opts.extras or "", opts.opaque or random(2, 0x7FFFFFFF), opts.cas or bytes_8, opts.vbucket_id or 0

  local opaque_bin = type(opaque) ~= "table" and put_i32(opaque) or pack_bytes(4, unpack(opaque))

  if #extras ~= 0 then
    if expire then
      extras = extras .. put_i32(expire)
    end
  else
    if expire then
      extras = put_i32(expire)
    end
  end

  local total_length = #key + #value + #extras

  return { put_i8(MAGIC.CLI_REQ)           .. -- b2   0
           put_i8(op)                      .. --      1
           put_i16(#key)                   .. -- h    2
           put_i8(#extras)                 .. -- b2   4
           put_i8(0)                       .. --      5
           put_i16(vbucket_id or 0)        .. -- h    6
           put_i32(total_length)           .. -- i    8
           opaque_bin                      .. --      12
           pack_bytes(8, unpack(cas))      .. -- b8   16
           extras                          .. -- A    24
           key                             ..
           value,
           opaque }
end

function _M.handle_header(hdr)
  assert(#hdr >= 24, "invalid header: sz=" .. #hdr)

  local buffer = {
    data = hdr,
    pos = 1
  }

  local magic, op                = unpack_bytes(2, buffer)
  local key_length               = get_i16(buffer)
  local extras_length, data_type = unpack_bytes(2, buffer)
  local status_code              = get_i16(buffer)
  local total_length             = get_i32(buffer)
  local opaque                   = get_i32(buffer)
  local cas                      = { unpack_bytes(8, buffer) }

  assert(magic == MAGIC.SRV_RESP, "incorrect magic")

  -- lazy initialized
  c = c or require "resty.couchbase.consts" 

  return {
    status_code   = status_code,
    status        = c.status_desc[status_code] or "Unknown status code " .. status_code,
    type          = data_type,
    key_length    = key_length,
    extras_length = extras_length,
    total_length  = total_length,
    opaque        = opaque,
    CAS           = cas
  }
end

function _M.handle_body(sock, header)
  if header.total_length == 0 then
    return
  end

  local body = assert(sock:receive(header.total_length))

  local extras = body:sub(1, header.extras_length)
  local key    = body:sub(1 + header.extras_length, header.extras_length + header.key_length)
  local value  = body:sub(1 + header.extras_length + header.key_length)

  -- cleanup protocol fields
  header.key_length = nil
  header.extras_length = nil
  header.total_length = nil

  return #key ~= 0 and key or nil,
         #value ~= 0 and value or nil,
         #extras ~= 0 and extras or nil
end

_M.put_i8 = put_i8
_M.put_i16 = put_i16
_M.put_i32 = put_i32
_M.get_i8 = get_i8
_M.get_i16 = get_i16
_M.get_i32 = get_i32
_M.pack_bytes = pack_bytes
_M.unpack_bytes = unpack_bytes

return _M