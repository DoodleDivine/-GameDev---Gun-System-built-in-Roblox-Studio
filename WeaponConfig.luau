local Config = {
	weaponName = "PewPew",
	weaponModel = "PewPewModel",
	
	-- Server Anims
	idleanimationID = "rbxassetid://87125531490984",
	shootanimationIDServer = "rbxassetid://110117207824092",
	reloadanimationIDServer = "rbxassetid://70375076238781",
	
	-- Client Anims
	shootanimationIDClient = "rbxassetid://100535312807755",
	reloadanimationIDClient = "rbxassetid://74901954684622",
	
	-- Sounds
	ShootSound = "rbxassetid://136658763437216",
	ReloadSound = "rbxassetid://140545321475073",
	
	-- Weapon Data
	reloadTime = 0.5,
	damage = 10,
	
	--Extras
	DashCD = 0.5,
	LastDashTime = 0,
	DashSpeed = 100,
	DashDuration = 0.2,
}

return Config
