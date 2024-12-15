-- Kiểm tra xem LPH đã được định nghĩa chưa
if not LPH_OBFUSCATED then
    LPH_JIT_MAX = (function(...) return ... end)
    LPH_NO_VIRTUALIZE = (function(...) return ... end)
    LPH_NO_UPVALUES = (function(...) return ... end)
end

-- Thiết lập các biến
NoAttackAnimation = true
NeedAttacking = true
Fast_Attack = true
DamageAura = true
UsefastattackPlayers = true -- Đặt `true` nếu muốn tự động tấn công người chơi

-- Xác định CombatFramework
local CombatFramework
local success, result = pcall(function()
    return require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("CombatFramework"))
end)
if success then
    CombatFramework = result
else
    warn("[Error]: CombatFramework không tồn tại trong PlayerScripts.")
    return
end

-- Xác định CombatFrameworkR
local CombatFrameworkR = getupvalues(CombatFramework)[2]
if not CombatFrameworkR then
    warn("[Error]: Không lấy được giá trị CombatFrameworkR.")
    return
end

-- Xác định các dịch vụ
local DmgAttack = game:GetService("ReplicatedStorage").Assets.GUI:WaitForChild("DamageCounter")
local PC = require(game.Players.LocalPlayer.PlayerScripts.CombatFramework.Particle)
local RL = require(game:GetService("ReplicatedStorage").CombatFramework.RigLib)
local RigEven = game:GetService("ReplicatedStorage").RigControllerEvent
local AttackAnim = Instance.new("Animation")

-- Ghi đè wrapAttackAnimationAsync
local oldRL = RL.wrapAttackAnimationAsync
RL.wrapAttackAnimationAsync = function(a, b, c, d, func)
    if not NoAttackAnimation then
        return oldRL(a, b, c, 60, func)
    end

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

-- Các hàm khác
getAllBladeHits = LPH_NO_VIRTUALIZE(function(Sizes)
    local Hits = {}
    local Client = game.Players.LocalPlayer
    local Enemies = game:GetService("Workspace").Enemies:GetChildren()
    for i, v in pairs(Enemies) do
        local Human = v:FindFirstChildOfClass("Humanoid")
        if Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < Sizes + 5 then
            table.insert(Hits, Human.RootPart)
        end
    end
    return Hits
end)

getAllBladeHitsPlayers = LPH_NO_VIRTUALIZE(function(Sizes)
    local Hits = {}
    local Client = game.Players.LocalPlayer
    local Characters = game:GetService("Workspace").Characters:GetChildren()
    for i, v in pairs(Characters) do
        local Human = v:FindFirstChildOfClass("Humanoid")
        if v.Name ~= Client.Name and Human and Human.RootPart and Human.Health > 0 and Client:DistanceFromCharacter(Human.RootPart.Position) < Sizes + 5 then
            table.insert(Hits, Human.RootPart)
        end
    end
    return Hits
end)

-- Tấn công
AttackFunction = LPH_JIT_MAX(function(typef)
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
                RigEven.FireServer(RigEven, "hit", bladehit, 3, "")
            end)
        end
    end
end)

-- Hàm kiểm tra trạng thái bị choáng
function CheckStun()
    local stun = game.Players.LocalPlayer.Character:FindFirstChild("Stun")
    if stun then
        return stun.Value ~= 0
    end
    return false
end

-- Vòng lặp tự động tấn công
spawn(function()
    while true do
        local ac = CombatFrameworkR.activeController
        if ac and ac.equipped and not CheckStun() then
            pcall(function()
                AttackFunction(1) -- Tấn công tự động kẻ thù trong phạm vi
            end)
        end
        wait(0.01) -- Khoảng thời gian giữa mỗi đòn đánh
    end
end)