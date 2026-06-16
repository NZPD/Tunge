local Maid = require(game:GetService("ReplicatedStorage").VyTax.Maid)
local Promise = require(game:GetService("ReplicatedStorage").VyTax.Promise)

local DataService = {}
DataService.__index = DataService

function DataService.new(): typeof(DataService)
	return setmetatable({}, DataService)
end

function DataService:_init()
	self._maid = Maid.new()
	self._sessions = {}
end

function DataService:_start()
	print("[VyTax] DataService started")
end

function DataService:LoadPlayerData(userId: number): Promise<any>
	return Promise.new(function(resolve, reject)
		local success, data = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore("PlayerData"):GetAsync(userId)
		end)
		if success then
			self._sessions[userId] = data or self:_getDefaultData()
			resolve(self._sessions[userId])
		else
			reject(data)
		end
	end)
end

function DataService:SavePlayerData(userId: number): Promise<boolean>
	return Promise.new(function(resolve, reject)
		if not self._sessions[userId] then
			resolve(false)
			return
		end
		local success, err = pcall(function()
			game:GetService("DataStoreService"):GetDataStore("PlayerData"):SetAsync(userId, self._sessions[userId])
		end)
		if success then resolve(true) else reject(err) end
	end)
end

function DataService:GetPlayerData(userId: number): any?
	return self._sessions[userId]
end

function DataService:SetPlayerData(userId: number, key: string, value: any)
	if not self._sessions[userId] then
		self._sessions[userId] = self:_getDefaultData()
	end
	self._sessions[userId][key] = value
end

function DataService:_getDefaultData(): {}
	return {
		Coins = 0,
		Level = 1,
		Experience = 0,
		Inventory = {},
		Settings = {},
	}
end

function DataService:Destroy()
	self._maid:DoCleaning()
	self._sessions = {}
end

return DataService.new()