--[[

	Main Client Handler
	
	Handles everything
	
	Tijn Epema

]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 

local Nevermore = require(ReplicatedStorage:WaitForChild("Nevermore"))
local NodeMain = Nevermore("NodeMain")

-- Movement
workspace:WaitForChild(game.Players.LocalPlayer.Name)

local Movement = require(script.Movement)
local MovementMain = Movement.new("Main",Vector3.new(355.76, 6.806, -148.524))
MovementMain:Enable()

-- setup interactor
local Interaction = require(script.Interaction)
local InteractorMain = Interaction.new(MovementMain)
InteractorMain:Enable()

-- flashlight
local Flashlight = require(script.Flashlight)
Flashlight.new(MovementMain)

-- setup ai
local AI = Nevermore("AI")
AI.new({
	Aggression = 5,
	NodeMap = MovementMain.NodeMap,
	StartPosition = Vector3.new(196.56, 6.806, -238.924)
})