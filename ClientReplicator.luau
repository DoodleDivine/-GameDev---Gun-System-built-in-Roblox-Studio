-- Services --
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunS = game:GetService("RunService")
local Players = game:GetService("Players")

local Camera = workspace.CurrentCamera

-- Remotes --
local ClientRepR = RS:WaitForChild("ClientRep")

ClientRepR.OnClientEvent:Connect(function(args)
	if not args then return end
	
	if args.effect == "BulletTrail" then
		
		print("Shooting")
		
		local hitPos = args.hitpos
		local origin = args.origin.ShootPart.Position
		local plr = args.plr
		
		if not hitPos or not origin then return end
		
		local trail = RS:WaitForChild("BulletTrail"):Clone()
		
		trail.Parent = workspace
		
		local dir = (hitPos - origin)
		local distance = dir.Magnitude
		
		local midPoint = (origin + hitPos) / 2
		trail.CFrame = CFrame.new(midPoint, hitPos)
		
		trail.Size = Vector3.new(trail.Size.X, trail.Size.Y, distance)
		
		local tween = TS:Create(trail, TweenInfo.new(0.2), {
			Transparency = 1
		})
		tween:Play()
		
		game:GetService("Debris"):AddItem(trail, 0.5)
	end
end)