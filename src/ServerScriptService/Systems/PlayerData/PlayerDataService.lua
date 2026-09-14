--!strict

-- PlayerDataService coordina la carga, el estado runtime y el guardado de PlayerData.
-- Los datos persistentes se validan antes de habilitar el gameplay.

local Players = game:GetService("Players")

local DataContract = require(script.Parent.DataContract)
local DataMigration = require(script.Parent.DataMigration)
local DataStoreRepository = require(script.Parent.DataStoreRepository)
local DataValidator = require(script.Parent.DataValidator)
local ProgressionCatalog = require(script.Parent.Parent.Progression.ProgressionCatalog)

-- Modo de desarrollo: no forma parte del contrato persistente.
local DEV_MODE = true
local DEV_TOMATO_SEEDS = 3
local AUTOSAVE_INTERVAL = 5 * 60

export type PlayerData = {
	Coins: number,
	Level: number,
	XP: number,
	Seeds: number,
	Inventory: {[string]: number},
}

export type LoadStatus = "Loading" | "Loaded" | "Failed"

local PlayerDataService = {}

local dataByPlayer: {[Player]: PlayerData} = {}
local statusByPlayer: {[Player]: LoadStatus} = {}
local repairedByPlayer: {[Player]: boolean} = {}
local devTomatoSeedsByPlayer: {[Player]: number} = {}
local activePlayersByUserId: {[number]: Player} = {}
type ClosingState = {
	Event: BindableEvent,
	Completed: boolean,
	Success: boolean,
}

local closingStatesByUserId: {[number]: ClosingState} = {}
local initialized = false
local shuttingDown = false

local function copyInventory(inventory: {[string]: number}): {[string]: number}
	local copy: {[string]: number} = {}

	for itemId, amount in inventory do
		copy[itemId] = amount
	end

	return copy
end

local function buildRuntimeData(
	persistentData: DataContract.PersistentData,
	isNewData: boolean,
	player: Player
): PlayerData
	local inventory = copyInventory(persistentData.Inventory)
	local devSeedGrant = 0

	if isNewData and DEV_MODE then
		inventory["TomatoSeeds"] = (inventory["TomatoSeeds"] or 0) + DEV_TOMATO_SEEDS
		devSeedGrant = DEV_TOMATO_SEEDS
	end

	devTomatoSeedsByPlayer[player] = devSeedGrant

	return {
		Coins = persistentData.Coins,
		Level = ProgressionCatalog.GetLevelForXP(persistentData.XP),
		XP = persistentData.XP,
		Seeds = inventory["Seeds"] or 0,
		Inventory = inventory,
	}
end

local function createPersistentPayload(player: Player): DataContract.PersistentData?
	local playerData = dataByPlayer[player]

	if not playerData then
		return nil
	end

	local inventory = copyInventory(playerData.Inventory)
	local devSeedGrant = devTomatoSeedsByPlayer[player] or 0

	if devSeedGrant > 0 then
		local currentTomatoSeeds = inventory["TomatoSeeds"] or 0
		local developmentAmountToExclude = math.min(devSeedGrant, currentTomatoSeeds)
		local remainingTomatoSeeds = currentTomatoSeeds - developmentAmountToExclude

		if remainingTomatoSeeds > 0 then
			inventory["TomatoSeeds"] = remainingTomatoSeeds
		else
			inventory["TomatoSeeds"] = nil
		end
	end

	inventory["Seeds"] = playerData.Seeds

	return {
		DataVersion = DataContract.CURRENT_DATA_VERSION,
		Coins = playerData.Coins,
		XP = playerData.XP,
		Inventory = inventory,
	}
end

local function setFailed(player: Player, message: string)
	statusByPlayer[player] = "Failed"
	warn(string.format("PlayerDataService no pudo cargar a %s: %s", player.Name, message))

	if player:IsDescendantOf(Players) then
		player:Kick("No se pudieron cargar tus datos. Intenta entrar nuevamente.")
	end
end

function PlayerDataService:GetPlayerData(player: Player): PlayerData?
	if statusByPlayer[player] ~= "Loaded" then
		return nil
	end

	return dataByPlayer[player]
end

function PlayerDataService:GetLoadStatus(player: Player): LoadStatus?
	return statusByPlayer[player]
end

function PlayerDataService:IsPlayerLoaded(player: Player): boolean
	return statusByPlayer[player] == "Loaded" and dataByPlayer[player] ~= nil
end

function PlayerDataService:SyncPlayerAttributes(player: Player)
	local playerData = self:GetPlayerData(player)

	if not playerData then
		return
	end

	player:SetAttribute("Coins", playerData.Coins)
	player:SetAttribute("Level", playerData.Level)
	player:SetAttribute("XP", playerData.XP)
	player:SetAttribute("Seeds", playerData.Seeds)
	player:SetAttribute("TomatoSeeds", playerData.Inventory["TomatoSeeds"] or 0)
end

function PlayerDataService:SavePlayerData(player: Player): boolean
	if statusByPlayer[player] ~= "Loaded" then
		return false
	end

	local persistentData = createPersistentPayload(player)

	if not persistentData then
		return false
	end

	local normalizedData, wasRepaired, errorMessage = DataValidator:Normalize(persistentData)

	if not normalizedData then
		warn(string.format("PlayerDataService no pudo validar el guardado de %s: %s", player.Name, errorMessage or "error desconocido"))
		return false
	end

	if wasRepaired then
		repairedByPlayer[player] = true
		warn(string.format("PlayerDataService reparó datos antes de guardar a %s.", player.Name))
	end

	local saved = DataStoreRepository:Save(player.UserId, normalizedData)

	if not saved then
		warn(string.format("PlayerDataService no pudo guardar a %s.", player.Name))
	end

	return saved
end

local function loadPlayerData(self: typeof(PlayerDataService), player: Player)
	statusByPlayer[player] = "Loading"

	local loaded, rawData, isNewData, loadError = DataStoreRepository:Load(player.UserId)

	if not loaded then
		setFailed(player, loadError or "error desconocido")
		return
	end

	local migratedData, wasMigrated, migrationError = DataMigration:ToCurrentVersion(rawData)

	if not migratedData then
		DataStoreRepository:Release(player.UserId)
		setFailed(player, migrationError or "migración no reconocible")
		return
	end

	local normalizedData, wasRepaired, validationError = DataValidator:Normalize(migratedData)

	if not normalizedData then
		DataStoreRepository:Release(player.UserId)
		setFailed(player, validationError or "validación no reconocible")
		return
	end

	if wasMigrated or wasRepaired then
		repairedByPlayer[player] = true
		warn(string.format("PlayerDataService transformó o reparó datos de %s durante la carga.", player.Name))
	end

	dataByPlayer[player] = buildRuntimeData(normalizedData, isNewData, player)
	statusByPlayer[player] = "Loaded"
	activePlayersByUserId[player.UserId] = player
	self:SyncPlayerAttributes(player)
end

function PlayerDataService:RemovePlayerData(player: Player)
	dataByPlayer[player] = nil
	statusByPlayer[player] = nil
	repairedByPlayer[player] = nil
	devTomatoSeedsByPlayer[player] = nil
	activePlayersByUserId[player.UserId] = nil
end

local function closePlayerSession(self: typeof(PlayerDataService), player: Player): boolean
	local userId = player.UserId

	local existingState = closingStatesByUserId[userId]

	if existingState then
		if not existingState.Completed then
			existingState.Event.Event:Wait()
		end

		return existingState.Success
	end

	local closingState: ClosingState = {
		Event = Instance.new("BindableEvent"),
		Completed = false,
		Success = false,
	}
	closingStatesByUserId[userId] = closingState

	local saved = true
	if self:IsPlayerLoaded(player) then
		saved = self:SavePlayerData(player)
		if not saved then
			warn(string.format(
				"PlayerDataService no pudo guardar PlayerData de UserId %d durante el cierre.",
				userId
			))
		end
	end

	local released = DataStoreRepository:Release(userId)

	if not released then
		warn(string.format(
			"PlayerDataService no pudo completar el cierre de UserId %d; el estado local se conservará hasta que termine la sesión.",
			userId
		))
	else
		self:RemovePlayerData(player)
	end

	closingState.Success = saved and released
	closingState.Completed = true
	closingState.Event:Fire()

	return closingState.Success
end

function PlayerDataService:Initialize()
	if initialized then
		warn("PlayerDataService ya fue inicializado.")
		return
	end

	initialized = true

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			loadPlayerData(self, player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		closePlayerSession(self, player)
	end)

	task.spawn(function()
		while not shuttingDown do
			task.wait(AUTOSAVE_INTERVAL)

			if shuttingDown then
				break
			end

			for _, player in Players:GetPlayers() do
				if self:IsPlayerLoaded(player) then
					self:SavePlayerData(player)
				end
			end
		end
	end)

	game:BindToClose(function()
		shuttingDown = true

		local userIds = DataStoreRepository:GetActiveUserIds()
		local closingEvents: {RBXScriptSignal} = {}

		for _, userId in userIds do
			local player = activePlayersByUserId[userId]

			if player then
				local closingState = closingStatesByUserId[userId]

				if closingState and not closingState.Completed then
					table.insert(closingEvents, closingState.Event.Event)
				else
					closePlayerSession(self, player)
				end
			end
		end

		for _, closingEvent in closingEvents do
			closingEvent:Wait()
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			loadPlayerData(self, player)
		end)
	end
end

return PlayerDataService
