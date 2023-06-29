local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- 

local Nevermore = require(ReplicatedStorage:WaitForChild("Nevermore"))
local Maid = Nevermore("Maid")
local mouse = Nevermore("mouse2")
local spring = Nevermore("spring")

mouse.TargetFilter = {}

-- 

local module = {}
module.__index = module

function module.new(movement)
	-- will just create a flashlight object & connect everything.
	local Flashlight = script.Flashlight:Clone()
	Flashlight.Parent = workspace.CurrentCamera
	
	local CamLight = script.Light:Clone()
	CamLight.Parent = workspace.CurrentCamera
	
	local meta = {
		Flashlight = Flashlight,
		Maid = Maid.new(),
		Enabled = false,
		Light = Flashlight.Light,
		CamLight = CamLight,
		Power = 140,
	}
	
	local gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainUI"):WaitForChild("BatteryUI"):WaitForChild("FillBar")
	
	meta.Maid.RSTask = RunService.RenderStepped:Connect(function(dt)
		local mouseHit = mouse.Hit
		local startPos = (workspace.CurrentCamera.CFrame  * CFrame.new(0,0,1)).Position

		local lookAt = CFrame.lookAt(Vector3.new(
			math.round(startPos.X * 5) / 5,
			math.round(startPos.Y * 5) / 5,
			math.round(startPos.Z * 5) / 5
		),mouseHit.Position)
		
		TweenService:Create(Flashlight.Light,TweenInfo.new(.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
			CFrame = lookAt
		}):Play()
		
		meta.CamLight.CFrame = workspace.CurrentCamera.CFrame
		
		if meta.Enabled then
			meta.Power = math.clamp(meta.Power - 10 * dt,0,140)
		elseif meta.LastOff == nil or tick() - meta.LastOff > 1 then
			meta.Power = math.clamp(meta.Power + 8 * dt,0,140)
		end
		
		if meta.Power < 1 and meta.Enabled then 
			meta.Light.NoPower:Play()
			meta.Lock = true
			meta:Disable()
		end
		
		TweenService:Create(gui.UIGradient,TweenInfo.new(.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
			Offset = Vector2.new(0,-(meta.Power / 135))
		}):Play()
		
		if meta.Lock and meta.Power == 140 then
			meta.Lock = nil
		end
	end)
	
	meta.Maid.Mouse = mouse.Button1Down:Connect(function()
		if workspace.Interactables:FindFirstChild("Highlight",true) and workspace.Interactables:FindFirstChild("Highlight",true).OutlineTransparency ~= 1 then return end 
		
		if meta.Enabled then 
			meta:Disable()
		else 
			meta:Enable()
		end
	end)
	
	meta = setmetatable(meta,module)
	return meta
end

function module:Enable()
	self.Light.On:Play()
	
	if self.Lock ~= true then 
		self.Enabled = true
		
		TweenService:Create(self.Light.Light,TweenInfo.new(.6,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
			Brightness = .5
		}):Play()
		
		TweenService:Create(self.Light.Shadow,TweenInfo.new(.6,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
			Brightness = .6
		}):Play()
	end
end

function module:Disable()
	self.Enabled = false
	self.Light.Off:Play()
	self.LastOff = tick()

	TweenService:Create(self.Light.Light,TweenInfo.new(.3,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
		Brightness = 0
	}):Play()

	TweenService:Create(self.Light.Shadow,TweenInfo.new(.3,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{
		Brightness = 0
	}):Play()
end


return module
