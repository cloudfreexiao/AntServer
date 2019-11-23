-- map(table, function)
-- e.g: map({1, 2, 3}, double) -> {2, 4, 6}
local function map(tbl, func)
    local ret = {}
    for i,v in ipairs(tbl) do
        ret[i] = func(v)
    end
    return ret
end

-- filter(table, function)
-- e.g: filter({1, 2, 3, 4}, is_even) -> {2, 4}
local function filter(tbl, func)
    local ret = {}
    for i,v in ipairs(tbl) do
        if func(v) then
            ret[i] = v
        end
    end
    return ret
end

-- head(table)
-- e.g: head({1, 2, 3}) -> 1
local function head(tbl)
    return tbl[1]
end

-- tail(table)
-- e.g: tail({1, 2, 3}) -> {2, 3}
local function tail(tbl)
    if #tbl < 1 then
        return nil
    else
        local ret = {}
        for i=2,#tbl do
            table.insert(ret, tbl[i])
        end
        return ret
    end
end

-- foldr(function, default, table)
-- e.g: foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
local function foldr(tbl, val, func)
    for _,v in pairs(tbl) do
        val = func(val, v)
    end
    return val
end

-- reduce(table, function)
-- e.g: reduce({1,2,3,4}, operator.add) -> 10
local function reduce(tbl, reducer)
    return foldr(tail(tbl), head(tbl), reducer)
end

local function slice(tbl, i, j)
    assert(type(tbl) == 'table', 'expected a table value.')
    local ret = {}
    if #tbl == 0 then return ret end
    if i == nil then
        i = 1
    end

    if i < 0 then
        i = #tbl + 1 + i
    end

    if i < 1 then
       i = 1
    end

    if j == nil then
        j = #tbl
    end

    if j < 0 then
        j = #tbl + 1 + j
    end

    for k=i,#tbl do
        if k > j then break end
        table.insert(ret, tbl[k])
    end

    return ret
end

local function indexOf(tbl, value)
    assert(type(tbl) == 'table', 'expected a table value.')
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end


return {
    map = map,
    filter = filter,
    head = head,
    tail = tail,
    reduce = reduce,
    slice = slice,
    indexOf = indexOf
}
