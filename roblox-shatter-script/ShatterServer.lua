local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local part = script.Parent
local remote = replicated_storage.ShatterRemote

part.Anchored = true

local players_on_part = {}
local cooldowns = {}

local function can_shatter(player)
	local last = cooldowns[player]
	return not last or (os.clock() - last) >= 0.5
end

local function signal_shatter(player, shattered)
	remote:FireClient(player, part, shattered)
end

part.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end
	if not can_shatter(player) then return end
	if players_on_part[player] then return end

	players_on_part[player] = true
	cooldowns[player] = os.clock()
	signal_shatter(player, true)
end)

part.Leave:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end
	if not players_on_part[player] then return end

	players_on_part[player] = nil
	signal_shatter(player, false)
end)

part.TouchEnded:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end
	if not players_on_part[player] then return end

	players_on_part[player] = nil
	signal_shatter(player, false)
end)