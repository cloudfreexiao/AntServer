require "errorcode"
require "luaext"
require "logger_api"

class = require "middleclass"


local inspect_lib = require "inspect"
function inspect(value)
    return inspect_lib(value, {
    process = function(item, path)
        if type(item) == "function" then
            return nil
        end
        
        if path[#path] == inspect_lib.METATABLE then
            return nil
        end
        
        return item
    end,
    newline = " ",
    indent = ""
})
end

function DUMP(value)
    return inspect_lib(value, {
    process = function(item, path)
        return item
    end,
    newline = " ",
    indent = ""
})
end

function TraceBack()
    for level = 1, math.huge do
        local info = debug.getinfo(level, "nSl")
        if not info then break end
        if info.what == "C" then -- is a C function?
            DEBUG(level, "C function")
        else
            DEBUG(info.name,string.format("%d, [%s] : %d", level, info.short_src, info.currentline))
        end
    end
end
