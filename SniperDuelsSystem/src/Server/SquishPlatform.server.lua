--!strict
local players = game:GetService("Players")

local squishfactor = 0.5
local squishspeed = 2
local returnspeed = 2
local tiltamount = 0.3

local part = script.Parent
local originalsize = part.Size
local originalcframe = part.CFrame
local squished = false
local currenttween = nil

local function getplayerpos()
	for _, player in ipairs(players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		local localpos = part.CFrame:PointToObjectSpace(root.Position)
		local halfsize = originalsize / 2
		if math.abs(localpos.X) < halfsize.X and math.abs(localpos.Z) < halfsize.Z and localpos.Y > -2 and localpos.Y < halfsize.Y + 5 then
			return root.Position
		end
	end
	return nil
end

while true do
	task.wait(0.1)
	if not part or not part.Parent then break end
	
	local playerpos = getplayerpos()
	if playerpos then
		local offset = part.CFrame:PointToObjectSpace(playerpos)
		local tiltx = math.clamp(-offset.X / (originalsize.X / 2), -1, 1) * tiltamount
		local tiltz = math.clamp(offset.Z / (originalsize.Z / 2), -1, 1) * tiltamount
		
		local squishsize = Vector3.new(originalsize.X, originalsize.Y * squishfactor, originalsize.Z)
		local heightdiff = originalsize.Y - squishsize.Y
		local targetcf = originalcframe * CFrame.new(0, -heightdiff / 2, 0) * CFrame.Angles(tiltx, 0, tiltz)
		
		if currenttween then currenttween:Cancel() end
		local tweeninfo = TweenInfo.new(squishspeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goals = { CFrame = targetcf, Size = squishsize }
		currenttween = game:GetService("TweenService"):Create(part, tweeninfo, goals)
		currenttween:Play()
		squished = true
	else
		if squished then
			if currenttween then currenttween:Cancel() end
			local tweeninfo = TweenInfo.new(returnspeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local goals = { CFrame = originalcframe, Size = originalsize }
			currenttween = game:GetService("TweenService"):Create(part, tweeninfo, goals)
			currenttween:Play()
			squished = false
		end
	end
end