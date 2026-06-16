--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchManager = require(script.MatchManager)
local GunHandler = require(script.GunHandler)

local function onServerStart()
	MatchManager:StartMatch()
end

game:GetService("Players").PlayerAdded:Connect(function(player)
	player:WaitForChild("PlayerGui")
	
	if MatchManager.CurrentMatch ~= nil then
		MatchManager:AddPlayerToMatch(player)
	end
end)

local clientReadyConnection = nil
clientReadyConnection = game:GetService("ReplicatedStorage"):FindFirstChild("SniperDuelsRemotes")
if clientReadyConnection then
	local remote = clientReadyConnection:FindFirstChild("ClientReady")
	if remote then
		remote.OnServerEvent:Connect(function(player)
			if MatchManager:IsPlayerInMatch(player) then
				MatchManager:SpawnPlayer(player)
			end
		end)
	end
end

onServerStart()