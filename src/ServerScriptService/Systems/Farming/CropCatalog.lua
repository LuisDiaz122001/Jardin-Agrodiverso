--!strict

-- CropCatalog es la definición compartida de cada cultivo.
-- FarmingService usa los datos de gameplay; CropVisualService usa los datos visuales.
-- No crea instancias del mapa: solo describe cómo interpretar parcelas y modelos existentes.

export type VisualAppearance = {
	Id: number,
	Scale: number,
	VisiblePartNames: {string}?,
}

export type GrowingVisualStage = {
	Id: number,
	AtProgress: number,
	Scale: number,
	VisiblePartNames: {string}?,
}

export type CropDefinition = {
	GrowthDuration: number,
	CoinsReward: number,
	XPReward: number,
	SeedDropChance: number,
	VisualModelName: string,
	GrowingVisualStages: {GrowingVisualStage},
	ReadyVisual: VisualAppearance,
}

local EMPTY_VISUAL_STAGE_ID = 0

local CROP_DEFINITIONS: {[string]: CropDefinition} = {
	Corn = {
		GrowthDuration = 30,
		CoinsReward = 10,
		XPReward = 5,
		SeedDropChance = 0.15,
		VisualModelName = "CornCrop",
		GrowingVisualStages = {
			{
				Id = 1,
				AtProgress = 0,
				Scale = 0.3,
				VisiblePartNames = { "Stem" },
			},
			{
				Id = 2,
				AtProgress = 0.5,
				Scale = 0.7,
			},
		},
		ReadyVisual = {
			Id = 3,
			Scale = 1,
		},
	},
}

local CropCatalog = {}

function CropCatalog.GetEmptyVisualStageId(): number
	return EMPTY_VISUAL_STAGE_ID
end

function CropCatalog.Get(cropType: string): CropDefinition?
	return CROP_DEFINITIONS[cropType]
end

function CropCatalog.FindGrowingStage(definition: CropDefinition, stageId: number): GrowingVisualStage?
	for _, stage in definition.GrowingVisualStages do
		if stage.Id == stageId then
			return stage
		end
	end

	return nil
end

function CropCatalog.GetFirstGrowingStage(definition: CropDefinition): GrowingVisualStage?
	return definition.GrowingVisualStages[1]
end

return CropCatalog
