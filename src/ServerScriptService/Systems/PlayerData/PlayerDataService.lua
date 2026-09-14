--!strict

-- PlayerDataService es la autoridad de los datos de jugador durante la sesión.
-- La persistencia (DataStore) se integrará aquí en una etapa posterior.

local Players = game:GetService("Players")

-- Modo de desarrollo: cambiar a false antes de probar el comportamiento normal.
local DEV_MODE = true
local DEV_TOMATO_SEEDS = 3

export type PlayerData = {
	Coins: number,
	Level: number,
	XP: number,
	Seeds: number,
	Inventory: {[string]: number},
}

local DEFAULT_DATA: PlayerData = {
	Coins = 100,
	Level = 1,
	XP = 0,
	Seeds = 0,
	Inventory = {},
}

local PlayerDataService = {}

local dataByPlayer: {[Player]: PlayerData} = {}
local initialized = false

local function createInitialData(): PlayerData
	local playerData: PlayerData = {
		Coins = DEFAULT_DATA.Coins,
		Level = DEFAULT_DATA.Level,
		XP = DEFAULT_DATA.XP,
		Seeds = DEFAULT_DATA.Seeds,
		Inventory = {},
	}

	if DEV_MODE then
		playerData.Inventory["TomatoSeeds"] = DEV_TOMATO_SEEDS
	end

	return playerData
end

function PlayerDataService:CreatePlayerData(player: Player): PlayerData
	local playerData = createInitialData()
	dataByPlayer[player] = playerData
	self:SyncPlayerAttributes(player)

	return playerData
end

function PlayerDataService:GetPlayerData(player: Player): PlayerData?
	return dataByPlayer[player]
end

function PlayerDataService:SyncPlayerAttributes(player: Player)
	local playerData = dataByPlayer[player]

	if not playerData then
		return
	end

	player:SetAttribute("Coins", playerData.Coins)
	player:SetAttribute("Level", playerData.Level)
	player:SetAttribute("XP", playerData.XP)
	player:SetAttribute("Seeds", playerData.Seeds)
	player:SetAttribute("TomatoSeeds", playerData.Inventory["TomatoSeeds"] or 0)
end

function PlayerDataService:RemovePlayerData(player: Player)
	dataByPlayer[player] = nil
end

function PlayerDataService:Initialize()
	if initialized then
		warn("PlayerDataService ya fue inicializado.")
		return
	end

	initialized = true

	Players.PlayerAdded:Connect(function(player)
		self:CreatePlayerData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:RemovePlayerData(player)
	end)

	-- Cubre jugadores que ya estén presentes si el sistema se inicializa después.
	for _, player in Players:GetPlayers() do
		self:CreatePlayerData(player)
	end
end

return PlayerDataService
