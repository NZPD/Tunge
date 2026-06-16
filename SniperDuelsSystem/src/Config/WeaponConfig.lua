--!strict

local WeaponConfig = {}

WeaponConfig.Weapons = {
	DefaultSniper = {
		Name = "R700",
		DisplayName = "R-700 Sniper",
		BaseDamage = 100,
		HeadshotMultiplier = 2.5,
		DamageFalloffStart = 200,
		DamageFalloffEnd = 500,
		MinDamage = 35,
		BulletSpeed = 1500,
		BulletDrop = 0.2,
		MaxDistance = 1000,
		MagazineSize = 5,
		TotalAmmo = 25,
		ReloadTime = 2.5,
		ReloadType = "SingleRound",
		SingleReloadTime = 0.8,
		FireRate = 1.2,
		ChamberTime = 0.5,
		RecoilVertical = 15,
		RecoilHorizontal = 5,
		RecoilResetTime = 0.8,
		RecoilRecoverySpeed = 8,
		SpreadPerShot = 0.5,
		MaxSpread = 8,
		SpreadRecoveryRate = 6,
		ZoomFOV = 20,
		ZoomInTime = 0.3,
		ZoomOutTime = 0.15,
		HasScopeGlint = true,
		ScopeGlintDistance = 300,
		ADSFOV = 40,
		ADSInTime = 0.2,
		ADSOutTime = 0.1,
		SwayAmount = 0.1,
		SwaySmoothing = 5,
		BreatheSwayMultiplier = 0.3,
		BreatheHoldDuration = 4,
		BreatheCooldown = 6,
		MuzzleFlashDuration = 0.08,
		Sounds = {
			Fire = "rbxassetid://9120385264",
			ReloadStart = "rbxassetid://9120385632",
			ReloadEnd = "rbxassetid://9120385789",
			Chamber = "rbxassetid://9120385943",
			Hitmarker = "rbxassetid://9120386105",
			Empty = "rbxassetid://9120386278",
		},
	},
}

WeaponConfig.Hitmarker = {
	BaseColor = Color3.fromRGB(255, 255, 255),
	KillColor = Color3.fromRGB(255, 50, 50),
	Size = 20,
	Duration = 0.3,
	KillDuration = 0.6,
	SpreadAngle = 45,
}

WeaponConfig.Crosshair = {
	DefaultColor = Color3.fromRGB(255, 255, 255),
	DamageColor = Color3.fromRGB(255, 50, 50),
	Size = 5,
	Gap = 10,
	Thickness = 2,
	DotEnabled = true,
	DotSize = 3,
	SpreadEnabled = true,
}

WeaponConfig.KillFeed = {
	MaxMessages = 6,
	Duration = 8,
	FadeTime = 1,
}

WeaponConfig.RespawnTime = 5
WeaponConfig.FriendlyFire = false

return WeaponConfig