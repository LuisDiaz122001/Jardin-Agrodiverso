--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local DataContract = require(script.Parent.DataContract)

type PersistentData = DataContract.PersistentData
type SessionLock = {
	Owner: string,
	ExpiresAt: number,
}

local DATASTORE_NAME = "JardinAgrodiverso_PlayerData_v1"
local LOCK_DATASTORE_NAME = "JardinAgrodiverso_SessionLocks_v1"
local MAX_ATTEMPTS = 3
local RETRY_DELAY = 2
local LOCK_DURATION = 120
local HEARTBEAT_INTERVAL = 30

local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
local lockStore = DataStoreService:GetDataStore(LOCK_DATASTORE_NAME)
local DataStoreRepository = {}
local sessions: {[string]: {Token: string, Heartbeat: thread?}} = {}
local closingSessions: {[string]: boolean} = {}

local function retry<T>(operation: () -> T): (boolean, T?, string?)
	local lastError: string? = nil

	for attempt = 1, MAX_ATTEMPTS do
		local success, resultOrError = pcall(operation)

		if success then
			return true, resultOrError, nil
		end

		lastError = tostring(resultOrError)

		if attempt < MAX_ATTEMPTS then
			task.wait(RETRY_DELAY)
		end
	end

	return false, nil, lastError
end

local function getKey(userId: number): string
	return tostring(userId)
end

local function stopHeartbeat(userId: number)
	local key = getKey(userId)
	local session = sessions[key]

	if session and session.Heartbeat then
		task.cancel(session.Heartbeat)
		session.Heartbeat = nil
	end
end

local function renewLock(userId: number, token: string): boolean
	local key = getKey(userId)
	local owner: string? = nil
	local success, _, errorMessage = retry(function()
		lockStore:UpdateAsync(key, function(value)
			local lock = value :: SessionLock?

			if not lock or lock.Owner ~= token then
				return value
			end

			owner = token
			return {
				Owner = token,
				ExpiresAt = os.time() + LOCK_DURATION,
			}
		end)
	end)

	if not success then
		warn(string.format(
			"DataStoreRepository no pudo renovar el session lock de UserId %d: %s",
			userId,
			errorMessage or "error desconocido"
		))
	end

	return success and owner == token
end

function DataStoreRepository:Load(userId: number): (boolean, any?, boolean, string?)
	local key = getKey(userId)
	local token = HttpService:GenerateGUID(false)
	local acquired = false
	local now = os.time()

	local lockSuccess, _, lockError = retry(function()
		lockStore:UpdateAsync(key, function(value)
			local lock = value :: SessionLock?

			if lock and lock.ExpiresAt > now and lock.Owner ~= token then
				return value
			end

			acquired = true
			return {
				Owner = token,
				ExpiresAt = now + LOCK_DURATION,
			}
		end)
	end)

	if not lockSuccess or not acquired then
		if not lockSuccess then
			warn(string.format(
				"DataStoreRepository no pudo adquirir el session lock de UserId %d: %s",
				userId,
				lockError or "error desconocido"
			))
		end

		return false, nil, false, "No se pudo adquirir el session lock."
	end

	sessions[key] = {
		Token = token,
		Heartbeat = task.spawn(function()
			while sessions[key] and not closingSessions[key] do
				task.wait(HEARTBEAT_INTERVAL)

				if sessions[key] and not closingSessions[key] and not renewLock(userId, token) then
					stopHeartbeat(userId)
					break
				end
			end
		end),
	}

	local dataSuccess, rawData, dataError = retry(function()
		return dataStore:GetAsync(key)
	end)

	if not dataSuccess then
		warn(string.format(
			"DataStoreRepository no pudo cargar PlayerData de UserId %d: %s",
			userId,
			dataError or "error desconocido"
		))
		self:Release(userId)
		return false, nil, false, "No se pudo cargar el PlayerData."
	end

	return true, rawData, rawData == nil, nil
end

function DataStoreRepository:Save(userId: number, data: PersistentData): boolean
	local key = getKey(userId)
	local session = sessions[key]

	if not session then
		warn(string.format(
			"DataStoreRepository no pudo guardar PlayerData de UserId %d: no existe una sesión activa.",
			userId
		))
		return false
	end

	local renewed = renewLock(userId, session.Token)

	if not renewed then
		return false
	end

	local saved, _, saveError = retry(function()
		dataStore:SetAsync(key, data)
	end)

	if not saved then
		warn(string.format(
			"DataStoreRepository no pudo guardar PlayerData de UserId %d: %s",
			userId,
			saveError or "error desconocido"
		))
	end

	return saved
end

function DataStoreRepository:Release(userId: number): boolean
	local key = getKey(userId)
	local session = sessions[key]

	if not session then
		return false
	end

	closingSessions[key] = true
	stopHeartbeat(userId)

	local released = false
	local releaseRequestSucceeded, _, releaseError = retry(function()
		lockStore:UpdateAsync(key, function(value)
			local lock = value :: SessionLock?

			if lock and lock.Owner == session.Token then
				released = true
				return {
					Owner = "",
					ExpiresAt = 0,
				}
			end

			return value
		end)
	end)

	if not releaseRequestSucceeded then
		warn(string.format(
			"DataStoreRepository no pudo liberar el session lock de UserId %d: %s",
			userId,
			releaseError or "UpdateAsync falló después de todos los reintentos"
		))
		return false
	end

	if not released then
		warn(string.format(
			"DataStoreRepository no liberó el session lock de UserId %d: el Owner no coincide con la sesión actual.",
			userId
		))
		return false
	end

	sessions[key] = nil
	closingSessions[key] = nil
	return true
end

function DataStoreRepository:GetActiveUserIds(): {number}
	local userIds: {number} = {}

	for key in sessions do
		local userId = tonumber(key)

		if userId then
			table.insert(userIds, userId)
		end
	end

	return userIds
end

return DataStoreRepository
