-- Kiểm tra và lấy CombatFramework
local CombatFramework = nil
pcall(function()
    CombatFramework = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("CombatFramework"))
end)

if not CombatFramework then
    warn("[Error]: CombatFramework không tìm thấy. Vui lòng kiểm tra tên hoặc vị trí module.")
    return
end

local CombatFrameworkR = nil
pcall(function()
    CombatFrameworkR = getupvalues(CombatFramework)[2]
end)

if not CombatFrameworkR then
    warn("[Error]: Không lấy được giá trị CombatFrameworkR.")
    return
end

-- Ghi đè hàm wrapAttackAnimationAsync
local RL = require(game:GetService("ReplicatedStorage").CombatFramework.RigLib)
local oldRL = RL.wrapAttackAnimationAsync

RL.wrapAttackAnimationAsync = function(a, b, c, d, func)
    local Hits = {}
    local Client = game.Players.LocalPlayer
    local Characters = game:GetService("Workspace").Characters:GetChildren()
    for i, v in pairs(Characters) do
        local Human = v:FindFirstChildOfClass("Humanoid")
        if v.Name ~= Client.Name and Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < 65 then
            table.insert(Hits, Human.RootPart)
        end
    end
    local Enemies = game:GetService("Workspace").Enemies:GetChildren()
    for i, v in pairs(Enemies) do
        local Human = v:FindFirstChildOfClass("Humanoid")
        if Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < 65 then
            table.insert(Hits, Human.RootPart)
        end
    end
    a:Play(0.01, 0.01, 0.01)
    pcall(func, Hits)
end

-- Hàm tấn công
function AttackFunction(typef)
    local ac = CombatFrameworkR.activeController
    if ac and ac.equipped then
        local bladehit = {}
        if typef == 1 then
            bladehit = getAllBladeHits(60)
        elseif typef == 2 then
            bladehit = getAllBladeHitsPlayers(65)
        else
            for _, v in pairs(getAllBladeHits(55)) do
                table.insert(bladehit, v)
            end
            for _, v in pairs(getAllBladeHitsPlayers(55)) do
                table.insert(bladehit, v)
            end
        end
        if #bladehit > 0 then
            pcall(function()
                ac.attack()
                game:GetService("ReplicatedStorage").RigControllerEvent:FireServer("hit", bladehit, 3, "")
            end)
        end
    end
end

-- Kiểm tra trạng thái bị choáng
function CheckStun()
    local stun = game.Players.LocalPlayer.Character:FindFirstChild("Stun")
    if stun then
        return stun.Value ~= 0
    end
    return false
end

-- Vòng lặp tấn công
spawn(function()
    while true do
        local ac = CombatFrameworkR.activeController
        if ac and ac.equipped and not CheckStun() then
            pcall(function()
                AttackFunction(1) -- Tấn công tự động kẻ thù trong phạm vi
            end)
        end
        wait(0.01) -- Điều chỉnh thời gian giữa các lần tấn công
    end
end)