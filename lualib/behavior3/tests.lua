require 'behavior3.index'


local log = b3.Class("log", b3.Action)

function log:ctor(params)
	b3.Action.ctor(self,params)

	self.info = params.info
end

function log:tick(tick)
	print(self.info)
	return b3.SUCCESS
end


TestLoader = {}

--从导出树载入
function TestLoader:testLoadTree()
	print("testLoadTree...")
	local file=io.open("lualib/behavior3/testbt.json", 'r')
	local txt = file:read("*a")
	local blackBoard = b3.Blackboard.new()

	local behaviorTree = b3.BehaviorTree.new()
	behaviorTree:loadjson(txt, {log=log})
	behaviorTree:tick(nil, blackBoard)

end

--从导出工程载入，包含子树的示例
function TestLoader:testSubtreeLoadFromProject()
	print("testSubtreeLoadFromProject...")
	local file=io.open("lualib/behavior3/testsubtree.json", 'r')
	local txt = file:read("*a")
	local blackBoard = b3.Blackboard.new()
	local treeMap = {}
	local treeMapByTitle = {}
	local custom = {log=log}
	b3.SetSubTreeLoadFunc(function(id)
		return treeMap[id]
	end)


	local projectConf = b3.decode_json(txt)
	for k, conf in pairs(projectConf.trees) do
		if conf.title=="testsub" or conf.title=="testsubtree" then
			print("load tree:",conf.title)
			local behaviorTree = b3.BehaviorTree.new()
			behaviorTree:load(conf, custom)
			treeMap[conf.id] = behaviorTree
			treeMapByTitle[conf.title] = behaviorTree
		end
	end

	treeMapByTitle["testsubtree"]:tick(nil, blackBoard)
end

return TestLoader