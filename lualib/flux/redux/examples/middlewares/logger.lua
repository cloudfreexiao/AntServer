local Logger = require 'src.utils.logger'

local function logger(store)
    return function (nextDispatch)
        return function (action)
            Logger.info('WILL DISPATCH:', action)
            local ret = nextDispatch(action)
            Logger.info('STATE AFTER DISPATCH:', store.getState())
            return ret

        end
    end
end

return logger
