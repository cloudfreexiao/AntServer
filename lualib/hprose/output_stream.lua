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
 * hprose/output_stream.lua                               *
 *                                                        *
 * hprose OutoutStream for Lua                            *
 *                                                        *
 * LastModified: Apr 25, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local setmetatable = setmetatable
local select       = select
local concat       = table.concat

local OutputStream = {}

function OutputStream:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buffer = { "" }
    return o
end

function OutputStream:write(...)
    for i = 1, select("#", ...) do
        self.buffer[#self.buffer + 1] = select(i, ...)
    end
end

function OutputStream:mark()
    self.buffer = { concat(self.buffer) }
end

function OutputStream:reset()
    self.buffer = { self.buffer[1] }
end

function OutputStream:clear()
    self.buffer = { "" }
end

function OutputStream:__tostring()
    return concat(self.buffer)
end

return OutputStream