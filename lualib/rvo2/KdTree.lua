local MAXLEAF_SIZE = 100
local Vector = irequire "rvo2.Vector"
local Vector2 = require "rvo2.Vector2"
local RVOMath = require "rvo2.RVOMath"
-----------------------------------------------
-------------FloatPair-------------------------
-----------------------------------------------
local FloatPair = class("FloatPair")

function FloatPair:ctor( a, b )
	self.a = a
	self.b = b
end

function FloatPair:mt(rhs)
	return self.a < rhs.a or not(rhs.a < self.a) and self.b < rhs.b
end
		
function FloatPair:met(rhs)
	return (self.a == rhs.a and self.b == rhs.b) or self:mt(rhs) 
end

function FloatPair:gt(rhs)
	return not self:met(rhs)
end

function FloatPair:get(rhs)
	return not self:mt(rhs)
end

-----------------------------------------------
-------------AgentTreeNode---------------------
-----------------------------------------------
local AgentTreeNode = class("AgentTreeNode")

-----------------------------------------------
-------------ObstacleTreeNode------------------
-----------------------------------------------
local ObstacleTreeNode = class("ObstacleTreeNode")

-----------------------------------------------
-------------KdTree----------------------------
-----------------------------------------------
local KdTree = class("KdTree")

function KdTree:ctor( sim )
	self.simulator = sim
	self.agents = Vector.new()
	self.agentTree = Vector.new()
	self.obstacleTree = {}
end

function KdTree:buildAgentTreeRecursive( begin, ends, node )
	self.agentTree:get()[node].begin = begin
	self.agentTree:get()[node].ends = ends
	self.agentTree:get()[node].maxX = self.agents:get()[begin].position.x
	self.agentTree:get()[node].maxY = self.agents:get()[begin].position.y
	self.agentTree:get()[node].minX = self.agentTree:get()[node].maxX
	self.agentTree:get()[node].minY = self.agentTree:get()[node].maxY

	for i=begin+1,ends-1 do
		self.agentTree:get()[node].maxX = math.max(self.agentTree:get()[node].maxX, self.agents:get()[i].position.x)
		self.agentTree:get()[node].minX = math.min(self.agentTree:get()[node].minX, self.agents:get()[i].position.x)
		self.agentTree:get()[node].maxY = math.max(self.agentTree:get()[node].maxX, self.agents:get()[i].position.y)
		self.agentTree:get()[node].minY = math.min(self.agentTree:get()[node].minY, self.agents:get()[i].position.y)
	end

	if ends - begin > MAXLEAF_SIZE then
		local isVertical = self.agentTree:get()[node].maxX - self.agentTree:get()[node].minX > self.agentTree:get()[node].maxY - self.agentTree:get()[node].minY
		local splitValue = RVOMath.judgeReturn( isVertical, 0.5 * (self.agentTree:get()[node].maxX + self.agentTree:get()[node].minX), 0.5 * (self.agentTree:get()[node].maxY + self.agentTree:get()[node].minY ))
		
		local left = begin
		local right = ends

		while left < right do
			while left < right and RVOMath.judgeReturn(isVertical, self.agents:get()[left].position.x, self.agents:get()[left].position.y) < splitValue do
				left = left + 1
			end

			while right > left and RVOMath.judgeReturn(isVertical, self.agents:get()[right - 1].position.x, self.agents:get()[right - 1].position.y) >= splitValue do
				right = right - 1
			end

			if left < right then
				local tmp = self.agents:get()[left]
				self.agents:get()[left] = self.agents:get()[right - 1]
 				self.agents:get()[right - 1] = tmp
 				left = left + 1
				right = right - 1
			end
		end

		local leftSize = left - begin

		if eftSize == 0 then
			leftSize = leftSize + 1
			left = left + 1
			right = right + 1
		end

		self.agentTree:get()[node].left = node + 1
		self.agentTree:get()[node].right = node + 1 + (2 * leftSize - 1)

		self:buildAgentTreeRecursive(begin, left, self.agentTree:get()[node].left)
		self:buildAgentTreeRecursive(left, ends, self.agentTree:get()[node].right)
	end

end

function KdTree:buildAgentTree()
	if self.agents.length ~= self.simulator:getNumAgents() then
		self.agents = self.simulator.agents
		for i=0,2*self.agents.length-1 do
			self.agentTree:push(AgentTreeNode.new())
		end
	end
	if self.agents.length > 0 then
		self:buildAgentTreeRecursive(0, self.agents.length, 0)
	end
end

function KdTree:buildObstacleTreeRecursive( obstacles )
	if obstacles.length == 0 then
		return nil
	end
	local node = ObstacleTreeNode.new()
	local optimalSplit = 0
	local minLeft, minRight = obstacles.length, obstacles.length

	for i=0,obstacles.length-1 do
		local leftSize = 0
		local rightSize = 0

		local obstacleI1 = obstacles:get()[i]
		local obstacleI2 = obstacleI1.nextObstacle

		for j=0,obstacles.length-1 do
			if i ~= j then
				local obstacleJ1 = obstacles:get()[j]
				local obstacleJ2 = obstacleJ1.nextObstacle
				local j1LeftOfI = RVOMath.leftOf(obstacleI1.point, obstacleI2.point, obstacleJ1.point)
                local j2LeftOfI = RVOMath.leftOf(obstacleI1.point, obstacleI2.point, obstacleJ2.point)

                if j1LeftOfI >= -RVOMath.RVO_EPSILON and j2LeftOfI >= -RVOMath.RVO_EPSILON then
                	leftSize = leftSize + 1
                elseif j1LeftOfI <= RVOMath.RVO_EPSILON and j2LeftOfI <= RVOMath.RVO_EPSILON then
                	rightSize = rightSize + 1
                else
                	leftSize = leftSize + 1
 					rightSize = rightSize + 1
                end

                local fp1 = FloatPair.new(math.max(leftSize, rightSize), math.min(leftSize, rightSize))
                local fp2 = FloatPair.new(math.max(minLeft, minRight), math.min(minLeft, minRight))

                if fp1:get(fp2) then
                	break
                end
			end
		end

		local fp1 = FloatPair.new(math.max(leftSize, rightSize), math.min(leftSize, rightSize))
		local fp2 = FloatPair.new(math.max(minLeft, minRight), math.min(minLeft, minRight))

		if fp1:mt(fp2) then
			minLeft = leftSize
			minRight = rightSize
			optimalSplit = i
		end
	end

	local leftObstacles = Vector.new()
	leftObstacles:resize( minLeft )
	local rightObstacles = Vector.new()
	rightObstacles:resize( minRight )

	local leftCounter = 0
    local rightCounter = 0
    local i = optimalSplit

    local obstacleI1 = obstacles:get()[i]
    local obstacleI2 = obstacleI1.nextObstacle

    for j=0,obstacles.length-1 do
    	if i ~= j then
    		local obstacleJ1 = obstacles:get()[j]
            local obstacleJ2 = obstacleJ1.nextObstacle

            local j1LeftOfI = RVOMath.leftOf(obstacleI1.point, obstacleI2.point, obstacleJ1.point)
            local j2LeftOfI = RVOMath.leftOf(obstacleI1.point, obstacleI2.point, obstacleJ2.point)

            if j1LeftOfI >= -RVOMath.RVO_EPSILON and j2LeftOfI >= -RVOMath.RVO_EPSILON then
            	leftObstacles:get()[leftCounter] = obstacles:get()[j]
            	leftCounter = leftCounter + 1
            elseif j1LeftOfI <= RVOMath.RVO_EPSILON and j2LeftOfI <= RVOMath.RVO_EPSILON then
            	rightObstacles:get()[rightCounter] = obstacles:get()[j]
            	rightCounter = rightCounter + 1
            else
            	local t = RVOMath.det(obstacleI2.point:minus(obstacleI1.point), obstacleJ1.point:minus(obstacleI1.point)) / RVOMath.det(obstacleI2.point:minus(obstacleI1.point), obstacleJ1.point:minus(obstacleJ2.point))
            	local splitpoint = obstacleJ1.point:plus( (obstacleJ2.point:minus(obstacleJ1.point)):scale(t) )

            	local newObstacle = Obstacle.new()
                newObstacle.point = splitpoint
                newObstacle.prevObstacle = obstacleJ1
                newObstacle.nextObstacle = obstacleJ2
                newObstacle.isConvex = true
                newObstacle.unitDir = obstacleJ1.unitDir
                newObstacle.id = self.simulator.obstacles.length

                self.simulator.obstacles:push( newObstacle )

                obstacleJ1.nextObstacle = newObstacle
                obstacleJ2.prevObstacle = newObstacle

                if j1LeftOfI > 0.0 then
                	leftObstacles:get()[leftCounter] = obstacleJ1
                	leftCounter = leftCounter + 1
                    rightObstacles:get()[rightCounter] = newObstacle
                    rightCounter = rightCounter + 1
                else
                	rightObstacles:get()[rightCounter] = obstacleJ1
                	rightCounter = rightCounter + 1
                    leftObstacles:get()[leftCounter] = newObstacle
                    leftCounter = leftCounter + 1
                end
            end
    	end
    end

    node.obstacle = obstacleI1
    node.left = self:buildObstacleTreeRecursive(leftObstacles)
    node.right = self:buildObstacleTreeRecursive(rightObstacles)
    return node
end

function KdTree:buildObstacleTree()
	local obstacles = self.simulator.obstacles
	self.obstacleTree = self:buildObstacleTreeRecursive(obstacles)
end

function KdTree:computeObstacleNeighbors( agent, rangeSq )
	self:queryObstacleTreeRecursive(agent, rangeSq, self.obstacleTree)
end

function KdTree:queryAgentTreeRecursive( agent, rangeSq, node )
	if self.agentTree:get()[node].ends - self.agentTree:get()[node].begin <= MAXLEAF_SIZE then
		for i=self.agentTree:get()[node].begin,self.agentTree:get()[node].ends-1 do
			agent:insertAgentNeighbor(self.agents:get()[i], rangeSq)
		end
	else
		local distSqLeft = RVOMath.sqr(math.max(0, self.agentTree:get()[self.agentTree:get()[node].left].minX - agent.position.x)) + RVOMath.sqr(math.max(0, agent.position.x - self.agentTree:get()[self.agentTree:get()[node].left].maxX)) + RVOMath.sqr(math.max(0, self.agentTree:get()[self.agentTree:get()[node].left].minY - agent.position.y)) + RVOMath.sqr(math.max(0, agent.position.y - self.agentTree:get()[self.agentTree:get()[node].left].maxY))
		local distSqRight = RVOMath.sqr(Math.max(0, self.agentTree:get()[self.agentTree:get()[node].right].minX - agent.position.x)) + RVOMath.sqr(Math.max(0, agent.position.x - self.agentTree:get()[self.agentTree:get()[node].right].maxX)) + RVOMath.sqr(Math.max(0, self.agentTree:get()[self.agentTree:get()[node].right].minY - agent.position.y)) + RVOMath.sqr(Math.max(0, agent.position.y - self.agentTree:get()[self.agentTree:get()[node].right].maxY))
		
		if distSqLeft < distSqRight then
			if distSqLeft < rangeSq then
				self:queryAgentTreeRecursive(agent, rangeSq, self.agentTree:get()[node].left)

				if distSqRight < rangeSq then
					self:queryAgentTreeRecursive(agent, rangeSq, self.agentTree:get()[node].right)
				end
			end
		else
			if distSqRight < rangeSq then
				self:queryAgentTreeRecursive(agent, rangeSq, self.agentTree:get()[node].right)
				if distSqLeft < rangeSq then
					self:queryAgentTreeRecursive(agent, rangeSq, self.agentTree:get()[node].left)
				end
			end
		end
	end
end

function KdTree:computeAgentNeighbors( agent, rangeSq )
	self:queryAgentTreeRecursive(agent, rangeSq, 0)
end

function KdTree:queryObstacleTreeRecursive( agent, rangeSq, node )
	if node == nil then
		return
	end

	local obstacle1 = node.obstacle
    local obstacle2 = obstacle1.nextObstacle

    local agentLeftOfLine = RVOMath.leftOf(obstacle1.point, obstacle2.point, agent.position)

    self:queryObstacleTreeRecursive(agent, rangeSq, RVOMath.judgeReturn(agentLeftOfLine >= 0, node.left, node.right))

    local distSqLine = RVOMath.sqr(agentLeftOfLine) / RVOMath.absSq(obstacle2.point:minus(obstacle1.point))

    if distSqLine < rangeSq then
    	if agentLeftOfLine < 0 then
    		agent:insertObstacleNeighbor(node.obstacle, rangeSq)
    	end
    	self:queryObstacleTreeRecursive(agent, rangeSq, RVOMath.judgeReturn(agentLeftOfLine >= 0, node.right, node.left))
    end
end

function KdTree:queryVisibility( q1, q2, radius )
	return self:queryVisibilityRecursive(q1, q2, radius, self.obstacleTree)
end

function KdTree:queryVisibilityRecursive( q1, q2, radius, node )
	if node == nil then
		return true
	end

	local obstacle1 = node.obstacle
    local obstacle2 = obstacle1.nextObstacle

    local q1LeftOfI = RVOMath.leftOf(obstacle1.point, obstacle2.point, q1)
    local q2LeftOfI = RVOMath.leftOf(obstacle1.point, obstacle2.point, q2)
    local invLengthI = 1.0 / RVOMath.absSq(obstacle2.point:minus(obstacle1.point))

    if q1LeftOfI >= 0 and q2LeftOfI >= 0 then
    	return self:queryVisibilityRecursive(q1, q2, radius, node.left) and ((RVOMath.sqr(q1LeftOfI) * invLengthI >= RVOMath.sqr(radius) and RVOMath.sqr(q2LeftOfI) * invLengthI >= RVOMath.sqr(radius)) or self:queryVisibilityRecursive(q1, q2, radius, node.right))
    elseif q1LeftOfI <= 0 and q2LeftOfI <= 0 then
    	return self:queryVisibilityRecursive(q1, q2, radius, node.right) and ((RVOMath.sqr(q1LeftOfI) * invLengthI >= RVOMath.sqr(radius) and RVOMath.sqr(q2LeftOfI) * invLengthI >= RVOMath.sqr(radius)) or self:queryVisibilityRecursive(q1, q2, radius, node.left))
    elseif q1LeftOfI >= 0 and q2LeftOfI <= 0 then
    	return self:queryVisibilityRecursive(q1, q2, radius, node.left) and self:queryVisibilityRecursive(q1, q2, radius, node.right)
    else
    	local point1LeftOfQ = RVOMath.leftOf(q1, q2, obstacle1.point)
        local point2LeftOfQ = RVOMath.leftOf(q1, q2, obstacle2.point)
        local invLengthQ = 1.0 / RVOMath.absSq(q2:minus(q1))

        return (point1LeftOfQ * point2LeftOfQ >= 0 and RVOMath.sqr(point1LeftOfQ) * invLengthQ > RVOMath.sqr(radius) and RVOMath.sqr(point2LeftOfQ) * invLengthQ > RVOMath.sqr(radius) and self:queryVisibilityRecursive(q1, q2, radius, node.left) and self:queryVisibilityRecursive(q1, q2, radius, node.right))
    end
end


return KdTree