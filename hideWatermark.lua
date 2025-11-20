-- for zyltex's animations btw

local localplayer = game:GetService("Players").LocalPlayer

local playerGui = localplayer.PlayerGui

local dest = playerGui:FindFirstChild("MainUI")
local currentGUI = dest:FindFirstChild("Watermark")

game:GetService("StarterGui"):SetCore("SendNotification",{
	Title = "Made by 22Four_L", -- Required
	Text = "This was made in 2 seconds lol", -- Required
	Icon = nil -- Optional
})

currentGUI:Destroy()

-- this way the game doesnt freak out
local replacee = Instance.new("ImageLabel")
replacee.Parent = dest
replacee.Name = "Watermark"
replacee.Position = UDim2.new(5, 0, 0, 0)
