b3 = require 'behavior3.b3'

local importer = require("behavior3.importer")
importer.enable()

--让本框架里的文件都有ECS这个全局变量
local B3Env = {
	b3 = b3,
}
setmetatable(B3Env, {
	__index = _ENV,	
	__newindex = function (t,k,v)
		--本框架内不允许新增和修改全局变量，实在想要的也可以使用_ENV.xx = yy这种形式
		error("b3 attempt to set a global value", 2)
	end,
})

b3.BaseNode = importer.require('behavior3.core.BaseNode', B3Env) 
b3.Action = importer.require('behavior3.core.Action', B3Env) 
b3.BehaviorTree = importer.require('behavior3.core.BehaviorTree', B3Env) 
b3.Blackboard = importer.require('behavior3.core.Blackboard', B3Env) 
b3.Composite = importer.require('behavior3.core.Composite', B3Env) 
b3.Condition = importer.require('behavior3.core.Condition', B3Env) 
b3.Decorator = importer.require('behavior3.core.Decorator', B3Env) 
b3.Tick = importer.require('behavior3.core.Tick', B3Env) 

b3.Error = importer.require('behavior3.actions.Error', B3Env) 
b3.Failer = importer.require('behavior3.actions.Failer', B3Env) 
b3.Runner = importer.require('behavior3.actions.Runner', B3Env) 
b3.Succeeder = importer.require('behavior3.actions.Succeeder', B3Env) 
b3.Wait = importer.require('behavior3.actions.Wait', B3Env) 

b3.MemPriority = importer.require('behavior3.composites.MemPriority', B3Env) 
b3.MemSequence = importer.require('behavior3.composites.MemSequence', B3Env) 
b3.Priority = importer.require('behavior3.composites.Priority', B3Env) 
b3.Sequence = importer.require('behavior3.composites.Sequence', B3Env) 
b3.Selector = importer.require('behavior3.composites.Selector', B3Env) 

b3.Inverter = importer.require('behavior3.decorators.Inverter', B3Env) 
b3.Limiter = importer.require('behavior3.decorators.Limiter', B3Env) 
b3.MaxTime = importer.require('behavior3.decorators.MaxTime', B3Env) 
b3.Repeater = importer.require('behavior3.decorators.Repeater', B3Env) 
b3.RepeatUntilFailure = importer.require('behavior3.decorators.RepeatUntilFailure', B3Env) 
b3.RepeatUntilSuccess = importer.require('behavior3.decorators.RepeatUntilSuccess', B3Env) 
b3.SubTree = importer.require('behavior3.core.SubTree', B3Env) 


--为了不影响全局，这里要还原一下package.searchers
importer.disable()

return b3





