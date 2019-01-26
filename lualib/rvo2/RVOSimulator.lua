local RVOMath = require "rvo2.RVOMath"
local Vector = require "rvo2.Vector"
local KdTree = require "rvo2.KdTree"
local Agent = require "rvo2.Agent"
local Obstacle = require "rvo2.Obstacle"

local RVOSimulator = class("RVOSimulator")

function RVOSimulator:ctor()
	self.agents = Vector.new() -- Agent[]
	self.obstacles = Vector.new() -- Obstacle[]
	self.goals = Vector.new() -- Vector2
    self.kdTree = KdTree.new( self )
    
    self.timeStep = 0.25
    
    self.defaultAgent = nil -- Agent
    self.time = 0.0
end


function RVOSimulator:getGlobalTime()
	return self.time
end

function RVOSimulator:getNumAgents()
	return self.agents.length
end

function RVOSimulator:getTimeStep()
	return self.timeStep
end

function RVOSimulator:setAgentPrefVelocity(i, velocity)
    self.agents:get()[i].prefVelocity = velocity
end

function RVOSimulator:setTimeStep(timeStep)
    self.timeStep = timeStep
end

function RVOSimulator:getAgentPosition(i)
    return self.agents:get()[i].position
end

function RVOSimulator:getAgentPrefVelocity(i)
    return self.agents:get()[i].prefVelocity
end

function RVOSimulator:getAgentVelocity(i)
    return self.agents:get()[i].velocity
end

function RVOSimulator:getAgentRadius(i)
    return self.agents:get()[i].radius
end

function RVOSimulator:getAgentOrcaLines(i)
    return self.agents:get()[i].orcaLines
end

function RVOSimulator:addAgent(position)
    if not self.defaultAgent then
        return "no default agent"
    end

    local agent = Agent.new( self )

    agent.position = position
    agent.maxNeighbors = self.defaultAgent.maxNeighbors
    agent.maxSpeed = self.defaultAgent.maxSpeed
    agent.neighborDist = self.defaultAgent.neighborDist
    agent.radius = self.defaultAgent.radius
    agent.timeHorizon = self.defaultAgent.timeHorizon
    agent.timeHorizonObst = self.defaultAgent.timeHorizonObst
    agent.velocity = self.defaultAgent.velocity

    agent.id = self.agents.length
    self.agents:push(agent)

    return self.agents.length - 1
end

function RVOSimulator:setAgentDefaults(neighborDist, maxNeighbors, timeHorizon, timeHorizonObst, radius,  maxSpeed, velocity)

    if not self.defaultAgent then
        self.defaultAgent = Agent.new( self )
    end

    self.defaultAgent.maxNeighbors = maxNeighbors
    self.defaultAgent.maxSpeed = maxSpeed
    self.defaultAgent.neighborDist = neighborDist
    self.defaultAgent.radius = radius
    self.defaultAgent.timeHorizon = timeHorizon
    self.defaultAgent.timeHorizonObst = timeHorizonObst
    self.defaultAgent.velocity = velocity
end

function RVOSimulator:doStep()	
	self.kdTree:buildAgentTree()

    for i=0,self:getNumAgents()-1 do
        self.agents:get()[i]:computeNeighbors()
        self.agents:get()[i]:computeNewVelocity()
        self.agents:get()[i]:update()
    end
	
	self.time = self.time + self.timeStep
end

function RVOSimulator:reachedGoal()
    for i=0,self:getNumAgents()-1 do
        if (RVOMath.absSq (self.goals:get()[i]:minus(self:getAgentPosition(i))) > RVOMath.RVO_EPSILON) then
            return false
        end
    end
	return true
end

function RVOSimulator:addGoals(goals)
	self.goals = goals
end

function RVOSimulator:getGoal(goalNo)
    return self.goals:get()[goalNo]
end

function RVOSimulator:addObstacle( vertices )
    if vertices.length < 2 then
        return -1
    end

    local obstacleNo = self.obstacles.length

    for i=0,vertices.length-1 do
        local obstacle = Obstacle.new()
        obstacle.point = vertices:get()[i]
        if (i ~= 0) then
            obstacle.prevObstacle = self.obstacles:get()[self.obstacles.length - 1]
            obstacle.prevObstacle.nextObstacle = obstacle
        end
        if (i == vertices.length - 1) then
            obstacle.nextObstacle = self.obstacles:get()[obstacleNo]
            obstacle.nextObstacle.prevObstacle = obstacle
        end

        obstacle.unitDir = RVOMath.normalize(vertices:get()[RVOMath.judgeReturn( i == vertices.length - 1, 0, i + 1 )]:minus(vertices:get()[i]))

        if (vertices.length == 2) then
            obstacle.isConvex = true
        else
            local a = RVOMath.judgeReturn( i == 0, vertices.length - 1, i - 1 )
            local b = RVOMath.judgeReturn( i == vertices.length - 1, 0, i + 1 )
            obstacle.isConvex = (RVOMath.leftOf(vertices:get()[a], vertices:get()[i], vertices:get()[b]) >= 0)
        end

        obstacle.id = self.obstacles.length

        self.obstacles:push(obstacle)
    end

    return obstacleNo
end

function RVOSimulator:processObstacles()
    self.kdTree:buildObstacleTree()
end

local queryVisibility = function(point1, point2, radius)
    return self.kdTree.queryVisibility(point1, point2, radius)
end

function RVOSimulator:getObstacles()
	return self.obstacles
end


return RVOSimulator