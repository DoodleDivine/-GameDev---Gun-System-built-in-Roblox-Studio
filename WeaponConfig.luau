local Config = {
	weaponName = "PewPew",
	weaponModel = "PewPewModel",
	
	-- Server Anims
	idleanimationID = "rbxassetid://PlaceYourOwnId",
	shootanimationIDServer = "rbxassetid://PlaceYourOwnId",
	reloadanimationIDServer = "rbxassetid://PlaceYourOwnId",
	
	-- Client Anims
	shootanimationIDClient = "rbxassetid://PlaceYourOwnId",
	reloadanimationIDClient = "rbxassetid://PlaceYourOwnId",
	
	-- Sounds
	ShootSound = "rbxassetid://PlaceYourOwnId",
	ReloadSound = "rbxassetid://PlaceYourOwnId",
	
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
