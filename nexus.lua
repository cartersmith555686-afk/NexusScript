-- NexusServer
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ALLOWED = {
	[5736860038] = true, -- Replace with your UserId
}

local remote = Instance.new("RemoteEvent")
remote.Name = "NexusRemote"
remote.Parent = ReplicatedStorage

local states = {}

local function cleanup(player)
	local s = states[player]
	if not s then return end

	if s.velocity then s.velocity:Destroy() end
	if s.orientation then s.orientation:Destroy() end
	if s.attachment then s.attachment:Destroy() end

	states[player] = nil
end

local function setup(player, character)
	cleanup(player)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 16
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setup(player, character)
	end)

	if player.Character then
		setup(player, player.Character)
	end
end)

Players.PlayerRemoving:Connect(cleanup)

remote.OnServerEvent:Connect(function(player, action, a, b)
	if not ALLOWED[player.UserId] then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	if action == "Walk" then
		humanoid.WalkSpeed = math.clamp(tonumber(a) or 16, 0, 100)

	elseif action == "Jump" then
		humanoid.JumpPower = math.clamp(tonumber(a) or 50, 0, 150)

	elseif action == "Fly" then
		if a == true then
			cleanup(player)

			local attachment = Instance.new("Attachment")
			attachment.Name = "NexusFlightAttachment"
			attachment.Parent = root

			local velocity = Instance.new("LinearVelocity")
			velocity.Attachment0 = attachment
			velocity.RelativeTo = Enum.ActuatorRelativeTo.World
			velocity.MaxForce = 1000000
			velocity.VectorVelocity = Vector3.zero
			velocity.Parent = root

			local orientation = Instance.new("AlignOrientation")
			orientation.Attachment0 = attachment
			orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
			orientation.MaxTorque = 1000000
			orientation.Responsiveness = 15
			orientation.Parent = root

			humanoid.AutoRotate = false
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)

			states[player] = {
				attachment = attachment,
				velocity = velocity,
				orientation = orientation,
				speed = 60,
				direction = Vector3.zero,
			}
		else
			cleanup(player)
			humanoid.AutoRotate = true
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

	elseif action == "FlyUpdate" then
		local s = states[player]
		if not s then return end

		if typeof(a) == "Vector3" then
			s.direction = Vector3.new(
				math.clamp(a.X, -1, 1),
				math.clamp(a.Y, -1, 1),
				math.clamp(a.Z, -1, 1)
			)
		end

		s.speed = math.clamp(tonumber(b) or 60, 0, 200)
		s.velocity.VectorVelocity = s.direction * s.speed

	elseif action == "SuperJump" then
		humanoid.JumpPower = math.clamp(tonumber(a) or 50, 0, 150)
	end
end)
