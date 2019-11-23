local directory = (...):match("(.-)[^%.]+$")
local Provider = require(directory .. 'provider')
local Component = require(directory .. 'component')

local function isComponent(comp)
    local mt = getmetatable(comp)
    while mt ~= nil do
        if mt == Component then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

local function connect(mapStateToProps, mapDispatchToProps)
    local store = Provider.store
    return function (comp)

        local function errFunc() end
        if store == nil then
            return errFunc
        end
        if not isComponent(comp) then
            return errFunc
        end

        return function (ownProps)
            local obj = comp:new(ownProps)

            local dispatchProps = {}
            local stateProps = {}
            if type(mapDispatchToProps) == 'function' then
                dispatchProps = mapDispatchToProps(store.dispatch, ownProps)
            end

            if type(mapStateToProps) == 'function' then
                stateProps = mapStateToProps(store.getState(), ownProps)
            end

            obj:setReduxProps(stateProps, dispatchProps)

            if type(mapStateToProps) ~= 'function' then
                -- we don't need to handle state changes any more
                return obj
            end

            local isDestroyed = false
            local function stateChanged()
                if isDestroyed then return end
                ownProps = obj:getOwnProps()
                stateProps = mapStateToProps(store.getState(), ownProps)
                obj:setReduxProps(stateProps, dispatchProps)
            end

            -- wrap `destroy` function to call `unsubscribe` function
            local destroy = obj.destroy
            local unsubscribe = store.subscribe(stateChanged)
            obj.destroy = function (...)
                unsubscribe()
                if type(destroy) == 'function' then
                    destroy(...)
                end
                isDestroyed = true
            end
            return obj
        end
    end
end

return connect
