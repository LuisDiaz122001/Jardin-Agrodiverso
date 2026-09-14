--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JardinHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(260, 130)
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 20)
panel.BackgroundColor3 = Color3.fromRGB(35, 45, 35)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = panel

local function createLabel(name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel

	return label
end

local coinsLabel = createLabel("CoinsLabel")
local levelLabel = createLabel("LevelLabel")
local xpLabel = createLabel("XPLabel")
local seedsLabel = createLabel("SeedsLabel")
local tomatoSeedsLabel = createLabel("TomatoSeedsLabel")

local function getNumberAttribute(name: string): number
	local value = player:GetAttribute(name)

	if type(value) ~= "number" then
		return 0
	end

	return value
end

local function updateLabels()
	coinsLabel.Text = string.format("Coins: %d", getNumberAttribute("Coins"))
	levelLabel.Text = string.format("Nivel: %d", getNumberAttribute("Level"))
	xpLabel.Text = string.format("XP: %d", getNumberAttribute("XP"))
	seedsLabel.Text = string.format("Maíz: %d", getNumberAttribute("Seeds"))
	tomatoSeedsLabel.Text = string.format("Tomate: %d", getNumberAttribute("TomatoSeeds"))
end

for _, attributeName in { "Coins", "Level", "XP", "Seeds", "TomatoSeeds" } do
	player:GetAttributeChangedSignal(attributeName):Connect(updateLabels)
end

updateLabels()
