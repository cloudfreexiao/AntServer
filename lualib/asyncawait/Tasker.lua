local Task = require('asyncawait.Task')
local Awaiter = require('asyncawait.Awaiter')
local objInvoke = function(obj,methodName)
	return function(...)
		obj[methodName](obj,...)
	end
end

local Source
Source = {
	Create = function(obj)
		return setmetatable({
			obj = obj
		},Source)
	end,
	dispatch = function(self)
		self.awaiter:onSuccess(self.obj)
	end,
	await = function(self,awaiter)
		self.awaiter = awaiter
	end
}
Source.__index = Source

local Tasker
local create = function(source,base)
	local tasker = setmetatable({
		base = Task.new(base),
		source = source,
	}, Tasker)
	tasker.source = source
	return tasker
end

Tasker = {
    Error = function(ex)
        return function(awaiter)
            awaiter:onError(ex)
        end
    end,
    Success = function(obj)
        return Task.new(function(awaiter)
            awaiter:onSuccess(obj)
        end)
    end,
	Create = function(task)
		return Tasker.Just(nil):taskMap(function()
			return task
		end)
	end,
	Just = function(obj)
		local source = Source.Create(obj)
		return create(source,source)
	end,
	taskMap = function(self,func)
		return create(self.source,function(awaiter)
			self.base:await(Awaiter.new{
				onSuccess = function(obj)
					Task.new(func(obj)):await(awaiter)
				end,
				onError = objInvoke(awaiter,'onError')
			})
		end)
	end,
	map = function(self,func)
		return create(self.source,function(awaiter)
			self.base:await(Awaiter.new{
				onSuccess = function(obj)
					awaiter:onSuccess(func(obj))
				end,
				onError = objInvoke(awaiter,'onError')
			})
		end)
	end,
	retryWhen = function(self,func)
		return create(self.source,function(awaiter)
			self.base:await(Awaiter.new{
				onSuccess = objInvoke(awaiter,'onSuccess'),
				onError = function(ex)
					Task.new(func(ex)):await(Awaiter.new{
						onSuccess = function()

							self.source:dispatch()


						end,
						onError = objInvoke(awaiter,'onError')
					})
				end,
			})
		end)
	end,
	doOnError = function(self,func)
		return create(self.source,function(awaiter)
			self.base:await(Awaiter.new{
				onSuccess = objInvoke(awaiter,'onSuccess'),
				onError = function(ex)
					Task.new(func(ex)):await(awaiter)
				end,
			})
		end)
	end,
	await = function(self,awaiter)
		self.base:await(Awaiter.new(awaiter))
		self.source:dispatch()
	end,
	toTask = function(self)
		return function(awaiter)
			self.base:await(awaiter)
			self.source:dispatch()
		end
	end
}

Tasker.__index = Tasker

return Tasker






