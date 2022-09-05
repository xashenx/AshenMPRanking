AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.Options = AshenMPRanking.Options or {}

AshenMPRanking.Options.receiveData = false
AshenMPRanking.Options.ladderLength = 2

if ModOptions and ModOptions.getInstance then
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
        print('imposto hotkey', hotkey, hotkey_array[hotkey])
        return hotkey_array[hotkey]
    end


    local function onModOptionsApply(optionValues)
        AshenMPRanking.Options.receiveData = optionValues.settings.options.receiveData
        AshenMPRanking.Options.ladderLength = optionValues.settings.options.ladderLength
        AshenMPRanking.Options.hotkey = getHotkeyValue(optionValues.settings.options.hotkey)
    end

    local function onModOptionApplyInGame(optionValues)
        AshenMPRanking.Options.receiveData = optionValues.settings.options.receiveData
        AshenMPRanking.Options.ladderLength = optionValues.settings.options.ladderLength
        AshenMPRanking.Options.hotkey = getHotkeyValue(optionValues.settings.options.hotkey)
        AshenMPRanking.mainUI:setKeyMN(AshenMPRanking.Options.hotkey)
    end

    local SETTINGS = {
        options_data = {
            receiveData = {
                name = getText("Options_receive"),
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionApplyInGame,
            },
            ladderLength = {
                "3", "5", "10",
                
                name = getText("Options_ladderLength"),
                default = 2,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionApplyInGame,
            },
            hotkey = {
                "L-CTRL", "L-ALT", "R-CTRL", "R-ALT", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "INSERT", "DELETE", "HOME", "END",
    
                name = getText("Options_hotkey"),
                default = 2,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionApplyInGame,
            },
        },

        mod_id = 'AshenMPRanking',
        mod_shortname = 'Ashen MP Ranking',
        mod_fullname = 'Ashen MP Ranking',
    }
    
    local optionsInstance = ModOptions:getInstance(SETTINGS)
    ModOptions:loadFile()

    Events.OnPreMapLoad.Add(function() onModOptionsApply({ settings = SETTINGS }) end)
end