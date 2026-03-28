Config = {}

-- Item name to register as usable
Config.ItemName = 'ultimorespiro'

-- Effect length in seconds
Config.Duration = 30

-- Soul movement multiplier while detached
Config.MoveRate = 1

-- If true, disable sprint entirely during the effect
Config.DisableSprint = true

-- If true, disable jump during the effect
Config.DisableJump = true

-- If true, the player snaps back to the original body location when the effect ends
Config.ReturnToBody = true

-- Body clone scenario / animation
Config.BodyScenario = ''

-- Visual effect used while detached
Config.DetachPostFx = 'DeathFailOut'

-- Optional commands blocked client-side by default keybinds only.
-- Hook your own inventory/target resources where noted in client/main.lua.
Config.BlockControls = {
    attack = true,
    aim = true,
    enterVehicle = true,
    melee = true,
    cover = true,
    weaponWheel = true
}

-- Debug prints
Config.Debug = false

-- pma-voice integration
-- NOTE:
-- Voice origin already follows the real player ped, and this resource uses the real player ped as the "soul".
-- So with pma-voice, voice will naturally come from the soul position as long as the player ped is what moves.
Config.UsePmaVoice = true

-- Override local proximity range while detached.
-- Set to nil to keep the player's current voice mode.
Config.PmaVoiceOverrideRange = 6.0

-- Disable F11 proximity cycling while detached.
Config.PmaVoiceDisableCycle = true


-- Soul-side presentation
-- Keeping the real player ped as the moving "soul" makes thermal-style detection
-- more likely to track the soul side, while the body clone is only visual dressing.
Config.SoulInvisible = true
Config.SoulAlpha = 0


-- Use-item presentation
Config.UseDrinkAnim = false
Config.DrinkAnimDuration = 2500
Config.DrinkScenario = 'WORLD_HUMAN_DRINKING'


-- Pill-use animation
Config.UsePillAnim = true
Config.PillAnimDict = 'mp_suicide'
Config.PillAnimClip = 'pill'
Config.PillAnimDuration = 2200


-- Detach transition feel
Config.UseWhiteFlash = true
Config.WhiteFlashDuration = 180
Config.UseCollapseAnim = true
Config.CollapseRagdollTime = 900


-- Body remnant presentation
-- Empty scenario means: don't use a sleeping scenario; leave the body as a collapsed ragdoll.
Config.BodySettleFreezeTime = 200


-- Transition tuning
-- If true, start soul detach immediately after the pill animation ends.
Config.ImmediateDetachAfterPill = true


-- Body ground fit
-- Small downward nudge after the clone settles so it doesn't look like it's floating.
Config.BodyGroundOffset = 0.035


-- Local-only soul ghost for the user
Config.ShowSoulToSelf = true
Config.SoulSelfAlpha = 220
Config.SoulSelfUseOutline = false
Config.SoulSelfOffsetZ = 0


Config.UseSoulRadioAnim = true
Config.SoulRadioAnimDict = 'random@arrests'
Config.SoulRadioAnimClip = 'generic_radio_chatter'
Config.UseSoulPhoneAnim = true
Config.SoulPhoneAnimDict = 'cellphone@'
Config.SoulPhoneAnimClip = 'cellphone_text_in'
Config.SoulPhoneAnimDelay = 250

Config.SoulPhoneAnimSpeed = 3.0
Config.SoulPhoneCloseAnimSpeed = 2.0

Config.SoulPhoneOpenClip = 'cellphone_text_in'
Config.SoulPhoneCloseClip = 'cellphone_text_out'