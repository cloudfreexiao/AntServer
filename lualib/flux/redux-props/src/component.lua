local function assign(target, ...)
    local args = {...}
    for i=1, #args do
        local tbl = args[i] or {}
        for k, v in pairs(tbl) do
            target[k] = v
        end
    end
    return target
end

local function isPropsChanged(prevProps, nextProps)
    for k,v in pairs(prevProps) do
        if nextProps[k] ~= v then
            return true
        end
    end
    for k,v in pairs(nextProps) do
        if prevProps[k] ~= v then
            return true
        end
    end
    return false
end


-- private
local function applyProps(self, props)
    if isPropsChanged(self.props, props) then
        self:propsWillChange(self.props, props)
        self.props = props
        self:propsDidChange()
    end
end


local Component = {}

local function suppressWarning()
    -- suppress luacheck warnings
end

function Component:constructor(props)
    local propsType = type(props)
    assert(propsType == 'table' or propsType == 'nil',
        string.format('invalid props type (a %s value)', propsType))

    props = assign({}, props)
    self.props = props
    self.ownProps = props
end

function Component:extends()
    local class = {}
    setmetatable(class, self)
    self.__index = self
    return class
end

function Component:new(props)
    local obj = {}
    obj.extends = function ()
        error('attempt to extends from an instance')
    end
    obj.new = function ()
        error('attempt to create instance from an instance')
    end
    setmetatable(obj, self)
    self.__index = self

    obj:constructor(props)

    return obj
end

function Component:propsWillChange(prevProps, nextProps)
    suppressWarning(self, prevProps, nextProps)
end

function Component:propsDidChange()
    suppressWarning(self)
end

function Component:destroy()
    suppressWarning(self)
end

function Component:setReduxProps(stateProps, dispatchProps)
    local props = assign({}, self.ownProps, stateProps, dispatchProps)
    applyProps(self, props)
end

function Component:updateProps(props)
    local propsType = type(props)
    assert(propsType == 'table', string.format('props is not a table (a %s value)', propsType))

    for k,_ in pairs(self.ownProps) do
        if props[k] then
            self.ownProps[k] = props[k]
        end
    end
    local fullProps = assign({}, self.props, props)
    applyProps(self, fullProps)
end

function Component:getOwnProps()
    return self.ownProps
end

return Component
