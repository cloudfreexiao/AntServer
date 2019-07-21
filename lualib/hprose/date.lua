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
 * hprose/date.lua                                        *
 *                                                        *
 * hprose Date for Lua                                    *
 *                                                        *
 * LastModified: Jun 19, 2015                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local date = require('date')
local dobj = getmetatable(date())
local pack = table.pack or function(...) return { n = select('#', ...), ... } end

local date_call     = date.__call
local dobj_toutc    = dobj.toutc
local dobj_tolocal  = dobj.tolocal
local dobj_copy     = dobj.copy

function date:__call(...)
    local arg = pack(...)
    local o = date_call(self, ...)
    if arg.n == 0 then
        o.utc = false
    elseif arg.n == 1 then
        if type(arg[1]) == "boolean" then
            o.utc = arg[1]
        elseif type(arg[1]) == "table" then
            o.utc = arg[1].utc and true or false
        end
    elseif arg.n == 4 then
        if type(arg[4]) == "boolean" then
            o.utc = arg[4]
        else
            o.utc = false
        end
    elseif arg.n == 7 then
        if type(arg[7]) == "boolean" then
            o.utc = arg[7]
        else
            o.utc = false
        end
    elseif arg.n == 8 then
        if type(arg[8]) == "boolean" then
            o.utc = arg[8]
        else
            o.utc = false
        end
    end
    return o
end

function dobj:tolocal()
    if self.utc then
        dobj_tolocal(self)
        self.utc = false
    end
    return self
end

function dobj:toutc()
    if not self.utc then
        dobj_toutc(self)
        self.utc = true
    end
    return self
end

function dobj:copy()
    local o = dobj_copy(self)
    o.utc = self.utc
    return o
end

return date