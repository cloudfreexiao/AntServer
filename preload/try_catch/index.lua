-- 异常捕获
-- _G.try_catch = function (block)
return function (block)
    local main = block.main
    local catch = block.catch
    local finally = block.finally
    assert(main)
    -- try to call it
    local ok, errors = xpcall(main, debug.traceback)
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