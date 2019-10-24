require 'behavior3.core.Composite'

local priority = b3.Class("Priority", b3.Composite)
b3.Priority = priority

function priority:ctor(params)
	b3.Composite.ctor(self,params)

	self.name = "Priority"
end

function priority:tick(tick)
	--print("priority start",self.title)
	for i,v in pairs(self.children) do
		local status = v:_execute(tick)

		if status ~= b3.FAILURE then
			--print("priority child succ",self.title,v.title)
			return status
		end
	end
	--print("priority all fail",self.title)
	return b3.FAILURE
end

