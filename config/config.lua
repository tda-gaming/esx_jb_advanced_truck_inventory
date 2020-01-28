--Truck
Config	=	{}

 -- Limit, unit can be whatever you want. Originally grams (as average people can hold 25kg)
Config.Limit = 25000

-- Default weight for an item:
	-- weight == 0 : The item do not affect character inventory weight
	-- weight > 0 : The item cost place on inventory
	-- weight < 0 : The item add place on inventory. Smart people will love it.
Config.DefaultWeight = 1000



-- If true, ignore rest of file
Config.WeightSqlBased = false

-- I Prefer to edit weight on the config.lua and I have switched Config.WeightSqlBased to false:

Config.PoliceWeapons = {
    [`WEAPON_VINTAGEPISTOL`] = true,
    [`WEAPON_SMG`] = true,
    [`WEAPON_NIGHTSTICK`] = true,
    [`WEAPON_COMBATPISTOL`] = true,
    [`WEAPON_APPISTOL`] = true,
    [`WEAPON_CARBINERIFLE`] = true,
    [`WEAPON_PUMPSHOTGUN`] = true,
    [`WEAPON_MG`] = true,
    [`WEAPON_SNIPERRIFLE`] = true,
    [`WEAPON_STUNGUN`] = true
}

Config.localWeight = {
	bread = 125,
	water = 330,
	WEAPON_COMBATPISTOL = 1000, -- poid poir une munnition
    black_money = 1, -- poids pour un argent
    coke = 500,
    weed = 500,
    meth = 500,
    weed_pooch = 1000,
    coke_pooch = 1750,
    meth_pooch = 1750,
    packaged_plank = 700,
    iron = 125,
    washed_stone = 2500,
    stone = 3000,
    gold = 100,
    diamond = 100,
    copper = 125,
    wood = 1000,
    cutted_wood = 800,
    alive_chicken = 3000,
    packaged_chicken = 600,
    fish = 500,
    essence = 750,
    petrol = 1000,
    petrol_raffin = 1500,
}

Config.ModelLimit = {
    -- Ik zet in plugin de DisplayName volledig om naar hoofdletters, om dus misverstanden te voorkomen
    [`KAMACHO`] = 100000,
    [`NISSANTITAN17`] = 125000,
    [`RAPTOR2017`] = 125000,
    [`LADA2107`] = 60000,
    [`DUBSTA`] = 80000,
    [`GUARDIAN`] = 135000,
    [`SEASHARK`] = 10000,
    [`A45`] = 60000,
    [`BAC2`] = 5000,
    [`BALLER`] = 40000,
    [`BARRACKS`] = 100000,
    [`BLAZER`] = 30000,
    [`BLAZER2`] = 30000,
    [`BLAZER3`] = 30000,
    [`BLAZER4`] = 30000,
    [`HAVOK`] = 10000,
    [`MICROLIGHT`] = 10000,
    [`TRAILERSMALL`] = 30000,
    [`BOATTRAILER`] = 30000,
    [`DUNE`] = 40000,
    [`RAM2500LIFTED`] = 125000,
    [`PHANTOM`] = 175000,
}

Config.VehicleLimit = {
    [0]=30000,  --Compact
    [1]=40000,  --Sedan
    [2]=70000,  --SUV
    [3]=60000,  --Coupes
    [4]=60000,  --Muscleq
    [5]=60000,  --Sports Classics
    [6]=60000,  --Sports
    [7]=60000,  --Super
    [8]=10000,  --Motorcycles
    [9]=100000,  --Off-road
    [10]=150000,--Industrial
    [11]=70000, --Utility
    [12]=90000, --Vans
    [13]=0,     --Cycles
    [14]=70000, --Boats
    [15]=200000, --Helicopters
    [16]=40000, --Planes
    [17]=40000, --Service
    [18]=40000, --Emergency
    [19] = 25000,   --Military
    [20]=200000,--Commercial
    [21] = 0,   --Trains
    [22] =100000,--Jeep
}