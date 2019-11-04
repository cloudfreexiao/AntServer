return function (obj, method, data)
    return function(...)
        if obj and data then
            return method(obj, data, ...)
        elseif obj and not data then
            return method(obj, ...)
        else
            return method(...)
        end
    end
end