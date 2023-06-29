local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- 

local Nevermore = require(ReplicatedStorage:WaitForChild("Nevermore"))
local NodeMain = Nevermore("NodeMain")
local Maid = Nevermore("Maid")
local spr = Nevermore("spr")

--

local module = {}
module.__index = module

function module.new(name,start)
	local nodeMap = NodeMain.new(name)

	start = start or Vector3.new(0,0,0)

	local startNode = nodeMap:GetClosestNode(start)
	local maid = Maid.new()

	return setmetatable({
		StartNode = startNode,
		NodeMap = nodeMap,
		Maid = maid
	}, module)
end

function module:Enable()
	local Camera = workspace.CurrentCamera
	Camera.CameraType = Enum.CameraType.Scriptable


	local currentDirection = "Right"

	local currentRotation = Instance.new("NumberValue")
	local Rotation3D = Instance.new("Vector3Value") -- this is inefficient, but I'm lazy
	local currentCameraPosition = Instance.new("Vector3Value")
	local lerp = Instance.new("NumberValue")
	local lerp2 = Instance.new("NumberValue")
	
	local TargetCF = Instance.new("CFrameValue")
	local TargetCF2 = Instance.new("CFrameValue")
	
	local currentTime = 0

	local BOB_FREQUENCY_X = 2
	local BOB_FREQUENCY_Y = 1
	local BOB_AMPLITUDE_X = 3
	local BOB_AMPLITUDE_Y = 1.5

	local cameraAngle = Vector2.new(0,0)
	local velocityMultiplier = 0

	local fov = Instance.new("NumberValue")

	self.Maid:GiveTask(currentRotation)
	self.Maid:GiveTask(Rotation3D)
	self.Maid:GiveTask(currentCameraPosition)
	self.Maid:GiveTask(fov)

	local CameraBob = CFrame.new()
	local currentIntendedRotation = 0
	local currentNode = self.StartNode
	local currentNodeRelations = self.NodeMap:GetNodeRelations(currentNode)
	local debounce = false

	local selectedNode
	local selectedDoor
	local targetCF
	local LerpCF
	local LerpCF2
	
	local lastCameraPosition

	local DirectionOrder = {
		"Front",
		"Left",
		"Back",
		"Right"
	}

	-- bobbing
	local function scalarLerp(a, b, c)
		c = math.clamp(c, 0, 1)
		return a + c *	(b - a)
	end

	function self.GetDirection()
		return currentDirection,table.find(DirectionOrder,currentDirection)
	end

	local function updateCF()
		targetCF = CFrame.new(currentCameraPosition.Value) * 
			script.Values.CameraOffset.Value *
			CFrame.fromEulerAnglesYXZ(math.rad(Rotation3D.Value.X),math.rad(currentRotation.Value),math.rad(Rotation3D.Value.Z)) *
			CameraBob

		LerpCF = TargetCF.Value *
			script.Values.CameraOffset.Value *
			CameraBob
		
		LerpCF2 = TargetCF2.Value *
			script.Values.CameraOffset.Value *
			CameraBob
		
		local l1 = targetCF:Lerp(LerpCF,lerp.Value)
		local l2 = l1:Lerp(LerpCF2,lerp2.Value)

		Camera.CFrame = l2
	end
	
	function self.getCurrentPosition()
		return CFrame.new(currentCameraPosition.Value) * 
			script.Values.CameraOffset.Value *
			CFrame.fromEulerAnglesYXZ(math.rad(Rotation3D.Value.X),math.rad(currentRotation.Value),math.rad(Rotation3D.Value.Z))
	end

	function self.MoveNode(new,override)
		if debounce and override ~= true then return end 

		currentNode = new 
		currentNodeRelations = self.NodeMap:GetNodeRelations(new)

		spr.target(currentCameraPosition,.83,.3,{
			Value = new.Node.Position
		})

		debounce = true 

		selectedNode = nil

		for i,v in pairs(currentNodeRelations) do 
			if v[1] == currentDirection then 
				selectedNode = i
			end
		end
		
		if selectedDoor then 
			self.ChangeDirection(0,true,{.83,6,.3})
		else 
			self.ChangeDirection(0,true,{.83,.3})
		end

		if override ~= true then 
			task.delay(2.3,function()
				debounce = false
			end)
		end
		--editCameraCF(CFrame.new(new.Node.Position) * CFrame.Angles(0,math.rad(currentIntendedRotation),0))
		self.Maid["AttributeChanged"] = currentNode.Node.AttributeChanged:Connect(function()
			self.ChangeDirection(0,true)
		end)
	end

	self.Maid["AttributeChanged"] = currentNode.Node.AttributeChanged:Connect(function()
		self.ChangeDirection(0,true)
	end)

	function self.ChangeDirection(increment,override,springSettings)	
		if debounce and not override then return end 

		if override ~= true then
			debounce = true 
		end

		local current = table.find(DirectionOrder,currentDirection)

		if increment == 0 then 
			local direction = currentDirection
			springSettings = springSettings or {.8,1.5}

			if currentNode.Node:GetAttribute(direction .. "ViewAngle") then 
				if typeof(currentNode.Node:GetAttribute(direction .. "ViewAngle")) == "Vector3" then 
					spr.target(currentRotation,springSettings[1],springSettings[3] or springSettings[2],{
						Value = currentIntendedRotation + (increment - currentNode.Node:GetAttribute(direction .. "ViewAngle").Y)
					})

					local attribute = currentNode.Node:GetAttribute(direction .. "ViewAngle")

					spr.target(Rotation3D,springSettings[1],springSettings[3] or springSettings[2],{
						Value = Vector3.new(attribute.X,0,attribute.Z)
					})
				else 
					spr.target(currentRotation,springSettings[1],springSettings[3] or springSettings[2],{
						Value = currentIntendedRotation + (increment - currentNode.Node:GetAttribute(direction .. "ViewAngle"))
					})

					spr.target(Rotation3D,springSettings[1],springSettings[3] or springSettings[2],{
						Value = Vector3.new(0,0,0)
					})
				end
			else 
				spr.target(currentRotation,springSettings[1],springSettings[2],{
					Value = currentIntendedRotation + increment
				})

				spr.target(Rotation3D,springSettings[1],springSettings[2],{
					Value = Vector3.new(0,0,0)
				})
			end 

			return
		end

		local add = increment > 0 and 1 or - 1

		if increment == 180 then 
			add = 2
		end

		if current == 4 then 
			if add == 1 then
				current = 0
			end

			if add == 2 then 
				current = 0
			end
		elseif current == 1 then 
			if add == -1 then
				current = 5
			end
		elseif current == 3 then 
			if add == 2 then
				current = -1
			end
		end

		current += add

		local direction = DirectionOrder[current]

		if currentNode.Node:GetAttribute(direction .. "ViewAngle") then 
			if typeof(currentNode.Node:GetAttribute(direction .. "ViewAngle")) == "Vector3" then 

				spr.target(currentRotation,.8,1.5,{
					Value = currentIntendedRotation + (increment - currentNode.Node:GetAttribute(direction .. "ViewAngle").Y)
				})

				local attribute = currentNode.Node:GetAttribute(direction .. "ViewAngle")

				spr.target(Rotation3D,.8,1.5,{
					Value = Vector3.new(attribute.X,0,attribute.Z)
				})
			else 
				spr.target(currentRotation,.8,1.5,{
					Value = currentIntendedRotation + (increment - currentNode.Node:GetAttribute(direction .. "ViewAngle"))
				})

				spr.target(Rotation3D,.8,1.5,{
					Value = Vector3.new(0,0,0)
				})
			end
		else 
			spr.target(currentRotation,.8,1.5,{
				Value = currentIntendedRotation + increment
			})

			spr.target(Rotation3D,.8,1.5,{
				Value = Vector3.new(0,0,0)
			})
		end

		currentIntendedRotation = currentIntendedRotation + increment
		currentDirection = direction

		task.delay(.5,function()
			debounce = false
		end)

		selectedNode = nil

		for i,v in pairs(currentNodeRelations) do
			if v[1] == currentDirection then 
				selectedNode = i
			end
		end
	end

	currentCameraPosition.Value = self.StartNode.Node.Position
	updateCF()
	self.ChangeDirection(90)

	self.Maid["CameraChanged"] = script.Values.CameraOffset.Changed:Connect(function()
		updateCF()
	end)

	self.Maid["Input"] = UIS.InputBegan:Connect(function(input,gp)
		if gp then return end 

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if selectedDoor and selectedDoor.inFront and selectedDoor.PeepHole ~= true and selectedDoor.Interacting ~= true then 
				selectedDoor.Interacting = true 
				
				local doorPart = selectedDoor.DoorPart.Parent.Peephole
				local doorPos = doorPart.Position
				local cmp = Camera.CFrame.Position - doorPos
				local doorLV = doorPart.CFrame.LookVector

				local cf 
				local originCF = doorPart.CFrame * CFrame.new(0,0,0) * script.Values.CameraOffset.Value:Inverse()

				if cmp:Dot(doorLV) < 0 then
					cf = doorPart.CFrame * CFrame.new(0,0,2) * script.Values.CameraOffset.Value:Inverse()
				else 
					cf = doorPart.CFrame * CFrame.new(0,0,-2) * script.Values.CameraOffset.Value:Inverse()
				end

				local oldPos = currentCameraPosition.Value

				TargetCF2.Value = CFrame.lookAt(cf.Position,originCF.Position)
				
				spr.target(lerp2,.8,.9,{
					Value = 1
				})
				
				wait(.7)
				selectedDoor.PeepHole = true
			elseif selectedDoor and selectedDoor.PeepHole == true then
				selectedDoor.PeepHole = nil
				spr.target(lerp2,.8,.9,{
					Value = 0
				})
				
				wait(.7)
				selectedDoor.Interacting = false 
			end
		end
		
		if input.UserInputType == Enum.UserInputType.Keyboard then 
			if input.KeyCode == Enum.KeyCode.A then 
				self.ChangeDirection(90)
			elseif input.KeyCode == Enum.KeyCode.D then 
				self.ChangeDirection(-90)
			elseif input.KeyCode == Enum.KeyCode.S then 
				if selectedDoor and selectedDoor.Interacting ~= true then 
					spr.target(currentCameraPosition,.8,.4,{
						Value = selectedDoor.OldPos
					})

					self.DeselectInteract(1)
					selectedDoor.Interacting = true

					task.wait(.8)
					
					selectedDoor.Module.Close(self,selectedDoor.DoorPart)

					task.wait(.8)
					
					self.SetDebounce(false)
					selectedDoor = nil
				elseif selectedDoor and selectedDoor.PeepHole then 
					selectedDoor.PeepHole = nil
					spr.target(lerp2,.8,.9,{
						Value = 0
					})
					
					spr.target(currentCameraPosition,.8,.4,{
						Value = selectedDoor.OldPos
					})

					self.DeselectInteract(1)
					selectedDoor.Interacting = true

					task.wait(.8)
					selectedDoor.Module.Close(self,selectedDoor.DoorPart)

					task.wait(.8)
					self.SetDebounce(false)
					selectedDoor = nil
				elseif selectedDoor == nil then 
					self.ChangeDirection(180)
				end
			elseif input.KeyCode == Enum.KeyCode.W then 
				if selectedNode and selectedDoor == nil then  
					if currentNodeRelations[selectedNode][3] ~= nil and debounce == false then
						-- get dot product
						local doorPart = currentNodeRelations[selectedNode][2].InteractionModel.DoorMain
						local doorPos = doorPart.Position
						local cmp = Camera.CFrame.Position - doorPos
						local doorLV = doorPart.CFrame.LookVector
						self.SetDebounce(true)

						local cf 
						local originCF = doorPart.CFrame * CFrame.new(0,-2,0)

						if cmp:Dot(doorLV) < 0 then
							cf = doorPart.CFrame * CFrame.new(0,-2,6)
						else 
							cf = doorPart.CFrame * CFrame.new(0,-2,-6)
						end

						local oldPos = currentCameraPosition.Value

						spr.target(currentCameraPosition,.83,.33,{
							Value = CFrame.lookAt(cf.Position,originCF.Position).Position
						})

						self.MoveTo(CFrame.lookAt(cf.Position,originCF.Position),.33)

						task.wait(1.3)
						local doorType = doorPart:GetAttribute("DoorType")
						local m = require(script.DoorModules:FindFirstChild(doorType))
						
						selectedDoor = {
							DoorPart = doorPart,
							Node = selectedNode,
							Module = m,
							OldPos = oldPos,
							inFront = true
						}
					else 
						self.MoveNode(selectedNode)
					end
				elseif selectedDoor and selectedDoor.Interacting ~= true then 
					if selectedDoor.inFront == true then 
						selectedDoor.Interacting = true
						
						if selectedDoor.Module.Open(self,selectedDoor.DoorPart) then 
							task.wait(.4)
							selectedDoor.inFront = nil 
							selectedDoor.Interacting = false
						end
					else 
						self.DeselectInteract(.5)

						self.MoveNode(selectedDoor.Node,true)					

						local module = selectedDoor.Module
						local dp = selectedDoor.DoorPart

						selectedDoor = nil

						task.delay(2,function()
							self.Maid.RSTask = nil
							module.Close(self,dp)
							self.SetDebounce(false)
						end)
					end
				end
			end
		end
	end)

	-- skidded from https://devforum.roblox.com/t/configurable-head-bobbing-script/1505850 (im bad at math)
	self.Maid["RenderStepped"] = RunService.RenderStepped:Connect(function(dt)
		if lastCameraPosition == nil then
			lastCameraPosition = currentCameraPosition.Value
			return
		end

		local diff = (lastCameraPosition - currentCameraPosition.Value).Magnitude
		currentTime += dt

		local nextFov = math.clamp(70 * (diff + .9),70,75)

		TweenService:Create(fov,TweenInfo.new(.05,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
			Value = nextFov
		}):Play()

		Camera.FieldOfView = fov.Value

		local FocusRadius = math.clamp(60 * math.clamp(math.abs(diff - .5) * 2,0,1),30,60)
		Lighting.DepthOfField.InFocusRadius = FocusRadius

		local bobOffsetY = (math.sin(currentTime * math.pi * BOB_FREQUENCY_Y) - 0.5) * BOB_AMPLITUDE_Y
		local bobOffsetX = (math.sin(currentTime * math.pi * BOB_FREQUENCY_X) - 0.5) * BOB_AMPLITUDE_X

		local velocityMagnitude = diff * 6
		local targetVelocityMultiplier = math.clamp(velocityMagnitude, 0, 16) / 16

		velocityMultiplier = scalarLerp(velocityMultiplier, targetVelocityMultiplier, 3 * dt)

		bobOffsetX *= velocityMultiplier
		bobOffsetY *= velocityMultiplier

		lastCameraPosition = currentCameraPosition.Value

		cameraAngle = Vector2.new(
			cameraAngle.X, 
			math.clamp(cameraAngle.Y, math.rad(-85), math.rad(85))
		) 

		CameraBob = 
			CFrame.new(Vector3.new(0,bobOffsetY,0)) *
			CFrame.Angles(0,cameraAngle.X,0) *
			CFrame.Angles(cameraAngle.Y,0,0) *
			CFrame.new(bobOffsetX,0,0)

		updateCF()
	end)

	self.GetDebounce = function()
		return debounce 
	end

	self.SetDebounce = function(v)
		debounce = v
	end

	self.MoveTo = function(cf,freq)
		if typeof(cf) == "Vector3" then 
			spr.target(currentCameraPosition,.83,.3,{
				Value = cf
			})
		else 
			TargetCF.Value = cf

			lerp.Value = 0
			
			spr.target(lerp,.8,freq or .7,{
				Value = 1
			})
		end
	end

	self.DeselectInteract = function(freq)
		freq = freq or .7

		spr.target(lerp,.8,freq,{
			Value = 0
		})
	end
end

function module:Destroy()
	self.Maid:DoCleaning()
end

return module
