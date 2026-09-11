--!strict

-- PlayerDataService es la autoridad de los datos de jugador durante la sesión.
-- La persistencia (DataStore) se integrará aquí en una etapa posterior.

local Players = game:GetService("Players")

export type PlayerData = {
	Coins: number,
	Level: number,
	XP: number,
	Seeds: number,
}

local DEFAULT_DATA: PlayerData = {
	Coins = 100,
	Level = 1,
	XP = 0,
	Seeds = 0,
}

local PlayerDataService = {}

local dataByPlayer: {[Player]: PlayerData} = {}
local initialized = false

local function createInitialData(): PlayerData
	return {
		Coins = DEFAULT_DATA.Coins,
		Level = DEFAULT_DATA.Level,
		XP = DEFAULT_DATA.XP,
		Seeds = DEFAULT_DATA.Seeds,
	}
end

function PlayerDataService:CreatePlayerData(player: Player): PlayerData
	local playerData = createInitialData()
	dataByPlayer[player] = playerData

	return playerData
end

function PlayerDataService:GetPlayerData(player: Player): PlayerData?
	return dataByPlayer[player]
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
