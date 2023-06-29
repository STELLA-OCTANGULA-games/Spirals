local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- 

local Nevermore = require(ReplicatedStorage:WaitForChild("Nevermore"))
local Maid = Nevermore("Maid")
local mouse = Nevermore("mouse")

--

local module = {}
module.__index = module

function module.new(movementManager)
	return setmetatable({
		Manager = movementManager,
		Maid = Maid.new()
	},module)
end

function module:Enable()
	-- setup mouse connection
	local Mouse = Players.LocalPlayer:GetMouse()
	local currentInteractionObject = nil
	
	local interactionStatus = nil
	
	local function getModel(part)
		local parent = part 
		
		repeat 
			parent = parent.Parent
		until parent.Parent == workspace.Interactables
		
		return parent
	end
	
	--
	
	local function updateInteraction(model)
		local old = currentInteractionObject		
		
		if old ~= nil and model ~= old.Model then 
			TweenService:Create(old.Highlight,TweenInfo.new(.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
				OutlineTransparency = 1
			}):Play()
			
			task.delay(.5,function()
				old.Highlight:Destroy()
			end)

			currentInteractionObject = nil
		end
		
		if model ~= nil and (old == nil or model ~= old.Model) then
			local Highlight = Instance.new("Highlight")
			Highlight.FillTransparency = 1
			Highlight.FillColor = Color3.fromRGB(255,255,255)
			Highlight.OutlineTransparency = 1
			
			Highlight.Parent = model.InteractionModel
			
			TweenService:Create(Highlight,TweenInfo.new(.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
				OutlineTransparency = .97
			}):Play()
			
			currentInteractionObject = {
				Highlight = Highlight,
				Model = model
			}
		end
	end
	
	self.Maid.MouseConnection = RunService.RenderStepped:Connect(function(dt)
		local currentHit = mouse.Target
		
		if currentHit and currentHit:IsDescendantOf(workspace.Interactables) then 
			Mouse.Icon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
			updateInteraction(getModel(currentHit))
		else 
			updateInteraction()
			Mouse.Icon = ""
		end
	end)
	
	self.Maid.UIS = UIS.InputBegan:Connect(function(input,gp)
		if gp then return end 
		
		if input.UserInputType == Enum.UserInputType.Keyboard then 
			if input.KeyCode == Enum.KeyCode.S then 
				if interactionStatus and interactionStatus.Busy ~= true then 
					self.Manager.DeselectInteract()
					wait(1)
					self.Manager.SetDebounce(false)
					interactionStatus = nil
				end
			end
		end
	end)
	
	self.Maid.LMB = mouse.Button1Down:Connect(function()
		if currentInteractionObject and interactionStatus == nil then
			local Node = currentInteractionObject.Model.Node
			
			if Node:GetAttribute("InteractType") == "2" then 
	 			self.Manager.MoveTo(Node.CFrame)
				self.Manager.SetDebounce(true)
				
				interactionStatus = {
					Type = Node:GetAttribute("InteractType"),
					Module = script.Modules:FindFirstChild(Node:GetAttribute("Module")),
					FirstClick = true,
					Busy = true
				}
				
				task.wait(1)
				interactionStatus.Busy = false
			else 
				self.Manager.SetDebounce(true)
				require(script.Modules:FindFirstChild(Node:GetAttribute("Module")))(self.Manager,currentInteractionObject)
			end 
		elseif interactionStatus ~= nil and interactionStatus.Type == "2" and interactionStatus.FirstClick == true and interactionStatus.Busy ~= true then 
			interactionStatus.FirstClick = false
			local req = require(interactionStatus.Module)
			req(self.Manager,currentInteractionObject)
			
			interactionStatus = nil
		end
	end)
end

return module
