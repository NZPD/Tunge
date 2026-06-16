--!strict
-- Types.luau
-- Shared type definitions for the Obby Framework

export type StageData = {
	StageNumber: number,
	PartCFrame: CFrame,
	PartSize: Vector3,
	BrickColor: BrickColor,
	Material: Enum.Material,
	CheckpointPosition: CFrame,
	IsFinishLine: boolean,
}

export type PlayerProgress = {
	Player: Player,
	CurrentStage: number,
	StartTime: number,
	BestTime: number?,
	StageTimes: { [number]: number },
	TotalCheckpointsPassed: number,
	Completed: boolean,
}

export type LeaderboardEntry = {
	PlayerName: string,
	PlayerUserId: number,
	FinalTime: number,
	StagesCompleted: number,
	TotalCheckpoints: number,
}

export type GameState = "Waiting" | "Playing" | "Finished"

export type ObbyConfig = {
	TotalStages: number,
	StartDelay: number,
	StageCompletionReward: number,
	GameCompleteReward: number,
	MaxPlayers: number,
	AutoStartCountdown: number,
	ForceResetTimeouts: boolean,
	TimeoutDuration: number,
}

export type ColorTheme = {
	Primary: Color3,
	Secondary: Color3,
	Accent: Color3,
	Background: Color3,
	TextPrimary: Color3,
	TextSecondary: Color3,
	Success: Color3,
	Error: Color3,
	Warning: Color3,
}