local MODULE_ID = "AshenMPRanking"

AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.MODULE_ID = MODULE_ID

AshenMPRanking.Options = {
    receiveData = false,
    ladderLength = 10,
    -- Fn = {}
}

local PZOptions

local config = {
    receiveData = nil,
    ladderLength = nil,
}

local function applyOptions()
    local options = PZAPI.ModOptions:getOptions(MODULE_ID)

    if options then
        AshenMPRanking.Options.receiveData = options:getOption("receiveData"):getValue()
        AshenMPRanking.Options.ladderLength = tonumber(options:getOption("ladderLength"):getValue())
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

    PZOptions.apply = function ()
        applyOptions()
    end
end

initConfig()

Events.OnMainMenuEnter.Add(function()
    applyOptions()
end)

return AshenMPRanking.Options

-- OLD IMPLEMENTATION
-- if ModOptions and ModOptions.getInstance then
--     local function getHotkeyValue(hotkey)
--         local hotkey_array = {
--             29, -- Left Ctrl
--             56, -- Left Alt
--             157, -- Right Ctrl
--             184, -- Right Alt
--             59, -- F1
--             60, -- F2
--             61, -- F3
--             62, -- F4
--             63, -- F5
--             64, -- F6
--             65, -- F7
--             66, -- F8
--             67, -- F9
--             68, -- F10
--             87, -- F11
--             88, -- F12
--             210, -- Insert
--             211, -- Delete
--             199, -- Home
--             207, -- End
--         }
--         return hotkey_array[hotkey]
--     end
    
--     local function getTimezoneValue(index)
--         tz = {"-12", "-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "0", "+1","+2","+3","+4","+5","+6","+7","+8","+9","+10","+11","+12"}
--         return tonumber(tz[index])
--     end

--     local function getLadderLengthValue(index)
--         length_values = {3, 5, 10, 15}
--         return length_values[index]
--     end

--     local function onModOptionsApply(optionValues)
--         AshenMPRanking.Options.receiveData = optionValues.settings.options.receiveData
--         AshenMPRanking.Options.ladderLength = getLadderLengthValue(optionValues.settings.options.ladderLength)
--         AshenMPRanking.Options.hotkey = getHotkeyValue(optionValues.settings.options.hotkey)
--         AshenMPRanking.Options.timezone = getTimezoneValue(optionValues.settings.options.timezone)
--     end

--     local function onModOptionApplyInGame(optionValues)
--         AshenMPRanking.Options.receiveData = optionValues.settings.options.receiveData
--         AshenMPRanking.Options.ladderLength = getLadderLengthValue(optionValues.settings.options.ladderLength)
--         AshenMPRanking.Options.hotkey = getHotkeyValue(optionValues.settings.options.hotkey)
--         AshenMPRanking.Options.timezone = getTimezoneValue(optionValues.settings.options.timezone)
--         AshenMPRanking.mainUI:setKeyMN(AshenMPRanking.Options.hotkey)
--     end

--     local SETTINGS = {
--         options_data = {
--             receiveData = {
--                 name = "UI_Options_receive",
--                 tooltip = "UI_Options_receive_tooltip",
--                 default = false,
--                 OnApplyMainMenu = onModOptionsApply,
--                 OnApplyInGame = onModOptionApplyInGame,
--             },
--             ladderLength = {
--                 "3", "5", "10", "15",
                
--                 name = "UI_Options_ladderLength",
--                 tooltip = "UI_Options_ladderLength_tooltip",
--                 default = 2,
--                 OnApplyMainMenu = onModOptionsApply,
--                 OnApplyInGame = onModOptionApplyInGame,
--             },
--             hotkey = {
--                 "L-CTRL", "L-ALT", "R-CTRL", "R-ALT", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "INSERT", "DELETE", "HOME", "END",
    
--                 name = "UI_Options_hotkey",
--                 tooltip = "UI_Options_hotkey_tooltip",
--                 default = 2,
--                 OnApplyMainMenu = onModOptionsApply,
--                 OnApplyInGame = onModOptionApplyInGame,
--             },
--             timezone = {
--                 "-12", "-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "0", "+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9", "+10", "+11", "+12",
                
--                 name = "UI_Options_timezone",
--                 tooltip = "UI_Options_timezone_tooltip",
--                 default = 13,
--                 OnApplyMainMenu = onModOptionsApply,
--                 OnApplyInGame = onModOptionApplyInGame,
--             },
--         },

--         mod_id = 'AshenMPRanking',
--         mod_shortname = 'Ashen MP Ranking',
--         mod_fullname = 'Ashen MP Ranking',
--     }
    
--     local optionsInstance = ModOptions:getInstance(SETTINGS)
--     ModOptions:loadFile()

--     Events.OnPreMapLoad.Add(function() onModOptionsApply({ settings = SETTINGS }) end)
-- end