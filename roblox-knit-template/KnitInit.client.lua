local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage:FindFirstChild("Knit"))

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
Knit.AddControllers(playerScripts:FindFirstChild("Controllers"))

Knit.Start():catch(warn):await()

print("[Knit] Client initialized")