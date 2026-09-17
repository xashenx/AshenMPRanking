if isServer() then return end;

require "ISUI/ISModalDialog"

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

-- grouping + preferred order within each group; anything not listed here (e.g. plugin
-- custom_ ladders) falls into the "custom" group, sorted alphabetically
local GENERAL_KEYS = { "daysSurvived", "zKills", "sKills", "deaths" }
local DERIVED_KEYS = { "daysSurvivedAbs", "zKillsAbs", "zKillsTot", "killsPerDay", "sKillsTot" }
local SKILL_KEYS = { "physicalcategory", "farmingcategory", "firearm", "crafting", "combat", "survivalist", "otherPerks" }

local SECTION_HEADER_COLOR = { a = 1, r = 1, g = 0.82, b = 0.35 }
local ROW_SHADE_COLOR = { r = 0.12, g = 0.12, b = 0.12, a = 1 }
local ROW_DEFAULT_COLOR = { r = 0, g = 0, b = 0, a = 1 }

-- every row (header, stat, buttons) is prefixed with one of these so nothing sits flush
-- against the window's left edge
local LEFT_MARGIN = 8
local ENTRY_WIDTH = 100

local function addLeftMargin(ui)
    ui:addEmpty(nil, 1, nil, LEFT_MARGIN)
end

local function statLabel(key)
    local textKey = STAT_LABEL_KEYS[key]
    if textKey then return getText(textKey) end
    if string.sub(key, 1, 7) == "custom_" then
        return string.sub(key, 8)
    end
    return key
end

-- splits the stats received from the server into the sections shown in the editor,
-- keeping only the ones that actually have at least one field to show
local function buildSections(stats)
    local sections = {}
    local seen = {}

    local function collect(keys)
        local out = {}
        for _, key in ipairs(keys) do
            if stats[key] ~= nil then
                table.insert(out, key)
                seen[key] = true
            end
        end
        return out
    end

    local general = collect(GENERAL_KEYS)
    if #general > 0 then
        table.insert(sections, { header = getText("UI_AdminEditStatsSectionGeneral"), keys = general })
    end

    local derived = collect(DERIVED_KEYS)
    if #derived > 0 then
        table.insert(sections, { header = getText("UI_AdminEditStatsSectionDerived"), keys = derived })
    end

    local skills = collect(SKILL_KEYS)
    if #skills > 0 then
        table.insert(sections, { header = getText("UI_AdminEditStatsSectionSkills"), keys = skills })
    end

    local custom = {}
    for key in pairs(stats) do
        if not seen[key] then table.insert(custom, key) end
    end
    table.sort(custom)
    if #custom > 0 then
        table.insert(sections, { header = getText("UI_AdminEditStatsSectionCustom"), keys = custom })
    end

    return sections
end

local function closeEditor()
    local ui = AshenMPRanking.adminEditor.ui
    if ui and ui.removeFromUIManager then
        ui:removeFromUIManager()
    end
    AshenMPRanking.adminEditor.ui = nil
end

local function performSave(ui)
    local stats = {}
    for _, key in ipairs(ui.statKeys) do
        -- an emptied entry box parses to nil, which would just drop the key silently -
        -- treat it as 0 instead so it still reaches the server-side validation
        stats[key] = ui["entry_" .. key]:getValue() or 0
    end

    sendClientCommand("AshenMPRanking", "setPlayerStats", { username = ui.username, stats = stats })
    closeEditor()
end

local function onSaveConfirmResult(_, button)
    if button.internal == "YES" then
        performSave(AshenMPRanking.adminEditor.ui)
    end
end

-- writes go straight to the ladder with no undo, so Save doesn't apply anything by
-- itself: it just raises the standard PZ Yes/No confirmation with the same warning
local function onSaveClick()
    local ui = AshenMPRanking.adminEditor.ui
    if not ui then return end

    local confirm = ISModalDialog:new(0, 0, 280, 150, getText("UI_AdminEditStatsDisclaimer"), true, nil, onSaveConfirmResult)
    confirm:initialise()
    confirm:addToUIManager()
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
    ui:setWidthPixel(340)

    local sections = buildSections(stats)
    local allKeys = {}
    local rowIndex = 0

    for sectionIndex, section in ipairs(sections) do
        local headerName = "sectionHeader" .. sectionIndex
        addLeftMargin(ui)
        ui:addText(headerName, section.header, "Medium", "Left")
        ui[headerName]:setColor(SECTION_HEADER_COLOR.a, SECTION_HEADER_COLOR.r, SECTION_HEADER_COLOR.g, SECTION_HEADER_COLOR.b)
        ui:nextLine()

        for _, key in ipairs(section.keys) do
            table.insert(allKeys, key)

            addLeftMargin(ui)
            ui:addText("label_" .. key, statLabel(key) .. ":", "Small", "Left")
            local label = ui["label_" .. key]
            label:setWidthPixel(190)
            -- alternate row shading so a long list of stats stays easy to scan
            label.backgroundColor = (rowIndex % 2 == 0) and ROW_SHADE_COLOR or ROW_DEFAULT_COLOR

            ui:addEntry("entry_" .. key, tostring(stats[key] or 0), true)
            ui["entry_" .. key]:setWidthPixel(ENTRY_WIDTH)
            ui["entry_" .. key]:setBorder(true)
            -- the entry box ignores its allotted width when left as the last column of the
            -- row (it keeps stretching to the window edge) - a trailing invisible spacer
            -- takes the "last column" spot instead, so the entry keeps its fixed width
            ui:addEmpty(nil, 1)

            ui:nextLine()
            rowIndex = rowIndex + 1
        end
    end

    ui.statKeys = allKeys
    ui.username = username

    addLeftMargin(ui)
    ui:addButton("saveBtn", getText("UI_AdminEditStatsSave"), onSaveClick)
    ui["saveBtn"]:setBackgroundRGBA(0.16, 0.42, 0.16, 1)
    ui["saveBtn"]:setBorderRGBA(0.35, 0.75, 0.35, 1)

    ui:addButton("cancelBtn", getText("UI_AdminEditStatsCancel"), onCancelClick)
    ui["cancelBtn"]:setBackgroundRGBA(0.45, 0.16, 0.16, 1)
    ui["cancelBtn"]:setBorderRGBA(0.75, 0.35, 0.35, 1)
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
