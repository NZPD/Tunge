local players = game:GetService("Players")
local debris = game:GetService("Debris")

local part = script.Parent
part.Anchored = true

local player_on_part = nil
local crack_parts = {}

local orig_transparency = part.Transparency
local orig_material = part.Material
local orig_reflectance = part.Reflectance
local orig_color = part.Color

local crack_depth = 6
local crack_thickness = 0.04
local crack_width = 0.06
local glass_color = Color3.fromRGB(200, 220, 255)
local glass_reflectance = 0.4
local glass_transparency = 0.3

local faces = {
	{normal = Vector3.new(1,0,0),  size_idx = 1, up = Vector3.new(0,1,0),   right = Vector3.new(0,0,1)},
	{normal = Vector3.new(-1,0,0), size_idx = 1, up = Vector3.new(0,1,0),   right = Vector3.new(0,0,-1)},
	{normal = Vector3.new(0,1,0),  size_idx = 2, up = Vector3.new(0,0,1),   right = Vector3.new(1,0,0)},
	{normal = Vector3.new(0,-1,0), size_idx = 2, up = Vector3.new(0,0,-1),  right = Vector3.new(1,0,0)},
	{normal = Vector3.new(0,0,1),  size_idx = 3, up = Vector3.new(0,1,0),   right = Vector3.new(1,0,0)},
	{normal = Vector3.new(0,0,-1), size_idx = 3, up = Vector3.new(0,1,0),   right = Vector3.new(-1,0,0)},
}

local function generate_branch_on_face(start_pos, dir_2d, depth, face, face_size)
	if depth <= 0 then return end

	local branch_len = face_size * (0.1 + math.random() * 0.2) * (depth / crack_depth)
	local end_pos_2d = start_pos + dir_2d * branch_len

	local half_size = face_size / 2
	local clamped_end = Vector3.new(
		math.clamp(end_pos_2d.X, -half_size, half_size),
		math.clamp(end_pos_2d.Y, -half_size, half_size),
		0
	)

	if (clamped_end - start_pos).Magnitude < branch_len * 0.3 then
		return
	end

	local right_3d = face.right
	local up_3d = face.up
	local center_3d = part.Position + face.normal * (part.Size[face.size_idx] / 2)
	local start_3d = center_3d + right_3d * start_pos.X + up_3d * start_pos.Y
	local end_3d = center_3d + right_3d * clamped_end.X + up_3d * clamped_end.Y

	local crack = Instance.new("Part")
	local length = (end_3d - start_3d).Magnitude
	crack.Size = Vector3.new(length, crack_width, crack_thickness)
	crack.Anchored = true
	crack.CanCollide = false
	crack.CanTouch = false
	crack.CanQuery = false
	crack.Material = Enum.Material.SmoothPlastic
	crack.Color = Color3.fromRGB(15, 15, 15)
	crack.Transparency = 0.15
	crack.Reflectance = 0

	local mid_3d = (start_3d + end_3d) / 2
	local dir_3d = (end_3d - start_3d).Unit
	local look_dir = dir_3d
	local up_dir = face.normal
	local right_dir = look_dir:Cross(up_dir).Unit
	up_dir = right_dir:Cross(look_dir).Unit

	crack.CFrame = CFrame.fromMatrix(mid_3d, right_dir, up_dir, look_dir)
	crack.Parent = part

	table.insert(crack_parts, crack)
	debris:AddItem(crack, 4)

	local branch_count = math.random(1, 2)
	for i = 1, branch_count do
		local angle_spread = math.rad(20 + math.random() * 35)
		local angle = (i == 1 and -angle_spread) or angle_spread

		local new_dir_2d = CFrame.Angles(0, 0, angle) * Vector3.new(dir_2d.X, dir_2d.Y, 0)
		generate_branch_on_face(clamped_end, Vector3.new(new_dir_2d.X, new_dir_2d.Y, 0).Unit, depth - 1, face, face_size)
	end
end

local function crack_surface()
	local size = part.Size

	part.Material = Enum.Material.Glass
	part.Reflectance = glass_reflectance
	part.Transparency = glass_transparency
	part.Color = glass_color

	local face_count = math.random(2, 3)
	local shuffled_faces = {}
	for _, f in ipairs(faces) do
		table.insert(shuffled_faces, f)
	end
	for i = #shuffled_faces, 2, -1 do
		local j = math.random(i)
		shuffled_faces[i], shuffled_faces[j] = shuffled_faces[j], shuffled_faces[i]
	end

	for fi = 1, face_count do
		local face = shuffled_faces[fi]
		local face_size = (face.size_idx == 1 and size.Z or size.X)
		local face_height = (face.size_idx == 2 and size.Z or size.Y)
		local max_dim = math.max(face_size, face_height)

		local start_2d = Vector3.new(
			(math.random() - 0.5) * face_size * 0.6,
			(math.random() - 0.5) * face_height * 0.6,
			0
		)

		local angle = math.rad(math.random(0, 360))
		local dir_2d = Vector3.new(math.cos(angle), math.sin(angle), 0)

		generate_branch_on_face(start_2d, dir_2d, crack_depth, face, max_dim)
	end
end

local function heal_glass()
	for _, cp in ipairs(crack_parts) do
		if cp and cp.Parent then
			cp:Destroy()
		end
	end
	crack_parts = {}

	part.Transparency = orig_transparency
	part.Material = orig_material
	part.Reflectance = orig_reflectance
	part.Color = orig_color
end

part.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end
	if player_on_part then return end

	player_on_part = player
	crack_surface()
end)

local function remove_player(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end
	if player ~= player_on_part then return end

	player_on_part = nil

	task.wait(0.5)
	if player_on_part then return end
	heal_glass()
end

part.Leave:Connect(remove_player)
part.TouchEnded:Connect(remove_player)