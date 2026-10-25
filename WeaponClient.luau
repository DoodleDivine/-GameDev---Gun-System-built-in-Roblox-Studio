-- Services --
local RS = game:GetService("ReplicatedStorage")
local RUNS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local SP = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local SS = game:GetService("SoundService")
local SGUI = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- Variables --
local tool = script.Parent
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local char = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera

local WeaponDescGui = playerGui:WaitForChild("WeaponDescGui")

local PewPewFrame = WeaponDescGui:WaitForChild("PewPewFrame")
local AmmoLabel = PewPewFrame:WaitForChild("TextLabel")
local InfoLabel = PewPewFrame:WaitForChild("InfoLabel")

local HeadShotLabel = WeaponDescGui:WaitForChild("HeadShotLabel")

local SendHeadShot = RS:WaitForChild("SendHeadShot")

local EquipSound = SS:WaitForChild("GlobalEquipSound")
local ReloadSound
local ShootSound

local Mouse = nil
local ShootDelay = 0.2
local LastFire = 0
local MaxAmmo = 10
local Ammo = MaxAmmo
local Reloading = false

local ActivatedConnection = nil
local InputConnection = nil

-- Texts
AmmoLabel.Text = "Ammo: " .. Ammo .. "/Inf"

InfoLabel.Text = "Scope: RMB\n" .. "Fire: LMB\n" .. "Reload: R\n" .. "Q to Dash"

-- Modules --
local Config = require(script.Parent:WaitForChild("WeaponConfig"))

-- Remotes --
local VMRemote = RS:WaitForChild("VMRemote")
local ShootRemote = RS:WaitForChild("ShootRemote")

player.CameraMinZoomDistance = 12
player.CameraMaxZoomDistance = 0

local VM

local Equipped = false

local id = player.UserId

local HumDesc = Players:GetHumanoidDescriptionFromUserIdAsync(id)

local function resetState()
	Equipped = false
	
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = 12
	player.CameraMaxZoomDistance = 12
	camera.FieldOfView = 70
	
	if PewPewFrame then
		PewPewFrame.Visible = false
	end
	
	if VM then
		VM:Destroy()
		VM = nil
	end
	
	if ReloadSound then
		ReloadSound:Destroy()
		ReloadSound = nil
	end
	
	if ShootSound then
		ShootSound:Destroy()
		ShootSound = nil
	end
	
	if ActivatedConnection then
		ActivatedConnection:Disconnect()
		ActivatedConnection = nil
	end
	
	if InputConnection then
		InputConnection:Disconnect()
		InputConnection = nil
	end
end

local function resetEffects()
	Equipped = false
	
	if PewPewFrame then
		PewPewFrame.Visible = false
	end
	
	local Mouse = player:GetMouse()
	if not Mouse then return end
	
	Mouse.Icon = ""
	
	player.CameraMode = Enum.CameraMode.Classic
	
	local UnequipTween = TS:Create(player, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CameraMinZoomDistance = 12, CameraMaxZoomDistance = 12})

	UnequipTween:Play()
	
	local FOVTween = TS:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = 70})

	FOVTween:Play()
	
	VMRemote:FireServer("StopAnim")

	if ReloadSound then
		local soundToDestroy = ReloadSound
		ReloadSound = nil
		task.delay(2, function() if soundToDestroy then soundToDestroy:Destroy() end end)
	end

	if ShootSound then
		local soundToDestroy = ShootSound
		ShootSound = nil
		task.delay(2, function() if soundToDestroy then soundToDestroy:Destroy() end end)
	end

	if VM then
		VM:Destroy()
		VM = nil
	end

	Mouse = nil

	if ActivatedConnection then ActivatedConnection:Disconnect() ActivatedConnection = nil end
	if InputConnection then InputConnection:Disconnect() InputConnection = nil end
end

local function ReloadPewPew()
	if Reloading then return end
	if Ammo >= MaxAmmo then return end
	
	Reloading = true
	
	print("Reloading..")
	
	-- Fire to server to play reloadAnimation (server)
	VMRemote:FireServer("ReloadAnim", Config)
	
	-- Play reload sound
	if ReloadSound then
		ReloadSound:Play()
	end
	
	-- Play reload animation
	
	AmmoLabel.Text = "Ammo: " .. Ammo .. " Reloading"
	
	if Config.reloadanimationIDClient then
		local ReloadAnim = Instance.new("Animation")
		ReloadAnim.AnimationId = Config.reloadanimationIDClient

		local ReloadAnimTrack = VM.Humanoid:LoadAnimation(ReloadAnim)
		ReloadAnimTrack.Name = "ReloadAnimTrack"
		ReloadAnimTrack:Play()

		ReloadAnimTrack:Destroy()
	else
		warn("AnimationID not found in config data")
	end
	
	task.wait(Config.reloadTime)
	
	print("Reloaded!")
	Ammo = MaxAmmo
	
	Reloading = false
	
	AmmoLabel.Text = "Ammo: " .. Ammo .. "/Inf"
end


local function getGunOrigin()
	if not VM then
		return camera.CFrame.Position
	end
	
	local PewPewVM = VM:FindFirstChild(Config.weaponName)
	
	if not PewPewVM then
		warn("Gun model geometry missing in VM arms!")
		return camera.CFrame.Position
	end
	
	local shootPart = PewPewVM:FindFirstChild("ShootPart")
	
	if shootPart then
		return shootPart.Position
	end
	
	local structuralpart = PewPewVM:FindFirstChild("StructuralPart")
	return structuralpart and structuralpart.Position or camera.CFrame.Position
end

local function ClientRaycast(origin, targetPos)
	local dir = (targetPos - origin).Unit * 300
	local rayParams = RaycastParams.new()
	
	rayParams.FilterDescendantsInstances = { char }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	
	return workspace:Raycast(origin, dir, rayParams)
end

local function PewPewShot()
	if Ammo > 0 and Reloading == false then
		
		local now = Workspace:GetServerTimeNow()
		
		if now - LastFire < ShootDelay then return end
		
		LastFire = now

		local origin = camera.CFrame.Position
		local lookDir = camera.CFrame.LookVector
		
		local spreadAngle = math.rad(0.1)
		local random = Random.new()
		local roll = random:NextNumber() * math.pi * 2
		local pitch = random:NextNumber() * spreadAngle
		local spreadCFrame = camera.CFrame * CFrame.Angles(pitch, 0, roll)
		local direction = spreadCFrame.LookVector * 1000
		
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { char, VM }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = true
		
		local rayResult = workspace:Raycast(origin, direction, rayParams)
		
		local hitInstance = nil
		local hitPosition = direction - origin
		local hitNormal = Vector3.new(0, 1, 0)
		
		if rayResult then
			print(rayResult.Instance)
			hitInstance = rayResult.Instance
			hitPosition = rayResult.Position
			hitNormal = rayResult.Normal
		end
		
		ShootRemote:FireServer(tool, now, origin, hitPosition, hitNormal, hitInstance, Config)
			
		Ammo -= 1
			
		AmmoLabel.Text = "Ammo: " .. Ammo .. "/Inf"
			
		print("Ammo left: ", Ammo)
			
		if ShootSound then
			ShootSound:Play()
		end
			
		if Config.shootanimationIDClient then
			local ShootAnim = Instance.new("Animation")
			ShootAnim.AnimationId = Config.shootanimationIDClient
				
			local ShootAnimTrack = VM.Humanoid:LoadAnimation(ShootAnim)
			ShootAnimTrack.Name = "ShootAnimTrack"
			ShootAnimTrack:Play()
				
			ShootAnim:Destroy()
		else
			warn("AnimationID not found in config data")
		end
			
		
	elseif Ammo <= 0 then
		ReloadPewPew()
	end
end

local function DashPewPew(direction)
	local currTime = os.clock()
	
	if currTime - Config.LastDashTime < Config.DashCD then return end
	
	local RootP = char:FindFirstChild("HumanoidRootPart")
	local Hum = char:FindFirstChild("Humanoid")
	if not RootP or not Hum or Hum.Health <= 0 then return end
	
	Config.LastDashTime = currTime
	
	-- Gets total mass from character items
	local mass = 0
	
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			mass += part:GetMass()
		end
	end
	
	-- Vector
	local FV
	
	if direction == "Left" then
		FV = -RootP.CFrame.RightVector
	elseif direction == "Right" then
		FV = RootP.CFrame.RightVector	
	elseif direction == "Forward" then
		FV = RootP.CFrame.LookVector
	elseif direction == "Backward" then
		FV = -RootP.CFrame.LookVector
	end
	
	if FV then
		local att = Instance.new("Attachment")
		att.Name = "Attachment"
		att.Parent = RootP

		local LV = Instance.new("LinearVelocity")
		LV.Name = "LinearVelocity"
		LV.Attachment0 = att

		LV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector

		LV.VectorVelocity = FV * Config.DashSpeed
		LV.MaxForce = math.huge
		LV.Parent = RootP

		local PewPewDash = SS:WaitForChild("PewPewDash"):Clone()

		PewPewDash.Parent = SS

		PewPewDash:Play()
		
		game:GetService("Debris"):AddItem(PewPewDash, PewPewDash.TimeLength)

		task.delay(Config.DashDuration, function()
			if LV then LV:Destroy() end
			if att then att:Destroy() end
		end)
	end
end

tool.Equipped:Connect(function()
	ActivatedConnection = tool.Activated:Connect(PewPewShot)
	
	Mouse = player:GetMouse()
	
	Equipped = true
	
	Mouse.Icon = "rbxassetid://9102463858"
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	
	local EquipTween = TS:Create(player, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CameraMinZoomDistance = 0, CameraMaxZoomDistance = 0})
	
	EquipTween:Play()
	
	VM = RS:WaitForChild("ViewModels"):FindFirstChild(Config.weaponModel):Clone()
	
	VM.Parent = camera
	
	task.spawn(function()
		VM.Humanoid:ApplyDescription(HumDesc)
		
		for _, parts in pairs(VM:GetDescendants()) do
			if parts:IsA("Accessory") or parts:IsA("Decal") then
				parts:Destroy()
			elseif parts:IsA("BasePart") then
				parts.CanCollide = false
				parts.CanQuery = false
				parts.CastShadow = false
			end
		end
	end)
	
	EquipSound:Play()
	
	-- Create Reload sound
	if Config.ReloadSound then
		ReloadSound = Instance.new("Sound")
		ReloadSound.SoundId = Config.ReloadSound
		ReloadSound.Parent = SS
		ReloadSound.Volume = 0.1	
	end
	-- Create Shoot sound
	if Config.ShootSound then
		ShootSound = Instance.new("Sound")
		ShootSound.SoundId = Config.ShootSound
		ShootSound.Parent = SS
		ShootSound.Volume = 0.1
	end
	
	-- Reload
	InputConnection = UIS.InputBegan:Connect(function(I, GPE)
		if GPE then return end

		if I.KeyCode == Enum.KeyCode.R then
			ReloadPewPew()
		elseif I.KeyCode == Enum.KeyCode.Q then
			
			if UIS:IsKeyDown(Enum.KeyCode.W) then
				DashPewPew("Forward")
			
			elseif UIS:IsKeyDown(Enum.KeyCode.S) then
				DashPewPew("Backward")
			
			elseif UIS:IsKeyDown(Enum.KeyCode.D) then
				DashPewPew("Right")
				
			elseif UIS:IsKeyDown(Enum.KeyCode.A) then
				DashPewPew("Left")
			
			else
				DashPewPew("Forward")
			end	
		end
		
	end)
	
	VMRemote:FireServer("PlayAnim", Config)
	
	PewPewFrame.Visible = true
end)

tool.Unequipped:Connect(resetEffects)

local function SetUpChar(newchar)
	char = newchar
	
	resetState()

	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end

	hum.Died:Connect(function()
		resetState()
	end)
end

player.CharacterAdded:Connect(SetUpChar)

if player.Character then SetUpChar(player.Character) end

local PlayersView = CFrame.new()
local SwayOffset = CFrame.new()
local AimView = CFrame.new()

RUNS.RenderStepped:Connect(function()
	local currentChar = player.Character
	if not currentChar then return end
	
	local hum = currentChar:FindFirstChild("Humanoid")
	if not hum or hum.Health <= 0 then
		if VM then
			VM:Destroy()
			VM = nil
		end
		return
	end
	
	if Equipped == true and VM ~= nil then
		
		if not VM.PrimaryPart then
			return
		end
		
		-- add sway

		local MouseDelta = UIS:GetMouseDelta()/100

		local swayX = math.clamp(MouseDelta.X, -0.2, 0.2)
		local swayY = math.clamp(MouseDelta.Y, -0.2, 0.2)

		PlayersView = PlayersView:Lerp(CFrame.new(swayX, swayY, 0), 0.1)

		SwayOffset = SwayOffset:Lerp(CFrame.new(-swayX, swayY, 0), 0.1)

		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			AimView = AimView:Lerp(CFrame.new(-1.5, 0.5, 2), 0.1)
			camera.FieldOfView = camera.FieldOfView + (50 - camera.FieldOfView) * 0.1
		else
			AimView = AimView:Lerp(CFrame.new(), 0.1)
			camera.FieldOfView = camera.FieldOfView + (70 - camera.FieldOfView) * 0.1
		end

		PlayersView = camera.CFrame * AimView * SwayOffset

		VM:SetPrimaryPartCFrame(PlayersView)	
	end
end)

local TweenHeadShot

SendHeadShot.OnClientEvent:Connect(function()
	
	local randomX = math.random(20,80) / 100
	local randomY = math.random(20,80)/ 100
	
	HeadShotLabel.Position = UDim2.fromScale(randomX, randomY)
	
	local randomRot = math.random(-90, 90)
	HeadShotLabel.Rotation = randomRot
	
	HeadShotLabel.Visible = true
	HeadShotLabel.TextTransparency = 0
	
	if TweenHeadShot then TweenHeadShot:Cancel() end
	
	TweenHeadShot = TS:Create(HeadShotLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {TextTransparency = 1})
	
	TweenHeadShot:Play()
	
	TweenHeadShot.Completed:Connect(function()
		if HeadShotLabel.TextTransparency == 1 then
			HeadShotLabel.Visible = false
		end
	end)
end)