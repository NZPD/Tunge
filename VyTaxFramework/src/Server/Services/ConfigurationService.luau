local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Configuration = ReplicatedStorage:FindFirstChild("Configuration")
if not Configuration then
	Configuration = Instance.new("Folder")
	Configuration.Name = "Configuration"
	Configuration.Parent = ReplicatedStorage
end

local TeamEvent = Configuration:FindFirstChild("TeamEvent")
if not TeamEvent then
	TeamEvent = Instance.new("RemoteEvent")
	TeamEvent.Name = "TeamEvent"
	TeamEvent.Parent = Configuration
end

local function setupGamepasses()
	local moduleScript = Configuration:FindFirstChild("Gamepasses")
	if not moduleScript then
		moduleScript = Instance.new("ModuleScript")
		moduleScript.Name = "Gamepasses"
		moduleScript.Parent = Configuration
		moduleScript.Source = [[
local ServerStorage = game:GetService("ServerStorage")

return {
	{
		GamepassName = "M4A1";
		GamepassID = 107934807;
		GamepassIcon = 11474788755;
		GamepassDescription = "M4A1 is one of the powerful weapons in this game, if you purchase this weapon you will receive it immediately and permanently.";
		GamepassPath = ServerStorage:FindFirstChild("M4A1");
	};
	{
		GamepassName = "King/Queen";
		GamepassID = 107934807;
		GamepassIcon = 11474788755;
		GamepassDescription = "The sovereign monarch of Great Britain, the King/Queen of Great Britain, has a special weapon to go along with their rule.";
		GamepassPath = ServerStorage:FindFirstChild("Sabre");
	};
	{
		GamepassName = "Prime Minister";
		GamepassID = 107934807;
		GamepassIcon = 11474788755;
		GamepassDescription = "As the Prime Minister you will rule over Britain and make important decisions";
		GamepassPath = ServerStorage:FindFirstChild("PMID");
	};
	{
		GamepassName = "Golden Glock";
		GamepassID = 107934807;
		GamepassIcon = 11474788755;
		GamepassDescription = "The Golden Glock can one shot anyone.";
		GamepassPath = ServerStorage:FindFirstChild("GG");
	};
}
]]
	end
	return require(moduleScript)
end

local function setupTeamInfo()
	local moduleScript = Configuration:FindFirstChild("TeamInfo")
	if not moduleScript then
		moduleScript = Instance.new("ModuleScript")
		moduleScript.Name = "TeamInfo"
		moduleScript.Parent = Configuration
		moduleScript.Source = [[
return {
	["Test"] = {
		MinimumRank = 0;
		MaximumRank = 255;
		GroupID = 0;
		LogoID = 12620342119;
	};
	["Test2"] = {
		MinimumRank = 1;
		MaximumRank = 255;
		GroupID = 35733760;
		LogoID = 8652665149;
	};
}
]]
	end
	return require(moduleScript)
end

local gConfig = setupGamepasses()
local teamConfig = setupTeamInfo()

local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
	Events = Instance.new("Folder")
	Events.Name = "Events"
	Events.Parent = ReplicatedStorage
end

local ECEvent = Events:FindFirstChild("EC_Event")
if not ECEvent then
	ECEvent = Instance.new("RemoteEvent")
	ECEvent.Name = "EC_Event"
	ECEvent.Parent = Events
end

local ReportEvent = ReplicatedStorage:FindFirstChild("reportSubmitter")
if not ReportEvent then
	ReportEvent = Instance.new("RemoteEvent")
	ReportEvent.Name = "reportSubmitter"
	ReportEvent.Parent = ReplicatedStorage
end

local CodeFunction = ReplicatedStorage:FindFirstChild("codeSubmitter")
if not CodeFunction then
	CodeFunction = Instance.new("RemoteFunction")
	CodeFunction.Name = "codeSubmitter"
	CodeFunction.Parent = ReplicatedStorage
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		for _, v in gConfig do
			if v.GamepassID and v.GamepassPath then
				local success, owned = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, v.GamepassID)
				end)
				if success and owned then
					local clone = v.GamepassPath:Clone()
					clone.Parent = plr.Backpack
				end
			end
		end
	end)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, purchased)
	if not purchased then return end
	for _, v in gConfig do
		if v.GamepassID == id and v.GamepassPath then
			local clone = v.GamepassPath:Clone()
			clone.Parent = plr.Backpack
			break
		end
	end
end)

TeamEvent.OnServerEvent:Connect(function(plr, teamName)
	local teamData = teamConfig[teamName]
	if not teamData then return end
	local currentRank = plr:GetRankInGroup(teamData.GroupID)
	if currentRank >= teamData.MinimumRank and currentRank <= teamData.MaximumRank then
		local targetTeam = Teams:FindFirstChild(teamName)
		if targetTeam then
			plr.Team = targetTeam
			plr:LoadCharacter()
		end
	end
end)

ReportEvent.OnServerEvent:Connect(function(plr, targetUserId, reason)
	local Reports = Instance.new("Folder")
	Reports.Name = "Reports"
	local datastore = game:GetService("DataStoreService"):GetDataStore("ReportLogs")
	local reportData = {
		Reporter = plr.UserId,
		Target = targetUserId,
		Reason = reason,
		Time = DateTime.now().UnixTimestampMillis,
	}
	pcall(function()
		local existing = datastore:GetAsync("reports") or {}
		table.insert(existing, reportData)
		datastore:SetAsync("reports", existing)
	end)
end)

CodeFunction.OnServerInvoke = function(plr, code)
	local Codes = Instance.new("Folder")
	Codes.Name = "Codes"
	local codeData = {
		Plr = plr.UserId,
		Code = code,
		Time = DateTime.now().UnixTimestampMillis,
	}
	local datastore = game:GetService("DataStoreService"):GetDataStore("CodeLogs")
	pcall(function()
		local existing = datastore:GetAsync("codes") or {}
		table.insert(existing, codeData)
		datastore:SetAsync("codes", existing)
	end)
	return "Code '" .. tostring(code) .. "' submitted for review."
end

ECEvent.OnServerEvent:Connect(function(plr, selectedUsers, coHost)
	if not plr:IsInGroup(35707664) then return end
	local message = "EC Event created by " .. plr.Name
	if coHost and coHost ~= "" then
		message = message .. " | Co-host: " .. coHost
	end
	if #selectedUsers > 0 then
		local names = {}
		for _, userId in selectedUsers do
			local target = Players:GetPlayerByUserId(userId)
			if target then table.insert(names, target.Name) end
		message = message .. " | Users: " .. table.concat(names, ", ")
		end
	end
	print(message)
	ECEvent:FireAllClients("Event logged: " .. message)
end)