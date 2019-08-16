require 'GameCore.3Party.behavior3.core.Composite'

local sequence = b3.Class("Sequence", b3.Composite)
b3.Sequence = sequence

function sequence:ctor(params)
	b3.Composite.ctor(self,params)

	self.name = "Sequence"
end

function sequence:tick(tick)
	--print("sequence start",self.title)
	for i,v in pairs(self.children) do
		local status = v:_execute(tick)

		if status ~= b3.SUCCESS then
			--print("sequence child fail",self.title,v.title)
			return status
		end
	end
	--print("sequence all succ",self.title)
	return b3.SUCCESS
end
