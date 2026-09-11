--!strict

-- PlotInteractionService conecta prompts existentes del mapa con FarmingService.
-- No crea ni modifica instancias del mapa.

local Workspace = game:GetService("Workspace")

local FarmingService = require(script.Parent.FarmingService)

local PlotInteractionService = {}

local initialized = false
local connectedPrompts: {[ProximityPrompt]: RBXScriptConnection} = {}

local function findFarmRoot(): Instance?
	local stations = Workspace:FindFirstChild("Stations")

	if not stations then
		return nil
	end

	return stations:FindFirstChild("Farm")
end

local function findPlotForPrompt(prompt: ProximityPrompt, farmRoot: Instance): Instance?
	local candidate = prompt.Parent

	while candidate and candidate ~= farmRoot do
		if type(candidate:GetAttribute("CropType")) == "string" then
			return candidate
		end

		candidate = candidate.Parent
	end

	return nil
end

local function connectPrompt(prompt: ProximityPrompt, plot: Instance)
	if connectedPrompts[prompt] then
		return
	end

	connectedPrompts[prompt] = prompt.Triggered:Connect(function(player)
		local cropState = FarmingService:GetCropState(plot)

		if cropState == "Empty" then
			FarmingService:Plant(player, plot)
		elseif cropState == "Ready" then
			FarmingService:Harvest(player, plot)
		end
	end)
end

function PlotInteractionService:Initialize()
	if initialized then
		return
	end

	local farmRoot = findFarmRoot()

	if not farmRoot then
		warn("PlotInteractionService no encontró Workspace.Stations.Farm.")
		return
	end

	for _, descendant in farmRoot:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			local plot = findPlotForPrompt(descendant, farmRoot)

			if plot then
				connectPrompt(descendant, plot)
			end
		end
	end

	initialized = true
end

return PlotInteractionService
