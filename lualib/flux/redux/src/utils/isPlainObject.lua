---
-- @param {any} obj The object to inspect.
-- @returns {boolean} True if the argument appears to be a plain object.
--
return function (tbl)
    if type(tbl) ~= 'table' then
        return false
    end
    return getmetatable(tbl) == nil
end
