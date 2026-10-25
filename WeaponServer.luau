-- Services -- 
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SS = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local SP = game:GetService("StarterPlayer")

-- Remotes --
local VMRemote = RS:WaitForChild("VMRemote")
local ShootRemote = RS:WaitForChild("ShootRemote")
local ClientRepR = RS:WaitForChild("ClientRep")
local SendHeadShot = RS:WaitForChild("SendHeadShot")

-- Variables -- 
local ServerRateLimit = 0.1
local pingBuffer = 15

local SpawedWeapons = {}
local playerState = {}

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAppearanceLoaded:Connect(function(model)
		for _, item in pairs(model:GetDescendants()) do
			if item:IsA("BasePart") and item.Parent:IsA("Accessory") and item.Name == "Handle" then
				item.CanQuery = false
			end
		end
	end)
	
	local char = plr.Character
	if not char then return end
	
	local hum = char:WaitForChild("Humanoid")
	
	if hum.Health <= 50 then
		SP.CharacterWalkSpeed = 10
	end
end)

VMRemote.OnServerEvent:Connect(function(plr, action, ConfigData)
	
	local Char = plr.Character or plr.CharacterAdded:Wait()
	local Hum = Char:WaitForChild("Humanoid")

	local Animator = Hum:WaitForChild("Animator")
	
	if action == "PlayAnim" then
		
		if not ConfigData or type(ConfigData) ~= "table" then
			warn("Invalid config data received")
			return
		end
		
		if SpawedWeapons[plr] then
			SpawedWeapons[plr]:Destroy()
		end
		
		local WeaponsFolder = RS:WaitForChild("Weapons")
		
		local targetWeapon = WeaponsFolder:FindFirstChild(ConfigData.weaponName)
		
		if not targetWeapon then
			warn("Missing model asset in replicated storage")
			return 
		end
		
		local WeaponModel = targetWeapon:Clone()

		local VMHolder = WeaponModel:WaitForChild("Holder")

		local VMMotor6d = VMHolder:FindFirstChild("WeaponMotor6D")

		if VMMotor6d then
			VMMotor6d.Part0 = Char:WaitForChild("Right Arm")
			VMMotor6d.Parent = VMHolder
		else
			warn("Motor6D not found in VMHolder")
		end

		WeaponModel.Parent = Char
		
		SpawedWeapons[plr] = WeaponModel
		
		-- Idle
		if ConfigData.idleanimationID then
			local IdleAnim = Instance.new("Animation")
			IdleAnim.AnimationId = ConfigData.idleanimationID
			
			local IdleAnimTrack = Animator:LoadAnimation(IdleAnim)
			IdleAnimTrack.Name = "IdleAnimTrack"
			IdleAnimTrack:Play()
			
			IdleAnim:Destroy()
		else
			warn("Idle animation ID not found in config data")
			return
		end
		
		
	elseif action == "StopAnim" then
		if SpawedWeapons[plr] then
			SpawedWeapons[plr]:Destroy()
			SpawedWeapons[plr] = nil
		end
		
		for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
			if track.Name == "IdleAnimTrack" then
				track:Stop()
			end
		end
		
	elseif action == "ReloadAnim" then
		
		if not ConfigData or type(ConfigData) ~= "table" then
			warn("Invalid config data received")
			return
		end
		
		if ConfigData.reloadanimationIDServer then
			local ReloadAnim = Instance.new("Animation")
			ReloadAnim.AnimationId = ConfigData.reloadanimationIDServer
			
			local ReloadAnimTrack = Animator:LoadAnimation(ReloadAnim)
			ReloadAnimTrack:Play()
			
			ReloadAnim:Destroy()
		else
			warn("AnimationID not found in config data")
		end
	end
	
end)

local function PlayerValidation(player)
	local st = playerState[player]
	if not st then
		st = { lastShot = 0 }
		playerState[player] = st
	end
	return st
end

ShootRemote.OnServerEvent:Connect(function(plr, tool, timestamp, origin, hitposition, hitnormal, hitinstance, config)
	if not tool or not origin or not hitposition then return end
	local now = Workspace:GetServerTimeNow()
	
	local ping = now - timestamp 

	if ping < 0 or ping > 1  then
		return
	end
	
	local char = plr.Character
	if not char or not char.PrimaryPart then return end
	
	local Animator = char:WaitForChild("Humanoid"):WaitForChild("Animator")
	
	local st = PlayerValidation(plr) or {lastShot = 0}
	
	playerState[plr] = st
	
	if now - st.lastShot < ServerRateLimit then return end
	
	st.lastShot = now
	
	if ClientRepR then
		local weaponOrigin = origin
		local serverWeapon = SpawedWeapons[plr]
		
		if serverWeapon and serverWeapon:FindFirstChild("ShootPart") then
			weaponOrigin = serverWeapon.ShootPart.Position
		end
		
		ClientRepR:FireAllClients({
			effect = "BulletTrail",
			origin = serverWeapon,
			hitpos = hitposition,
			normal = hitnormal,
			plr = plr
		})
	end
	
	if hitinstance and hitinstance.Parent then
		local targetModel = hitinstance:FindFirstAncestorOfClass("Model")
		local hum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
		
		if hum and hum.Health > 0 then
			
			local isHeadshot = false
			
			if hitinstance.Name == "Head" then
				isHeadshot = true
			end
			
			local Damage = config.damage

			if isHeadshot then
				Damage *= 2

				if SendHeadShot then
					SendHeadShot:FireClient(plr)
				end

				local HeadShotSound = SS:WaitForChild("HeadShotSound"):Clone()

				HeadShotSound.Parent = targetModel.PrimaryPart

				HeadShotSound:Play()

				Debris:AddItem(HeadShotSound, HeadShotSound.TimeLength)
			else
				local HitSound = SS:WaitForChild("HitSound"):Clone()

				HitSound.Parent = targetModel.PrimaryPart

				HitSound:Play()

				Debris:AddItem(HitSound, HitSound.TimeLength)
			end
			
			hum:TakeDamage(Damage)

			if config.shootanimationIDServer then
				local ShootAnim = Instance.new("Animation")
				ShootAnim.AnimationId = config.shootanimationIDServer

				local ShootAnimTrack = Animator:LoadAnimation(ShootAnim)
				ShootAnimTrack.Name = "ShootAnimTrack"
				ShootAnimTrack:Play()

				ShootAnim:Destroy()
			else
				warn("AnimationID not found in config data")
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	playerState[plr] = nil
end)