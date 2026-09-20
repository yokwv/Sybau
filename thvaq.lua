<html><head><meta name="color-scheme" content="light dark"></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">local NeverLose = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/NeverLose/refs/heads/main/source.luau"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local function getRoot()
    local Character = Player.Character
    if not Character then return nil end

    return Character:FindFirstChild("HumanoidRootPart")
        or Character:FindFirstChild("UpperTorso")
        or Character:FindFirstChild("Torso")
end

local Window = NeverLose:CreateWindow({
    Logo = "rbxassetid://79039548677185",
    Name = "thvaq.win",
    Content = "thvaq.win",
    Size = NeverLose.Scales.Small,
    ConfigFolder = "thvaq.win",
    Enable3DRenderer = false,
    Keybind = "Insert"
})

local Watermark = Window:Watermark()
local UIToggle = Watermark:AddBlock("cube-vertexes", "thvaq.win")

UIToggle:Input(function()
    Window:ToggleInterface()
end)

Window:AddTabLabel("MAIN")

local AutoFarm = Window:AddTab({
    Icon = "pickaxe",
    Name = "Auto Farm"
})

local Teleports = Window:AddTab({
    Icon = "location-arrow",
    Name = "Teleports"
})

local Farming = AutoFarm:AddSection({
    Name = "MAIN"
})

local TeleportSection = Teleports:AddSection({
    Name = "TELEPORTS"
})

local WoodPositions = {}
local OrePositions = {}

local function moveParts(PartName, Storage)
    local Root = getRoot()
    if not Root then return end

    local TargetCFrame = Root.CFrame * CFrame.new(0, 0, -20)

    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object:IsA("BasePart") and Object.Name == PartName then
            if not Storage[Object] then
                Storage[Object] = Object.CFrame
            end

            Object.CFrame = TargetCFrame
        end
    end
end

local function restoreParts(Storage)
    for Object, OriginalCFrame in pairs(Storage) do
        if Object and Object.Parent then
            Object.CFrame = OriginalCFrame
        end
    end

    table.clear(Storage)
end

Farming:AddLabel("Nigga Wood"):AddToggle({
    Default = false,
    Flag = "NiggaWood",
    Callback = function(Value)
        if Value then
            moveParts("WoodHitPart", WoodPositions)
        else
            restoreParts(WoodPositions)
        end
    end
})

Farming:AddLabel("Nigga Ore"):AddToggle({
    Default = false,
    Flag = "NiggaOre",
    Callback = function(Value)
        if Value then
            moveParts("RockHitPart", OrePositions)
        else
            restoreParts(OrePositions)
        end
    end
})

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

local function checkNPCs()
    local PlayerRoot = getRoot()
    if not PlayerRoot then return end

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
                        local Distance = (PlayerRoot.Position - Position).Magnitude

                        if Distance &lt;= 20 then
                            Head:Destroy()
                        end
                    end
                end
            end
        end
    end
end

Farming:AddLabel("Kill NPC (20 studs)"):AddToggle({
    Default = false,
    Flag = "KillNPC",
    Callback = function(Value)
        if KillNPCConnection then
            KillNPCConnection:Disconnect()
            KillNPCConnection = nil
        end

        if not Value then
            return
        end

        KillNPCConnection = RunService.Heartbeat:Connect(function()
            checkNPCs()
        end)
    end
})

local ProximityData = {}
local ProximityConnection

local function disableProximity()
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

local function enableProximity()
    disableProximity()

    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object:IsA("ProximityPrompt") then
            ProximityData[Object] = {
                HoldDuration = Object.HoldDuration,
                RequiresLineOfSight = Object.RequiresLineOfSight
            }

            Object.HoldDuration = 0
            Object.RequiresLineOfSight = false
        end
    end

    ProximityConnection = Workspace.DescendantAdded:Connect(function(Object)
        if Object:IsA("ProximityPrompt") then
            ProximityData[Object] = {
                HoldDuration = Object.HoldDuration,
                RequiresLineOfSight = Object.RequiresLineOfSight
            }

            Object.HoldDuration = 0
            Object.RequiresLineOfSight = false
        end
    end)
end

Farming:AddLabel("No Proximity"):AddToggle({
    Default = false,
    Flag = "NoProximity",
    Callback = function(Value)
        if Value then
            enableProximity()
        else
            disableProximity()
        end
    end
})

Farming:AddButton({
    Icon = "location-arrow",
    Name = "Tp Boss",
    Callback = function()
        local Root = getRoot()
        if not Root then return end

        local BossHolder = Workspace:FindFirstChild("BossHolder")
        if not BossHolder then return end

        for _, Boss in ipairs(BossHolder:GetChildren()) do
            if Boss:IsA("Model") then
                local BossRoot =
                    Boss:FindFirstChild("HumanoidRootPart")
                    or Boss.PrimaryPart
                    or Boss:FindFirstChild("UpperTorso")
                    or Boss:FindFirstChild("Torso")
                    or Boss:FindFirstChildWhichIsA("BasePart")

                if BossRoot then
                    Root.CFrame = BossRoot.CFrame + Vector3.new(0, 3, 0)
                    break
                end
            end
        end
    end
})

local SpectateConnection
local SpectatingBoss = false

local function getBoss()
    local BossHolder = Workspace:FindFirstChild("BossHolder")
    if not BossHolder then return nil end

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

local function stopSpectate()
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

Farming:AddLabel("Spectate Boss"):AddToggle({
    Default = false,
    Flag = "SpectateBoss",
    Callback = function(Value)
        stopSpectate()

        if not Value then
            return
        end

        local Camera = Workspace.CurrentCamera
        local BossRoot = getBoss()

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

            local CurrentBoss = getBoss()

            if CurrentBoss and CurrentBoss.Parent then
                Camera.CameraSubject = CurrentBoss
            else
                stopSpectate()
            end
        end)
    end
})

TeleportSection:AddButton({
    Icon = "axe",
    Name = "Hoe Wood Woman",
    Callback = function()
        local Root = getRoot()
        if not Root then return end

        local Lumberjack = Workspace:FindFirstChild("Lumberjack", true)
        if not Lumberjack then return end

        local Target =
            Lumberjack:IsA("BasePart") and Lumberjack
            or Lumberjack:FindFirstChild("HumanoidRootPart", true)
            or Lumberjack:FindFirstChildWhichIsA("BasePart", true)

        if Target then
            Root.CFrame = Target.CFrame + Vector3.new(0, 3, 0)
        end
    end
})

TeleportSection:AddButton({
    Icon = "pickaxe",
    Name = "Hoe Ore Woman",
    Callback = function()
        local Root = getRoot()
        if not Root then return end

        local Miner = Workspace:FindFirstChild("Miner", true)
        if not Miner then return end

        local Target =
            Miner:IsA("BasePart") and Miner
            or Miner:FindFirstChild("HumanoidRootPart", true)
            or Miner:FindFirstChildWhichIsA("BasePart", true)

        if Target then
            Root.CFrame = Target.CFrame + Vector3.new(0, 3, 0)
        end
    end
})

local Destroyed = false

local function DestroyUI()
    if Destroyed then return end
    Destroyed = true

    if KillNPCConnection then
        KillNPCConnection:Disconnect()
        KillNPCConnection = nil
    end

    stopSpectate()
    disableProximity()

    pcall(function()
        Window:Destroy()
    end)

    pcall(function()
        Window:Remove()
    end)

    pcall(function()
        Window:Unload()
    end)
end

UserInputService.InputBegan:Connect(function(Input, Processed)
    if Processed then return end

    if Input.KeyCode == Enum.KeyCode.M then
        DestroyUI()
    end
end)
</pre></body></html>
