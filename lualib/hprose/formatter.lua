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
 * hprose/reader.lua                                      *
 *                                                        *
 * hprose Reader for Lua                                  *
 *                                                        *
 * LastModified: May 13, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local OutputStream = require("hprose.output_stream")
local InputStream  = require("hprose.input_stream")
local Writer       = require("hprose.writer")
local Reader       = require("hprose.reader")
local tostring     = tostring

local Formatter = {
    serialize = function(variable, simple)
        local stream = OutputStream:new()
        local writer = Writer:new(stream, simple)
        writer:serialize(variable)
        return tostring(stream)
    end,
    unserialize = function(variable_representation, simple)
        local stream = InputStream:new(variable_representation)
        local reader = Reader:new(stream, simple)
        return reader:unserialize()
    end
}

return Formatter