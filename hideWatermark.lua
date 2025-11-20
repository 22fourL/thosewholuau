-- for zyltex's animations btw

local localplayer = game:GetService("Players").LocalPlayer

local playerGui = localplayer.PlayerGui

local currentGUI = playerGui:FindFirstChild("MainUI"):FindFirstChild("Watermark")

game:GetService("StarterGui"):SetCore("SendNotification",{
	Title = "Made by 22Four_L",
	Text = "This was made in 2 seconds lol",
	Icon = nil
})

currentGUI:Destroy()
