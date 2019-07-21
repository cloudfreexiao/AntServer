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
 * hprose/writer.lua                                      *
 *                                                        *
 * hprose Writer for Lua                                  *
 *                                                        *
 * LastModified: Jun 17, 2015                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

require("hprose.common")
local Tags         = require("hprose.tags")
local ClassManager = require("hprose.class_manager")
local date         = require("date")
local error        = error
local type         = type
local pairs        = pairs
local setmetatable = setmetatable
local getmetatable = getmetatable
local floor        = math.floor
local modf         = math.modf
local huge         = math.huge
local format       = string.format
local ostime       = os.time
local osdate       = os.date

local FakeWriterRefer = {
    set = function(self, val) end,
    write = function(self, val) return false end,
    reset = function (self) end
}

local RealWriterRefer = {}

function RealWriterRefer:new(stream)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stream = stream
    o.ref = { __mode = "k" }
    o.refcount = 0
    return o
end

function RealWriterRefer:set(val)
    self.ref[val] = self.refcount
    self.refcount = self.refcount + 1
end

function RealWriterRefer:write(val)
    local index = self.ref[val]
    if index ~= nil then
        self.stream:write(Tags.Ref, index, Tags.Semicolon)
        return true
    end
    return false
end

function RealWriterRefer:reset()
    self.ref = { __mode = "k" }
    self.refcount = 0
end

local digits = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = true,
}

local function isserializable(val)
    local t = type(val)
    return t == "nil" or
           t == "boolean" or
           t == "number" or
           t == "string" or
           t == "table"
end

local function getfields(val, fields)
    fields = fields or {}
    if val == nil then return fields end
    for k, v in pairs(val) do
        if isserializable(k) and isserializable(v) and
           (type(k) ~= "string" or k:sub(1, 2) ~= "__") then
            fields[#fields + 1] = k
        end
    end
    return getfields(getmetatable(val), fields)
end

local function isarray(val)
    if type(val.n) == 'number' and floor(val.n) == val.n and val.n >= 1 then
        return true
    end
    local len = #val
    for k,v in pairs(val) do
        if type(k) ~= 'number' then
            return false
        end
        local _, decim = modf(k)
        if not (decim == 0 and 1 <= k) then
            return false
        end
        if k > len then
            return false
        end
    end
    return true
end

local function isobject(val)
    return ClassManager.getClassAlias(getmetatable(val)) ~= nil
end

local dobj = getmetatable(date())
local function isdate(val)
    return getmetatable(val) == dobj
end

local function isdatetime(val)
    return type(val.year) == "number" and
        type(val.month) == "number" and
        type(val.day) == "number" and
        (type(val.hour) == "number" or type(val.hour) == "nil") and
        (type(val.min) == "number" or type(val.min) == "nil") and
        (type(val.sec) == "number" or type(val.sec) == "nil") and
        (type(val.utc) == "boolean" or type(val.utc) == "nil")
end

local function isosdate(val)
    return (type(val.hour) == "number" and val.hour == 0 or type(val.hour) == "nil") and
        (type(val.min) == "number" and val.min == 0 or type(val.min) == "nil") and
        (type(val.sec) == "number" and val.sec == 0 or type(val.sec) == "nil")
end

local function isostime(val)
    return val.year == 1970 and val.month == 1 and val.day == 1
end

local function writeNull(writer, val)
    writer:writeNull()
end

local function writeBoolean(writer, val)
    writer:writeBoolean(val)
end

local function writeNumber(writer, val)
    writer:writeNumber(val)
end

local function writeString(writer, val)
    if val:isutf8() then
        if val:len() < 4 then
            local len = val:ulen()
            if len == 0 then
                writer:writeEmpty()
                return
            elseif len == 1 then
                writer:writeUTF8Char(val)
                return
            end
        end
        writer:writeStringWithRef(val)
    else
        writer:writeBytesWithRef(val)
    end
end

local function writeTable(writer, val)
    if isobject(val) then
        writer:writeObjectWithRef(val)
    elseif isdate(val) then
        writer:writeDateWithRef(val)
    elseif isdatetime(val) then
        writer:writeDateTimeWithRef(val)
    elseif isarray(val) then
        writer:writeListWithRef(val)
    else
        writer:writeMapWithRef(val)
    end
end

local serializeMethods = {
    ["nil"] = writeNull,
    ["boolean"] = writeBoolean,
    ["number"] = writeNumber,
    ["string"] = writeString,
    ["userdata"] = writeNull,
    ["function"] = writeNull,
    ["thread"] = writeNull,
    ["table"] = writeTable
}

local Writer = {}

function Writer:new(stream, simple)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stream = stream
    o.refer = simple and FakeWriterRefer or RealWriterRefer:new(stream)
    o.classref = {}
    o.fieldsref = {}
    return o
end

function Writer:serialize(val)
    serializeMethods[type(val)](self, val)
end

function Writer:writeNull()
    self.stream:write(Tags.Null)
end

function Writer:writeBoolean(val)
    self.stream:write(val and Tags.True or Tags.False)
end

function Writer:writeNumber(val)
    if digits[val] then
        self.stream:write(val)
    elseif (val ~= val) then
        self.stream:write(Tags.NaN)
    elseif (val == huge) then
        self.stream:write(Tags.Infinity, Tags.Pos)
    elseif (val == -huge) then
        self.stream:write(Tags.Infinity, Tags.Neg)
    elseif (floor(val) == val) then
        local isint32 = (val >= -2147483648) and (val <= 2147483647)
        self.stream:write(isint32 and Tags.Integer or Tags.Long, val, Tags.Semicolon)
    else
        self.stream:write(Tags.Double, val, Tags.Semicolon)
    end
end

function Writer:writeEmpty()
    self.stream:write(Tags.Empty)
end

function Writer:writeDate(val)
    self.refer:set(val)
    local timezone = val.utc and Tags.UTC or Tags.Semicolon
    local h, i, s, u = val:gettime()
    if h == 0 and i == 0 and s == 0 and u == 0 then
        self.stream:write(Tags.Date, val:fmt("%Y%m%d", time), timezone)
    else
        local y, m, d = val:getdate()
        if y == 1970 and m == 1 and d == 1 then
            self.stream:write(Tags.Time, val:fmt("%H%M%\f", time), timezone)
        else
            self.stream:write(Tags.Date, val:fmt("%Y%m%d", time),
                              Tags.Time, val:fmt("%H%M%\f", time), timezone)
        end
    end
end

function Writer:writeDateWithRef(val)
    if not self.refer:write(val) then self:writeDate(val) end
end

function Writer:writeDateTime(val)
    self.refer:set(val)
    local timezone = val.utc and Tags.UTC or Tags.Semicolon
    local time = ostime(val)
    if isosdate(val) then
        self.stream:write(Tags.Date, osdate("%Y%m%d", time), timezone)
    else
        val = osdate("*t", time)
        if isostime(val) then
            self.stream:write(Tags.Time, osdate("%H%M%S", time), timezone)
        else
            self.stream:write(Tags.Date, osdate("%Y%m%d", time),
                              Tags.Time, osdate("%H%M%S", time), timezone)
        end
    end
end

function Writer:writeDateTimeWithRef(val)
    if not self.refer:write(val) then self:writeDateTime(val) end
end

function Writer:writeBytes(val)
    self.refer:set(val)
    self.stream:write(Tags.Bytes, val:len(), Tags.Quote, val, Tags.Quote)
end

function Writer:writeBytesWithRef(val)
    if not self.refer:write(val) then self:writeBytes(val) end
end

function Writer:writeUTF8Char(val)
    self.stream:write(Tags.UTF8Char, val)
end

function Writer:writeString(val)
    self.refer:set(val)
    self.stream:write(Tags.String, val:ulen(), Tags.Quote, val, Tags.Quote)
end

function Writer:writeStringWithRef(val)
    if not self.refer:write(val) then self:writeString(val) end
end

function Writer:writeList(val)
    self.refer:set(val)
    local count = val.n or #val
    self.stream:write(Tags.List, count, Tags.Openbrace)
    for i = 1, count do
        self:serialize(val[i])
    end
    self.stream:write(Tags.Closebrace)
end

function Writer:writeListWithRef(val)
    if not self.refer:write(val) then self:writeList(val) end
end

function Writer:writeMap(val)
    self.refer:set(val)
    local fields = getfields(val)
    local count = #fields
    self.stream:write(Tags.Map, count, Tags.Openbrace)
    for i = 1, count do
        self:serialize(fields[i])
        self:serialize(val[fields[i]])
    end
    self.stream:write(Tags.Closebrace)
end

function Writer:writeMapWithRef(val)
    if not self.refer:write(val) then self:writeMap(val) end
end

function Writer:writeObject(val)
    local mt = getmetatable(val)
    local classname = ClassManager.getClassAlias(mt)
    local fields
    local index = self.classref[classname]
    if index == nil then
        fields = getfields(mt:new())
        index = self:writeClass(classname, fields)
    else
        fields = self.fieldsref[index]
    end
    self.refer:set(val)
    self.stream:write(Tags.Object, index - 1, Tags.Openbrace)
    for i = 1, #fields do
        self:serialize(val[fields[i]])
    end
    self.stream:write(Tags.Closebrace)
end

function Writer:writeObjectWithRef(val)
    if not self.refer:write(val) then self:writeObject(val) end
end

function Writer:writeClass(classname, fields)
    local count = #fields
    local len = classname:ulen()
    if len < 0 then error("class name must be encoding in utf8.") end
    self.stream:write(Tags.Class, len, Tags.Quote, classname, Tags.Quote, count, Tags.Openbrace)
    for i = 1, count do
        self:writeString(fields[i])
    end
    self.stream:write(Tags.Closebrace)
    local index = #self.fieldsref + 1
    self.classref[classname] = index
    self.fieldsref[index] = fields
    return index
end

function Writer:reset()
    self.classref = {}
    self.fieldsref = {}
    self.refer:reset()
end

return Writer