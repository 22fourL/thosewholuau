getgenv().RAYFIELD_SECURE = true
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local WashingMachines = loadstring(game:HttpGet("https://raw.githubusercontent.com/22fourL/thosewholuau/refs/heads/main/modules/WashingMachines.lua"))()

local localplayer = game.Players.LocalPlayer
local nonsavevars = localplayer:WaitForChild("NonSaveVars")
local savevars = localplayer:WaitForChild("SaveVars")
local plot: ObjectValue = nonsavevars:WaitForChild("OwnsPlot")
local basketFullness: ObjectValue = nonsavevars:WaitForChild("BackpackAmount")
local basketMax: ObjectValue = nonsavevars:WaitForChild("BasketSize")

local hrp: Part = nil

local laundryCache = {}

-- flags
local autofarmFLAG = false
local purchaseWhenCan = "None"

-- global vars
local ping = localplayer:GetNetworkPing() * 2000

-- init window for notifs to play in func

local window = Rayfield:CreateWindow({
	name = "Laundry Simulator Hub",
	subtitle = "phonk hub refernece boiiii",
	sidebarLayout = true,
	theme = "cobalt",
	icon = "feather"
})


-- replace later
local function debuglog(string)
	print(string)
end

-- uses physics to stay at a position for the time specified, does not yeild
local function tweenTo(pos: Vector3, timee: number)
	local attach = Instance.new("Attachment")
	local align = Instance.new("AlignPosition")
	Debris:AddItem(attach, timee)
	Debris:AddItem(align, timee)
	align.Parent = hrp
	attach.Parent = hrp

	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.ApplyAtCenterOfMass = true
	align.Position = pos
	align.ReactionForceEnabled = true
	align.RigidityEnabled = true
	align.Attachment0 = attach
end

-- yeilds until a ping tick has happened however many times specified
local function waitPingTrip(amount)
	task.wait(
		(ping / 1000) * amount
	)
end

local function getPingTrip()
	return ping / 1000
end

local function moveHRP(Pos: Vector3)
	hrp.Anchored = false
	hrp.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)
	hrp.CFrame = CFrame.new(Pos.X, Pos.Y, Pos.Z)
	tweenTo(Pos, getPingTrip())
	waitPingTrip(1)
	hrp.Anchored = true
end

-- assumes you will be anchored later, otherwise you will fall
local function fastMoveHRP(Pos: Vector3)
	hrp.Anchored = false
	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	hrp.CFrame = CFrame.new(Pos.X, Pos.Y, Pos.Z)
end

local function moveHRPHome()
	moveHRP(plot.Value.Furniture.SofaOne:GetPivot().Position - Vector3.new(0, 10, 0))
end

local function buyLaundryMachine(ID: number)
	window:Notify({
		title = "Bought a '" .. WashingMachines[tostring(ID)].Name .. " machine!!",
		content = "Cost: " .. tostring(WashingMachines[tostring(ID)].Price) .. " coins.",
		duration = 30,
	})

	local Event = game:GetService("ReplicatedStorage").Events.BuyWashingMachine
	Event:InvokeServer(
		tostring(ID)
	)
end

local function depositDirtyLaundry(Model: Model)
	moveHRP(Model:GetPivot().Position - Vector3.new(0, 10, 0))

	waitPingTrip(1)

	local Event = game:GetService("ReplicatedStorage").Events.LoadWashingMachine
	Event:FireServer(
		Model
	)

	waitPingTrip(1)
end

-- ends when the basket is filled or goal amount is reached, if goal amount isnt reached then return false
local function collectLaundry(goalAmount: number)
	local clothesFolder = workspace.Debris.Clothing

	hrp.Anchored = false
	hrp.CFrame = CFrame.new(-67, -5, -11)
	tweenTo(Vector3.new(-67, -5, -11), getPingTrip())
	waitPingTrip(1)

	hrp.Anchored = true

	repeat
		local clothes = clothesFolder:GetChildren()

		if #clothes < goalAmount or #clothes < 2 then
			repeat
				print("not enough clothes, waiting for more...")
				clothes = clothesFolder:GetChildren()
				task.wait(1)
			until #clothes > goalAmount
		end

		local chosen: BasePart = clothes[math.random(1, #clothes)]

		-- prioritize ANY special item
		for i, clothing: MeshPart in clothes do
			-- check if shiny or from blackhole
			if clothing:FindFirstChild("SpecialTag") or clothing.BrickColor == BrickColor.new("Really black") then
				-- is special
				chosen = clothing
				continue
			end
		end

		-- fastMoveHRP(chosen.Position - Vector3.new(0, 10, 0))

		-- incase someone else has it, check just in case
		if not chosen then continue end

		local Event = game:GetService("ReplicatedStorage").Events.GrabClothing
		Event:FireServer(
			chosen
		)

		waitPingTrip(1)

		print(tostring(goalAmount) .. "/" .. tostring(basketFullness.Value))

	until basketFullness.Value >= goalAmount or basketFullness.Value >= basketMax.Value

	hrp.Anchored = true

	waitPingTrip(2)

	print(basketFullness.Value >= goalAmount)

	return basketFullness.Value >= goalAmount
end

-- empties a machine assuming its clean, it will use multiple baskets if there is a bigger load than the basket space
local function emptyMachine(MachinePath: Model, lookup)

	repeat
		moveHRP(MachinePath:GetPivot().Position - Vector3.new(0, 20, 0))

		waitPingTrip(1)

		-- pick from machine
		local Event = game:GetService("ReplicatedStorage").Events.UnloadWashingMachine
		Event:FireServer(
			MachinePath
		)

		moveHRP(Vector3.new(-144, -2, -11))

		waitPingTrip(1)

		-- drop in chute
		local Event = game:GetService("ReplicatedStorage").Events.DropClothesInChute
		Event:FireServer()

	until lookup.clean.Value == false
end



local function autoFarm(activated: boolean)

	-- init cache on start
	laundryCache = {}
	local char = localplayer.Character
	hrp = char:FindFirstChild("HumanoidRootPart")
	hrp.Anchored = true

	for i, v in plot.Value.WashingMachines:GetChildren() do
		laundryCache[i] = {}
		local washI = laundryCache[i]

		local config = v.Config

		-- add max to config shhhh
		if config:FindFirstChild("MaxLoad") == nil then
			local maxNum = Instance.new("NumberValue")
			maxNum.Parent = config
			maxNum.Name = "MaxLoad"
			maxNum.Value = string.split(v.Parts.Screen.SurfaceGui.Frame.TextLabel.Text, "/")[2]
		end

		if config:FindFirstChild("Rank") == nil then
			local maxNum = Instance.new("NumberValue")
			maxNum.Parent = config
			maxNum.Name = "Rank"
			maxNum.Value = tonumber(v.Name)
		end

		if config:FindFirstChild("Model") == nil then
			local maxNum = Instance.new("ObjectValue")
			maxNum.Parent = config
			maxNum.Name = "Model"
			maxNum.Value = v
		end

		washI.washing = config.Started
		washI.usage = config.Capacity
		washI.max = config.MaxLoad
		washI.rank = config.Rank
		washI.clean = config.CycleFinished
		washI.model = config.Model

	end
	print("reconstructed cache")

	-- loop, determine which task is most important and do it

	while autofarmFLAG do
		task.wait(1)

		for i, machineNumber in laundryCache do
			-- if clean, deposit
			if machineNumber.clean.Value then
				print("emptying machine #" .. tostring(i))
				emptyMachine(machineNumber.model.Value, machineNumber)
				continue
			end

			-- if machine isnt all the way full
			if machineNumber.usage.Value < machineNumber.max.Value then
				print("collecting laundry for machine #" .. tostring(i))

				local Event = game:GetService("ReplicatedStorage").Events.LoadWashingMachine

				local success = collectLaundry(machineNumber.max.Value - machineNumber.usage.Value)

				if not success then
					print("Basket was too small to fill, retrying...")
					repeat
						success = collectLaundry(machineNumber.max.Value - machineNumber.usage.Value)

						depositDirtyLaundry(machineNumber.model.Value)

						waitPingTrip(2)
					until success
				else
					depositDirtyLaundry(machineNumber.model.Value)
				end

				print("put laundry in machine")

				moveHRPHome()

			end

			moveHRPHome()
		end

		-- auto buy machine

		if purchaseWhenCan ~= "None" then

			local price = math.huge
			local id = 0

			for i, v in WashingMachines do
				if v.Name == purchaseWhenCan then
					price = v.Price
					id = v.LayoutOrder
				end
			end

			print(price)

			if savevars.Coins.Value >= price then
				buyLaundryMachine(id)
			end

		end
	end

	print("auto farm end")

	-- auto farm ended
	hrp.Anchored = false
	hrp.CFrame = plot.Value.Base.CFrame * CFrame.new(0, 3, 0)
end

if plot.Value == nil then
	window:Notify({
		title = "Claim a plot first",
		content = "ok ok mkay",
		duration = 3,
	})
	task.wait(3)
	window:Unload()
end

local tag = window:CreateTag({
	text = "us-en",
	color = Color3.fromRGB(255, 175, 15),
})

tag:Set({ text = "V1.1", color = Color3.fromRGB(80, 200, 120) })

local maintab = window:CreateTab({ name = "Main", icon = 93364949241311 })

local autofarm = maintab:CreateToggle({
	name = "Auto Farm",
	flag = "autofarm",
	value = false,
	callback = function(value)
		autofarmFLAG = value
		if value then
			autoFarm(value)
		else
			window:Notify({
				title = "Auto farm queued to stop",
				content = "Auto farm will stop on its next available cycle to prevent errors, please wait...",
				duration = 5,
			})
		end
	end,
})

-- create dropdown from items in modulescript

local list = {}

for i, v in WashingMachines do
	if v.LayoutOrder == 0 then
		continue
	end

	table.insert(list, v.Name)

	table.sort(list)
end

table.insert(list, "None") -- cant forget to give the option to disable it

maintab:CreateDropdown({
	name = "Auto-purchase...",
	multiSelect = false,
	options = list,
	value = { "None" },
	callback = function(selected)
		purchaseWhenCan = selected
	end,
})

maintab:CreateButton({
	name = "Unload Window",
	callback = function()
		window:Unload()
	end,
})

RunService.Heartbeat:Connect(function(deltaTime: number)
	ping = localplayer:GetNetworkPing() * 2000
end)
