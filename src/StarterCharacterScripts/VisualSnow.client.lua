--!strict

local Players = game:GetService 'Players'
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character :: Model

local PlayerGui = localPlayer.PlayerGui
local visualSnowGui = PlayerGui:WaitForChild 'VisualSnow'
local noiseSequence = visualSnowGui:WaitForChild 'NoiseSequence'

-- Set the transparency of all the images in the noise sequence to 1 so they're invisible by default
for _, image in noiseSequence:GetChildren() do
	if image:IsA 'ImageLabel' then
		image.ImageTransparency = 1
	end
end

print(character)
