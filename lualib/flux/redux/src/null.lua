local mt = {}

function mt.__newindex()
    error("attempt to modify a Null value.", 2)
end

function mt.__index()
    error("attempt to index a Null value.", 2)
end

return setmetatable({}, mt)
