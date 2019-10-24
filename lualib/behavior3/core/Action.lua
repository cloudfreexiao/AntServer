require 'behavior3.core.BaseNode'

local action = b3.Class("Action", b3.BaseNode)
b3.Action = action

function action:ctor(params)
	b3.BaseNode.ctor(self,params)

	self.category = b3.ACTION
end