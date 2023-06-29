--[[

UserInputServiceMouse module

Ever hate having to use the player mouse or the plugin mouse? Well here's a soltuion! This module returns a custom mouse class that uses
the UserInputService instead. Yay! No more having to worry if `plugin:Activate(true)` was called and still active!

Here's what you need to know from the API side of things. Most of this class is pretty much identical in functionality to the player or plugin mouse.
That being said I've added/changed a few things that I felt were either useful additions or how the mouse object should have behaved in the first place.

API:

Properties:
	mouse.Hit [readonly][CFrame]
		> The CFrame of the mouse’s position in 3D space.
	mouse.Origin [readonly][CFrame]
		> A DataType/CFrame positioned at the Workspace/CurrentCamera and oriented toward the Mouse's 3D position
	mouse.Target [readonly][Instance]
		> The object in 3D space the mouse is pointing to.
	mouse.TargetFilter [Instance] or [Array of Instances]
		> Determines an object (and its descendants) to be included when determining Mouse.Hit and Mouse.Target
		> Note for added functionality this can be set to either a single instance or a table of instances.
		> Defaulted to the workspace.
	mouse.TargetSurface [readonly][Enum.NormalId]
		> Describes the NormalId of the BasePart surface at which the mouse is pointing
	mouse.UnitRay [readonly][Ray]
		> A Ray directed towards the Mouse's world position, originating from the Camera's world position
	mouse.ViewSizeX [readonly][Number]
		> Describes the width of the screen in pixels
	mouse.ViewSizeY [readonly][Number]
		> Describes the height of the scree in pixels
	mouse.X [readonly][Number]
		> Describes the X (horizontal) component of the mouse’s screen position
	mouse.Y [readonly][Number]
		> Describes the Y (vertical) component of the mouse’s screen position

	mouse.TargetSurfaceNormal [readonly][Vector3]
		> Describes the SurfaceNormal of the BasePart surface at which the mouse is pointing	
	mouse.ViewSize [readonly][Vector2]
		> Describes the width and height of the screen in pixels
	mouse.Position [readonly][Vector2]
		> Describes the X and Y components of the mouse’s screen position
	mouse.TargetBlackList [Instance] or [Array of Instances]
		> Determines an object (and its descendants) to be ignored when determining Mouse.Hit and Mouse.Target
		> This can be set to either a single instance or a table of instances.
	mouse.IgnoreCharacter [boolean]
		> Only applies when a local player's character exists and is automatically set to true. This is a very odd property I admit, 
		> but for whatever reason the player mouse ignores the character so I figured I'd include this to perfectly emulate.

Events:
	mouse.Button1Down
		> Fired when the left mouse button is pressed.
	mouse.Button1Up
		> Fires when the left mouse button is released.
	mouse.Button2Down
		> Fires when the right mouse button is pressed.
	mouse.Button2Up
		> Fired when the right mouse button is released.
	mouse.Button3Down
		> Fires when the middle mouse button is pressed.
	mouse.Button3Up
		> Fired when the middle mouse button is released.
	mouse.Idle
		> Fired during every heartbeat that the mouse isn’t being passed to another mouse event.
	mouse.Move
		> Fired when the mouse is moved.
	mouse.WheelBackward
		> Fires when the mouse wheel is scrolled backwards.
	mouse.WheelForward
		> Fires when the mouse wheel is scrolled forwards.
		
Methods:
	mouse:Destroy()
		> Disconnects any events and removes anything related to the mouse. You should never have to call this to be completely honest,
		> but it's there just in case.

Enjoy!
EgoMoose
--]]

local UIS = game:GetService("UserInputService");
local RUNSERVICE = game:GetService("RunService");
local WORKSPACE = game:GetService("Workspace");
local PLAYERS = game:GetService("Players");
local CAMERA = game:GetService("Workspace").CurrentCamera;

local raycast = require(script:WaitForChild("raycast"));

-- private functions/methods

local function copyArray(array)
	local t, n = {}, #array;
	local i, j = 1, n;
	while (i < j) do
		t[i], t[j] = array[i], array[j];
		i, j = i + 1, j - 1;
	end
	if (n%2 == 1) then
		local m = math.ceil(n/2);
		t[m] = array[m];
	end
	return t;
end

local function planeIntersect(point, vector, origin, normal)
	local rpoint = point - origin;
	local t = -rpoint:Dot(normal)/vector:Dot(normal);
	return point + t * vector, t;
end

local function planeSideCheck(start, dir, cf, size2)
	local lstart = cf:pointToObjectSpace(start);
	local ldir = cf:vectorToObjectSpace(dir);
	
	for i, enum in next, Enum.NormalId:GetEnumItems() do
		local lv = Vector3.FromNormalId(enum);
		local origin = lv*size2;
		local p = planeIntersect(lstart, ldir, origin, lv) + lv;
		
		if ((p - origin):Dot(lv) > 0 and lv:Dot(ldir) <= 0) then
			local pass = true;
			for j, enum2 in next, Enum.NormalId:GetEnumItems() do
				if (i ~= j) then
					local lv2 = Vector3.FromNormalId(enum2);
					local origin2 = lv2*size2;
					
					if ((p - origin2):Dot(lv2) > 0) then
						pass = false;
						break;
					end
				end
			end
			if (pass) then
				return enum;
			end
		end
	end
end

local function getMouseScreenPos()
	if (PLAYERS.LocalPlayer) then
		return UIS:GetMouseLocation() - Vector2.new(0, 36);
	end
	return UIS:GetMouseLocation();
end

local function getScreenSize()
	if (PLAYERS.LocalPlayer) then
		return CAMERA.ViewportSize - Vector2.new(0, 72);
	end
	return CAMERA.ViewportSize;
end

local function castMouseRay(self)
	local whiteList = self.TargetFilter;
	if (type(whiteList) ~= "table") then
		whiteList = {whiteList};
	end
	local blackList = self.TargetBlackList;
	if (type(blackList) ~= "table") then
		blackList = {blackList};
	end
	if (self.IgnoreCharacter and PLAYERS.LocalPlayer and PLAYERS.LocalPlayer.Character) then
		blackList = #blackList > 0 and copyArray(blackList) or {};
		table.insert(blackList, PLAYERS.LocalPlayer.Character);
	end

	local v = UIS:GetMouseLocation();
	local r = CAMERA:ViewportPointToRay(v.x, v.y, 0);
	local ray = Ray.new(r.Origin, r.Direction*10000);
	
	local hit, pos, normal, material;
	if (#blackList > 0) then
		hit, pos, normal, material = raycast.FindPartOnRayWithBlackAndWhiteList(ray, blackList, whiteList, true);
	else
		hit, pos, normal, material = WORKSPACE:FindPartOnRayWithWhitelist(ray, whiteList, true);
	end

	return hit, pos, normal, material, r;
end


-- get properties

local funcProps = {};

-- original properties

function funcProps.TargetSurface(self)
	local hit, pos, normal, material, unitRay = castMouseRay(self);
	if (hit and hit.ClassName ~= "Terrain") then
		return planeSideCheck(unitRay.Origin, unitRay.Direction, hit.CFrame, hit.Size/2);
	end
end

function funcProps.UnitRay(self)
	local v = UIS:GetMouseLocation();
	return CAMERA:ViewportPointToRay(v.x, v.y, 0);
end

function funcProps.ViewSizeX(self)
	return getScreenSize().x
end

function funcProps.ViewSizeY(self)
	return getScreenSize().y
end

function funcProps.X(self)
	return getMouseScreenPos().x
end

function funcProps.Y(self)
	return getMouseScreenPos().y
end

function funcProps.Target(self)
	local hit, pos, normal, material, unitRay = castMouseRay(self);
	return hit;
end

function funcProps.Origin(self)
	local v = UIS:GetMouseLocation();
	local unitRay = CAMERA:ViewportPointToRay(v.x, v.y, 0);
	return CFrame.new(unitRay.Origin, unitRay.Origin + unitRay.Direction);
end

function funcProps.Hit(self)
	local hit, pos, normal, material, unitRay = castMouseRay(self);
	return CFrame.new(pos, pos + unitRay.Direction);
end

-- new properties

function funcProps.ViewSize(self)
	return getScreenSize();
end

function funcProps.Position(self)
	return getMouseScreenPos();
end

function funcProps.TargetSurfaceNormal(self)
	local hit, pos, normal, material, unitRay = castMouseRay(self);
	return normal;
end

function funcProps.TargetMaterial(self)
	local hit, pos, normal, material, unitRay = castMouseRay(self);
	return material;
end

--

local mouse = {};
local mouse_mt = {};
local storage = setmetatable({}, {__mode = "k"});

function mouse_mt.__index(mousey, k)
	k = k:sub(1, 1):upper() .. k:sub(2);

	if (mouse[k]) then
		return mouse[k];
	elseif (storage[mousey].readOnly[k]) then
		return storage[mousey].readOnly[k];
	elseif (funcProps[k]) then
		return funcProps[k](mousey)
	elseif (storage[mousey].validKey[k]) then
		return rawget(mousey, k);
	else
		error(k .. " is not a valid member of Mouse");
	end
end

function mouse_mt.__newindex(mousey, k, v)
	return nil;
end

function mouse_mt.__tostring()
	return "Mouse";
end

mouse_mt.__metatable = false;

--

function mouse.new()
	local self = {};

	self.TargetFilter = {WORKSPACE};
	self.TargetBlackList = {};
	self.IgnoreCharacter = true;
	
	local mouseEvents = {};
	
	local button1Down = Instance.new("BindableEvent");
	local button1Up = Instance.new("BindableEvent");
	local button2Down = Instance.new("BindableEvent");
	local button2Up = Instance.new("BindableEvent");
	local button3Down = Instance.new("BindableEvent");
	local button3Up = Instance.new("BindableEvent");
	local idle = Instance.new("BindableEvent");
	local move = Instance.new("BindableEvent");
	local wheelBackward = Instance.new("BindableEvent");
	local wheelForward = Instance.new("BindableEvent");
	
	table.insert(mouseEvents, UIS.InputBegan:Connect(function(input, process)
		if (process) then return; end
		
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			button1Down:Fire();
		elseif (input.UserInputType == Enum.UserInputType.MouseButton2) then
			button2Down:Fire()
		elseif (input.UserInputType == Enum.UserInputType.MouseButton3) then
			button3Down:Fire()
		end
	end))
	
	table.insert(mouseEvents, UIS.InputEnded:Connect(function(input, process)
		if (process) then return; end
		
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			button1Up:Fire();
		elseif (input.UserInputType == Enum.UserInputType.MouseButton2) then
			button2Up:Fire();
		elseif (input.UserInputType == Enum.UserInputType.MouseButton3) then
			button3Up:Fire();
		end
	end))
	
	table.insert(mouseEvents, UIS.InputChanged:Connect(function(input, process)
		if (process) then return; end
		
		if (input.UserInputType == Enum.UserInputType.MouseMovement) then
			move:Fire();
		elseif (input.UserInputType == Enum.UserInputType.MouseWheel) then
			if (input.Position.z > 0) then
				wheelForward:Fire();
			else
				wheelBackward:Fire();
			end
		end
	end))
	
	local lastLocation = UIS:GetMouseLocation();
	table.insert(mouseEvents, RUNSERVICE.Heartbeat:Connect(function()
		local currentLocation = UIS:GetMouseLocation();
		if (currentLocation == lastLocation) then
			idle:Fire();
		end
		lastLocation = currentLocation;
	end))
	
	local readOnly = {};
	readOnly.Button1Down = button1Down.Event;
	readOnly.Button1Up = button1Up.Event;
	readOnly.Button2Down = button2Down.Event;
	readOnly.Button2Up = button2Up.Event;
	readOnly.Button3Down = button3Down.Event;
	readOnly.Button3Up = button3Up.Event;
	readOnly.Idle = idle.Event;
	readOnly.Move = move.Event;
	readOnly.WheelBackward = wheelBackward.Event;
	readOnly.WheelForward = wheelForward.Event;
	
	storage[self] = {
		readOnly = readOnly;
		mouseEvents = mouseEvents;
		validKey = {["TargetFilter"] = true, ["TargetBlackList"] = true, ["IgnoreCharacter"] = true};
		bindableEvents = {button1Down, button1Up, button2Down, button2Up, button3Down, button3Up, idle, move, wheelBackward, wheelForward};
	}
	
	return setmetatable(self, mouse_mt);
end

function mouse:Destroy()
	local store = storage[self];
	local mouseEvents = store.mouseEvents;
	local bindableEvents = store.bindableEvents;
	
	for i = 1, #mouseEvents do
		mouseEvents[i]:Disconnect();
	end
	for i = 1, #bindableEvents do
		bindableEvents[i]:Destroy();
	end
	
	storage[self] = {};
end

return mouse.new();