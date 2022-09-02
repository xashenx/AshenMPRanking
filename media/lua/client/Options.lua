AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.Options = AshenMPRanking.Options or {}

AshenMPRanking.Options.receiveData = false;
AshenMPRanking.Options.ladderLength = 5;

if ModOptions and ModOptions.getInstance then
    local function onModOptionsApply(optionValues)
        AshenMPRanking.Options.receiveData = optionValues.settings.options.receiveData;
        AshenMPRanking.Options.ladderLength = optionValues.settings.options.ladderLength;
    end

    local SETTINGS = {
        options_data = {
            receiveData = {
                name = getText("Options_receive"),
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply,
            },
            ladderLength = {
                name = getText("Options_ladderLength"),
                default = 5,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply,
            },
        },

        mod_id = 'AshenMPRanking',
        mod_shortname = 'Ashen\'s MP Ranking',
        mod_fullname = 'Ashen\'s MP Ranking',
    }
    
    local optionsInstance = ModOptions:getInstance(SETTINGS)
    ModOptions:loadFile()

    Events.OnPreMapLoad.Add(function() onModOptionsApply({ settings = SETTINGS }) end)
end