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
 * hprose/client.lua                                      *
 *                                                        *
 * hprose Client for Lua                                  *
 *                                                        *
 * LastModified: May 14, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local Tags         = require("hprose.tags")
local ResultMode   = require("hprose.result_mode")
local OutputStream = require("hprose.output_stream")
local InputStream  = require("hprose.input_stream")
local Writer       = require("hprose.writer")
local Reader       = require("hprose.reader")
local tostring     = tostring
local error        = error
local setmetatable = setmetatable
local remove       = table.remove

local dynamicProxy = {
    new = function (self, client, namespace)
        local o = {}
        setmetatable(o, self)
        o.client = client
        if namespace ~= nil then
            o.namespace = namespace .. "_"
        else
            o.namespace = ""
        end
        return o
    end,
    __index = function (self, name)
        return function (...)
            return self.client:invoke(self.namespace .. name, {...}, false, ResultMode.Normal, false)
        end
    end,
}

local Client = {}

function Client:new(uri)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.uri = uri
    o.filters = {}
    o.simple = false
    return o
end

function Client:useService(uri, namespace)
    if uri ~= nil then self.uri = uri end
    return dynamicProxy:new(self, namespace)
end

function Client:invoke(name, args, byRef, resultMode, simple)
    if args == nil then args = {} end
    if simple == nil then simple = self.simple end
    local stream = OutputStream:new()
    stream:write(Tags.Call)
    local writer = Writer:new(stream, simple)
    writer:writeString(name)
    if #args > 0 or byRef then
        writer:reset()
        writer:writeList(args)
        if byRef then writer:writeBoolean(true) end
    end
    stream:write(Tags.End)
    local data = tostring(stream)
    local count = #self.filters
    for i = 1, count do
        data = self.filters[i].outputFilter(data, self)
    end
    data = self:sendAndReceive(data)
    for i = count, 1, -1 do
        data = self.filters[i].inputFilter(data, self)
    end
    if resultMode == ResultMode.RawWithEndTag then
        return data
    end
    if resultMode == ResultMode.Raw then
        return data:sub(1, -2)
    end
    stream = InputStream:new(data)
    local reader = Reader:new(stream)
    local result = nil
    local tag = stream:getc()
    while tag ~= Tags.End do
        if tag == Tags.Result then
            if resultMode == ResultMode.Serialized then
                result = reader:readRaw()
            else
                reader:reset()
                result = reader:unserialize()
            end
        elseif tag == Tags.Argument then
            reader:reset()
            local arguments = reader:readList()
            for i = 1, #arguments do
                args[i] = arguments[i]
            end
        elseif tag == Tags.Error then
            reader:reset()
            error(reader:readString())
        else
            error("Wrong Response: \r\n" .. data)
        end
        tag = stream:getc()
    end
    return result
end

function Client:getFilter()
    if #self.filters == 0 then
        return nil
    else
        return self.filters[1]
    end
end

function Client:setFilter(filter)
    if filter == nil then
        self.filters = {}
    else
        self.filters = { filter }
    end
end

function Client:addFilter(filter)
    self.filters[#self.filters + 1] = filter
end

function Client:removeFilter(filter)
    for i = 1, #self.filters do
        if self.filters[i] == filter then
            remove(self.filters, i)
            return true
        end
    end
    return false
end

return Client