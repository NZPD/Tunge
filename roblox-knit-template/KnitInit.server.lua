local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage:FindFirstChild("Knit"))

Knit.AddServices(ServerScriptService:FindFirstChild("Services"))

Knit.Start():catch(warn):await()

print("[Knit] Server initialized")