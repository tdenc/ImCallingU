ICU = ICU or {}
local ICU = ICU
local EM = EVENT_MANAGER

----------------------
--INITIATE VARIABLES--
----------------------
ICU.name = "ImCallingU"
ICU.version = "0.0.1"
ICU.variableVersion = 1
ICU.defaultSettings = {
    ["se"] = 2,
    ["volume"] = tonumber(GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME)),
    ["vibration"] = 80,
    ["activity"] = true,
    ["ready"] = true,
    ["friend"] = true,
    ["guild"] = true,
    ["group"] = true,
    ["duel"] = true,
    ["trade"] = true,
}
ICU.soundEffects = {
    [1] = "NONE",
    [2] = "GROUP_ELECTION_REQUESTED",
    [3] = "INVENTORY_ITEM_APPLY_CHARGE",
    [4] = "BATTLEGROUND_CAPTURE_FLAG_TAKEN_OWN_TEAM",
    [5] = "BATTLEGROUND_COUNTDOWN_FINISH",
    [6] = "NEW_TIMED_NOTIFICATION",
    [7] = "QUEST_ABANDONED",
    [8] = "RAID_TRIAL_COUNTER_UPDATE",
    [9] = "ABILITY_COMPANION_ULTIMATE_READY",
    [10] = "AVA_GATE_CLOSED",
    [11] = "CHAMPION_POINTS_COMMITTED",
    [12] = "CODE_REDEMPTION_SUCCESS",
    [13] = "DAILY_LOGIN_REWARDS_CLAIM_FANFARE",
    [14] = "DUEL_ACCEPTED",
    [15] = "ELDER_SCROLL_CAPTURED_BY_ALDMERI",
    [16] = "GIFT_INVENTORY_VIEW_FANFARE_SPARKS",
    [17] = "GUILD_ROSTER_REMOVED",
    [18] = "LEVEL_UP_REWARD_FANFARE",
}

---------------------
--WRAPPER FUNCTIONS--
---------------------
local function isCallingDisabled()
    -- Do not use IsInGamepadPreferredMode() / IsConsoleUI()
    return ICU.savedVariables.se == 1 and (GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION) == "0" or ICU.savedVariables.vibration == 0)
end

local function setVolume(volume)
    SetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME, tostring(volume))
end

function ICU.PlaySound()
    if ICU.userVibration then
        SetGamepadVibration(1000, ICU.vibrationIntensity, ICU.vibrationIntensity / 2, 0, 0, ICU.name)
    end
    PlaySound(ICU.seString)
end

function ICU.RegisterUpdate()
    if ICU.isCalling then return end

    EM:UnregisterForUpdate(ICU.name)
    ICU.isCalling = true
    setVolume(ICU.savedVariables.volume)
    ICU.PlaySound()
    EM:RegisterForUpdate(ICU.name, 2000, ICU.PlaySound)
end

function ICU.UnregisterUpdate()
    ICU.isCalling = false
    setVolume(ICU.userVolume)
    EM:UnregisterForUpdate(ICU.name)
end

-------------------
--EVENT FUNCTIONS--
-------------------
function ICU.OnEventTriggered(eventCode, ...)
    if isCallingDisabled() then return end

    local sV = ICU.savedVariables
    -- Activity finder
    if (eventCode == EVENT_ACTIVITY_FINDER_STATUS_UPDATE) then
        if sV.activity then
            local result = ...
            if (result == ACTIVITY_FINDER_STATUS_READY_CHECK) then
                ICU.RegisterUpdate()
            elseif not HasLFGReadyCheckNotification() then
                ICU.UnregisterUpdate()
            end
        end
    -- Ready check
    elseif (eventCode == EVENT_GROUP_ELECTION_NOTIFICATION_ADDED) then
        if sV.ready then ICU.RegisterUpdate() end
    elseif (eventCode == EVENT_GROUP_ELECTION_NOTIFICATION_REMOVED) then
        if sV.ready then ICU.UnregisterUpdate() end
    -- Friend invite
    elseif (eventCode == EVENT_INCOMING_FRIEND_INVITE_ADDED) then
        if sV.friend then ICU.RegisterUpdate() end
    elseif (eventCode == EVENT_INCOMING_FRIEND_INVITE_REMOVED) then
        if sV.friend then ICU.UnregisterUpdate() end
    -- Guild invite
    elseif (eventCode == EVENT_GUILD_INVITE_ADDED) then
        if sV.guild then ICU.RegisterUpdate() end
    elseif (eventCode == EVENT_GUILD_INVITE_REMOVED) then
        if sV.guild then ICU.UnregisterUpdate() end
    -- Group invite
    elseif (eventCode == EVENT_GROUP_INVITE_RECEIVED) then
        if sV.group then ICU.RegisterUpdate() end
    elseif (eventCode == EVENT_GROUP_INVITE_REMOVED) then
        if sV.group then ICU.UnregisterUpdate() end
    -- Duel invite
    elseif (eventCode == EVENT_DUEL_INVITE_RECEIVED) then
        if sV.duel then ICU.RegisterUpdate() end
    elseif (eventCode == EVENT_DUEL_INVITE_REMOVED) then
        if sV.duel then ICU.UnregisterUpdate() end
    -- Trade invite
    elseif (eventCode == EVENT_TRADE_INVITE_CONSIDERING) then
        if sV.trade then ICU.RegisterUpdate() end
    elseif (eventCode == EVENT_TRADE_INVITE_REMOVED) then
        if sV.trade then ICU.UnregisterUpdate() end
    end

end

--------------------
--INITIALIZE ADDON--
--------------------
-- Register event
function ICU:RegisterEvents()
    local eventList = {
        EVENT_ACTIVITY_FINDER_STATUS_UPDATE,
        EVENT_GROUP_ELECTION_NOTIFICATION_ADDED, EVENT_GROUP_ELECTION_NOTIFICATION_REMOVED,
        EVENT_INCOMING_FRIEND_INVITE_ADDED, EVENT_INCOMING_FRIEND_INVITE_REMOVED,
        EVENT_GUILD_INVITE_ADDED, EVENT_GUILD_INVITE_REMOVED,
        EVENT_GROUP_INVITE_RECEIVED, EVENT_GROUP_INVITE_REMOVED,
        EVENT_DUEL_INVITE_RECEIVED, EVENT_DUEL_INVITE_REMOVED,
        EVENT_TRADE_INVITE_CONSIDERING, EVENT_TRADE_INVITE_REMOVED,
    }
    for _, key in ipairs(eventList) do
        EM:RegisterForEvent(ICU.name, key, ICU.OnEventTriggered)
    end
    SLASH_COMMANDS["/icu"] = ICU.UnregisterUpdate
end

-- LibAddonMenu
function ICU.CreateSettingsWindow()
    local LAM2 = LibAddonMenu2
    local panelData = {
        type = "panel",
        name = "I'm Calling U",
        displayName = "I'm Calling U",
        author = "@tdenc",
        version = ICU.version,
        slashCommand = "/icusetting",
        registerForRefresh = true,
        registerForDefaults = true,
        website = "https://www.esoui.com/downloads/info3147-ImCallingU-Dontmissnotification.html",
    }
    local cntrlOptionsPanel = LAM2:RegisterAddonPanel("ICU_Settings", panelData)

    local choices = {[1] = GetString(SI_CHECK_BUTTON_OFF)}
    for i = 2, #ICU.soundEffects do
        choices[i] = string.format("%i", i - 1)
    end
    local choicesValues = {}
    for i = 1, #ICU.soundEffects do
        choicesValues[i] = i
    end

    local function trialListening()
        ICU.RegisterUpdate()
        zo_callLater(function()
            ICU.UnregisterUpdate()
        end, 3000)
    end
    local optionsData = {
        {
            ["type"] = "header",
            ["name"] = GetString(SI_SETTINGSYSTEMPANEL0),
        },
        {
            ["type"] = "dropdown",
            ["name"] = GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES103),
            ["choices"] = choices,
            ["choicesValues"] = choicesValues,
            ["default"] = ICU.defaultSettings.se,
            ["getFunc"] = function() return ICU.savedVariables.se end,
            ["setFunc"] = function(newValue)
                ICU.savedVariables.se = newValue
                ICU.seString = SOUNDS[ICU.soundEffects[newValue]]
                trialListening()
            end,
            ["width"] = "half",
        },
        {
            ["type"] = "slider",
            ["min"] = 0,
            ["max"] = 100,
            ["default"] = ICU.defaultSettings.volume,
            ["getFunc"] = function() return ICU.savedVariables.volume end,
            ["setFunc"] = function(newValue)
                ICU.savedVariables.volume = newValue
                trialListening()
            end,
            ["disabled"] = function() return ICU.savedVariables.se == 1 end,
            ["width"] = "half",
        },
        {
            ["type"] = "header",
            ["name"] = GetString(SI_GAMEPAD_SECTION_HEADER),
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_OPTIONS_VIBRATION_GAMEPAD),
            ["default"] = GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION) == "1",
            ["getFunc"] = function() return GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION) == "1" end,
            ["setFunc"] = function(newValue)
                ICU.userVibration = newValue
                if newValue then
                    SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION, "1")
                else
                    SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION, "0")
                end
            end,
            ["width"] = "half",
        },
        {
            ["type"] = "slider",
            ["min"] = 0,
            ["max"] = 100,
            ["default"] = ICU.defaultSettings.vibration,
            ["getFunc"] = function() return ICU.savedVariables.vibration end,
            ["setFunc"] = function(newValue)
                ICU.savedVariables.vibration = newValue
                ICU.vibrationIntensity = newValue / 100
                trialListening()
            end,
            ["disabled"] = function() return GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION) == "0" end,
            ["width"] = "half",
        },
        {
            ["type"] = "header",
            ["name"] = GetString(SI_SOCIAL_OPTIONS_NOTIFICATIONS),
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_MAIN_MENU_ACTIVITY_FINDER),
            ["default"] = ICU.defaultSettings.activity,
            ["getFunc"] = function() return ICU.savedVariables.activity end,
            ["setFunc"] = function(newValue) ICU.savedVariables.activity = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
        {
            ["type"] = "checkbox",
            ["name"] = string.format("%s / %s", GetString(SI_ACTIVITYFINDERSTATUS4), GetString(SI_NOTIFICATIONTYPE16)),
            ["default"] = ICU.defaultSettings.ready,
            ["getFunc"] = function() return ICU.savedVariables.ready end,
            ["setFunc"] = function(newValue) ICU.savedVariables.ready = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_NOTIFICATION_FRIEND_INVITE),
            ["default"] = ICU.defaultSettings.friend,
            ["getFunc"] = function() return ICU.savedVariables.friend end,
            ["setFunc"] = function(newValue) ICU.savedVariables.friend = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_NOTIFICATION_GUILD_INVITE),
            ["default"] = ICU.defaultSettings.guild,
            ["getFunc"] = function() return ICU.savedVariables.guild end,
            ["setFunc"] = function(newValue) ICU.savedVariables.guild = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_NOTIFICATION_GROUP_INVITE),
            ["default"] = ICU.defaultSettings.group,
            ["getFunc"] = function() return ICU.savedVariables.group end,
            ["setFunc"] = function(newValue) ICU.savedVariables.group = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_NOTIFICATION_DUEL_INVITE),
            ["default"] = ICU.defaultSettings.duel,
            ["getFunc"] = function() return ICU.savedVariables.duel end,
            ["setFunc"] = function(newValue) ICU.savedVariables.duel = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
        {
            ["type"] = "checkbox",
            ["name"] = GetString(SI_PROMPT_TITLE_TRADE_INVITE_PROMPT),
            ["default"] = ICU.defaultSettings.trade,
            ["getFunc"] = function() return ICU.savedVariables.trade end,
            ["setFunc"] = function(newValue) ICU.savedVariables.trade = newValue end,
            ["disabled"] = function() return isCallingDisabled() end,
        },
    }
    LAM2:RegisterOptionControls("ICU_Settings", optionsData)
end

-- Load savedVars
function ICU:Initialize()
    ICU.savedVariables = ZO_SavedVars:NewAccountWide("ICUSavedVars", ICU.variableVersion, nil, ICU.defaultSettings)
    ICU.isCalling = false
    ICU.userVolume = tonumber(GetSetting(SETTING_TYPE_AUDIO, AUDIO_SETTING_UI_VOLUME))
    ICU.userVibration = GetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_VIBRATION) == "1"
    ICU.vibrationIntensity = ICU.savedVariables.vibration / 100
    ICU.seString = SOUNDS[ICU.soundEffects[ICU.savedVariables.se]]

    ICU.CreateSettingsWindow()
    ICU:RegisterEvents()

    EM:UnregisterForEvent(ICU.name, EVENT_ADD_ON_LOADED)
end

-- Addon loaded
function ICU.OnAddOnLoaded(event, addonName)
    if (addonName == ICU.name) then
        ICU:Initialize()
    end
end

EM:RegisterForEvent(ICU.name, EVENT_ADD_ON_LOADED, ICU.OnAddOnLoaded)