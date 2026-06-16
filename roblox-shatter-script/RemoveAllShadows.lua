local Lighting = game:GetService("Lighting")

Lighting.GlobalShadows = false
Lighting.ShadowSoftness = 0
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

local function removeShadowsFromInstance(instance)
	if instance:IsA("BasePart") or instance:IsA("Model") or instance:IsA("Attachment") then
		pcall(function()
			instance.CastShadow = false
		end)
	end

	if instance:IsA("Light") then
		pcall(function()
			instance.Shadows = false
		end)
	end
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	removeShadowsFromInstance(descendant)
end

for _, descendant in ipairs(Lighting:GetDescendants()) do
	if descendant:IsA("Light") then
		descendant.Shadows = false
	end
end

workspace.DescendantAdded:Connect(function(descendant)
	removeShadowsFromInstance(descendant)
end)