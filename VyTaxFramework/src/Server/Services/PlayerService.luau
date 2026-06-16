local Maid = require(game:GetService("ReplicatedStorage").VyTax.Maid)
local Signal = require(game:GetService("ReplicatedStorage").VyTax.Signal)
local Promise = require(game:GetService("ReplicatedStorage").VyTax.Promise)

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(): typeof(PlayerService)
	return setmetatable({}, PlayerService)
end

function PlayerService:_init()
	self._maid = Maid.new()
	self.PlayerAdded = Signal.new()
	self.PlayerRemoved = Signal.new()
	self._players = {}

	self._maid:GiveTask(game:GetService("Players").PlayerAdded:Connect(function(player)
		self._players[player.UserId] = player
		self.PlayerAdded:Fire(player)
	end))

	self._maid:GiveTask(game:GetService("Players").PlayerRemoving:Connect(function(player)
		self._players[player.UserId] = nil
		self.PlayerRemoved:Fire(player)
	end))

	for _, player in game:GetService("Players"):GetPlayers() do
		self._players[player.UserId] = player
	end
end

function PlayerService:_start()
	print(("[VyTax] PlayerService started | %d players online"):format(#self._players))
end

function PlayerService:GetPlayer(userId: number): Player?
	return self._players[userId]
end

function PlayerService:GetPlayers(): { Player }
	local list = {}
	for _, player in self._players do
		list[#list + 1] = player
	end
	return list
end

function PlayerService:GetPlayerCount(): number
	local count = 0
	for _ in self._players do count += 1 end
	return count
end

function PlayerService:Destroy()
	self._maid:DoCleaning()
end

return PlayerService.new()