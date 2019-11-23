return function (target, ...)
    local args = {...}
    for i=1, #args do
        local tbl = args[i] or {}
        for k, v in pairs(tbl) do
            target[k] = v
        end
    end
    return target
end
