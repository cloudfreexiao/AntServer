local M = {}
--default xpcall
M.xpcall = _G.xpcall
--default errorHandler
M.errorHandler = function(info)
    local tbl = { info = info, traceback = debug.traceback()}
    local str = tostring(tbl)
    return setmetatable(tbl,{__tostring = function(t)
        return str..'(use ex.info & ex.traceback to view detail)'
    end})
end

function M.try(block)
    local main = block[1]
    local catch = block.catch
    local finally = block.finally
    assert(main,'main function not found')
    -- try to call it
    local ok, errors = M.xpcall(main, M.errorHandler)
    if not ok then
        -- run the catch function
        if catch then
            catch(errors)
        end
    end

    -- run the finally function
    if finally then
        finally(ok, errors)
    end

    -- ok?
    if ok then
        return errors
    end
end

return M