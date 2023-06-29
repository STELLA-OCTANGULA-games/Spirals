---
-- @module NodeMain
-- @author VirtualButFake

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace") -- no actual benefits over using "workspace", but good practice

-- Modules
local require = require(ReplicatedStorage:WaitForChild("Nevermore"))
local Octree = require("Octree")

-- Variables
local NodeMain = {}
NodeMain.__index = NodeMain

local function getModel(part)
	local parent = part 

	repeat 
		parent = parent.Parent
	until parent.Parent == workspace.Doors

	return parent
end

function NodeMain.new(name)
	local nodeFolder = Workspace.Nodes:FindFirstChild(name)
	
	assert(nodeFolder ~= nil,("Could not find nodes for name %s"):format(name))

	-- Setup node maps
	local NodeMap = {}
	local OctreeMap = Octree.new() -- create both a table & octree map, allows me to pack information with nodes
	
	local Positions = {}
	
	for _,node in nodeFolder:GetChildren() do 
		local position = node.Position 
		
		table.insert(Positions,{
			Node = node,
			PositionX = math.ceil(position.X),
			PositionZ = math.ceil(position.Z)
		})
		
		OctreeMap:CreateNode(position,node)
	end
	
	-- Group positions & then sort them
	NodeMap.Nodes = {}
	NodeMap.NodesDirect = {}
	
	for _,nodeInfo in pairs(Positions) do 
		if NodeMap.Nodes[nodeInfo.PositionX] == nil then 
			NodeMap.Nodes[nodeInfo.PositionX] = {}
		end
		
		if NodeMap.Nodes[nodeInfo.PositionX][nodeInfo.PositionZ] == nil then 
			NodeMap.Nodes[nodeInfo.PositionX][nodeInfo.PositionZ] = {}
		end
		
		NodeMap.Nodes[nodeInfo.PositionX][nodeInfo.PositionZ] = nodeInfo
	end
	
	-- now sort them by index instead of number
	local TableIndex = 1
	local TempTable = {}
	
	local NodeOrder = {}
	
	for i,nodeContainer in NodeMap.Nodes do 
		local ChildrenIndex = {}
		
		for CI,_ in nodeContainer do 
			table.insert(ChildrenIndex,CI)
		end
		
		table.sort(ChildrenIndex,function(a,b)
			return a > b
		end)
		
		table.insert(NodeOrder,{
			SelfI = i,
			ChildrenIndex = ChildrenIndex
		})
	end
	
	table.sort(NodeOrder,function(a,b)
		return a.SelfI > b.SelfI
	end)
	
	for TableIndex,TableInfo in NodeOrder do 
		local NodeContainer = NodeMap.Nodes[TableInfo.SelfI]
		
		TempTable[TableIndex] = {}
		
		for SubIndex,v in TableInfo.ChildrenIndex do 
			local Node = NodeContainer[v]

			Node.XIndex = TableIndex
			Node.ZIndex = SubIndex

			TempTable[TableIndex][SubIndex] = Node
			NodeMap.NodesDirect[Node.Node] = Node

			Node.Node.Name = ("%s %s"):format(TableIndex,SubIndex)
		end
	end
	
	NodeMap.Nodes = TempTable
	NodeMap.Octree = OctreeMap
	
	return setmetatable(NodeMap,NodeMain)
end

function NodeMain:GetNode(x,z,inverse)
	if inverse then 
		assert(self.Nodes[z] and self.Nodes[z][x],("A node at %s,%s does not exist."):format(z,x))

		return self.Nodes[z][x]
	else 
		assert(self.Nodes[x] and self.Nodes[x][z],("A node at %s,%s does not exist."):format(x,z))

		return self.Nodes[x][z]
	end
end

function NodeMain:GetClosestNode(position,radius)
	assert(typeof(position) == "Vector3",("Position has to be a Vector3. Got: %s"):format(typeof(position)))
	
	local part,pos = self.Octree:KNearestNeighborsSearch(position,1,radius or 100)
	
	if part and part[1] and self.NodesDirect[part[1]] then 
		return self.NodesDirect[part[1]]
	end
end

function NodeMain:GetClosestNodes(max,position,radius)
	assert(typeof(position) == "Vector3",("Position has to be a Vector3. Got: %s"):format(typeof(position)))

	local part = self.Octree:KNearestNeighborsSearch(position,max or 9,radius or 100)

	return part
end

function NodeMain:GetNodeRelations(node)
	assert(node,"No Node was provided.")
	
	--[[-- Determine closest 4 nodes, all in their respective directions.
	local NodeX = node.XIndex
	local NodeZ = node.ZIndex
	
	-- inefficient: determine directions by getting 9 closest
	local ClosestNodes = self:GetClosestNodes(9,node.Node.Position,100)
	local ViableDirections = {}
	
	local NodeDistances = {}
	
	for i,v in pairs(ClosestNodes) do 
		local vNode = self.NodesDirect[v]
		
		local diff = math.abs(vNode.PositionX - node.PositionX) + math.abs(vNode.PositionZ - node.PositionZ)
		
		table.insert(NodeDistances,diff)
		
		ViableDirections[vNode] = {
			Difference = diff,
			Node = vNode
		}
	end	

	-- determine the positions & use cframe magic to determine what side its on
	local directionCheck = {
		["Left"] = CFrame.Angles(0,math.rad(90),0),
		["Right"] = CFrame.Angles(0,math.rad(-90),0),
		["Front"] = CFrame.Angles(0,math.rad(0),0),
		["Back"] = CFrame.Angles(0,math.rad(180),0)
	}
	
	local removeAmount = 4
	
	local viableDetected = -1
	
	for i,v in pairs(ViableDirections) do 
		local lookAt = CFrame.lookAt(node.Node.Position,i.Node.Position)
		local x,y,z = lookAt:ToEulerAnglesXYZ()
		
		if (math.abs(math.deg(y)) > 65 and math.abs(math.deg(y)) < 110) or (math.deg(y) > -10 and math.abs(math.deg(y)) < 25) then 
			viableDetected += 1
		end
	end
	
	if viableDetected ~= 4 then 
		removeAmount = 6
	end
	
	print(NodeDistances)
	
	for i = 1,removeAmount do 
		local highest = math.max(unpack(NodeDistances))
		
		table.remove(NodeDistances,table.find(NodeDistances,highest))
	end
	
	ViableDirections = {}
	
	for i,v in pairs(ClosestNodes) do 
		local vNode = self.NodesDirect[v]
		local diff = math.abs(vNode.PositionX - node.PositionX) + math.abs(vNode.PositionZ - node.PositionZ)
		
		if table.find(NodeDistances,diff) then 
			ViableDirections[i] = vNode
		else 
			vNode.Node.BrickColor = BrickColor.new("Black")
		end
	end 
	
	print(viableDetected)
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = {workspace.Map}
	
	for direction,info in ViableDirections do 
		-- raycast towards each & figure out whether it's hittable
		local LookAt = CFrame.lookAt(node.Node.Position,info.Node.Position)
		local Unit = LookAt.LookVector * (node.Node.Position - info.Node.Position).Magnitude
		
		local result = workspace:Raycast(node.Node.Position,Unit,params)
		
		if result then 
			ViableDirections[direction] = nil
			info.Node.BrickColor = BrickColor.new("Black")
		else 
			info.Node.BrickColor = BrickColor.new("Pink")
		end
	end
	
	return ViableDirections]]
	
	--[[
	
		functionality
		
		find nearest neighbours 
		sort neighbours by smallest x and z diff
	
	]]
	
	local ClosestNodes = self:GetClosestNodes(9,node.Node.Position,500)
	
	for i,v in ClosestNodes do 
		if v == node.Node then 
			table.remove(ClosestNodes,i)
		end
	end
	
	-- figure out corners. we can do this by checking the x and z position, and checking whether they're off by a lot
	local PositionData = {
		X = {},
		Z = {}
	}
	
	local actualPoints = {}
	
	for i,v in pairs(ClosestNodes) do 
		local Node = self.NodesDirect[v]
		local XDiff = math.abs(Node.PositionX - node.PositionX)
		local ZDiff = math.abs(Node.PositionZ - node.PositionZ)

		if (XDiff < 12 or ZDiff < 12) then 
			table.insert(actualPoints,Node)
		end
	end
	
	-- determine what side they're on
	local PosData = {
		["Right"] = Vector3.new(0,0,1),
		["Left"] = Vector3.new(0,0,-1),
		["Front"] = Vector3.new(1,0,0),
		["Back"] = Vector3.new(-1,0,0)
	}
	
	local bestMatches = {}
	
	for i,v in pairs(actualPoints) do 
		local magnitudes = {}
		
		for name,posAdd in PosData do 
			local nodePos = node.Node.Position + posAdd 
			local mag = (v.Node.Position - nodePos).Magnitude 
			
			table.insert(magnitudes,{
				Name = name,
				Mag = mag
			})
		end
		
		table.sort(magnitudes,function(a,b)
			return a.Mag > b.Mag
		end)
		
		bestMatches[v] = magnitudes[1]
	end
	
	local sortedThings = {}
	
	for i,v in pairs(bestMatches) do 
		if sortedThings[v.Name] == nil then
			sortedThings[v.Name] = {
				Mag = v.Mag,
				Object = i
			}
		end
		
		if sortedThings[v.Name].Mag > v.Mag then 
			sortedThings[v.Name] = {
				Mag = v.Mag,
				Object = i
			}
		end
	end
	
	bestMatches = {}
	
	for i,v in pairs(sortedThings) do 
		bestMatches[v.Object] = {
			i,
			v.Object
		}
	end
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = {workspace.Map}

	for _,info in actualPoints do 
		-- raycast towards each & figure out whether it's hittable
		local LookAt = CFrame.lookAt(node.Node.Position,info.Node.Position)
		local Unit = LookAt.LookVector * (node.Node.Position - info.Node.Position).Magnitude

		local result = workspace:Raycast(node.Node.Position,Unit,params)

		if result then 
			bestMatches[info] = nil
		end
	end
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = {workspace.Doors}

	for _,info in actualPoints do 
		-- raycast towards each & figure out whether it's hittable
		local LookAt = CFrame.lookAt(node.Node.Position,info.Node.Position)
		local Unit = LookAt.LookVector * (node.Node.Position - info.Node.Position).Magnitude

		local result = workspace:Raycast(node.Node.Position,Unit,params)

		if result and bestMatches[info] then 
			bestMatches[info] = {
				bestMatches[info][1],
				getModel(result.Instance),
				info
			}
		end
	end
	
	return bestMatches
end

return NodeMain
