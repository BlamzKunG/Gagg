getgenv().FullAutoFarm = true

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer

local collectDelay      = 0.002
local sellPos           = Vector3.new(61, 2, 0)
local isSelling         = false

-- ตรวจว่าเป็นฟาร์มของเรา
local function isOwnedByPlayer(farm)
    local data = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data")
    return data and data:FindFirstChild("Owner") and data.Owner.Value == LocalPlayer.Name
end

-- ล็อกกล้องไปที่ Owner_Tag
local function lockCameraToFarm()
    for _, farm in ipairs(workspace:WaitForChild("Farm"):GetChildren()) do
        if isOwnedByPlayer(farm) then
            local tag = farm:FindFirstChild("Owner_Tag")
            if tag then
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.new(tag.Position + Vector3.new(0,10,0), tag.Position)
                return
            end
        end
    end
end

-- เก็บของอัตโนมัติ (วาร์ปไปยิง prompt)
local function collectAvailablePlants()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    for _, farm in ipairs(workspace.Farm:GetChildren()) do
        if isOwnedByPlayer(farm) then
            local phys = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
            if phys then
                for _, prompt in ipairs(phys:GetDescendants()) do
                    if isSelling or not getgenv().FullAutoFarm then return end
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        local orig = root.Position
                        root.CFrame = prompt.Parent.CFrame
                        task.wait(0.05)
                        fireproximityprompt(prompt)
                        task.wait(collectDelay)
                        root.CFrame = CFrame.new(orig)
                    end
                end
            end
        end
    end
end

-- ขายของ
local function sellAll()
    isSelling = true
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    local originalPos = root.Position

    root.CFrame = CFrame.new(sellPos + Vector3.new(0, 3, 0))
    task.wait(0.5)

    ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()

    task.wait(2)
    root.CFrame = CFrame.new(originalPos)

    isSelling = false
end

-- เริ่มล็อกกล้อง
lockCameraToFarm()

-- ลูปหลัก: ทำงาน 30 วินาที -> ขาย -> วนใหม่
task.spawn(function()
    while true do
        if not getgenv().FullAutoFarm then
            Camera.CameraType = Enum.CameraType.Custom
            break
        end

        -- เก็บต่อเนื่อง 30 วินาที
        local start = tick()
        while tick() - start < 8 do
            if not getgenv().FullAutoFarm then
                Camera.CameraType = Enum.CameraType.Custom
                return
            end
            pcall(collectAvailablePlants)
            task.wait(0.1)
        end

        -- ไปขาย
        if getgenv().FullAutoFarm then
            pcall(sellAll)
            lockCameraToFarm()
        end
    end
end)
