-- ESP Module
local ESP = {}
ESP.__index = ESP

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
ESP.Settings = {
    Enabled = true,
    BoxESP = true,
    NameESP = true,
    DistanceESP = true,
    TeamCheck = false, -- Set true to skip teammates
    BoxColor = Color3.fromRGB(255, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(255, 255, 0),
    TextSize = 13,
    BoxThickness = 1.5,
}

-- Storage for drawings per player
local ESPObjects = {}

-- Create drawing objects for a player
local function CreateESP(player)
    ESPObjects[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
    }

    local obj = ESPObjects[player]

    obj.Box.Visible = false
    obj.Box.Color = ESP.Settings.BoxColor
    obj.Box.Thickness = ESP.Settings.BoxThickness
    obj.Box.Filled = false

    obj.Name.Visible = false
    obj.Name.Color = ESP.Settings.NameColor
    obj.Name.Size = ESP.Settings.TextSize
    obj.Name.Center = true
    obj.Name.Outline = true
    obj.Name.Font = Drawing.Fonts.UI

    obj.Distance.Visible = false
    obj.Distance.Color = ESP.Settings.DistanceColor
    obj.Distance.Size = ESP.Settings.TextSize
    obj.Distance.Center = true
    obj.Distance.Outline = true
    obj.Distance.Font = Drawing.Fonts.UI
end

-- Remove drawings for a player
local function RemoveESP(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
end

-- Get bounding box of a character in screen space
local function GetBoundingBox(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return nil
    end

    local rootPos = rootPart.Position
    local height = 5.5 -- Approximate character height in studs

    local topPoint, topVisible = Camera:WorldToViewportPoint(rootPos + Vector3.new(0, height / 2, 0))
    local bottomPoint, bottomVisible = Camera:WorldToViewportPoint(rootPos - Vector3.new(0, height / 2, 0))

    if not topVisible and not bottomVisible then
        return nil
    end

    local boxHeight = math.abs(topPoint.Y - bottomPoint.Y)
    local boxWidth = boxHeight * 0.5

    return {
        X = topPoint.X - boxWidth / 2,
        Y = topPoint.Y,
        Width = boxWidth,
        Height = boxHeight,
        Center = Vector2.new(topPoint.X, topPoint.Y - boxHeight / 2),
    }
end

-- Update ESP each frame
local function UpdateESP()
    if not ESP.Settings.Enabled then
        for _, obj in pairs(ESPObjects) do
            for _, drawing in pairs(obj) do
                drawing.Visible = false
            end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- Team check
        if ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team then
            if ESPObjects[player] then
                for _, drawing in pairs(ESPObjects[player]) do
                    drawing.Visible = false
                end
            end
            continue
        end

        if not ESPObjects[player] then continue end

        local character = player.Character
        local obj = ESPObjects[player]

        if not character then
            for _, drawing in pairs(obj) do
                drawing.Visible = false
            end
            continue
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            for _, drawing in pairs(obj) do
                drawing.Visible = false
            end
            continue
        end

        local bbox = GetBoundingBox(character)
        if not bbox then
            for _, drawing in pairs(obj) do
                drawing.Visible = false
            end
            continue
        end

        local distance = math.floor((LocalPlayer.Character and
            LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
            (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) or 0)

        -- Box ESP
        if ESP.Settings.BoxESP then
            obj.Box.Visible = true
            obj.Box.Position = Vector2.new(bbox.X, bbox.Y)
            obj.Box.Size = Vector2.new(bbox.Width, bbox.Height)
        else
            obj.Box.Visible = false
        end

        -- Name ESP
        if ESP.Settings.NameESP then
            obj.Name.Visible = true
            obj.Name.Text = player.DisplayName
            obj.Name.Position = Vector2.new(bbox.Center.X, bbox.Y - 16)
        else
            obj.Name.Visible = false
        end

        -- Distance ESP
        if ESP.Settings.DistanceESP then
            obj.Distance.Visible = true
            obj.Distance.Text = distance .. " studs"
            obj.Distance.Position = Vector2.new(bbox.Center.X, bbox.Y + bbox.Height + 2)
        else
            obj.Distance.Visible = false
        end
    end
end

-- Initialize ESP for all current and future players
function ESP:Init()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)

    RunService.RenderStepped:Connect(UpdateESP)
end

-- Toggle ESP on/off
function ESP:Toggle(state)
    ESP.Settings.Enabled = state
end

ESP:Init()
return ESP
