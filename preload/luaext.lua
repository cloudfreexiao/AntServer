-- lua扩展

-- table扩展

-- 判断table是否为空
table.empty = function(t)
    return not next(t)
end

table.nums = function(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

-- 返回table索引列表
table.indices = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, k)
    end
end

-- 返回table值列表
table.values = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
end

-- 浅拷贝
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

-- 深拷贝
function deepcopy(object)
    if not object then return object end
    local new = {}
    for k, v in pairs(object) do
        local t = type(v)
        if t == "table" then
            new[k] = deepcopy(v)
        elseif t == "userdata" then
            new[k] = deepcopy(v)
        else
            new[k] = v
        end
    end
    return new
end

table.merge = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

table.lower_bound = function(elements, x, field)
    local first = 0
    local mid, half 
    local len = #elements 
    while len >0 do
        half = math.floor(len/2)
        mid = first + half 
        local element = elements[mid + 1]
        local value = field and element[field] or element 
        if value <x then
            first = mid + 1
            len = len - half - 1
        else
            len = half 
        end
    end
    return first + 1
end

-- string扩展

-- 下标运算
do
    local mt = getmetatable("")
    local _index = mt.__index

    mt.__index = function (s, ...)
        local k = ...
        if "number" == type(k) then
            return _index.sub(s, k, k)
        else
            return _index[k]
        end
    end
end

string.split = function(s, delim)
    local split = {}
    local pattern = "[^" .. delim .. "]+"
    string.gsub(s, pattern, function(v) table.insert(split, v) end)
    return split
end

string.ltrim = function(s, c)
    local pattern = "^" .. (c or "%s") .. "+"
    return (string.gsub(s, pattern, ""))
end

string.rtrim = function(s, c)
    local pattern = (c or "%s") .. "+" .. "$"
    return (string.gsub(s, pattern, ""))
end

string.trim = function(s, c)
    return string.rtrim(string.ltrim(s, c), c)
end

local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

do
    local _tostring = tostring
    tostring = function(v)
        if type(v) == 'table' then
            return dump(v)
        else
            return _tostring(v)
        end
    end
end

-- math扩展
do
    local _floor = math.floor
    math.floor = function(n, p)
        if p and p ~= 0 then
            local e = 10 ^ p
            return _floor(n * e) / e
        else
            return _floor(n)
        end
    end
end

math.round = function(n, p)
        local e = 10 ^ (p or 0)
        return math.floor(n * e + 0.5) / e
end

math.atan2 = function(dy, dx)
    local angle = math.atan(dy, dx)
    if angle <0 then
        angle = angle + 2 * math.pi
    end 
    return angle
end 


function handler(target, method)
    return function(...)
        method(target, ...)
    end
end


function array_new(len, val)
    local r = {}
    for i = 1, len do 
        table.insert(r, val)
    end
    return r
end

function array_find(t, val)
    for i, v in ipairs(t) do
        if val == v then return i end
    end
    return -1
end

function array_remove(t, val)
    local idx = luautils.array_find(t, val)
    if idx ~= -1 then
        table.remove(t, idx)
        return true
    end

    return false
end

function array_size(t)
    return #t
end
