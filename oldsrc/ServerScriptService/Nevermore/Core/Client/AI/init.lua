local module = {}
local AI = {}

---
-- @module AI
-- @author VirtualButFake

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Astar = require(script.AStar)

--// AI Functions
function AI.Setup(Config)
	local meta = setmetatable(AI,{})
	meta:EditAggression(Config)
	
	meta.Timer = 0
	meta.Enabled = true
	meta.AIPosOffset = Vector3.new(0,2,0)
	
	-- determine start node
	local NearestNode = Config.NodeMap.Octree:KNearestNeighborsSearch(Config.StartPosition,1,100)
	meta.State = {
		CurrentNode = NearestNode
	}
	
	-- setup clock for AI action
	meta.Connection = RunService.RenderStepped:Connect(function(dt)
		if meta.Config.Enabled then
			meta.Timer += dt
			
			if meta.Timer > meta.Config.Interval then 
				meta.Timer = 0
				meta:Update()
			end
		end
	end)
end

module.new = AI.Setup

function AI:Path(startNode,endNode)
	local nodemap = self.Config.NodeMap
	
	return Astar.path(startNode, endNode, nodemap.NodesDirect, true, function(node,neighbour)
		local AdjacentNodes = nodemap:GetNodeRelations(nodemap:GetNode(node.XIndex,node.ZIndex))

		for _, node in AdjacentNodes do 
			local nodePart = node[3] or node[2]

			if nodePart.XIndex == neighbour.XIndex and nodePart.ZIndex == neighbour.ZIndex then
				return true
			end
		end

		return false
	end)
end

function AI:EditAggression(Config)
	local aiTable = {} -- goes off of aggression unless it finds values capable of replacing it
	local aggression = Config.Aggression or 1

	-- determine base values
	local AIValues = {
		["Interval"] = function()
			return 5.5 - (math.clamp(aggression - 1,0,4) * .5)
		end,
		["RNGFactor"] = function()
			return 1 + (.05 * aggression)
		end,
		["HearingRange"] = function()
			return 125 + (math.clamp(aggression - 1,0,4) * 20)
		end,
		["RoomChance"] = function()
			return math.clamp(aggression - 3,0,2) * .05
		end,
		["DetectionSpeed"] = function()
			return 9 - aggression * 1
		end,
	}

	for id, value in AIValues do -- __iter
		Config[id] = Config[id] or AIValues[id](aggression)
	end
	
	self.Config = Config
end

function AI:Update()
	print("Updating")
end

function AI:RegisterSound(position)
	--local magnitude = 
end

return module
