local QBCore = exports['qb-core']:GetCoreObject()

local Memento = {
    active = false,
    startedAt = 0,
    endsAt = 0,
    bodyPed = nil,
    bodyCoords = nil,
    bodyHeading = nil,
    soulGhostPed = nil,
    phoneOpenedAt = 0,
    phoneAnimPlaying = false,
    phoneWasOpen = false,
    phoneClosingUntil = 0,
    phoneCloseQueuedAt = 0,
    originalAlpha = 255
}

local function dbg(...)
    if Config.Debug then
        print('[mementomori]', ...)
    end
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            return nil
        end
    end
    return hash
end


local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        Wait(0)
        if GetGameTimer() > timeout then
            return false
        end
    end
    return true
end

local function drawTxt(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale or 0.4, scale or 0.4)
    SetTextColour(255, 255, 255, 220)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function getTimeLeft()
    local ms = math.max(Memento.endsAt - GetGameTimer(), 0)
    local sec = math.ceil(ms / 1000)
    return sec
end

local function copyBasicAppearance(fromPed, toPed)
    for i = 0, 11 do
        SetPedComponentVariation(
            toPed,
            i,
            GetPedDrawableVariation(fromPed, i),
            GetPedTextureVariation(fromPed, i),
            GetPedPaletteVariation(fromPed, i)
        )
    end

    for i = 0, 7 do
        local propIndex = GetPedPropIndex(fromPed, i)
        local propTexture = GetPedPropTextureIndex(fromPed, i)
        if propIndex ~= -1 then
            SetPedPropIndex(toPed, i, propIndex, propTexture, true)
        else
            ClearPedProp(toPed, i)
        end
    end

    SetPedHeadBlendData(toPed, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
end

local function setSoulVisual(ped, enabled)
    if enabled then
        Memento.originalAlpha = GetEntityAlpha(ped)

        if Config.SoulInvisible then
            SetEntityVisible(ped, false, false)
        else
            SetEntityVisible(ped, true, false)
        end

        SetEntityAlpha(ped, Config.SoulAlpha or 0, false)
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
    else
        ResetEntityAlpha(ped)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
    end
end


local function clearSoulGhost()
    if Memento.soulGhostPed and DoesEntityExist(Memento.soulGhostPed) then
        DeleteEntity(Memento.soulGhostPed)
    end
    Memento.soulGhostPed = nil
end

local function createSoulGhost()
    if not Config.ShowSoulToSelf then return end

    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local hash = loadModel(model)
    if not hash then
        return
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local ghost = CreatePed(4, hash, coords.x, coords.y, coords.z + (Config.SoulSelfOffsetZ or -1.0), heading, false, false)
    if ghost == 0 then
        return
    end

    copyBasicAppearance(ped, ghost)

    SetEntityAsMissionEntity(ghost, true, true)
    SetEntityInvincible(ghost, true)
    SetEntityCollision(ghost, false, false)
    SetEntityCompletelyDisableCollision(ghost, false, false)
    SetBlockingOfNonTemporaryEvents(ghost, true)
    FreezeEntityPosition(ghost, true)
    SetEntityAlpha(ghost, Config.SoulSelfAlpha or 110, false)
    SetEntityVisible(ghost, true, false)

    if Config.SoulSelfUseOutline then
        SetEntityDrawOutline(ghost, true)
    end

    Memento.soulGhostPed = ghost
    SetModelAsNoLongerNeeded(hash)
end

local function isPhoneOpen()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.phoneOpen == true
end

local function isRadioTalking()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioActive == true
end


local function playSoulPhoneOneShot(ghost, clip)
    local dict = Config.SoulPhoneAnimDict or 'cellphone@'
    if not loadAnimDict(dict) then return end

    TaskPlayAnim(
        ghost,
        dict,
        clip,
        Config.SoulPhoneAnimSpeed or 3.0,
        Config.SoulPhoneAnimSpeed or 3.0,
        -1,
        50,
        0.0,
        false, false, false
    )
end


local function playSoulPhoneClose(ghost)
    local dict = Config.SoulPhoneAnimDict or 'cellphone@'
    local clip = Config.SoulPhoneCloseClip or 'cellphone_text_out'
    if not loadAnimDict(dict) then return end

    ClearPedTasksImmediately(ghost)

    TaskPlayAnim(
        ghost,
        dict,
        clip,
        Config.SoulPhoneAnimSpeed or 3.0,
        Config.SoulPhoneAnimSpeed or 3.0,
        Config.SoulPhoneCloseAnimDuration or 400,
        50,
        0.0,
        false, false, false
    )

    Memento.phoneClosingUntil = GetGameTimer() + (Config.SoulPhoneCloseAnimDuration or 400)
end

local function updateSoulGhost()
    if not Config.ShowSoulToSelf then return end
    if not Memento.soulGhostPed or not DoesEntityExist(Memento.soulGhostPed) then return end

    local ped = PlayerPedId()
    local ghost = Memento.soulGhostPed
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    SetEntityCoordsNoOffset(
        ghost,
        coords.x,
        coords.y,
        coords.z + (Config.SoulSelfOffsetZ or 0.0),
        false,
        false,
        false
    )
    SetEntityHeading(ghost, heading)

    local phoneOpen = isPhoneOpen()


    -- qb-phone寄せ: 開く瞬間だけ one-shot、開いている間は継続モーションしない
    if phoneOpen and not Memento.phoneWasOpen then
        playSoulPhoneOneShot(ghost, Config.SoulPhoneOpenClip or 'cellphone_text_in')
        Memento.phoneAnimPlaying = true
        Memento.phoneWasOpen = true
        Memento.phoneCloseQueuedAt = 0
        return
    elseif (not phoneOpen) and Memento.phoneWasOpen then

        if Memento.phoneCloseQueuedAt == 0 then
            playSoulPhoneOneShot(ghost, Config.SoulPhoneOpenClip or 'cellphone_text_in')
            Memento.phoneCloseQueuedAt = GetGameTimer()
        end

        if GetGameTimer() - Memento.phoneCloseQueuedAt >= (400) then
            Memento.phoneAnimPlaying = false
            Memento.phoneWasOpen = false
            Memento.phoneCloseQueuedAt = 0
        end
        return
    end

    -- phoneが開いてる間は追加モーションなし
    if phoneOpen then
        return
    end


    if Memento.phoneClosingUntil and Memento.phoneClosingUntil > GetGameTimer() then
        return
    elseif Memento.phoneClosingUntil and Memento.phoneClosingUntil ~= 0 then
        ClearPedTasksImmediately(ghost)
        Memento.phoneClosingUntil = 0
    end

    if Config.UseSoulRadioAnim and isRadioTalking() then
        if loadAnimDict(Config.SoulRadioAnimDict or 'random@arrests') then
            if not IsEntityPlayingAnim(
                ghost,
                Config.SoulRadioAnimDict or 'random@arrests',
                Config.SoulRadioAnimClip or 'generic_radio_chatter',
                3
            ) then
                TaskPlayAnim(
                    ghost,
                    Config.SoulRadioAnimDict or 'random@arrests',
                    Config.SoulRadioAnimClip or 'generic_radio_chatter',
                    8.0,
                    -8.0,
                    -1,
                    49,
                    0.0,
                    false, false, false
                )
            end
        end
        return
    end

    if IsEntityPlayingAnim(
        ghost,
        Config.SoulRadioAnimDict or 'random@arrests',
        Config.SoulRadioAnimClip or 'generic_radio_chatter',
        3
    ) then
        ClearPedTasks(ghost)
        return
    end

    if IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped) then
        local speed = GetEntitySpeed(ped)
        local headingRad = math.rad(heading)
        local targetX = coords.x + math.sin(headingRad) * -0.08
        local targetY = coords.y - math.cos(headingRad) * -0.08

        TaskGoStraightToCoord(
            ghost,
            targetX,
            targetY,
            coords.z + (Config.SoulSelfOffsetZ or 0.0),
            1.0,
            100,
            heading,
            0.0
        )
    else
        ClearPedTasks(ghost)
    end
end

local function clearBodyClone()
    if Memento.bodyPed and DoesEntityExist(Memento.bodyPed) then
        FreezeEntityPosition(Memento.bodyPed, false)
        DeleteEntity(Memento.bodyPed)
    end
    Memento.bodyPed = nil
end

-- This intentionally leaves the real player ped as the moving soul.
-- In practice, that is the closest way to get the "moving strange heat source" feeling:
-- the thing that actually moves is still a real ped, but it is visually hidden.
-- The body clone is just a visual remnant and may still appear on thermal depending on game/client behavior.
local function createBodyClone()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local hash = loadModel(model)
    if not hash then
        dbg('failed to load model for body clone')
        return false
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Snap spawn to ground first so the body is less likely to hover.
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    if foundGround then
        coords = vector3(coords.x, coords.y, groundZ)
    end

    local clone = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, true, true)
    if clone == 0 then
        dbg('failed to create body clone')
        return false
    end

    copyBasicAppearance(ped, clone)

    SetEntityAsMissionEntity(clone, true, true)
    SetEntityInvincible(clone, true)
    SetBlockingOfNonTemporaryEvents(clone, true)
    FreezeEntityPosition(clone, false)
    SetPedCanRagdoll(clone, false)
    SetPedDiesWhenInjured(clone, false)
    SetPedFleeAttributes(clone, 0, false)
    SetPedKeepTask(clone, true)

    ClearPedTasksImmediately(clone)
    if Config.BodyScenario and Config.BodyScenario ~= '' then
        TaskStartScenarioInPlace(clone, Config.BodyScenario, 0, true)
    else
        -- Collapse like a corpse instead of using a sleeping pose
        SetEntityHealth(clone, 0)
        Wait(0)
        SetPedToRagdoll(clone, 2500, 2500, 0, false, false, false)

        local settleUntil = GetGameTimer() + (Config.BodySettleFreezeTime or 1200)
        while GetGameTimer() < settleUntil do
            Wait(0)
        end

        local finalCoords = GetEntityCoords(clone)
        SetEntityCoordsNoOffset(
            clone,
            finalCoords.x,
            finalCoords.y,
            finalCoords.z - (Config.BodyGroundOffset or 0.035),
            false,
            false,
            false
        )

        FreezeEntityPosition(clone, true)
        SetEntityInvincible(clone, true)
    end

    Memento.bodyPed = clone
    Memento.bodyCoords = coords
    Memento.bodyHeading = heading

    SetModelAsNoLongerNeeded(hash)
    return true
end


local function disableHotbarControls()
    -- Number row / common inventory hotbar binds
    DisableControlAction(0, 157, true) -- 1
    DisableControlAction(0, 158, true) -- 2
    DisableControlAction(0, 160, true) -- 3
    DisableControlAction(0, 164, true) -- 4
    DisableControlAction(0, 165, true) -- 5
    DisableControlAction(0, 159, true) -- 6
    DisableControlAction(0, 161, true) -- 7
    DisableControlAction(0, 162, true) -- 8
    DisableControlAction(0, 163, true) -- 9
    DisableControlAction(0, 56, true)  -- F9-ish / alt binds on some setups
    DisableControlAction(0, 289, true) -- F2
    DisableControlAction(0, 170, true) -- F3
    DisableControlAction(0, 166, true) -- F5
    DisableControlAction(0, 167, true) -- F6
    DisableControlAction(0, 168, true) -- F7
end

local function disableControls()
    if Config.BlockControls.attack then
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
    end

    if Config.BlockControls.aim then
        DisableControlAction(0, 25, true)
    end

    if Config.BlockControls.enterVehicle then
        DisableControlAction(0, 23, true)
        DisableControlAction(0, 75, true)
    end

    if Config.BlockControls.melee then
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
    end

    if Config.BlockControls.cover then
        DisableControlAction(0, 44, true)
    end

    if Config.BlockControls.weaponWheel then
        DisableControlAction(0, 37, true)
        DisableControlAction(0, 199, true)
    end

    if Config.DisableJump then
        DisableControlAction(0, 22, true)
    end

    if Config.DisableSprint then
        DisableControlAction(0, 21, true)
    end
end

local function applyMovementStyle(ped)
    SetPedMoveRateOverride(ped, Config.MoveRate + 0.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end


local function hasPmaVoice()
    return Config.UsePmaVoice and GetResourceState('pma-voice') == 'started'
end

local function applyPmaVoiceForSoul()
    if not hasPmaVoice() then return end

    if Config.PmaVoiceOverrideRange ~= nil then
        exports['pma-voice']:overrideProximityRange(Config.PmaVoiceOverrideRange + 0.0, Config.PmaVoiceDisableCycle == true)
    elseif Config.PmaVoiceDisableCycle then
        exports['pma-voice']:setAllowProximityCycleState(true)
    end
end

local function clearPmaVoiceForSoul()
    if not hasPmaVoice() then return end

    if Config.PmaVoiceOverrideRange ~= nil then
        exports['pma-voice']:clearProximityOverride()
    elseif Config.PmaVoiceDisableCycle then
        exports['pma-voice']:setAllowProximityCycleState(false)
    end
end

local function cleanupEffect(notifyServer)
    local ped = PlayerPedId()

    if Config.DetachPostFx and AnimpostfxIsRunning(Config.DetachPostFx) then
        AnimpostfxStop(Config.DetachPostFx)
    end

    if Config.ReturnToBody and Memento.bodyCoords then
        SetEntityCoordsNoOffset(
            ped,
            Memento.bodyCoords.x,
            Memento.bodyCoords.y,
            Memento.bodyCoords.z + 0.1,
            false, false, false
        )
        if Memento.bodyHeading then
            SetEntityHeading(ped, Memento.bodyHeading)
        end
    end

    ClearTimecycleModifier()
    ResetPedMovementClipset(ped, 0.25)
    clearPmaVoiceForSoul()
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('invBusy', false, true)
        LocalPlayer.state:set('mementoNoItemUse', false, true)
    end
    pcall(function()
        exports['qb-target']:AllowTargeting(true)
    end)
    pcall(function()
        exports.ox_target:disableTargeting(false)
    end)
    setSoulVisual(ped, false)
    clearSoulGhost()
    clearBodyClone()

    Memento.active = false
    Memento.startedAt = 0
    Memento.endsAt = 0
    Memento.bodyCoords = nil
    Memento.bodyHeading = nil
    Memento.phoneOpenedAt = 0
    Memento.phoneAnimPlaying = false
    Memento.phoneWasOpen = false
    Memento.phoneClosingUntil = 0
    Memento.phoneCloseQueuedAt = 0

    if notifyServer then
        TriggerServerEvent('mementomori:server:finish')
    end
end

RegisterNetEvent('mementomori:client:cleanup', function()
    cleanupEffect(false)
end)





local function playWhiteFlash()
    if not Config.UseWhiteFlash then return end

    DoScreenFadeOut(0)
    Wait(0)
    DoScreenFadeIn(Config.WhiteFlashDuration or 180)
end

local function playCollapseBeforeDetach()
    if not Config.UseCollapseAnim then return end

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    SetPedToRagdoll(
        ped,
        Config.CollapseRagdollTime or 900,
        Config.CollapseRagdollTime or 900,
        0,
        false,
        false,
        false
    )

    local endAt = GetGameTimer() + (Config.CollapseRagdollTime or 900)
    while GetGameTimer() < endAt do
        Wait(0)
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 23, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
    end
end

local function playDrinkAnimBeforeDetach()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        return false
    end

    if Config.UsePillAnim then
        local dict = Config.PillAnimDict or 'mp_suicide'
        local clip = Config.PillAnimClip or 'pill'
        if not loadAnimDict(dict) then
            return false
        end

        ClearPedTasks(ped)
        TaskPlayAnim(
            ped,
            dict,
            clip,
            8.0,
            -8.0,
            Config.PillAnimDuration or 2200,
            49,
            0.0,
            false, false, false
        )

        local endAt = GetGameTimer() + (Config.PillAnimDuration or 2200)
        while GetGameTimer() < endAt do
            Wait(0)
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
        end

        ClearPedTasks(ped)
        RemoveAnimDict(dict)
        return true
    end

    if not Config.UseDrinkAnim then return true end

    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, Config.DrinkScenario or 'WORLD_HUMAN_DRINKING', 0, true)

    local endAt = GetGameTimer() + (Config.DrinkAnimDuration or 2500)
    while GetGameTimer() < endAt do
        Wait(0)
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 23, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
    end

    ClearPedTasks(ped)
    return true
end

exports('useItem', function(data, slot)
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.mementoNoItemUse then
        return
    end

    local resolvedSlot = slot
    if not resolvedSlot and type(data) == 'table' then
        resolvedSlot = data.slot or (data.metadata and data.metadata.slot)
    end

    TriggerServerEvent('mementomori:server:useOxItem', resolvedSlot)
end)

RegisterNetEvent('mementomori:client:start', function(data)
    if Memento.active then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify('車両内では使えない。', 'error')
        return
    end

    local drank = playDrinkAnimBeforeDetach()
    if not drank then
        QBCore.Functions.Notify('この状態では飲めない。', 'error')
        TriggerServerEvent('mementomori:server:forceClear')
        return
    end

    local ok = createBodyClone()
    if not ok then
        QBCore.Functions.Notify('本体生成に失敗した。', 'error')
        TriggerServerEvent('mementomori:server:forceClear')
        return
    end

    Memento.active = true
    Memento.startedAt = GetGameTimer()
    Memento.endsAt = GetGameTimer() + ((data and data.duration or Config.Duration) * 1000)

    setSoulVisual(ped, true)
    createSoulGhost()

    if Config.DetachPostFx then
        AnimpostfxPlay(Config.DetachPostFx, 0, true)
    end

    applyPmaVoiceForSoul()
    SetTimecycleModifier('NG_filmic04')
    SetPedCanRagdoll(ped, false)

    -- Hook your own resources here if needed:
    -- pma-voice voice origin is already on the soul side because the real player ped is the one moving.
    -- The pma integration above only locks/overrides proximity while detached.
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('invBusy', true, true)
        LocalPlayer.state:set('mementoNoItemUse', true, true)
    end
    pcall(function()
        exports.ox_inventory:closeInventory()
    end)
    pcall(function()
        exports['qb-target']:AllowTargeting(false)
    end)
    pcall(function()
        exports.ox_target:disableTargeting(true)
    end)

    CreateThread(function()
        while Memento.active do
            Wait(0)

            local curPed = PlayerPedId()
            disableControls()
            disableHotbarControls()
            applyMovementStyle(curPed)
            updateSoulGhost()

            local timeLeft = getTimeLeft()
            drawTxt(0.5, 0.88, ('MEMORY DETACHED 00:%02d'):format(timeLeft), timeLeft <= 5 and 0.55 or 0.45)

            -- keep body clone in place as the visible "heat source"
            if Memento.bodyPed and DoesEntityExist(Memento.bodyPed) then
                SetEntityInvincible(Memento.bodyPed, true)
                SetEntityHealth(Memento.bodyPed, GetEntityMaxHealth(Memento.bodyPed))
            end

            if GetGameTimer() >= Memento.endsAt then
                break
            end
        end

        cleanupEffect(true)
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if Memento.active then
        cleanupEffect(false)
    else
        clearSoulGhost()
    end
end)
