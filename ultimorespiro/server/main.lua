local QBCore = exports['qb-core']:GetCoreObject()
local Active = {}

local function dbg(...)
    if Config.Debug then
        print('[mementomori]', ...)
    end
end

local function notify(src, msg, typ)
    TriggerClientEvent('QBCore:Notify', src, msg, typ or 'primary')
end

local function clearState(src)
    Active[src] = nil
    local player = Player(src)
    if player and player.state then
        player.state:set('mementoActive', false, true)
        player.state:set('mementoEndsAt', 0, true)
    end
end

local function canUse(Player, source)
    if not Player then return false, 'player missing' end
    if Active[source] then
        return false, 'already active'
    end

    local ped = GetPlayerPed(source)
    if ped == 0 then
        return false, 'ped missing'
    end

    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return false, 'in vehicle'
    end

    local metadata = Player.PlayerData.metadata or {}
    if metadata['isdead'] or metadata['inlaststand'] then
        return false, 'dead/laststand'
    end

    return true
end

local function startEffect(source)
    local endsAt = os.time() + Config.Duration
    Active[source] = { endsAt = endsAt }

    local player = Player(source)
    if player and player.state then
        player.state:set('mementoActive', true, true)
        player.state:set('mementoEndsAt', endsAt, true)
    end

    TriggerClientEvent('mementomori:client:start', source, {
        duration = Config.Duration
    })
end

local function consumeItem(Player, source, item)
    -- Compatibility note:
    -- Some QBCore builds return true/false from RemoveItem.
    -- Some return nil even when the removal succeeded.
    -- So only explicit false is treated as failure.
    local ok = Player.Functions.RemoveItem(Config.ItemName, 1, item and item.slot or nil)
    if ok == false then
        dbg('RemoveItem explicit false for', source)
        return false
    end

    local sharedItem = QBCore.Shared.Items and QBCore.Shared.Items[Config.ItemName]
    if sharedItem then
        TriggerClientEvent('inventory:client:ItemBox', source, sharedItem, 'remove', 1)
    end
    return true
end


RegisterNetEvent('mementomori:server:useOxItem', function(slot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ok, reason = canUse(Player, src)
    if not ok then
        dbg('ox use blocked', src, reason)
        if reason == 'already active' then
            notify(src, '今は使えない。', 'error')
        elseif reason == 'dead/laststand' then
            notify(src, 'この状態では使えない。', 'error')
        elseif reason == 'in vehicle' then
            notify(src, '車両内では使えない。', 'error')
        else
            notify(src, '使用条件を満たしていない。', 'error')
        end
        return
    end

    local removed = Player.Functions.RemoveItem(Config.ItemName, 1, slot)
    if removed == false then
        notify(src, 'アイテム消費に失敗した。slot連携を確認して。', 'error')
        return
    end

    local sharedItem = QBCore.Shared.Items and QBCore.Shared.Items[Config.ItemName]
    if sharedItem then
        TriggerClientEvent('inventory:client:ItemBox', src, sharedItem, 'remove', 1)
    end

    dbg('starting effect from ox export for', src, 'slot', tostring(slot))
    startEffect(src)
end)

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    local ok, reason = canUse(Player, source)
    if not ok then
        dbg('use blocked', source, reason)
        if reason == 'already active' then
            notify(source, '今は使えない。', 'error')
        elseif reason == 'dead/laststand' then
            notify(source, 'この状態では使えない。', 'error')
        elseif reason == 'in vehicle' then
            notify(source, '車両内では使えない。', 'error')
        else
            notify(source, '使用条件を満たしていない。', 'error')
        end
        return
    end

    if not consumeItem(Player, source, item) then
        notify(source, 'アイテム消費に失敗した。inventory連携を確認して。', 'error')
        return
    end

    dbg('starting effect from usable item for', source)
    startEffect(source)
end)


RegisterNetEvent('mementomori:server:finish', function()
    clearState(source)
end)

AddEventHandler('playerDropped', function()
    clearState(source)
end)

RegisterNetEvent('mementomori:server:forceClear', function()
    clearState(source)
end)

local function isMementoActive(source)
    local player = Player(source)
    return player and player.state and player.state.mementoActive == true
end

exports('CanUseItems', function(source)
    return not isMementoActive(source)
end)

RegisterNetEvent('mementomori:server:canUseItems', function(cbEventName)
    local src = source
    local allowed = not isMementoActive(src)
    if cbEventName and cbEventName ~= '' then
        TriggerClientEvent(cbEventName, src, allowed)
    end
end)
