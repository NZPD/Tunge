--!strict
-- Constants.luau
-- Contains all constant values used across the Obby Framework

local Types = require(script.Parent.Types)

export module

-- Remote Event Names
export const REMOTE_EVENTS = {
	STAGE_REACHED = "StageReached",
	PLAYER_FINISHED = "PlayerFinished",
	PLAYER_FELL = "PlayerFell",
	CHECKPOINT_PASSED = "CheckpointPassed",
	REQUEST_RESPAWN = "RequestRespawn",
	UPDATE_TIMER = "UpdateTimer",
	GAME_STATE_CHANGED = "GameStateChanged",
	LEADERBOARD_UPDATE = "LeaderboardUpdate",
	PLAYER_JOINED = "PlayerJoined",
	PLAYER_LEFT = "PlayerLeft",
	SYNC_PROGRESS = "SyncProgress",
	REQUEST_START_TIMER = "RequestStartTimer",
	PLAYER_TIMEOUT = "PlayerTimeout",
}

-- Default Game Configuration
export const DEFAULT_CONFIG: Types.ObbyConfig = {
	TotalStages = 10,
	StartDelay = 5,
	StageCompletionReward = 50,
	GameCompleteReward = 500,
	MaxPlayers = 12,
	AutoStartCountdown = 10,
	ForceResetTimeouts = true,
	TimeoutDuration = 60,
}

-- Color Theme
export const COLOR_THEME: Types.ColorTheme = {
	Primary = Color3.fromRGB(0, 170, 255),
	Secondary = Color3.fromRGB(255, 170, 0),
	Accent = Color3.fromRGB(255, 50, 100),
	Background = Color3.fromRGB(25, 25, 35),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 180),
	Success = Color3.fromRGB(0, 200, 100),
	Error = Color3.fromRGB(255, 50, 50),
	Warning = Color3.fromRGB(255, 200, 50),
}

-- Stage Brick Colors (Cycled)
export const STAGE_COLORS: { BrickColor } = {
	BrickColor.new("Bright blue"),
	BrickColor.new("Bright red"),
	BrickColor.new("Bright yellow"),
	BrickColor.new("Bright green"),
	BrickColor.new("Bright violet"),
	BrickColor.new("Bright orange"),
	BrickColor.new("Cyan"),
	BrickColor.new("Magenta"),
	BrickColor.new("Lime green"),
	BrickColor.new("Pink"),
}

-- Physics / Gameplay Constants
export const FALL_DETECTION_HEIGHT = -50
export const RESPAWN_DELAY = 1.5
export const CHECKPOINT_TRIGGER_DISTANCE = 8
export const FINISH_LINE_TRIGGER_DISTANCE = 5
export const TIMER_UPDATE_INTERVAL = 0.1
export const LEADERBOARD_MAX_ENTRIES = 50

-- Folder Names in Workspace
export const WORKSPACE_FOLDERS = {
	STAGES = "Stages",
	CHECKPOINTS = "Checkpoints",
	SPAWN_POINT = "SpawnPoint",
	FINISH_LINE = "FinishLine",
	LOBBY = "Lobby",
}

-- Tag Names for Parts
export const TAGS = {
	STAGE_PART = "StagePart",
	CHECKPOINT = "Checkpoint",
	FINISH_LINE = "FinishLine",
	SPAWN_POINT = "SpawnPoint",
	KILL_VOLUME = "KillVolume",
	LOBBY_AREA = "LobbyArea",
}

return module