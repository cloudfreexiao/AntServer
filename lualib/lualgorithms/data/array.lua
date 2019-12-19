Array = {}
function Array.equal(a, b)
    if #a ~= #b then
        return false
    end
    for i, k in ipairs(a) do
        if b[i] ~= k then
            return false
        end
    end
    return true
end

function Array.to_string(a)
    local res = '{'
    local size = #a
    for i, k in ipairs(a) do
        res = res .. k
        if i ~= size then
            res = res .. ', '
        end
    end
    return res .. '}'
end

function Array.copy(array)
    local new = {}
    for i, k in ipairs(array) do
        new[i] = k
    end
    return new
end

function Array.slice(array, i, k)
    return {table.unpack(array, i, k)}
end

function Array.find_median(array)
    local sorted = Array.copy(array)
    table.sort(sorted)
    return sorted[math.ceil(#sorted/2)]
    --[[
    --TODO: implement median of medains
    -- https://brilliant.org/wiki/median-finding-algorithm/
    if #array <= 5 then
        local sorted = Array.copy(array)
        table.sort(sorted)
        return sorted[math.ceil(#sorted/2)]
    end
    local median_array = {}
    local new_i = 1
    for i=1,#array,5 do
        median_array[new_i] = Array.find_median(Array.slice(array, i, i+5))
        new_i = new_i + 1
    end
    return Array.find_median(median_array)
    ]]
end
