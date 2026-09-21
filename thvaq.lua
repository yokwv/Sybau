local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "thvaq.win",
    SubTitle = "fuckest library ever",
    TabWidth = 100,
    Size = UDim2.fromOffset(460, 360),
    Acrylic = true,
    Theme = "Light",
    MinimizeKey = Enum.KeyCode.M
})

local Tabs = {
    AutoFarm = Window:AddTab({
        Title = "Auto Farm",
        Icon = "pickaxe"
    }),

    Teleports = Window:AddTab({
        Title = "Teleports",
        Icon = "map-pin"
    }),

    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}

local Options = Fluent.Options

local function getPlayerRoot()
    local Character = Player.Character
    if not Character then
        return nil
    end

    return Character:FindFirstChild("HumanoidRootPart")
        or Character:FindFirstChild("UpperTorso")
        or Character:FindFirstChild("Torso")
end

local WoodPositions = {}
local OrePositions = {}

local function moveResourceParts(PartName, Storage)
    local PlayerRoot = getPlayerRoot()
    if not PlayerRoot then
        return
    end

    local TargetCFrame = PlayerRoot.CFrame * CFrame.new(0, 0, -20)

    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object:IsA("BasePart") and Object.Name == PartName then
            if not Storage[Object] then
                Storage[Object] = Object.CFrame
            end

            Object.CFrame = TargetCFrame
        end
    end
end

local function restoreResourceParts(Storage)
    for Object, OriginalCFrame in pairs(Storage) do
        if Object and Object.Parent then
            Object.CFrame = OriginalCFrame
        end
    end

    table.clear(Storage)
end

local KillNPCConnection

local function getNPCPosition(NPC)
    local Root =
        NPC:FindFirstChild("HumanoidRootPart")
        or NPC:FindFirstChild("UpperTorso")
        or NPC:FindFirstChild("Torso")
        or NPC:FindFirstChild("Head")

    if Root and Root:IsA("BasePart") then
        return Root.Position
    end

    return nil
end

local function checkNearbyNPCs()
    local PlayerRoot = getPlayerRoot()
    if not PlayerRoot then
        return
    end

    local Holders = {
        Workspace:FindFirstChild("MobsHolder"),
        Workspace:FindFirstChild("BossHolder")
    }

    for _, Holder in ipairs(Holders) do
        if Holder then
            for _, NPC in ipairs(Holder:GetChildren()) do
                if NPC:IsA("Model") then
                    local Head = NPC:FindFirstChild("Head")
                    local Position = getNPCPosition(NPC)

                    if Head and Position then
                        if (PlayerRoot.Position - Position).Magnitude <= 20 then
                            Head:Destroy()
                        end
                    end
                end
            end
        end
    end
end

local ProximityData = {}
local ProximityConnection

local function disableNoProximity()
    for Prompt, Data in pairs(ProximityData) do
        if Prompt and Prompt.Parent then
            Prompt.HoldDuration = Data.HoldDuration
            Prompt.RequiresLineOfSight = Data.RequiresLineOfSight
        end
    end

    table.clear(ProximityData)

    if ProximityConnection then
        ProximityConnection:Disconnect()
        ProximityConnection = nil
    end
end

local function applyPrompt(Object)
    if not Object:IsA("ProximityPrompt") then
        return
    end

    if not ProximityData[Object] then
        ProximityData[Object] = {
            HoldDuration = Object.HoldDuration,
            RequiresLineOfSight = Object.RequiresLineOfSight
        }
    end

    Object.HoldDuration = 0
    Object.RequiresLineOfSight = false
end

local function enableNoProximity()
    disableNoProximity()

    for _, Object in ipairs(Workspace:GetDescendants()) do
        applyPrompt(Object)
    end

    ProximityConnection = Workspace.DescendantAdded:Connect(applyPrompt)
end

local function teleportToBoss()
    local PlayerRoot = getPlayerRoot()
    if not PlayerRoot then
        return
    end

    local BossHolder = Workspace:FindFirstChild("BossHolder")
    if not BossHolder then
        return
    end

    for _, Boss in ipairs(BossHolder:GetChildren()) do
        if Boss:IsA("Model") then
            local BossRoot =
                Boss:FindFirstChild("HumanoidRootPart")
                or Boss.PrimaryPart
                or Boss:FindFirstChild("UpperTorso")
                or Boss:FindFirstChild("Torso")
                or Boss:FindFirstChildWhichIsA("BasePart")

            if BossRoot then
                PlayerRoot.CFrame = BossRoot.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end
end

local SpectateConnection
local SpectatingBoss = false

local function getBossRoot()
    local BossHolder = Workspace:FindFirstChild("BossHolder")
    if not BossHolder then
        return nil
    end

    for _, Boss in ipairs(BossHolder:GetChildren()) do
        if Boss:IsA("Model") then
            local BossRoot =
                Boss:FindFirstChild("HumanoidRootPart")
                or Boss.PrimaryPart
                or Boss:FindFirstChild("Head")
                or Boss:FindFirstChildWhichIsA("BasePart")

            if BossRoot then
                return BossRoot
            end
        end
    end

    return nil
end

local function stopBossSpectate()
    SpectatingBoss = false

    if SpectateConnection then
        SpectateConnection:Disconnect()
        SpectateConnection = nil
    end

    local Camera = Workspace.CurrentCamera
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

    if Camera and Humanoid then
        Camera.CameraSubject = Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function teleportToNPC(Name)
    local PlayerRoot = getPlayerRoot()
    if not PlayerRoot then
        return
    end

    local NPC = Workspace:FindFirstChild(Name, true)
    if not NPC then
        return
    end

    local Target =
        NPC:IsA("BasePart") and NPC
        or NPC:FindFirstChild("HumanoidRootPart", true)
        or NPC:FindFirstChildWhichIsA("BasePart", true)

    if Target then
        PlayerRoot.CFrame = Target.CFrame + Vector3.new(0, 3, 0)
    end
end

local AutoFarmGroup = Tabs.AutoFarm:AddSection("MAIN")

AutoFarmGroup:AddToggle("niggawood", {
    Title = "nigga wood",
    Default = false
}):OnChanged(function(Value)
    if Value then
        moveResourceParts("WoodHitPart", WoodPositions)
    else
        restoreResourceParts(WoodPositions)
    end
end)

AutoFarmGroup:AddToggle("niggaore", {
    Title = "nigga ore",
    Default = false
}):OnChanged(function(Value)
    if Value then
        moveResourceParts("RockHitPart", OrePositions)
    else
        restoreResourceParts(OrePositions)
    end
end)

AutoFarmGroup:AddToggle("killbanana", {
    Title = "kill banana (20 studs)",
    Default = false
}):OnChanged(function(Value)
    if KillNPCConnection then
        KillNPCConnection:Disconnect()
        KillNPCConnection = nil
    end

    if Value then
        KillNPCConnection = RunService.Heartbeat:Connect(checkNearbyNPCs)
    end
end)

AutoFarmGroup:AddToggle("noproximity", {
    Title = "no proximity",
    Default = false
}):OnChanged(function(Value)
    if Value then
        enableNoProximity()
    else
        disableNoProximity()
    end
end)

AutoFarmGroup:AddButton({
    Title = "tp boss",
    Description = "tp to the current boss",
    Callback = function()
        teleportToBoss()
    end
})

AutoFarmGroup:AddToggle("viewboss", {
    Title = "view view",
    Default = false
}):OnChanged(function(Value)
    stopBossSpectate()

    if not Value then
        return
    end

    local Camera = Workspace.CurrentCamera
    local BossRoot = getBossRoot()

    if not Camera or not BossRoot then
        return
    end

    SpectatingBoss = true
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = BossRoot

    SpectateConnection = RunService.Heartbeat:Connect(function()
        if not SpectatingBoss then
            return
        end

        local CurrentBoss = getBossRoot()

        if CurrentBoss and CurrentBoss.Parent then
            Camera.CameraSubject = CurrentBoss
        else
            stopBossSpectate()
        end
    end)
end)

local BossStatusParagraph = AutoFarmGroup:AddParagraph({
    Title = "boss status",
    Content = "chk..."
})

local function updateBossStatus()
    local BossHolder = Workspace:FindFirstChild("BossHolder")
    local Alive = false

    if BossHolder then
        for _, Object in ipairs(BossHolder:GetChildren()) do
            if Object:IsA("Model") then
                Alive = true
                break
            end
        end
    end

    if Alive then
        BossStatusParagraph:SetDesc("Alive")
    else
        BossStatusParagraph:SetDesc("Dead")
    end
end

local BossStatusConnection

local function setupBossStatus()
    if BossStatusConnection then
        BossStatusConnection:Disconnect()
    end

    local BossHolder = Workspace:FindFirstChild("BossHolder")

    if BossHolder then
        local function update()
            task.defer(updateBossStatus)
        end

        BossHolder.ChildAdded:Connect(update)
        BossHolder.ChildRemoved:Connect(update)
    end

    BossStatusConnection = RunService.Heartbeat:Connect(updateBossStatus)
end

setupBossStatus()

local TeleportGroup = Tabs.Teleports:AddSection("TELEPORTS")

TeleportGroup:AddButton({
    Title = "Hoe Wood Woman",
    Description = "tp to lumberjack",
    Callback = function()
        teleportToNPC("Lumberjack")
    end
})

TeleportGroup:AddButton({
    Title = "Hoe Ore Woman",
    Description = "tp to miner",
    Callback = function()
        teleportToNPC("Miner")
    end
})

local UtilityGroup = Tabs.Settings:AddSection("UTILITY")

UtilityGroup:AddButton({
    Title = "Destroy UI",
    Description = "Close thvaq.win",
    Callback = function()
        if KillNPCConnection then
            KillNPCConnection:Disconnect()
            KillNPCConnection = nil
        end

        if BossStatusConnection then
            BossStatusConnection:Disconnect()
            BossStatusConnection = nil
        end

        stopBossSpectate()
        disableNoProximity()

        Fluent:Destroy()
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("thvaq.win")
SaveManager:SetFolder("thvaq.win")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "thvaq.win",
    Content = "carregado :3.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()

task.defer(function()
    task.wait(1)

    local PlayerGui = Player:WaitForChild("PlayerGui")
    local ScreenGui

    for _, Gui in ipairs(PlayerGui:GetChildren()) do
        if Gui:IsA("ScreenGui") then
            local Found = Gui:FindFirstChild("Window", true)
                or Gui:FindFirstChild("Main", true)
                or Gui:FindFirstChild("Container", true)

            if Found then
                ScreenGui = Gui
                break
            end
        end
    end

    if not ScreenGui then
        for _, Gui in ipairs(PlayerGui:GetChildren()) do
            if Gui:IsA("ScreenGui") then
                if Gui:FindFirstChildWhichIsA("Frame", true) then
                    ScreenGui = Gui
                    break
                end
            end
        end
    end

    if not ScreenGui then
        return
    end

    local RootFrame

    for _, Object in ipairs(ScreenGui:GetDescendants()) do
        if Object:IsA("Frame") then
            local Size = Object.AbsoluteSize

            if Size.X >= 350 and Size.X <= 700 and Size.Y >= 250 and Size.Y <= 500 then
                RootFrame = Object
                break
            end
        end
    end

    if not RootFrame then
        return
    end

    local Background = Instance.new("ImageLabel")
    Background.Name = "thvaqBackground"
    Background.Parent = RootFrame
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.Image = "rbxassetid://79039548677185"
    Background.ImageTransparency = 0.82
    Background.ScaleType = Enum.ScaleType.Fit
    Background.Size = UDim2.fromScale(1, 1)
    Background.Position = UDim2.fromScale(0, 0)
    Background.AnchorPoint = Vector2.new(0, 0)
    Background.ZIndex = 0
    Background.Active = false
    Background.Selectable = false

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Background

    for _, Object in ipairs(RootFrame:GetDescendants()) do
        if Object:IsA("GuiObject") and Object ~= Background then
            if Object.ZIndex <= 0 then
                Object.ZIndex = 1
            end
        end
    end
end)
