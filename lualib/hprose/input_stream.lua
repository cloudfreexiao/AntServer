--[[
/**********************************************************\
|                                                          |
|                          hprose                          |
|                                                          |
| Official WebSite: http://www.hprose.com/                 |
|                   http://www.hprose.org/                 |
|                                                          |
\**********************************************************/

/**********************************************************\
 *                                                        *
 * hprose/input_stream.lua                                *
 *                                                        *
 * hprose InputStream for Lua                             *
 *                                                        *
 * LastModified: Apr 25, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local setmetatable = setmetatable
local error        = error

local InputStream = {}

function InputStream:new(buffer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buffer = buffer
    o.pos = 1
    o.length = buffer:len()
    return o
end

function InputStream:getc()
    local c = self.buffer:sub(self.pos, self.pos)
    self:skip(1)
    return c
end

function InputStream:read(len)
    local str = self.buffer:sub(self.pos, self.pos + len - 1)
    self:skip(len)
    return str
end

function InputStream:skip(n)
    self.pos = self.pos + n
end

function InputStream:readuntil(tag)
    local bp = self.pos
    local c = self:getc()
    local lastpos = self.length + 1
    while (c ~= tag) and (self.pos ~= lastpos) do
        c = self:getc()
    end
    local ep = self.pos - 1
    if c == tag then ep = ep - 1 end
    if ep - bp < 0 then return '' end
    return self.buffer:sub(bp, ep)
end

-- @param len is utf16 length, but read utf8 string
function InputStream:readstring(len)
    local p = self.pos
    local i = 1
    local a, b, c, d
    while i <= len do
        local a = self.buffer:byte(self.pos)
        i = i + 1
        if a < 0x80 then
            self:skip(1)
        elseif a >= 0xC0 and a < 0xE0 then
            self:skip(2)
        elseif a >= 0xE0 and a < 0xF0 then
            self:skip(3)
        elseif a >= 0xF0 and a < 0xF8 then
            self:skip(4)
            i = i + 1
        else
            error("bad utf-8 encoding")
        end
    end
    return self.buffer:sub(p, self.pos - 1)
end

return InputStream