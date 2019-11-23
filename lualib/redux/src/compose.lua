local directory = (...):match("(.-)[^%.]+$")
local Array = require(directory..'helpers.array')

--[[
    Composes single-argument functions from right to left. The rightmost
    function can take multiple arguments as it provides the signature for
    the resulting composite function.

    @param {...Function} funcs The functions to compose.
    @returns {Function} A function obtained by composing the argument functions
    from right to left. For example, compose(f, g, h) is identical to doing
    (...args) => f(g(h(...args))).
--]]

local function compose(...)
    local funcs = {...}
    if #funcs == 0 then
        return function(argument)
            return argument
        end
    end

    if #funcs == 1 then
        return funcs[1]
    end

    return Array.reduce(
        funcs,
        function(a, b)
            return function (...)
                return a(b(...))
            end
        end
    )
end

return compose
