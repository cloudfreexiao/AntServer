-- lua扩展

-- 判断table是否为空
table.empty = function(t)
    return not next(t)
end

table.nums = function(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 返回table索引列表
table.indices = function(t)
    local result = {}
    for k, _ in pairs(t) do
        table.insert(result, k)
    end
end

-- 返回table值列表
table.values = function(t)
    local result = {}
    for _, v in pairs(t) do
        table.insert(result, v)
    end
end

-- 浅拷贝
table.clone = function(object)
    local lookup_table = {}
    local function _copy(obj)
        if type(obj) ~= "table" then
            return obj
        elseif lookup_table[obj] then
            return lookup_table[obj]
        end
        local new_table = {}
        lookup_table[obj] = new_table
        for key, value in pairs(obj) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(obj))
    end
    return _copy(object)
end

-- 深拷贝
function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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

-- math扩展
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
    local idx = array_find(t, val)
    if idx ~= -1 then
        table.remove(t, idx)
        return true
    end

    return false
end

