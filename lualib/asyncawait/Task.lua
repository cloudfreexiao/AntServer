local Awaiter = require('asyncawait.Awaiter')
local try = require('asyncawait.TryCatchFinally').try
local TaskMetatable
TaskMetatable = {
    __needRef = true,
    __call = function(t, awaiter)
        if (type(awaiter)=='table'and awaiter.__type ~= 'Awaiter')then
            t.__ori(Awaiter.new(awaiter))
        end
        t.__ori(awaiter)
    end,
    await = function(t,awaiter)
        try {
            function()
                t.__ori(awaiter)
            end,
            catch = function(ex)
                print('task await ex')
                awaiter:onError(ex)
            end
        }
    end,
    new = function(base)
        if (type(base)=='table')then
            return base
        elseif (type(base)=='function')then
            return setmetatable({ __ori = base, __type = 'Task'}, TaskMetatable)
        else
            error(base)
        end
    end
}
TaskMetatable.__index = TaskMetatable
return TaskMetatable