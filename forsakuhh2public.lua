-- [PROTECTED BY LITERALLY NOTHING V2]

--[[

You leveled up: skid -> skid who can read
Bonus: +5 IQ

OK in all seriousness, this code is open source because SOMEONE (moonsec) doesnt support continue.
also being open source is sigma, so haw haw. 

Feel free to use my code I literally dont care.

beware: bad code

Script by @22fourL 
]]

-- what are these called again
local Debris = game:GetService("Debris")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- more boring variables lol
local localPlayer = game.Players.LocalPlayer
local killerfolder: Folder = workspace.Players.Killers
local survivorfolder: Folder = workspace.Players.Survivors
local ingamefolder: Folder = workspace.Map.Ingame
-- todo: optimize aaaaaaaaaaaaaaaaaaaaaaaaaa
local currentMap
local killerESPWatch
local survivorESPWatch
local miscESPWatch
-- unused local gensESPWatch

-- spooky event :)
local eventESPWatch
local eventRemovingWatch

local watchForAutoGen
local fillTransparency = 0.5
local spoofrushspeed = 1
local autoGenRNG = 0
local autoGenTime = 4
local existingHighlights = {}
local createdInstances = {}
local listeners = {}
local activeRBXScriptConnections = {}

-- ring vars
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- config
local ringRadius = 150
local minFadeDistance = 75
local maxFadeDistance = 300
local baseIndicatorSize = 50
local useCollectionServiceTag = true
local csTagName = "DirectionalTarget"
local hideIfBehindCamera = false
local syncInterval = 1.0
local HUBNAME = "Pexsaken" -- just because im indecisive as hell lmao

-- internal state
local indicatorPool = {}
local activeIndicators = {} -- model -> { model, part, indicator, clone }
local renderConnection = nil
local running = false

-- functions lol

local function on(eventName, callback)
	if not listeners[eventName] then
		listeners[eventName] = {}
	end
	table.insert(listeners[eventName], callback)
end

local function broadcast(eventName, ...)
	local eventListeners = listeners[eventName]
	if eventListeners then
		for _, callback in ipairs(eventListeners) do
			task.spawn(callback, ...)
		end
	end
end

local function off(eventName, callback)
	local eventListeners = listeners[eventName]
	if not eventListeners then return end

	for i, cb in ipairs(eventListeners) do
		if cb == callback then
			table.remove(eventListeners, i)
			break
		end
	end
end

-- huge giant highlight object function (but its used alot so hahahah)
local function highlightObject(object : Instance, objType : string)
	local newKillerHighlight = Instance.new("Highlight")
	local newFloatGUI = Instance.new("BillboardGui")
	local newTextlabel = Instance.new("TextLabel")

	-- different modes for different modes lol
	if objType == "evil" then
		newFloatGUI.Parent = object:WaitForChild("HumanoidRootPart")
		newFloatGUI.StudsOffset = Vector3.new(0, 3.5, 0)
	elseif objType == "cool" then
		newFloatGUI.Parent = object:WaitForChild("HumanoidRootPart")
		newFloatGUI.StudsOffset = Vector3.new(0, 3.5, 0)

	elseif objType == "misc" then
		newFloatGUI.Parent = object
		if object:IsA("Model") then
			if object.Name == "Map" then
				return
			end
			local objcframe, objsize = object:GetBoundingBox()
			newFloatGUI.StudsOffset = Vector3.new(0, objsize.Y + 1, 0)
		else
			newFloatGUI.StudsOffset = Vector3.new(0, 3.5, 0)
		end
	elseif objType == "generator" then
		newFloatGUI.Parent = object
		newFloatGUI.StudsOffset = Vector3.new(0, 3, 0)
	end 

	newFloatGUI.Name = "espBillboard"
	newKillerHighlight.Parent = object
	table.insert(existingHighlights, newKillerHighlight)

	newFloatGUI.Size = UDim2.new(50, 0, 1.5, 0)
	newFloatGUI.AlwaysOnTop = true
	
	newTextlabel.Parent = newFloatGUI
	newTextlabel.Size = UDim2.new(1, 0, 1, 0)
	newTextlabel.FontFace.Bold = true
	newTextlabel.TextScaled = true
	newTextlabel.BackgroundTransparency = 1
	newTextlabel.TextStrokeTransparency = 0
	newTextlabel.FontFace = Font.fromName("Roboto", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	newTextlabel.Text = object.Name
	
	newKillerHighlight.FillTransparency = fillTransparency

	if objType == "misc" then
		newKillerHighlight.Name = "mehHighlightLMAO"
		newKillerHighlight.FillColor = Color3.fromRGB(208, 208, 208)
		newKillerHighlight.OutlineColor = Color3.fromRGB(153, 153, 153)

		newTextlabel.TextColor3 = Color3.fromRGB(198, 198, 198)
	elseif objType == "evil" then
		newKillerHighlight.Name = "evilHighlightLMAO"
		newKillerHighlight.FillColor = Color3.fromRGB(208, 0, 0)
		newKillerHighlight.OutlineColor = Color3.fromRGB(153, 1, 1)

		newTextlabel.TextColor3 = Color3.fromRGB(225, 93, 95)
	elseif objType == "cool" then
		newKillerHighlight.Name = "coolHighlightLMAO"
		newKillerHighlight.FillColor = Color3.fromRGB(132, 132, 0)
		newKillerHighlight.OutlineColor = Color3.fromRGB(199, 189, 52)

		newTextlabel.TextColor3 = Color3.fromRGB(255, 242, 58)
	elseif objType == "generator" then
		newKillerHighlight.Name = "puzzleHighlightLMAO"
		newKillerHighlight.FillColor = Color3.fromRGB(132, 0, 132)
		newKillerHighlight.OutlineColor = Color3.fromRGB(186, 0, 199)

		newTextlabel.TextColor3 = Color3.fromRGB(242, 53, 255)
	elseif objType == "special" then
		newKillerHighlight.Name = "sigmaHighlightLMAO"
		newKillerHighlight.FillColor = Color3.fromRGB(255, 234, 0)
		newKillerHighlight.OutlineColor = Color3.fromRGB(255, 255, 78)

		newTextlabel.TextColor3 = Color3.fromRGB(255, 218, 69)
	end
	
	-- removes it from the backend uhhh idk i wrote this comment like a month after i wrote the code what the hell is wrong with me
	newKillerHighlight.Destroying:Once(function()
		table.remove(existingHighlights, table.find(existingHighlights, newKillerHighlight))	
	end)
end

local function Relocate()
	-- animation: 140042539182927
	local STUNTIME = 2.5

	local Character = game.Players.LocalPlayer.Character
	local SpawnPoints = currentMap:WaitForChild("SpawnPoints"):WaitForChild("Survivors"):GetChildren()
	local goalspawnpoint = SpawnPoints[math.random(1, #SpawnPoints)]

	local humanoid = Character:FindFirstChild("Humanoid")
	local hrp = Character:FindFirstChild("HumanoidRootPart")
	local animator = humanoid:WaitForChild("Animator")
	local sfx = Instance.new("Sound")
	local tempanimObject = Instance.new("Animation")

	tempanimObject.Parent = humanoid
	tempanimObject.AnimationId = "rbxassetid://140042539182927"
	Debris:AddItem(tempanimObject, 5)
	sfx.Name = "fakeTPSFX"
	sfx.Parent = hrp
	sfx.SoundId = "rbxassetid://125253972523701"
	Debris:AddItem(sfx, 10)
	local tpTrack = animator:LoadAnimation(tempanimObject)

	-- halt player
	local folderSpeed = Character:FindFirstChild("SpeedMultipliers")
	if folderSpeed ~= nil then
		local newHaltNumberValue = Instance.new("NumberValue")
		Debris:AddItem(newHaltNumberValue, STUNTIME)
		newHaltNumberValue.Parent = folderSpeed
		newHaltNumberValue.Name = "bwahahaISortaBalancedThisXD"
	end

	tpTrack:Play()
	sfx:Play()

	task.spawn(function()
		task.wait(STUNTIME)
		tpTrack:Stop()
	end)

	task.wait(1.5)

	Character:MoveTo(goalspawnpoint.Position)
end

local function getMouseHit(ignoreList)
	local mouse = game.Players.LocalPlayer:GetMouse()

	local rayOrigin = workspace.CurrentCamera.CFrame.Position
	local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * 1000 -- long ray

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = ignoreList or {}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	-- Skip transparent parts
	while result and result.Instance and result.Instance.Transparency >= 1 do
		table.insert(ignoreList, result.Instance)
		raycastParams.FilterDescendantsInstances = ignoreList
		result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	end

	return result
end

local function spoofRush()
	-- void rush animation: 126896426760253
	-- void rush manual stop: 139321362207112
	-- void rush sfx: 113037804008732
	-- void rush manual end sfx: 105484443350662

	local Character = game.Players.LocalPlayer.Character
	local hrp = Character:FindFirstChild("HumanoidRootPart")
	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	local mouse = game.Players.LocalPlayer:GetMouse()

	local sfx = Instance.new("Sound")
	sfx.Parent = Character
	sfx.SoundId = "rbxassetid://113037804008732"
	Debris:AddItem(sfx, 10)
	local endsfx = Instance.new("Sound")
	endsfx.Parent = Character
	endsfx.SoundId = "rbxassetid://105484443350662"
	Debris:AddItem(endsfx, 2)

	local animation = Instance.new("Animation")
	animation.Parent = humanoid
	animation.AnimationId = "rbxassetid://126896426760253"
	local voidRushTrack = animator:LoadAnimation(animation)
	animation.AnimationId = "rbxassetid://139321362207112"
	local voidStopRushTrack = animator:LoadAnimation(animation)

	local result = getMouseHit({})
	local mousepos = result.Position

	-- hrp.Anchored = true
	local goalpos = mousepos + Vector3.new(0, 4, 0)

	local cfValue = Instance.new("CFrameValue")
	cfValue.Value = hrp.CFrame
	cfValue.Parent = hrp

	local goalCFrame = CFrame.new(mousepos + Vector3.new(0, 4, 0))

	local tweenInfo = TweenInfo.new(
		spoofrushspeed, -- Time
		Enum.EasingStyle.Linear, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching its goal)
		0 -- DelayTime
	)
	local tween = TweenService:Create(cfValue, tweenInfo, { Value = goalCFrame })

	local running = true

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not running then
			connection:Disconnect()
			return
		end

		local currentPos = cfValue.Value.Position

		-- If you want to keep the HRP upright, flatten Y on look target:
		local lookTarget = Vector3.new(goalpos.X, currentPos.Y, goalpos.Z)

		hrp.CFrame = CFrame.lookAt(currentPos, lookTarget)
	end)

	-- MOOOVEEE

	sfx:Play()
	tween:Play()
	voidRushTrack:Play()

	task.wait(spoofrushspeed)
	running = false

	sfx:Stop()
	endsfx:Play()
	voidRushTrack:Stop()
	voidStopRushTrack:Play()
	hrp.Anchored = false
end

local function highlightGenerators()
	if currentMap == nil then
		return
	end
	for i, randomObj in currentMap:GetChildren() do
		if randomObj.Name == "Generator" or randomObj.Name == "FakeGenerator" then
			highlightObject(randomObj, "generator")
		end
	end
end

local function clamp(x, a, b) return math.clamp(x, a, b) end

local function getTargetPart(model)
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	return model:FindFirstChildWhichIsA("BasePart")
end

-- script discrimination
local function sanitizeClone(modelClone)
	for _, v in ipairs(modelClone:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
			v:Destroy()
		end
	end
end

-- ASHLEY, LOOK AT ME.
local function makeModelFaceCamera(modelClone)
	-- find the uhhhhhhhhhhhhh
	local primary = modelClone.PrimaryPart or modelClone:FindFirstChild("HumanoidRootPart") or modelClone:FindFirstChildWhichIsA("BasePart")
	if not primary then
		-- uh oh
		return
	end

	if modelClone.PrimaryPart then
		modelClone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, 0))
	else
		local temp = Instance.new("Part")
		temp.Name = "__TEMP_Primary"
		temp.Size = Vector3.new(1,1,1)
		temp.Anchored = true
		temp.Transparency = 1
		temp.CanCollide = false
		temp.CFrame = CFrame.new(0,0,0)
		temp.Parent = modelClone
		modelClone.PrimaryPart = temp
		modelClone:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, 0))
		modelClone.PrimaryPart = nil
		temp:Destroy()
	end
	-- wall of configs ^
end

-- recenter model clone so its bounding box center is at origin and return approximate size magnitude
local function frameModelToOrigin(modelClone)
	-- ooo pcall boundbingbox im so smart
	local ok, bboxCF, bboxSize = pcall(function() return modelClone:GetBoundingBox() end)
	if not ok or not bboxCF then
		-- fallback
		local parts = {}
		for _, d in ipairs(modelClone:GetDescendants()) do
			if d:IsA("BasePart") then table.insert(parts, d) end
		end
		if #parts == 0 then return 1 end
		local sum = Vector3.new(0,0,0)
		for _, p in ipairs(parts) do sum += p.Position end
		local center = sum / #parts
		for _, p in ipairs(parts) do
			p.Position = p.Position - center
			p.Anchored = true
		end
		local maxMag = 0
		for _, p in ipairs(parts) do
			maxMag = math.max(maxMag, p.Size.Magnitude)
		end
		-- look at vro
		makeModelFaceCamera(modelClone)
		return math.max(maxMag, 0.001)
	end

	-- move all parts so bounding-box center goes to origin
	for _, d in ipairs(modelClone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Position = d.Position - bboxCF.Position
			d.Anchored = true
		end
	end

	-- rotate model so front faces camera
	makeModelFaceCamera(modelClone)

	local sizeMag = math.max(bboxSize.X, bboxSize.Y, bboxSize.Z)
	return math.max(sizeMag, 0.001)
end

-- yoink, your viewportFrame is mine
local function borrowIndicator(screenGui, templateGui, model)
	local ind = table.remove(indicatorPool)
	if not ind then
		ind = Instance.new("ViewportFrame")
		ind.Name = "Indicator"
		ind.Size = UDim2.fromOffset(baseIndicatorSize, baseIndicatorSize)
		ind.BackgroundTransparency = 1
		ind.BorderSizePixel = 0
		ind.LightDirection = Vector3.new(0, 0, -1)
		ind.Ambient = Color3.fromRGB(255,255,255)
		ind.AnchorPoint = Vector2.new(0.5, 0.5)
		ind.ZIndex = (templateGui and templateGui.ZIndex) or 1
		ind.ImageTransparency = 0
		ind.Parent = screenGui

		local cam = Instance.new("Camera")
		cam.Name = "ViewportCamera"
		cam.Parent = ind
		ind.CurrentCamera = cam

		local distText = Instance.new("TextLabel")
		distText.Name = "DistanceLabel"
		distText.BackgroundTransparency = 1
		distText.Size = UDim2.new(1, 0, 0, 14)
		distText.Position = UDim2.new(0, 0, 1, 0)
		distText.Font = Enum.Font.GothamBold
		distText.TextColor3 = Color3.new(1,1,1)
		distText.TextStrokeTransparency = 0.6
		distText.TextScaled = true
		distText.ZIndex = ind.ZIndex + 1
		distText.Parent = ind
	end

	local clone = model:Clone()
	sanitizeClone(clone)
	clone.Parent = ind

	local sizeMag = frameModelToOrigin(clone)

	local cam = ind:FindFirstChild("ViewportCamera")
	if cam then
		local forwardDistance = math.max(1, sizeMag * 0.8)
		local verticalOffset = sizeMag * 0.25
		cam.CFrame = CFrame.new(Vector3.new(0, verticalOffset, forwardDistance), Vector3.new(0,0,0))
		cam.FieldOfView = 70
	end

	ind.Visible = true
	ind.ImageTransparency = 0
	return ind, clone
end

-- who wrote this, oh wait its me 🥲
local function returnIndicator(ind)
	if not ind then return end
	for _, child in ipairs(ind:GetChildren()) do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
	ind.Visible = false
	ind.ImageTransparency = 1
	local distLabel = ind:FindFirstChild("DistanceLabel")
	if distLabel then distLabel.TextTransparency = 0 end
	table.insert(indicatorPool, ind)
end

-- gather killerfolder and survivorfolder
local function gatherTargets()
	local results = {}
	if useCollectionServiceTag then
		for _, obj in ipairs(CollectionService:GetTagged(csTagName)) do
			if obj and obj:IsA("Model") then table.insert(results, obj) end
		end
	end
	
	local trackedFolders = {
		killerfolder,
		survivorfolder,
	}
	
	for _, folder in ipairs(trackedFolders) do
		table.insert(activeRBXScriptConnections,
			folder.ChildRemoved:Connect(function(child)
				if indicatorPool[child] then
					indicatorPool[child]:Destroy()
					indicatorPool[child] = nil
				end
			end)
		)
	end

	for _, folder in ipairs(trackedFolders) do
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") then
				
				-- skip local player's character
				if model == player.Character then
					continue
				end
				
				if folder and folder:IsA("Folder") then
					for _, item in ipairs(folder:GetChildren()) do
						if item and item:IsA("Model") then
							
							if item == player.Character then
								continue
							end
							
							-- duplicate? nah.
							local dup = false
							for _, v in ipairs(results) do if v == item then dup = true; break end end
							if not dup then table.insert(results, item) end
						end
					end
				end
				
			end
		end
	end
	
	return results
end

local function syncActiveTargets(screenGui, templateGui)
	local targets = gatherTargets()
	local wanted = {}
	for _, model in ipairs(targets) do
		wanted[model] = true
		if not activeIndicators[model] then
			local part = getTargetPart(model)
			if part then
				local ind, clone = borrowIndicator(screenGui, templateGui, model)
				activeIndicators[model] = { model = model, part = part, indicator = ind, clone = clone }
			end
		end
	end
	-- remove the
	for model, data in pairs(activeIndicators) do
		if not wanted[model] or not data.model or not data.part then
			if data.indicator then returnIndicator(data.indicator) end
			activeIndicators[model] = nil
		end
	end
end

-- AAA WALL OF ####
local function ToggleDirectionalIndicators(enabled, screenGui, templateGui)
	if enabled and not running then
		if not screenGui or not screenGui:IsA("ScreenGui") then
			error("ToggleDirectionalIndicators: screenGui must be a ScreenGui")
		end
		running = true
		local syncTimer = 0

		syncActiveTargets(screenGui, templateGui)

		renderConnection = RunService.RenderStepped:Connect(function(dt)
			syncTimer += dt
			if syncTimer >= syncInterval then
				syncTimer = 0
				syncActiveTargets(screenGui, templateGui)
			end

			if not next(activeIndicators) then return end

			local guiCenter
			local okCenter = false
			if screenGui.AbsoluteSize and screenGui.AbsoluteSize.Magnitude > 0 then
				guiCenter = screenGui.AbsolutePosition + (screenGui.AbsoluteSize / 2)
				okCenter = true
			else
				local vs = camera.ViewportSize
				guiCenter = Vector2.new(vs.X * 0.5, vs.Y * 0.5)
			end

			for model, data in pairs(activeIndicators) do
				if not data or not data.model or not data.part or not data.indicator then
					if data and data.indicator then returnIndicator(data.indicator) end
					activeIndicators[model] = nil
					continue
				end

				local part = data.part
				local ind = data.indicator

				-- wow optimization (once in a blue moon)
				if not part.Parent then
					returnIndicator(ind)
					activeIndicators[model] = nil
					continue
				end

				-- gross math with orientations
				local camCF = camera.CFrame
				local camPos = camCF.Position
				local toTarget = (part.Position - camPos)
				local dist = toTarget.Magnitude
				if dist < 0.001 then dist = 0.001 end

				local camForward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
				local camRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
				local flatTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
				if flatTarget.Magnitude < 0.001 then continue end

				camForward = camForward.Unit
				camRight = camRight.Unit
				flatTarget = flatTarget.Unit

				local angle = math.atan2(-camRight:Dot(flatTarget), camForward:Dot(flatTarget))

				-- orienttation ring
				local x = -math.sin(angle) * ringRadius
				local y = -math.cos(angle) * ringRadius
				
				-- p = position
				local px = math.floor(guiCenter.X + x + 0.5)
				local py = math.floor(guiCenter.Y + y + 0.5)
				ind.Position = UDim2.fromOffset(px, py)

				-- scrapped behind-camera, might make a toggle idfk
				local _, onScreen = camera:WorldToViewportPoint(part.Position)
				if hideIfBehindCamera and not onScreen then
					ind.Visible = false
					continue
				else
					ind.Visible = true
				end

				-- update distance text
				local distLabel = ind:FindFirstChild("DistanceLabel")
				if distLabel then
					distLabel.Text = string.format("%d", math.floor(dist))
				end

				-- fade and scale
				local t = clamp((dist - minFadeDistance) / math.max(1, (maxFadeDistance - minFadeDistance)), 0, 1)
				local alpha = 1 - t -- 1 = near, 0 = far
				local sizeScale = 0.6 + 0.4 * alpha
				ind.Size = UDim2.fromOffset(baseIndicatorSize * sizeScale, baseIndicatorSize * sizeScale)

				ind.ImageTransparency = 1 - alpha

				if distLabel then
					distLabel.TextTransparency = 1 - alpha
				end
			end
		end)

	elseif not enabled and running then
		-- disable & cleanup
		running = false
		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
		for _, data in pairs(activeIndicators) do
			if data.indicator then returnIndicator(data.indicator) end
		end
		activeIndicators = {}
	end
end

-- rafield setup yawn

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "🎃 " .. HUBNAME,
	Icon = "scroll-text", -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
	LoadingTitle = "Hey " .. localPlayer.DisplayName .. "! thx for using my gui :)",
	LoadingSubtitle = "Those who snow",
	ShowText = "the scripts :?", -- for mobile users to unhide rayfield, change if you'd like
	Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

	ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface
})

-- for stupid people
if game.PlaceId ~= 18687417158 then
	Rayfield:Notify({
		Title = HUBNAME,
		Content = "Unsupported game!!1!, Shutting down...",
		Duration = 3,
		Image = "triangle-alert",
	})
	task.wait(3)
	Rayfield:Destroy()
	return
end

-- background processe(s)
local previousmap = nil

local backgroundProcesses = RunService.Heartbeat:Connect(function()
	task.spawn(function()
		previousmap = currentMap
		task.wait(1)
		local Model = ingamefolder:FindFirstChild("Map")
		if Model == nil then
			currentMap = nil
		else
			currentMap = Model
		end

		-- broadcasts :3
		if previousmap ~= currentMap then
			broadcast("highlightGens")
			print("highlightgensbroadcasted")
		end
	end)
	
	
end)

-- subscriptions

-- ui setup (yawn)

local i = Window:CreateTab("Welcome", "book-open") -- information
local sf = Window:CreateTab("Safe Functions", "square-plus") -- safe functions
local uf = Window:CreateTab("Unsafe Functions", "square-minus") -- unsafe functions

local ufWarningSection = uf:CreateSection("These functions have a greater risk of getting reported and banned! Use at your own risk.")
local sfWarningSection = sf:CreateSection("These functions are undetectable and not easy to get banned with.")

-- // objects for info // 

local parone = i:CreateParagraph({Title = "Hello, " .. localPlayer.DisplayName .. ".", Content = "hi hi hi welcome to my very own #Forsaken gui, this gui is intended to be subtle. And not get you banned."})
local partwo = i:CreateParagraph({Title = "Tips", Content = "Make sure to use all functions in Unsafe Functions IN MODERATION. Any of those functions can get you BANNED! Since Roblox has bumped up their security on in-experience bans, its better to play it safe if you dont know what your doing."})

local shutdown = i:CreateButton({
	Name = "Shut down GUI & processes",
	Callback = function()
		Rayfield:Notify({
			Title = HUBNAME,
			Content = "Shutting down... This may lag your game.",
			Duration = 1,
			Image = "loader-circle",
		})
		
		task.wait(1)
		
		backgroundProcesses:Disconnect()
		
		for i, v in existingHighlights do
			if v:IsA("Instance") then
				v:Destroy()
			end
		end
		
		for i, v in createdInstances do
			if v:IsA("Instance") then
				v:Destroy()
			end
		end
		
		for i, v:RBXScriptConnection in activeRBXScriptConnections do
			v:Disconnect()
			v = nil
		end
		
		local probGUI = localPlayer.PlayerGui:FindFirstChild("ringGUI")
		if probGUI == nil then
			
		else
			ToggleDirectionalIndicators(false, probGUI, nil)
		end
		
		for i, v in game.Workspace:GetDescendants() do
			if v:IsA("BillboardGui") then
				if v.Name == "espBillboard" then
					v:Destroy()
				end
			end
		end
		
		Rayfield:Notify({
			Title = HUBNAME,
			Content = "Shut down successfully :D",
			Duration = 2,
			Image = "check",
		})
		
		task.wait(2)
		
		Rayfield:Destroy()
	end,
})

-- local warnlabel = i:CreateLabel("For this to take full effect, make sure every highlight toggle is disabled.", "traffic-cone")

-- // objects for Safe Functions //

local unnamedLabel = sf:CreateLabel("Compass Ring [beta]", "compass")

local ringCircleSize = sf:CreateSlider({
	Name = "Ring Radius",
	Range = {100, 300},
	Increment = 10,
	Suffix = "Pixels",
	CurrentValue = 150,
	Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		ringRadius = Value
	end,
})

local ringViewportFrameSize = sf:CreateSlider({
	Name = "Ring Icon Scale",
	Range = {35, 100},
	Increment = 5,
	Suffix = "Pixels",
	CurrentValue = 50,
	Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		baseIndicatorSize = Value
	end,
})

local ringEnabled = sf:CreateToggle({
	Name = "Ring Enabled",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		-- make a host gui
		local probGUI = localPlayer.PlayerGui:FindFirstChild("ringGUI")
		
		if probGUI == nil then
			local newScreenGui = Instance.new("ScreenGui")
			table.insert(createdInstances, newScreenGui)
			newScreenGui.Parent = localPlayer.PlayerGui
			newScreenGui.Name = "ringGUI"
			newScreenGui.ResetOnSpawn = false
			probGUI = newScreenGui
		else
			
		end
		
		-- this is what the uhhh
		ToggleDirectionalIndicators(Value, probGUI, nil)
	end,
})

local unnamedLabel = sf:CreateLabel("Highlights", "eye")

local fillTransparency = sf:CreateSlider({
	Name = "Highlight Fill Transparency",
	Range = {0, 1},
	Increment = 0.1,
	Suffix = "Transparency",
	CurrentValue = 0.5,
	Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		fillTransparency = Value
		for i, v in existingHighlights do
			v.FillTransparency = Value
		end
	end,
})

local killerESP = sf:CreateToggle({
	Name = "Highlight killer(s)",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		if Value then
			for i, killerChar in killerfolder:GetChildren() do
				highlightObject(killerChar, "evil")
			end
			
			killerESPWatch = killerfolder.ChildAdded:Connect(function(object)
				highlightObject(object, "evil")
			end)
			table.insert(activeRBXScriptConnections, killerESPWatch)
		else
			if killerESPWatch then
				killerESPWatch:Disconnect()
				killerESPWatch = nil
				table.remove(activeRBXScriptConnections, table.find(activeRBXScriptConnections, killerESPWatch))
			end
			
			for i, v in killerfolder:GetDescendants() do
				if v.Name == "evilHighlightLMAO" or v.Name == "espBillboard" then
					v:Destroy()
				end
			end
		end
	end,
})

local survivorESP = sf:CreateToggle({
	Name = "Highlight survivors",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		if Value then
			for i, survivorChar in survivorfolder:GetChildren() do
				highlightObject(survivorChar, "cool")
			end

			survivorESPWatch = survivorfolder.ChildAdded:Connect(function(object)
				highlightObject(object, "cool")
			end)
			
			table.insert(activeRBXScriptConnections, survivorESPWatch)
		else
			if survivorESPWatch then
				survivorESPWatch:Disconnect()
				survivorESPWatch = nil
				table.remove(activeRBXScriptConnections, table.find(activeRBXScriptConnections, survivorESPWatch))
			end

			for i, v in survivorfolder:GetDescendants() do
				if v.Name == "coolHighlightLMAO" or v.Name == "espBillboard" then
					v:Destroy()
				end
			end
		end
		
	end,
})

local miscESP = sf:CreateToggle({
	Name = "Highlight miscellaneous",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		if Value then
			for i, randomObj in ingamefolder:GetChildren() do
				highlightObject(randomObj, "misc")
			end

			miscESPWatch = ingamefolder.ChildAdded:Connect(function(object)
				highlightObject(object, "misc")
			end)
			
			table.insert(activeRBXScriptConnections, miscESPWatch)
		else
			if miscESPWatch then
				miscESPWatch:Disconnect()
				miscESPWatch = nil
				table.remove(activeRBXScriptConnections, table.find(activeRBXScriptConnections, miscESPWatch))
			end

			for i, v in ingamefolder:GetDescendants() do
				if v.Name == "mehHighlightLMAO" or v.Name == "espBillboard" then
					v:Destroy()
				end
			end
		end

	end,
})

local genESP = sf:CreateToggle({
	Name = "Highlight generators [mega wip]",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		if currentMap == nil then
			Rayfield:Notify({
				Title = HUBNAME,
				Content = "Wait until the map exists, then re-enable.",
				Duration = 3,
				Image = "triangle-alert",
			})
			
			return
		end
		
		if Value then
			for i, randomObj in currentMap:GetChildren() do
				if randomObj.Name == "Generator" or randomObj.Name == "FakeGenerator" then
					highlightObject(randomObj, "generator")
				end
			end
			
			on("highlightGens", highlightGenerators)
			
			--[[
			this is a archive
			
			gensESPWatch = currentMap.ChildAdded:Connect(function(object)
				if object.Name == "Generator" or object.Name == "FakeGenerator" then
					highlightObject(object, "generator")
				end
			end)
			]]
		else
			--[[
			this is a archive
			
			if gensESPWatch then
				gensESPWatch:Disconnect()
				gensESPWatch = nil
			end
			]]
			
			off("highlightGens", highlightGenerators)

			for i, v in currentMap:GetDescendants() do
				if v.Name == "puzzleHighlightLMAO" or v.Name == "espBillboard" then
					v:Destroy()
				end
			end
		end

	end,
})

local eventESP = sf:CreateToggle({
	Name = "[🎃] Highlight event currency",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		local currencyFolder = ingamefolder:FindFirstChild("CurrencyLocations")
		
		if currencyFolder == nil then
			Rayfield:Notify({
				Title = HUBNAME,
				Content = "The folder for collectables doesnt exist, wait a bit then re-enable.",
				Duration = 3,
				Image = "triangle-alert",
			})

			return
		end
		
		if Value then
			for i, randomObj in currencyFolder:GetChildren() do
				highlightObject(randomObj, "special")
			end

			eventESPWatch = currencyFolder.ChildAdded:Connect(function(object)
				highlightObject(object, "special")
			end)
			
			eventRemovingWatch = currencyFolder.Destroying:Once(function()
				Rayfield:Notify({
					Title = HUBNAME,
					Content = "There are no more collectables! Turn off the toggle when your ready.",
					Duration = 3,
					Image = "info",
				})
			end)
			
			table.insert(activeRBXScriptConnections, eventESPWatch)
			table.insert(activeRBXScriptConnections, eventRemovingWatch)
		else
			if eventESPWatch then
				eventESPWatch:Disconnect()
				eventESPWatch = nil
				table.remove(activeRBXScriptConnections, table.find(activeRBXScriptConnections, eventESPWatch))
			end
			
			if eventRemovingWatch then
				eventRemovingWatch:Disconnect()
				eventRemovingWatch = nil
				table.remove(activeRBXScriptConnections, table.find(activeRBXScriptConnections, eventRemovingWatch))
			end
			

			for i, v in currencyFolder:GetDescendants() do
				if v.Name == "sigmaHighlightLMAO" or v.Name == "espBillboard" then
					v:Destroy()
				end
			end
		end

	end,
})

-- // objects for unsafe functions //

local relocateButton = uf:CreateButton({
	Name = "Relocate",
	Callback = function()
		Relocate()
	end,
})

local spoofRushSpeed = uf:CreateSlider({
	Name = "SpoofRush Time",
	Range = {1, 10},
	Increment = 1,
	Suffix = "Seconds",
	CurrentValue = 1,
	Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		spoofrushspeed = Value
	end,
})

local spoofRushButton = uf:CreateButton({
	Name = "SpoofRush",
	Callback = function()
		spoofRush()
	end,
})

local autoGenRNGSlider = uf:CreateSlider({
	Name = "Auto Gen randomness",
	Range = {0, 5},
	Increment = 0.5,
	Suffix = "Seconds",
	CurrentValue = 0,
	Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		autoGenRNG = Value
	end,
})

local autoGenTimeSlider = uf:CreateSlider({
	Name = "Auto Gen Delay Time",
	Range = {3, 10},
	Increment = 0.25,
	Suffix = "Seconds",
	CurrentValue = 4,
	Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		autoGenTime = Value
	end,
})

local autoGen = uf:CreateToggle({
	Name = "Automatically Fix Generators",
	CurrentValue = false,
	Flag = "Toggle1",
	Callback = function(Value)
		
		if currentMap == nil then
			Rayfield:Notify({
				Title = HUBNAME,
				Content = "Wait until the map exists, then re-enable.",
				Duration = 3,
				Image = "triangle-alert",
			})

			return
		end

		if Value then
			watchForAutoGen = ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
				local model = prompt.Parent.Parent
				if model:IsDescendantOf(currentMap) then
					if model:IsA("Model") then
						for i = 1, 5, 1 do
							task.wait(autoGenTime + math.random(0, autoGenRNG))
							
							model.Remotes.RE:FireServer()
						end
					end
				end
			end)
			
			table.insert(activeRBXScriptConnections, watchForAutoGen)
		else
			if watchForAutoGen then
				watchForAutoGen:Disconnect()
				watchForAutoGen = nil
				table.remove(activeRBXScriptConnections, table.find(activeRBXScriptConnections, watchForAutoGen))
			end
		end
	end,
})
