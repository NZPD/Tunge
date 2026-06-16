--!strict
-- Main.server.luau
-- Entry point for the Obby Framework server. Bootstrap all services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Create shared folder in ReplicatedStorage if not exists
local obbyShared = ReplicatedStorage:FindFirstChild("ObbyShared")
if not obbyShared then
	obbyShared = Instance.new("Folder")
	obbyShared.Name = "ObbyShared"
	obbyShared.Parent = ReplicatedStorage
end

-- Load shared modules
local Types = require(script.Parent.Parent.Shared.Types)
local Constants = require(script.Parent.Parent.Shared.Constants)
local RemoteEvents = require(script.Parent.Parent.Shared.RemoteEvents)

-- Clone shared modules into ReplicatedStorage for client access
local sharedSource = script.Parent.Parent.Shared
for _, child in sharedSource:GetChildren() do
	if child:IsA("ModuleScript") and not obbyShared:FindFirstChild(child.Name) then
		local clone = child:Clone()
		clone.Parent = obbyShared
	end
end

-- Require server services
local ObbyService = require(script.Parent.ObbyService)
local CheckpointSystem = require(script.Parent.CheckpointSystem)

-- Initialize services
local services: { { Init: (any) -> boolean } } = {
	ObbyService,
}

-- Bootstrap all services
for _, service in services do
	local success, err = pcall(function()
		return service.Init()
	end)
	if not success then
		warn(`[Main] Failed to init service: {err}`)
		error(`[Main] Service initialization failed: {err}`)
	end
end

print("[Main] Obby Framework initialized successfully!")

-- Handle game close
game:BindToClose(function()
	print("[Main] Shutting down Obby Framework...")
	ObbyService.Destroy()
	RemoteEvents.Destroy()
end)