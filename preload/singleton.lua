
return function (classname, super)
	local obj = {}
	obj.__index = obj
	setmetatable(obj, super)

	function obj.new(...)
		if obj._instance then
            return obj._instance
		end

		local instance = setmetatable({}, obj)
        if instance.initialize then
            instance:initialize(...)
		end

		obj._instance = instance
        return obj._instance
	end

	obj._name = classname

	return obj
end
