--[[
raycast module

An extended set of raycasting functions. Useful for situations when you want to do thing like raycast, but only return parts that aren't transparent.
	
API:

Static Functions:
	raycast.FindPartOnRay(ray, ignore, terrainCellsAreCubes, ignoreWater)
		> Same as :FindPartOnRay(ray, ignore, terrainCellsAreCubes, ignoreWater) method
	raycast.FindPartOnRayWithIgnoreList(ray, ignoreList, terrainCellsAreCubes, ignoreWater)
		> Same as :FindPartOnRayWithIgnoreList(ray, ignoreList, terrainCellsAreCubes, ignoreWater) method
	raycast.FindPartOnRayWithWhiteList(ray, whiteList, ignoreWater)
		> Same as :FindPartOnRayWithWhitelist(ray, whiteList, ignoreWater)

	raycast.FindPartOnRayWithBlackAndWhiteList(ray, blackList, whiteList, ignoreWater)
		> Returns hit, position, surfaceNormal, and material of a ray that intersects with instances and their descendants in the whiteList,
		> but not with instances and their descendants in the blackList.
	
Callback functions:
	> These functions are the same as the above except that they require a callback function.
	> Callback functions will be fired with four parameters which represent the variables a raycast would return
		>> hit
		>> position
		>> surfaceNormal
		>> material
	> Callback functions must return one of three states:
		>> raycast.CallbackResult.Continue 	-> The current parameters in the callback function are not what we're looking for, continue the raycast
		>> raycast.CallbackResult.Finished 	-> The current parameters in the callback function are what we're looking for, raycast complete
		>> raycast.CallbackResult.Fail		-> The current parameters in the callback function require that our raycast fail and we return nil
	
	raycast.FindPartOnRayWithCallBack(ray, ignore, terrainCellsAreCubes, ignoreWater, callBackFunc)
		> Same as raycast.FindPartOnRay, but with callback function
	raycast.FindPartOnRayWithCallBackBlackList(ray, blackList, terrainCellsAreCubes, ignoreWater, callBackFunc)
		> Same as raycast.FindPartOnRayWithIgnoreList, but with callback function
	raycast.FindPartOnRayWithCallBackWhiteList(ray, whiteList, ignoreWater, callBackFunc)
		> Same as raycast.FindPartOnRayWithWhiteList, but with callback function

Example: A raycast that ignores transparent parts

local mouse = game.Players.LocalPlayer:GetMouse();
local raycast = require(raycastModule);

mouse.Button1Down:Connect(function()
	local ray = Ray.new(mouse.UnitRay.Origin, mouse.UnitRay.Direction*1000);
	local hit, pos, normal, material = raycast.FindPartOnRayWithCallBack(ray, game.Players.LocalPlayer.Character, false, true, function(hit, pos, normal, material)
		if (not hit) then
			return raycast.CallbackResult.Fail;
		elseif (hit.Transparency == 0) then
			return raycast.CallbackResult.Finished;
		else
			return raycast.CallbackResult.Continue;
		end
	end)
	
	if (hit) then
		print(hit, pos, normal, material)
	else
		print("Nothing was hit!")
	end
end)

Enjoy!
EgoMoose

--]]

local WORKSPACE = game:GetService("Workspace");

--

local MINLENGTH = 1E-4;
local SHIFTDIST = 1E-4;

local CALLBACKRESULT 	= {};
CALLBACKRESULT.Continue = 1;
CALLBACKRESULT.Finished = 2;
CALLBACKRESULT.Fail 	= 3;

--

local raycast = {};

function raycast.FindPartOnRay(ray, ignore, terrainCellsAreCubes, ignoreWater)
	return WORKSPACE:FindPartOnRay(ray, ignore, terrainCellsAreCubes, ignoreWater);
end

function raycast.FindPartOnRayWithIgnoreList(ray, ignoreList, terrainCellsAreCubes, ignoreWater)
	return WORKSPACE:FindPartOnRayWithIgnoreList(ray, ignoreList, terrainCellsAreCubes, ignoreWater);
end

function raycast.FindPartOnRayWithWhiteList(ray, whiteList, ignoreWater)
	return WORKSPACE:FindPartOnRayWithWhitelist(ray, whiteList, ignoreWater);
end

--

raycast.CallbackResult = CALLBACKRESULT;

function raycast.FindPartOnRayWithCallBack(ray, ignore, terrainCellsAreCubes, ignoreWater, callBackFunc)
	local rayLen = ray.Direction.magnitude;
	local unitDir = ray.Direction.unit;
	
	while (true) do
		local hit, pos, normal, material = WORKSPACE:FindPartOnRay(ray, ignore, terrainCellsAreCubes, ignoreWater);
		local result = callBackFunc(hit, pos, normal, material);

		if (result == CALLBACKRESULT.Continue) then
			rayLen = rayLen - (pos - ray.Origin).magnitude;
			if (rayLen < MINLENGTH) then
				return;
			end
			ray = Ray.new(pos+unitDir*SHIFTDIST, unitDir*rayLen);
		elseif (result == CALLBACKRESULT.Finished) then
			return hit, pos, normal, material;
		elseif (result == CALLBACKRESULT.Fail or result == nil) then
			return;
		end
	end
end

function raycast.FindPartOnRayWithCallBackBlackList(ray, blackList, terrainCellsAreCubes, ignoreWater, callBackFunc)
	local rayLen = ray.Direction.magnitude;
	local unitDir = ray.Direction.unit;
	
	while (true) do
		local hit, pos, normal, material = WORKSPACE:FindPartOnRayWithIgnoreList(ray, blackList, terrainCellsAreCubes, ignoreWater);
		local result = callBackFunc(hit, pos, normal, material);
		
		if (result == CALLBACKRESULT.Continue) then
			rayLen = rayLen - (pos - ray.Origin).magnitude;
			if (rayLen < MINLENGTH) then
				return;
			end
			ray = Ray.new(pos+unitDir*SHIFTDIST, unitDir*rayLen);
		elseif (result == CALLBACKRESULT.Finished) then
			return hit, pos, normal, material;
		elseif (result == CALLBACKRESULT.Fail or result == nil) then
			return;
		end
	end
end

function raycast.FindPartOnRayWithCallBackWhiteList(ray, whiteList, ignoreWater, callBackFunc)
	local rayLen = ray.Direction.magnitude;
	local unitDir = ray.Direction.unit;
	
	while (true) do
		local hit, pos, normal, material = WORKSPACE:FindPartOnRayWithWhitelist(ray, whiteList, ignoreWater);
		local result = callBackFunc(hit, pos, normal, material);
		if (result == CALLBACKRESULT.Continue) then
			rayLen = rayLen - (pos - ray.Origin).magnitude;
			if (rayLen < MINLENGTH) then
				return;
			end
			ray = Ray.new(pos+unitDir*SHIFTDIST, unitDir*rayLen);
		elseif (result == CALLBACKRESULT.Finished) then
			return hit, pos, normal, material;
		elseif (result == CALLBACKRESULT.Fail or result == nil) then
			return;
		end
	end
end

function raycast.FindPartOnRayWithBlackAndWhiteList(ray, blackList, whiteList, ignoreWater)
	return raycast.FindPartOnRayWithCallBackWhiteList(ray, whiteList, ignoreWater, function(hit, pos, normal, material)
		if (not hit) then
			return CALLBACKRESULT.Finished;
		end
		
		for i = 1, #blackList do
			if (hit == blackList[i] or hit:IsDescendantOf(blackList[i])) then
				return CALLBACKRESULT.Continue;
			end
		end
		
		return CALLBACKRESULT.Finished;
	end)
end

-- 	

return raycast;
		
