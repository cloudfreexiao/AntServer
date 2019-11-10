local succeeder = b3.Class("Succeeder", b3.Action)
b3.Succeeder = succeeder

function succeeder:ctor(params)
	b3.Action.ctor(self,params)

	self.name = "Succeeder"
end

function succeeder:tick(tick)
	return b3.SUCCESS
end

return succeeder