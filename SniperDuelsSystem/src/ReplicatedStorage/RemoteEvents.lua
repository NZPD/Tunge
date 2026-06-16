--!strict

local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "SniperDuelsRemotes"

local FireBullet = Instance.new("RemoteEvent")
FireBullet.Name = "FireBullet"
FireBullet.Parent = RemoteEvents

local BulletHit = Instance.new("RemoteEvent")
BulletHit.Name = "BulletHit"
BulletHit.Parent = RemoteEvents

local PlayerDied = Instance.new("RemoteEvent")
PlayerDied.Name = "PlayerDied"
PlayerDied.Parent = RemoteEvents

local MatchStateChanged = Instance.new("RemoteEvent")
MatchStateChanged.Name = "MatchStateChanged"
MatchStateChanged.Parent = RemoteEvents

local ScopeChanged = Instance.new("RemoteEvent")
ScopeChanged.Name = "ScopeChanged"
ScopeChanged.Parent = RemoteEvents

local ReloadStarted = Instance.new("RemoteEvent")
ReloadStarted.Name = "ReloadStarted"
ReloadStarted.Parent = RemoteEvents

local WeaponEquipped = Instance.new("RemoteEvent")
WeaponEquipped.Name = "WeaponEquipped"
WeaponEquipped.Parent = RemoteEvents

local ClientReady = Instance.new("RemoteEvent")
ClientReady.Name = "ClientReady"
ClientReady.Parent = RemoteEvents

local RequestRespawn = Instance.new("RemoteEvent")
RequestRespawn.Name = "RequestRespawn"
RequestRespawn.Parent = RemoteEvents

RemoteEvents.Parent = script

return RemoteEvents