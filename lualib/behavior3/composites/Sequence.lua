local sequence = b3.Class("Sequence", b3.Composite)
b3.Sequence = sequence

function sequence:ctor(params)
	b3.Composite.ctor(self,params)

	self.name = "Sequence"
end

function sequence:tick(tick)
	for i,v in pairs(self.children) do
		local status = v:_execute(tick)

		if status ~= b3.SUCCESS then
			return status
		end
	end
	return b3.SUCCESS
end

return sequence
