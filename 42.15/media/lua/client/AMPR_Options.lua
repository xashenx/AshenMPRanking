local MODULE_ID = "AshenMPRanking"

AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.MODULE_ID = MODULE_ID

AshenMPRanking.Options = {
    receiveData = false,
    ladderLength = 10,
    uiLayout = "classic",
    -- Fn = {}
}

local PZOptions

local config = {
    receiveData = nil,
    ladderLength = nil,
    hotkey = nil,
}

AshenMPRanking.forceRender = false

local function getHotkeyValue(hotkey)
    local hotkey_array = {
        29, -- Left Ctrl
        56, -- Left Alt
        157, -- Right Ctrl
        184, -- Right Alt
        59, -- F1
        60, -- F2
        61, -- F3
        62, -- F4
        63, -- F5
        64, -- F6
        65, -- F7
        66, -- F8
        67, -- F9
        68, -- F10
        87, -- F11
        88, -- F12
        210, -- Insert
        211, -- Delete
        199, -- Home
        207, -- End
    }
    return hotkey_array[hotkey]
end

AshenMPRanking.Options.applyOptions = function()
-- local function applyOptions()
    local options = PZAPI.ModOptions:getOptions(MODULE_ID)

    if options then
        AshenMPRanking.Options.receiveData = options:getOption("receiveData"):getValue()
        if tonumber(options:getOption("ladderLength"):getValue()) * 5 ~= AshenMPRanking.Options.ladderLength then
            AshenMPRanking.forceRender = true
        end
        AshenMPRanking.Options.ladderLength = tonumber(options:getOption("ladderLength"):getValue()) * 5
        AshenMPRanking.Options.hotkey = getHotkeyValue(options:getOption("hotkey"):getValue())
        AshenMPRanking.mainUI:setKeyMN(AshenMPRanking.Options.hotkey)

        local newUiLayout = (options:getOption("uiLayout"):getValue() == 2) and "compact" or "classic"
        if newUiLayout ~= AshenMPRanking.Options.uiLayout then
            AshenMPRanking.Options.uiLayout = newUiLayout
            AshenMPRanking.rebuildUI()
        end
    else
        print("AshenMPRanking: Could not load saved settings.  Using defaults.")
    end
end

local function initConfig()
    PZOptions = PZAPI.ModOptions:create(MODULE_ID, getText("UI_AshenMPRanking_Options_Title"))

    config.receiveData = PZOptions:addTickBox(
        "receiveData",
        getText("UI_AshenMPRanking_Options_receiveData"),
        AshenMPRanking.Options.receiveData,
        getText("UI_AshenMPRanking_Options_receiveData_Tooltip")
    )

    config.ladderLength = PZOptions:addComboBox(
        "ladderLength",
        getText("UI_AshenMPRanking_Options_ladderLength"),
        AshenMPRanking.Options.ladderLength,
        getText("UI_AshenMPRanking_Options_ladderLength_Tooltip")
    )

    config.ladderLength:addItem("5", false)
    config.ladderLength:addItem("10", true)
    config.ladderLength:addItem("15", false)

    config.hotkey = PZOptions:addComboBox(
        "hotkey",
        getText("UI_AshenMPRanking_Options_hotkey"),
        AshenMPRanking.Options.hotkey,
        getText("UI_AshenMPRanking_Options_hotkey_Tooltip")
    )

    local hotkeys = {"L-CTRL", "L-ALT", "R-CTRL", "R-ALT", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "INSERT", "DELETE", "HOME", "END"}
    for _, hotkey in ipairs(hotkeys) do
        config.hotkey:addItem(hotkey, hotkey == "R-CTRL")
    end

    config.uiLayout = PZOptions:addComboBox(
        "uiLayout",
        getText("UI_AshenMPRanking_Options_uiLayout"),
        AshenMPRanking.Options.uiLayout,
        getText("UI_AshenMPRanking_Options_uiLayout_Tooltip")
    )

    config.uiLayout:addItem("Classico", true)
    config.uiLayout:addItem("Compatto", false)

    PZOptions.apply = function ()
        -- applyOptions()
        AshenMPRanking.Options.applyOptions()
    end
end

initConfig()

return AshenMPRanking.Options