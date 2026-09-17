if isServer() then return end;

AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.adminEditor = AshenMPRanking.adminEditor or {}

-- maps a raw stat key (as sent by the server) to the translation key used elsewhere in the
-- mod for that same stat, so the editor stays consistent with the leaderboard UI labels
local STAT_LABEL_KEYS = {
    daysSurvived = "UI_aliveFor",
    daysSurvivedAbs = "UI_aliveForAbs",
    zKills = "UI_zKills",
    zKillsAbs = "UI_zKillsABS",
    zKillsTot = "UI_zKillsTOT",
    deaths = "UI_deaths",
    killsPerDay = "UI_killsPerDay",
    sKills = "UI_sKills",
    sKillsTot = "UI_sKillsTOT",
    physicalcategory = "UI_physicalcategory",
    farmingcategory = "UI_farmingcategory",
    firearm = "UI_firearm",
    crafting = "UI_crafting",
    combat = "UI_combat",
    survivalist = "UI_survivalist",
    otherPerks = "UI_otherPerks",
}

-- preferred display order; anything not listed here (e.g. plugin custom_ ladders) is
-- appended afterwards, sorted alphabetically
local STAT_ORDER = {
    "daysSurvived", "daysSurvivedAbs",
    "zKills", "zKillsAbs", "zKillsTot", "killsPerDay",
    "sKills", "sKillsTot",
    "deaths",
    "physicalcategory", "farmingcategory", "firearm", "crafting", "combat", "survivalist", "otherPerks",
}

local function statLabel(key)
    local textKey = STAT_LABEL_KEYS[key]
    if textKey then return getText(textKey) end
    if string.sub(key, 1, 7) == "custom_" then
        return string.sub(key, 8)
    end
    return key
end

local function orderedStatKeys(stats)
    local ordered = {}
    local seen = {}
    for _, key in ipairs(STAT_ORDER) do
        if stats[key] ~= nil then
            table.insert(ordered, key)
            seen[key] = true
        end
    end

    local extra = {}
    for key in pairs(stats) do
        if not seen[key] then table.insert(extra, key) end
    end
    table.sort(extra)
    for _, key in ipairs(extra) do table.insert(ordered, key) end

    return ordered
end

local function closeEditor()
    local ui = AshenMPRanking.adminEditor.ui
    if ui and ui.removeFromUIManager then
        ui:removeFromUIManager()
    end
    AshenMPRanking.adminEditor.ui = nil
end

local function onSaveClick()
    local ui = AshenMPRanking.adminEditor.ui
    if not ui then return end

    local stats = {}
    for _, key in ipairs(ui.statKeys) do
        -- an emptied entry box parses to nil, which would just drop the key silently -
        -- treat it as 0 instead so it still reaches the server-side validation
        stats[key] = ui["entry_" .. key]:getValue() or 0
    end

    sendClientCommand("AshenMPRanking", "setPlayerStats", { username = ui.username, stats = stats })
    closeEditor()
end

local function onCancelClick()
    closeEditor()
end

local function openEditor(username, stats, isInactive)
    closeEditor()

    local ui = NewUI()
    local title = username
    if isInactive then
        title = title .. " [" .. getText("UI_AdminEditStatsInactiveTag") .. "]"
    end
    ui:setTitle(title)
    ui:setWidthPixel(320)

    local statKeys = orderedStatKeys(stats)
    ui.statKeys = statKeys
    ui.username = username

    for _, key in ipairs(statKeys) do
        ui:addText("label_" .. key, statLabel(key) .. ":", "Small", "Left")
        ui["label_" .. key]:setWidthPixel(190)
        ui:addEntry("entry_" .. key, tostring(stats[key] or 0), true)
        ui:nextLine()
    end

    ui:addButton("saveBtn", getText("UI_AdminEditStatsSave"), onSaveClick)
    ui:addButton("cancelBtn", getText("UI_AdminEditStatsCancel"), onCancelClick)
    ui:nextLine()

    ui:saveLayout()

    AshenMPRanking.adminEditor.ui = ui
end

local function onServerCommand(module, command, args)
    if module ~= "AshenMPRanking" or command ~= "ccPlayerStats" then
        return
    end

    if not args.found then
        processSayMessage(string.format(getText("UI_ErrorPlayerNotFound"), args.username))
    else
        openEditor(args.username, args.stats, args.isInactive)
    end
end

Events.OnServerCommand.Add(onServerCommand)
