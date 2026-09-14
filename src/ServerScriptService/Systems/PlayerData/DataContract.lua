--!strict

local DataContract = {}

DataContract.CURRENT_DATA_VERSION = 1
DataContract.MAX_COINS = 1_000_000_000
DataContract.MAX_XP = 1_000_000_000
DataContract.MAX_ITEM_COUNT = 1_000_000

export type PersistentData = {
	DataVersion: number,
	Coins: number,
	XP: number,
	Inventory: {[string]: number},
}

function DataContract.CreateDefaultData(): PersistentData
	return {
		DataVersion = DataContract.CURRENT_DATA_VERSION,
		Coins = 100,
		XP = 0,
		Inventory = {},
	}
end

return DataContract
