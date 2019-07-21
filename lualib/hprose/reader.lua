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
 * LastModified: May 28, 2015                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local Tags         = require("hprose.tags")
local ClassManager = require("hprose.class_manager")
local OutputStream = require("hprose.output_stream")
local floor        = math.floor
local tonumber     = tonumber
local tostring     = tostring
local error        = error
local setmetatable = setmetatable
local huge         = math.huge

local function unexpectedTag(tag, expectTags)
    if tag == nil then
        error('No byte found in stream')
    else
        if expectTags then
            error("tag '" .. expectTags .. "' expected, but '" .. tag .. "' found in stream")
        else
            error("Unexpected serialize tag '" .. tag .. "' in stream")
        end
    end
end

local rawReaderMethods

local function readRaw(istream, ostream, tag)
    ostream:write(tag)
    local read = rawReaderMethods[tag]
    if read == nil then
        unexpectedTag(tag)
    else
        read(istream, ostream)
    end
end

local function readInfRaw(istream, ostream)
    local tag = istream:getc()
    ostream:write(tag)
end

local function readNumberRaw(istream, ostream)
    repeat
        local tag = istream:getc()
        ostream:write(tag)
    until tag == Tags.Semicolon
end

local function readDateTimeRaw(istream, ostream)
    repeat
        local tag = istream:getc()
        ostream:write(tag)
    until tag == Tags.Semicolon or tag == Tags.UTC
end

local function readUTF8CharRaw(istream, ostream)
    ostream:write(istream:readstring(1))
end

local function readBytesRaw(istream, ostream)
    local count = 0
    local tag = "0"
    repeat
        count = count * 10
        count = count + tag:byte() - 48
        tag = istream:getc()
        ostream:write(tag)
    until tag == Tags.Quote
    ostream:write(istream:read(count + 1))
end

local function readStringRaw(istream, ostream)
    local count = 0
    local tag = "0"
    repeat
        count = count * 10
        count = count + tag:byte() - 48
        tag = istream:getc()
        ostream:write(tag)
    until tag == Tags.Quote
    ostream:write(istream:readstring(count + 1))
end

local function readGuidRaw(istream, ostream)
    ostream:write(istream:read(38))
end

local function readComplexRaw(istream, ostream)
    local tag
    repeat
        tag = istream:getc()
        ostream:write(tag)
    until tag == Tags.Openbrace
    tag = istream:getc()
    while tag ~= Tags.Closebrace do
        readRaw(istream, ostream, tag)
        tag = istream:getc()
    end
    ostream:write(tag)
end

local function readClassRaw(istream, ostream)
    readComplexRaw(istream, ostream)
    readRaw(istream, ostream, istream:getc())
end

local function readErrorRaw(istream, ostream)
    readRaw(istream, ostream, istream:getc())
end

rawReaderMethods = {
    ['0'] = function() end,
    ['1'] = function() end,
    ['2'] = function() end,
    ['3'] = function() end,
    ['4'] = function() end,
    ['5'] = function() end,
    ['6'] = function() end,
    ['7'] = function() end,
    ['8'] = function() end,
    ['9'] = function() end,
    [Tags.Null] = function() end,
    [Tags.Empty] = function() end,
    [Tags.True] = function() end,
    [Tags.False] = function() end,
    [Tags.NaN] = function() end,
    [Tags.Infinity] = readInfRaw,
    [Tags.Integer] = readNumberRaw,
    [Tags.Long] = readNumberRaw,
    [Tags.Double] = readNumberRaw,
    [Tags.Ref] = readNumberRaw,
    [Tags.Date] = readDateTimeRaw,
    [Tags.Time] = readDateTimeRaw,
    [Tags.UTF8Char] = readUTF8CharRaw,
    [Tags.Bytes] = readBytesRaw,
    [Tags.String] = readStringRaw,
    [Tags.Guid] = readGuidRaw,
    [Tags.List] = readComplexRaw,
    [Tags.Map] = readComplexRaw,
    [Tags.Object] = readComplexRaw,
    [Tags.Class] = readClassRaw,
    [Tags.Error] = readErrorRaw,
}

local RawReader = {}

function RawReader:new(stream)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stream = stream
    return o
end

function RawReader:readRaw()
    local ostream = OutputStream:new()
    readRaw(self.stream, ostream, self.stream:getc())
    return tostring(ostream)
end

local FakeReaderRefer = {
    set = function(self, val) end,
    read = function(self, index) error("Unexpected serialize tag '" .. Tags.Ref .. "' in stream"); end,
    reset = function (self) end
}

local RealReaderRefer = {}

function RealReaderRefer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.ref = { __mode = "v" }
    return o
end

function RealReaderRefer:set(val)
    self.ref[#self.ref + 1] = val
end

function RealReaderRefer:read(index)
    return self.ref[index]
end

function RealReaderRefer:reset()
    self.ref = { __mode = "v" }
end

local function readNumber(stream, tag)
    local s = stream:readuntil(tag)
    if s == "" then
        return 0
    else
        return tonumber(s)
    end
end

local function readInteger(reader)
    return floor(readNumber(reader.stream, Tags.Semicolon))
end

local function readLong(reader)
    return reader.stream:readuntil(Tags.Semicolon)
end

local function readDouble(reader)
    return readNumber(reader.stream, Tags.Semicolon)
end

local function readInfinity(reader)
    return reader.stream:getc() == Tags.Neg and -huge or huge
end

local function readDateTime(reader)
    local stream = reader.stream
    local date = {
        year = tonumber(stream:read(4), 10),
        month = tonumber(stream:read(2), 10),
        day = tonumber(stream:read(2), 10),
        hour = 0,
        min = 0,
        sec = 0,
        msec = 0
    }
    local tag = stream:getc()
    if tag == Tags.Time then
        date.hour = tonumber(stream:read(2), 10)
        date.min = tonumber(stream:read(2), 10)
        date.sec = tonumber(stream:read(2), 10)
        tag = stream:getc()
        if tag == Tags.Point then
            date.msec = tonumber(stream:read(3), 10)
            tag = stream:getc()
            if tag >= '0' and tag <= '9' then
                stream:skip(2)
                tag = stream:getc()
                if tag >= '0' and tag <= '9' then
                    stream:skip(2)
                    tag = stream:getc()
                end
            end
        end
    end
    date.utc = (tag == Tags.UTC)
    reader.refer:set(date)
    return date
end

local function readTime(reader)
    local stream = reader.stream
    local time = {
        year = 1970,
        month = 1,
        day = 1,
        hour = tonumber(stream:read(2), 10),
        min = tonumber(stream:read(2), 10),
        sec = tonumber(stream:read(2), 10),
        msec = 0
    }
    local tag = stream:getc()
    if tag == Tags.Point then
        time.msec = tonumber(stream:read(3), 10)
        tag = stream:getc()
        if tag >= '0' and tag <= '9' then
            stream:skip(2)
            tag = stream:getc()
            if tag >= '0' and tag <= '9' then
                stream:skip(2)
                tag = stream:getc()
            end
        end
    end
    time.utc = (tag == Tags.UTC)
    reader.refer:set(time)
    return time
end

local function readUTF8Char(reader)
    return reader.stream:readstring(1)
end

local function readBytes(reader)
    local stream = reader.stream
    local count = readNumber(stream, Tags.Quote)
    local bytes = stream:read(count)
    stream:skip(1)
    reader.refer:set(bytes)
    return bytes
end

local function readStringWithoutRef(reader)
    local stream = reader.stream
    local count = readNumber(stream, Tags.Quote)
    local str = stream:readstring(count)
    stream:skip(1)
    return str
end

local function readString(reader)
    local str = readStringWithoutRef(reader)
    reader.refer:set(str)
    return str
end

local function readGuid(reader)
    local stream = reader.stream
    stream:skip(1)
    local guid = stream:read(36)
    stream:skip(1)
    reader.refer:set(guid)
    return guid
end

local function readList(reader)
    local stream = reader.stream
    local list = {}
    reader.refer:set(list)
    local count = readNumber(stream, Tags.Openbrace)
    for i = 1, count do
        list[i] = reader:unserialize()
    end
    stream:skip(1)
    return list
end

local function readMap(reader)
    local stream = reader.stream
    local map = {}
    reader.refer:set(map)
    local count = readNumber(stream, Tags.Openbrace)
    for i = 1, count do
        local k = reader:unserialize()
        local v = reader:unserialize()
        map[k] = v
    end
    stream:skip(1)
    return map
end

local function readObject(reader)
    local stream = reader.stream
    local classinfo = reader.classref[readNumber(stream, Tags.Openbrace) + 1]
    local obj = classinfo.class:new()
    reader.refer:set(obj)
    for i = 1, classinfo.count do
        obj[classinfo.fields[i]] = reader:unserialize()
    end
    stream:skip(1)
    return obj
end

local function getClass(classname, fields)
    local class = ClassManager.getClass(classname)
    if class then return class end
    class = {
        new = function(self)
            local o = {}
            setmetatable(o, self)
            self.__index = self
            for i = 1, #fields do
                o[fields[i]] = ''
            end
            return o
        end
    }
    ClassManager.register(class, classname)
    return class
end

local function readClass(reader)
    local stream = reader.stream
    local classname = readStringWithoutRef(reader)
    local count = readNumber(stream, Tags.Openbrace)
    local fields = {}
    for i = 1, count do
        fields[i] = reader:unserialize()
    end
    stream:skip(1)
    local classinfo = {
        class = getClass(classname, fields),
        count = count,
        fields = fields
    }
    reader.classref[#reader.classref + 1] = classinfo
end

local function readRef(reader)
    return reader.refer:read(readNumber(reader.stream, Tags.Semicolon) + 1)
end

local unserializeMethods = {
    ['0'] = function() return 0 end,
    ['1'] = function() return 1 end,
    ['2'] = function() return 2 end,
    ['3'] = function() return 3 end,
    ['4'] = function() return 4 end,
    ['5'] = function() return 5 end,
    ['6'] = function() return 6 end,
    ['7'] = function() return 7 end,
    ['8'] = function() return 8 end,
    ['9'] = function() return 9 end,
    [Tags.Null] = function() return nil end,
    [Tags.Empty] = function() return "" end,
    [Tags.True] = function() return true end,
    [Tags.False] = function() return false end,
    [Tags.NaN] = function() return 0/0 end,
    [Tags.Infinity] = readInfinity,
    [Tags.Integer] = readInteger,
    [Tags.Long] = readLong,
    [Tags.Double] = readDouble,
    [Tags.Ref] = readRef,
    [Tags.Date] = readDateTime,
    [Tags.Time] = readTime,
    [Tags.UTF8Char] = readUTF8Char,
    [Tags.Bytes] = readBytes,
    [Tags.String] = readString,
    [Tags.Guid] = readGuid,
    [Tags.List] = readList,
    [Tags.Map] = readMap,
    [Tags.Object] = readObject,
    [Tags.Class] = function(reader)
        readClass(reader)
        return reader:unserialize()
    end,
    [Tags.Error] = function(reader)
        error(reader:readString())
    end
}

local Reader = RawReader:new()

function Reader:new(stream, simple)
    local o = RawReader:new(stream)
    setmetatable(o, self)
    self.__index = self
    o.refer = simple and FakeReaderRefer or RealReaderRefer:new(stream)
    o.classref = {}
    return o
end

function Reader:checkTag(expectTag)
    local tag = self.stream:getc()
    if tag ~= expectTag then
        unexpectedTag(tag, expectTag)
    end
end

function Reader:checkTags(expectTags)
    local tag = self.stream:getc()
    for i = 1, #expectTags do
        if expectTags[i] == tag then return tag end
    end
    unexpectedTag(tag, expectTags)
end

function Reader:unserialize()
    local tag = self.stream:getc()
    if unserializeMethods[tag] then
        return unserializeMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readIntegerMethods = {
    ['0'] = function() return 0 end,
    ['1'] = function() return 1 end,
    ['2'] = function() return 2 end,
    ['3'] = function() return 3 end,
    ['4'] = function() return 4 end,
    ['5'] = function() return 5 end,
    ['6'] = function() return 6 end,
    ['7'] = function() return 7 end,
    ['8'] = function() return 8 end,
    ['9'] = function() return 9 end,
    [Tags.Integer] = readInteger,
    [Tags.Error] = function(reader)
        error(reader:readString())
    end
}

function Reader:readInteger()
    local tag = self.stream:getc()
    if readIntegerMethods[tag] then
        return readIntegerMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readLongMethods = {
    ['0'] = function() return "0" end,
    ['1'] = function() return "1" end,
    ['2'] = function() return "2" end,
    ['3'] = function() return "3" end,
    ['4'] = function() return "4" end,
    ['5'] = function() return "5" end,
    ['6'] = function() return "6" end,
    ['7'] = function() return "7" end,
    ['8'] = function() return "8" end,
    ['9'] = function() return "9" end,
    [Tags.Integer] = readLong,
    [Tags.Long] = readLong,
    [Tags.Error] = function(reader)
        error(reader:readString())
    end
}

function Reader:readLong()
    local tag = self.stream:getc()
    if readLongMethods[tag] then
        return readLongMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readDoubleMethods = {
    ['0'] = function() return 0 end,
    ['1'] = function() return 1 end,
    ['2'] = function() return 2 end,
    ['3'] = function() return 3 end,
    ['4'] = function() return 4 end,
    ['5'] = function() return 5 end,
    ['6'] = function() return 6 end,
    ['7'] = function() return 7 end,
    ['8'] = function() return 8 end,
    ['9'] = function() return 9 end,
    [Tags.Integer] = readInteger,
    [Tags.Long] = readLong,
    [Tags.Double] = readDouble,
    [Tags.Error] = function(reader)
        error(reader:readString())
    end
}

function Reader:readDouble()
    local tag = self.stream:getc()
    if readDoubleMethods[tag] then
        return readDoubleMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readBooleanMethods = {
    [Tags.True] = function() return true end,
    [Tags.False] = function() return false end,
}

function Reader:readBoolean()
    local tag = self.stream:getc()
    if readBooleanMethods[tag] then
        return readBooleanMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readDateTimeMethods = {
    [Tags.Ref] = readRef,
    [Tags.Date] = readDateTime,
}

function Reader:readDateTime()
    local tag = self.stream:getc()
    if readDateTimeMethods[tag] then
        return readDateTimeMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readTimeMethods = {
    [Tags.Ref] = readRef,
    [Tags.Time] = readTime,
}

function Reader:readTime()
    local tag = self.stream:getc()
    if readTimeMethods[tag] then
        return readTimeMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readBytesMethods = {
    [Tags.Ref] = readRef,
    [Tags.Empty] = function() return "" end,
    [Tags.Bytes] = readBytes,
}

function Reader:readBytes()
    local tag = self.stream:getc()
    if readBytesMethods[tag] then
        return readBytesMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readStringMethods = {
    [Tags.Ref] = readRef,
    [Tags.Empty] = function() return "" end,
    [Tags.UTF8Char] = readUTF8Char,
    [Tags.String] = readString,
}

function Reader:readString()
    local tag = self.stream:getc()
    if readStringMethods[tag] then
        return readStringMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readGuidMethods = {
    [Tags.Ref] = readRef,
    [Tags.Guid] = readGuid,
}

function Reader:readGuid()
    local tag = self.stream:getc()
    if readGuidMethods[tag] then
        return readGuidMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readListMethods = {
    [Tags.Ref] = readRef,
    [Tags.List] = readList,
}

function Reader:readList()
    local tag = self.stream:getc()
    if readListMethods[tag] then
        return readListMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readMapMethods = {
    [Tags.Ref] = readRef,
    [Tags.Map] = readMap,
}

function Reader:readMap()
    local tag = self.stream:getc()
    if readMapMethods[tag] then
        return readMapMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

local readObjectMethods = {
    [Tags.Ref] = readRef,
    [Tags.Object] = readObject,
    [Tags.Class] = function(reader)
        readClass(reader)
        return reader:unserialize()
    end,
}

function Reader:readObject()
    local tag = self.stream:getc()
    if readObjectMethods[tag] then
        return readObjectMethods[tag](self)
    else
        unexpectedTag(tag)
    end
end

function Reader:reset()
    self.classref = {}
    self.refer:reset()
end

return Reader
