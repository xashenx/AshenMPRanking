if isServer() then return end;
AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.textureOff = getTexture("media/textures/icon_off.png")
AshenMPRanking.textureOn = getTexture("media/textures/icon_on.png")
AshenMPRanking.mainUI = {}
AshenMPRanking.descUI = {}
AshenMPRanking.plugin = AshenMPRanking.plugin or {}

local items = {}
local perksItems = {}
local player, username
local ladderLength = 5
local labels = {}
local current_ranking = {}

local initUI = true
local initVars = true
local toolbarButton = {}

-- player stats
local zombieKills = -1
local daysSurvived = 0
local timeSurvived = nil

local playerData = {}
playerData.perkScores = {}

local laddersToWrite = {}

local BASE_HEIGHT = 20

local customLadders = {}
local customExtraLadders = 0

PERKS_FIREARM = {"Aiming", "Reloading"}
PERKS_COMBAT = {"Blunt", "Axe", "Spear", "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt"}
PERKS_CRAFTING = {"Cooking", "Woodwork", "Farming", "Electricity", "Blacksmith", "MetalWelding", "Mechanics", "Tailoring", "Melting", "Masonry", "FlintKnapping", "Pottery", "Carving", "Glassmaking", "AnimalCare"}
PERKS_FARMING = {"Farming", "Husbandry", "Butchering"}
PERKS_PHYSICAL = {"Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble"}
PERKS_SURVIVALIST = {"Fishing", "Trapping", "PlantScavenging", "Tracking", "Doctor"}
PERKS_OTHERPERKS = {}

-- a summary row's `.position` field is overloaded to hold the *other* ladder's label
-- (see onLadderUpdate), so the daysSurvived/daysSurvivedAbs check has to look at both
local function isDaysSurvivedEntry(title, v)
    return title == labels.daysSurvived or title == labels.daysSurvivedAbs
        or tostring(v.position) == labels.daysSurvived or tostring(v.position) == labels.daysSurvivedAbs
end

local function formatScore(isDaysSurvived, score)
    if isDaysSurvived then
        return string.format("%.1f", score)
    end
    return tostring(score)
end

-- resolves "where do I rank" for the ladder shown on a summary row
local function summaryYouText(v)
    if v.user == username then
        return ""
    end
    local ranked = items[v.position] or perksItems[v.position]
    if ranked ~= nil and ranked.player ~= nil then
        return tostring(ranked.player.position)
    end
    return getText("UI_Unranked")
end

-- custom row renderer for descUI/summaryUI: single-line text, colored by colorState
-- ("self" = highlighted in green like the original UI, "outOfRange" = red "you, but not ranked")
local function drawLadderListItem(self, y, listItem, alt)
    if not listItem.height then listItem.height = self.itemheight end
    if y < -self:getYScroll() then return y + listItem.height end
    if y > self:getHeight() - self:getYScroll() then return y + listItem.height end

    if self.selected == listItem.index then
        self:drawRect(0, y, self:getWidth(), listItem.height - 1, 0.3, 0.7, 0.35, 0.15)
    end
    self:drawRectBorder(0, y, self:getWidth(), listItem.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    local itemPadY = self.itemPadY or (listItem.height - self.fontHgt) / 2

    local r, g, b = 0.9, 0.9, 0.9
    local state = listItem.item and listItem.item.colorState
    if state == "self" then
        r, g, b = 0, 1, 0.2
    elseif state == "outOfRange" then
        r, g, b = 1, 0, 0
    end
    self:drawText(listItem.text, 15, y + itemPadY, r, g, b, 0.9, self.font)

    return y + listItem.height
end

-- turns an items[label]/perksItems[label] entry into display rows; shared by the classic
-- popup (openLadderDesc) and the compact layout's single always-visible list
local function buildCategoryRows(item)
    local title = item.title
    local isSummary = title == labels.summaryLB
    local rows = {}
    local foundSelf = false

    for k, v in pairs(item) do
        if k ~= 'title' and k ~= 'player' then
            local isSelf = v.user == username
            if isSelf then foundSelf = true end

            local scoreText = formatScore(isDaysSurvivedEntry(title, v), v.score)
            local rowText

            if isSummary then
                local youText = summaryYouText(v)
                rowText = v.position .. ": " .. v.user .. " (" .. scoreText .. ")"
                if youText ~= "" then
                    rowText = rowText .. "  [" .. getText("UI_SummaryYou") .. ": " .. youText .. "]"
                end
            else
                rowText = "#" .. tostring(v.position) .. "  " .. v.user .. " (" .. scoreText .. ")"
            end

            table.insert(rows, {text = rowText, colorState = isSelf and "self" or nil})
        end
    end

    -- if the player isn't in the top N shown above, append their own position/score
    if not isSummary and not foundSelf and item.player ~= nil then
        local text = tostring(item.player.position) .. "  " .. item.player.user .. " (" ..
            formatScore(isDaysSurvivedEntry(title, item.player), item.player.score) .. ")"
        table.insert(rows, {text = "..."})
        table.insert(rows, {text = text, colorState = "outOfRange"})
    end

    return rows
end

local function openLadderDesc(_, item)
    ladderLength = tonumber(AshenMPRanking.Options.ladderLength) or 10
    if ladderLength == 2 then
        ladderLength = 10
    end

    local title = item.title
    local isSummary = title == labels.summaryLB

    if isSummary then
        AshenMPRanking.descUI:close()
        AshenMPRanking.summaryUI:open()
        AshenMPRanking.summaryUI:setPositionPixel(AshenMPRanking.mainUI:getX() + AshenMPRanking.mainUI:getWidth(), AshenMPRanking.mainUI:getY())
    else
        AshenMPRanking.summaryUI:close()
        AshenMPRanking.descUI:open()
        AshenMPRanking.descUI:setPositionPixel(AshenMPRanking.mainUI:getX() + AshenMPRanking.mainUI:getWidth(), AshenMPRanking.mainUI:getY())
        AshenMPRanking.descUI:setTitle(title)
    end

    local list = isSummary and AshenMPRanking.summaryUI["list"] or AshenMPRanking.descUI["list"]
    list:clear()

    for _, row in ipairs(buildCategoryRows(item)) do
        list:addItem(row.text, {colorState = row.colorState})
    end
end

local ICON_POSITION_FILE = "/AshenMPRanking/icon_position.txt"
local ICON_DRAG_THRESHOLD = 6

local function clampIconToScreen(x, y, w, h)
    local maxX = math.max(0, getCore():getScreenWidth() - w)
    local maxY = math.max(0, getCore():getScreenHeight() - h)
    return math.max(0, math.min(x, maxX)), math.max(0, math.min(y, maxY))
end

local function saveIconPosition(x, y)
    local dataFile = getFileWriter(ICON_POSITION_FILE, true, false)
    dataFile:write(tostring(x) .. "," .. tostring(y))
    dataFile:close()
end

local function loadIconPosition()
    local dataFile = getFileReader(ICON_POSITION_FILE, false)
    if dataFile == nil then
        return nil
    end
    local line = dataFile:readLine()
    dataFile:close()
    if line == nil then
        return nil
    end
    local parts = string.split(line, ",")
    local x = parts[1] and tonumber(parts[1])
    local y = parts[2] and tonumber(parts[2])
    if x == nil or y == nil then
        return nil
    end
    return x, y
end

local function showWindowToolbar()
    -- rebuildUI (che costruisce mainUI) gira solo dopo ~200 tick da OnCharReset:
    -- ignora il click se l'utente lo preme prima che la UI sia pronta, altrimenti
    -- mainUI è ancora {} e :getIsVisible() genera un errore silenzioso
    if initUI then return end
    if AshenMPRanking.mainUI and AshenMPRanking.mainUI:getIsVisible() then
        AshenMPRanking.mainUI:close()
        toolbarButton:setImage(AshenMPRanking.textureOff)
    else
        AshenMPRanking.mainUI:open()
        toolbarButton:setImage(AshenMPRanking.textureOn)
    end
end

local function refreshSelfSurvived()
    -- checking the extended survival time
    local tmpSurvive = player:getTimeSurvived()
    local receiveData = AshenMPRanking.Options.receiveData
    if tmpSurvive ~= timeSurvived then
        timeSurvived = tmpSurvive
        AshenMPRanking.mainUI["self_survive"]:setText(timeSurvived)

        -- check if receive is nil
        if receiveData == nil or receiveData then
        -- if receive then
            -- writing to file
            local dataFile = getFileWriter("/AshenMPRanking/self_survive.txt", true, false)
            dataFile:write(timeSurvived)
            dataFile:close()
        end
    end
end

local function refreshSelfKills()
    local receiveData = AshenMPRanking.Options.receiveData
    if zombieKills ~= player:getZombieKills() then
        zombieKills = player:getZombieKills()

        if zombieKills > 0 then
            AshenMPRanking.mainUI["self_zkills"]:setText(getText("UI_Self_Zkills") .. ": " .. zombieKills)
        else
            AshenMPRanking.mainUI["self_zkills"]:setText(getText("UI_Self_0ZKills"))
        end

        -- if AshenMPRanking.Options.receiveData then
        -- check if receive is nil
        if receiveData == nil  or receiveData then
            -- write file
            local text
            if  zombieKills > 999 then
                text = string.format("%.1f", zombieKills / 1000) .. 'k'
            else
                text = tostring(zombieKills)
            end
            local dataFile = getFileWriter("/AshenMPRanking/self_zkills.txt", true, false)
            dataFile:write(text)
            dataFile:close()
        end
    end
end

function getPerkCategoryScore(category)
    local score = 0
    for i, label in ipairs(category) do
        perk = Perks[label]
        if perk ~= nil then
            level = player:getPerkLevel(perk)
            score = score + level
        end
    end
    return score
end

function getPerkPoints()
    -- -- add levels of PERKS_PASIV to playerData.perkScores.passiv
    -- playerData.perkScores.passiv = getPerkCategoryScore(PERKS_PASSIV)

    -- add levels of PERKS_PHYSICAL to playerData.perkScores.physicalcategory
    playerData.perkScores.physicalcategory = getPerkCategoryScore(PERKS_PHYSICAL)

    -- add levels of PERKS_FARMING to playerData.perkScores.farmingcategory
    playerData.perkScores.farmingcategory = getPerkCategoryScore(PERKS_FARMING)

    -- add levels of PERKS_FIREARM to playerData.perkScores.firearm
    playerData.perkScores.firearm = getPerkCategoryScore(PERKS_FIREARM)

    -- add levels of PERKS_CRAFTING to playerData.perkScores.crafting
    playerData.perkScores.crafting = getPerkCategoryScore(PERKS_CRAFTING)

    -- add levels of PERKS_COMBAT to playerData.perkScores.combat
    playerData.perkScores.combat = getPerkCategoryScore(PERKS_COMBAT)

    -- add levels of PERKS_SURVIVALIST to playerData.perkScores.survivalist
    playerData.perkScores.survivalist = getPerkCategoryScore(PERKS_SURVIVALIST)

    if AshenMPRanking.sandboxSettings.otherPerks then
        playerData.perkScores.otherPerks = getPerkCategoryScore(AshenMPRanking.sandboxSettings.otherPerksList)
    end
end

local function LevelPerkListener(player, perk, perkLevel, addBuffer)
    local parent = perk:getParent()
    local parent_name = parent:toString():lower()
    -- print(perk:toString():lower() .. " " .. tostring(parent_name) .. " " .. tostring(perkLevel) .. " " .. tostring(addBuffer))

    -- print('perklevelup', perk, parent_name, perkLevel)
    if addBuffer then
        delta = 1
    else
        delta = -1
    end
    if playerData.perkScores[parent_name] ~= nil then
        playerData.perkScores[parent_name] = playerData.perkScores[parent_name] + delta
    elseif AshenMPRanking.sandboxSettings.otherPerks then
        playerData.perkScores.otherPerks = playerData.perkScores.otherPerks + delta
    end
end

-- returns "classic" (two lists + detail popup) or "compact" (single dropdown-driven panel);
-- read directly from the saved Mod Option so the correct layout is built on the very first
-- boot, before AshenMPRanking.Options.applyOptions() has had a chance to run once
local function readInitialUiLayout()
    local options = PZAPI.ModOptions:getOptions(AshenMPRanking.MODULE_ID)
    if options and options:getOption("uiLayout") then
        return (options:getOption("uiLayout"):getValue() == 2) and "compact" or "classic"
    end
    return "classic"
end

local function buildClassicUI()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small);
    -- shared cap for every scrollable list in the mod (main list, perks list, desc/summary popups)
    -- so the windows stay a consistent, reasonable size no matter how many ladders are active
    local POPUP_LIST_HEIGHT = fontHgt * 15
    -- List UI
    AshenMPRanking.mainUI = NewUI() -- Create UI
    -- AshenMPRanking.mainUI:setTitle(getText("UI_MainWTitle"))
    AshenMPRanking.mainUI:setTitle(AshenMPRanking.sandboxSettings.mainUiTitle)
    -- AshenMPRanking.mainUI:setWidthPercent(0.1)
    -- AshenMPRanking.mainUI:setWidthPixel(276)
    AshenMPRanking.mainUI:setWidthPixel(21 * fontHgt)
    AshenMPRanking.mainUI:setKeyMN(157)
    AshenMPRanking.mainUI:addText("self_survive", "", "Small", "Center")
    AshenMPRanking.mainUI:addText("self_zkills", "", "Small", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("onlinePlayers", getText("UI_WaitingForUpdate"), "", "Center")
    AshenMPRanking.mainUI["onlinePlayers"]:setColor(1, 1, 1, 0)
    -- AshenMPRanking.mainUI:addText("lastupdate", getText("UI_WaitingForUpdate"), "", "Center")
    -- AshenMPRanking.mainUI["lastupdate"]:setColor(1, 1, 1, 0)
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("LaddersLabel", getText("UI_LaddersLabel"), "Large", "Center")
    AshenMPRanking.mainUI["LaddersLabel"]:setColor(1, 1, 0, 0)
    AshenMPRanking.mainUI:setLineHeightPixel(30)
    AshenMPRanking.mainUI:nextLine()

    -- if AshenMPRanking.sandboxSettings.perkScores then
    --     AshenMPRanking.mainUI:addText("StatsLabel", getText("UI_StatsLabel"), "", "Center")
    --     AshenMPRanking.mainUI:addText("PerksLabel", getText("UI_PerksLabel"), "", "Center")
    -- end
    -- AshenMPRanking.mainUI:nextLine()

    -- calculate the proper height for scrolllists
    -- base is calculated with dayS, zKill and relative Absolutes AND sKillTot
    -- local height = BASE_HEIGHT * 5
    local height = fontHgt * 8
    local perksHeight = 0
    if AshenMPRanking.sandboxSettings.perkScores then
        if AshenMPRanking.sandboxSettings.otherPerks then
            perksHeight = fontHgt * 7
        else
            perksHeight = fontHgt * 6
        end
    end
    if AshenMPRanking.sandboxSettings.sKills then
        height = height + fontHgt * 2

        if AshenMPRanking.sandboxSettings.summaryLB then
            height = height + fontHgt
        end

        if AshenMPRanking.sandboxSettings.killsPerDay then
            height = height + fontHgt
        end

        if AshenMPRanking.sandboxSettings.moreDeaths then
            height = height + fontHgt
        end

        if AshenMPRanking.sandboxSettings.lessDeaths then
            height = height + fontHgt
        end
    elseif AshenMPRanking.sandboxSettings.moreDeaths or AshenMPRanking.sandboxSettings.lessDeaths then
        if AshenMPRanking.sandboxSettings.summaryLB then
            height = height + fontHgt
        end

        if AshenMPRanking.sandboxSettings.killsPerDay then
            height = height + fontHgt
        end

        if AshenMPRanking.sandboxSettings.moreDeaths then
            height = height + fontHgt
        end

        if AshenMPRanking.sandboxSettings.lessDeaths then
            height = height + fontHgt
        end

        if customExtraLadders > 0 then
            height = height + (customExtraLadders * fontHgt)
        end
    end

    -- default scrollList
    AshenMPRanking.mainUI:addScrollList("list", items); -- Create list
    AshenMPRanking.mainUI["list"]:setOnMouseDownFunction(_, openLadderDesc)
    -- get max height of the scrollList, capped so the window doesn't grow unbounded
    -- when many ladders (sandbox options + custom ladders) are active - it scrolls instead
    height = math.max(height, perksHeight)
    height = math.min(height, POPUP_LIST_HEIGHT)
    AshenMPRanking.mainUI:setDefaultLineHeightPixel(height)
    
    if AshenMPRanking.sandboxSettings.perkScores then
        -- perks scrollList
        AshenMPRanking.mainUI:addScrollList("perksList", perksItems); -- Create list
        AshenMPRanking.mainUI["perksList"]:setOnMouseDownFunction(_, openLadderDesc)
        AshenMPRanking.mainUI:setLineHeightPixel(height)
    end

    AshenMPRanking.mainUI:saveLayout() -- Create window
    AshenMPRanking.mainUI:setPositionPercent(0.1, 0.1)

    -- Description UI (scrollable: a ladder can have more entries than fit on screen)
    AshenMPRanking.descUI = NewUI()
    AshenMPRanking.descUI:setTitle(getText("UI_LadderTitle"))
    AshenMPRanking.descUI:isSubUIOf(AshenMPRanking.mainUI)
    AshenMPRanking.descUI:setWidthPixel(fontHgt * 18)
    AshenMPRanking.descUI:addScrollList("list", {})
    AshenMPRanking.descUI["list"].doDrawItem = drawLadderListItem
    AshenMPRanking.descUI:setLineHeightPixel(POPUP_LIST_HEIGHT)

    -- Summary UI (scrollable: the number of categories grows with sandbox options + custom ladders)
    AshenMPRanking.summaryUI = NewUI()
    AshenMPRanking.summaryUI:setTitle(getText("UI_LadderTitle"))
    AshenMPRanking.summaryUI:isSubUIOf(AshenMPRanking.mainUI)
    AshenMPRanking.summaryUI:setWidthPixel(fontHgt * 28)
    AshenMPRanking.summaryUI:addScrollList("list", {})
    AshenMPRanking.summaryUI["list"].doDrawItem = drawLadderListItem
    AshenMPRanking.summaryUI:setLineHeightPixel(POPUP_LIST_HEIGHT)

    AshenMPRanking.descUI:saveLayout()
    AshenMPRanking.descUI:close()
    AshenMPRanking.summaryUI:saveLayout()
    AshenMPRanking.summaryUI:close()
end

-- returns the items[label]/perksItems[label] entry currently selected in the compact
-- layout's category combo (nil until the combo has data)
local function currentCompactItem()
    local combo = AshenMPRanking.mainUI and AshenMPRanking.mainUI["categoryCombo"]
    if not combo then return nil end
    local label = combo:getValue()
    if not label then return nil end
    return items[label] or perksItems[label]
end

-- repopulates the compact layout's single scrollList + "your position" line for whatever
-- category is currently selected in the combo; called on combo change and whenever fresh
-- ladder data arrives from the server
local function refreshCompactSelection()
    local mainUI = AshenMPRanking.mainUI
    if not mainUI or not mainUI["list"] then return end

    local item = currentCompactItem()
    mainUI["list"]:clear()

    if not item then
        mainUI["selfPosition"]:setText(getText("UI_AMPR_YourPosition") .. ": —")
        return
    end

    for _, row in ipairs(buildCategoryRows(item)) do
        mainUI["list"]:addItem(row.text, {colorState = row.colorState})
    end

    if item.player then
        local scoreText = formatScore(isDaysSurvivedEntry(item.title, item.player), item.player.score)
        mainUI["selfPosition"]:setText(getText("UI_AMPR_YourPosition") .. ": #" .. tostring(item.player.position) ..
            "  " .. item.player.user .. " (" .. scoreText .. ")")
    else
        -- e.g. the "Riepilogo"/summary category never populates .player - show a neutral
        -- placeholder rather than leaving the line blank, so it reads as intentional
        mainUI["selfPosition"]:setText(getText("UI_AMPR_YourPosition") .. ": —")
    end
end

-- rebuilds the compact layout's category combo from the live items/perksItems tables
-- (rather than re-deriving sandbox conditionals) so it always matches exactly what data
-- actually exists, including plugin-registered custom ladders
local function refreshCompactCategoryCombo()
    local combo = AshenMPRanking.mainUI and AshenMPRanking.mainUI["categoryCombo"]
    if not combo then return end

    local previousLabel = combo:getValue()

    local orderedLabels = {}
    for _, v in pairs(items) do
        if v.title then table.insert(orderedLabels, v.title) end
    end
    for _, v in pairs(perksItems) do
        if v.title then table.insert(orderedLabels, v.title) end
    end

    combo:setItems(orderedLabels)

    if previousLabel then
        for i, label in ipairs(orderedLabels) do
            if label == previousLabel then
                combo:setSelected(i)
                break
            end
        end
    end
end

local function buildCompactUI()
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local POPUP_LIST_HEIGHT = fontHgt * 15

    AshenMPRanking.mainUI = NewUI()
    AshenMPRanking.mainUI:setTitle(AshenMPRanking.sandboxSettings.mainUiTitle)
    AshenMPRanking.mainUI:setWidthPixel(21 * fontHgt)
    AshenMPRanking.mainUI:setKeyMN(157)

    AshenMPRanking.mainUI:addText("self_survive", "", "Small", "Center")
    AshenMPRanking.mainUI:addText("self_zkills", "", "Small", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("onlinePlayers", getText("UI_WaitingForUpdate"), "", "Center")
    AshenMPRanking.mainUI["onlinePlayers"]:setColor(1, 1, 1, 0)
    AshenMPRanking.mainUI:nextLine()

    AshenMPRanking.mainUI:addText("categoryLabel", getText("UI_AMPR_CategoryPickerLabel"), "Small", "Left")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addComboBox("categoryCombo", {})
    AshenMPRanking.mainUI["categoryCombo"]:setOnChange(_, refreshCompactSelection)
    AshenMPRanking.mainUI:nextLine()

    AshenMPRanking.mainUI:addScrollList("list", {})
    AshenMPRanking.mainUI["list"].doDrawItem = drawLadderListItem
    AshenMPRanking.mainUI:setLineHeightPixel(POPUP_LIST_HEIGHT)
    AshenMPRanking.mainUI:nextLine()

    AshenMPRanking.mainUI:addText("selfPosition", "", "Small", "Left")

    AshenMPRanking.mainUI:saveLayout()
    AshenMPRanking.mainUI:setPositionPercent(0.1, 0.1)
end

-- tears down whatever UI is currently active and builds the layout named by
-- AshenMPRanking.Options.uiLayout ("classic" or "compact") - used both for the very first
-- boot and for an immediate, no-restart switch when the player changes the Mod Option
AshenMPRanking.rebuildUI = function()
    if AshenMPRanking.mainUI and AshenMPRanking.mainUI.removeFromUIManager then
        AshenMPRanking.mainUI:removeFromUIManager()
    end
    if AshenMPRanking.descUI and AshenMPRanking.descUI.removeFromUIManager then
        AshenMPRanking.descUI:removeFromUIManager()
        AshenMPRanking.descUI = nil
    end
    if AshenMPRanking.summaryUI and AshenMPRanking.summaryUI.removeFromUIManager then
        AshenMPRanking.summaryUI:removeFromUIManager()
        AshenMPRanking.summaryUI = nil
    end

    if AshenMPRanking.Options.uiLayout == "compact" then
        buildCompactUI()
    else
        buildClassicUI()
    end

    AshenMPRanking.mainUI:close()
    if toolbarButton and toolbarButton.setImage then
        toolbarButton:setImage(AshenMPRanking.textureOff)
    end
    if AshenMPRanking.Options.hotkey then
        AshenMPRanking.mainUI:setKeyMN(AshenMPRanking.Options.hotkey)
    end

    ladderLength = tonumber(AshenMPRanking.Options.ladderLength) or 10
    if ladderLength == 2 then
        ladderLength = 10
    end

    -- force a repaint on the freshly built window: refreshSelfSurvived/refreshSelfKills only
    -- call setText when the value differs from the last poll, so without resetting this cache
    -- the new "self_survive"/"self_zkills" text elements would stay blank after a rebuild
    -- whenever the underlying value hasn't actually changed since the last tick
    timeSurvived = nil
    zombieKills = -1
    refreshSelfSurvived()
    refreshSelfKills()
    if AshenMPRanking.Options.uiLayout == "compact" then
        refreshCompactCategoryCombo()
        refreshCompactSelection()
    end
    AshenMPRanking.forceRender = true
end

-- rimuove i caratteri non ammessi nei nomi di file/cartella su Windows
-- (il nome del server è impostato liberamente dall'admin e può contenere | \ / : * ? " < >)
local function sanitizeServerName(name)
    return tostring(name):gsub('[\\/:*?"<>|]', "_")
end

local function writeLadder(ladder, label, ladder_name)
    -- text = label .. "\n\n"
    text = label .. ": "

    for i=1,math.min(#ladder,ladderLength) do
        if i > 1 then
            text = text .. " "
        end

        if ladder_name == "daysSurvived" or ladder_name == "daysSurvivedAbs" then
            text = text .. "#" .. i .. " " .. ladder[i][1] .. " (" .. string.format("%." .. 1 .. "f", ladder[i][2]) .. ")"
        else
            text = text .. "#" .. i .. " " .. ladder[i][1] .. " (" .. ladder[i][2] .. ")"
        end
    end

    local dataFile = getFileWriter("/AshenMPRanking/" .. sanitizeServerName(AshenMPRanking.sandboxSettings.server_name) .. "/" .. ladder_name .. ".txt", true, false)
    dataFile:write(text)
    dataFile:close()
end

local function writeToFile(ladder)
    -- write ladders
    for k,v in pairs(ladder) do
        if k == "perkScores" then
            for kk,vv in pairs(v) do
                if laddersToWrite[labels[kk]] then
                    -- print('DEBUG AMPR write ladder: ',  kk, labels[kk])
                    writeLadder(vv, labels[kk], kk)
                    laddersToWrite[labels[kk]] = false
                end
            end
        else
            if laddersToWrite[labels[k]] then
                -- print('DEBUG AMPR write ladder: ',  k, labels[k])
                writeLadder(v, labels[k], k)
                laddersToWrite[labels[k]] = false
            end
        end
    end
end

-- executed when a change in the rank of the player is detected
local function onRankChange(movement, ladder_label)
    if movement == "up" then
        HaloTextHelper.addTextWithArrow(player, ladder_label, true, HaloTextHelper.getColorGreen());
    else
        HaloTextHelper.addTextWithArrow(player, ladder_label, false, HaloTextHelper.getColorRed());
    end
end

local function updateRankingItems(ladder_name, ladder_label, player_username, position, value, list)
    -- -- Add debug print to see what's happening
    -- if ladder_name == "zKills" and player_username == "ashen" then
    --     print('DEBUG updateRankingItems called: ', player_username, ' == ', username, ' ? ', player_username == username)
    -- end

    if player_username == username then
        list[ladder_label]["player"] = {}
        list[ladder_label]["player"].position = position
        list[ladder_label]["player"].user = player_username
        list[ladder_label]["player"].score = value

        if current_ranking[ladder_name] ~= nil and value > 0 and position <= ladderLength then
            if position > current_ranking[ladder_name] then
                onRankChange("down", ladder_label)
            elseif position < current_ranking[ladder_name] then
                onRankChange("up", ladder_label)
            end
        end
        current_ranking[ladder_name] = position
    end

    list[ladder_label][tostring(position)] = {}
    list[ladder_label][tostring(position)].position = position
    list[ladder_label][tostring(position)].user = player_username
    list[ladder_label][tostring(position)].score = value
end

local function checkForChanges(new, old)
    local render = false
    -- laddersToWrite[k] = true
    if old == nil then
        return true
    end

    for k,v in pairs(new) do
        for kk,vv in pairs(v) do
            if kk ~= "title" then
                -- print('DEBUG AMPR checkForChanges: ', k, kk)
                if old[k] == nil then
                    laddersToWrite[k] = true
                    render = true
                else
                    if new[k][kk] ==  nil or old[k][kk] == nil then
                        laddersToWrite[k] = true
                        render = true
                    else
                        local newScore = new[k][kk].score
                        local oldScore = old[k][kk].score
                        if k == labels.daysSurvived or k == labels.daysSurvivedAbs then
                            newScore = string.format("%.1f", newScore)
                            oldScore = string.format("%.1f", oldScore)
                        elseif kk == labels.daysSurvived or kk == labels.daysSurvivedAbs then
                            newScore = string.format("%.1f", newScore)
                            oldScore = string.format("%.1f", oldScore)
                        end

                        if new[k][kk].user ~= old[k][kk].user or newScore ~= oldScore then
                            -- print('DEBUG AMPR checkForChanges: ', k, kk, "CHANGED!")
                            laddersToWrite[k] = true
                            render = true
                        end
                    end
                end
            end
        end
    end

    return render
end

local onLadderUpdate = function(module, command, args)
    if module ~= "AshenMPRanking"  or command ~= "LadderUpdate" then
        return
    end

    if args.onlineplayers ~= nil then
        local hour = tonumber(os.date('%H'))
        -- setting hour with timezone setting
        if AshenMPRanking.Options.timezone == nil then
            AshenMPRanking.Options.timezone = 0
        end
        hour = (hour + AshenMPRanking.Options.timezone) % 24
        hour = string.format("%02d", hour)
        local time = hour .. ":" .. os.date('%M')
        AshenMPRanking.mainUI["onlinePlayers"]:setText(getText("UI_OnlinePlayers") .. ": " .. args.onlineplayers)
        AshenMPRanking.mainUI["onlinePlayers"]:setColor(1, 1, 1, 1)
        -- AshenMPRanking.mainUI["lastupdate"]:setText(getText("UI_LastUpdate") .. ": " .. time)
        -- AshenMPRanking.mainUI["lastupdate"]:setColor(1, 1, 1, 1)
    end

    local ladder = args.ladder

    local tmpItems = {}
    local renderItems = false
    local tmpPerksItems = {}
    local renderPerksItems = false

    if AshenMPRanking.sandboxSettings.summaryLB then
        tmpItems[labels.summaryLB] = items[labels.summaryLB]
        -- items[labels.summaryLB] = labels.summaryLB .. " <LINE>"
        items[labels.summaryLB] = {}
        items[labels.summaryLB].title = labels.summaryLB
    end

    local max_cardinality = 1
    for k,v in pairs(ladder) do
        if k == "perkScores" then
            for kk,vv in pairs(v) do
                tmpPerksItems[labels[kk]] = perksItems[labels[kk]]
                -- perksItems[labels[kk]] = labels[kk] .. " <LINE><LINE>"
                perksItems[labels[kk]] = {}
                perksItems[labels[kk]].title = labels[kk]
                -- get max cardinality of perkScores ladders
                if #vv > max_cardinality then
                    max_cardinality = #vv
                end
            end
        else
            tmpItems[labels[k]] = items[labels[k]]
            -- items[labels[k]] = labels[k] .. " <LINE><LINE>"
            items[labels[k]] = {}
            items[labels[k]].title = labels[k]
            if #v > max_cardinality then
                max_cardinality = #v
            end
        end
    end

    if args.user_positions[username] ~= nil then
        for k,v in pairs(args.user_positions[username]) do
            if k == "perkScores" then
                for kk,vv in pairs(v) do
                    perksItems[labels[kk]]["player"] = {}
                    perksItems[labels[kk]]["player"].position = vv[1]
                    perksItems[labels[kk]]["player"].user = username
                    perksItems[labels[kk]]["player"].score = vv[2]
                end
            else
                items[labels[k]]["player"] = {}
                items[labels[k]]["player"].position = v[1]
                items[labels[k]]["player"].user = username
                items[labels[k]]["player"].score = v[2]
            end
        end
    end

    for i=1,ladderLength do
        for k,v in pairs(ladder) do
            if k == "perkScores" then
                for kk,vv in pairs(v) do
                    if #vv >= i and (i <= ladderLength or vv[i][1] == username) then
                        updateRankingItems(kk, labels[kk], vv[i][1], i, vv[i][2], perksItems)
                        if AshenMPRanking.sandboxSettings.summaryLB and i == 1 then
                            items[labels.summaryLB][labels[kk]] = {}
                            items[labels.summaryLB][labels[kk]].position = labels[kk]
                            items[labels.summaryLB][labels[kk]].user = vv[i][1]
                            items[labels.summaryLB][labels[kk]].score = vv[i][2]
                        end
                    end
                end
            else
                if #v >= i and (i <= ladderLength or v[i][1] == username) then
                    updateRankingItems(k, labels[k], v[i][1], i, v[i][2], items)
                    -- if summaryLB and i == 1 add to the list
                    if AshenMPRanking.sandboxSettings.summaryLB and i == 1 then
                        items[labels.summaryLB][labels[k]] = {}
                        items[labels.summaryLB][labels[k]].position = labels[k]
                        items[labels.summaryLB][labels[k]].user = v[i][1]
                        items[labels.summaryLB][labels[k]].score = v[i][2]
                    end
                end
            end
        end
    end

    -- check if there are changes in the tables
    renderItems = checkForChanges(items, tmpItems)
    -- print('DEBUG AMPR renderItems: ', renderItems)

    renderPerksItems = checkForChanges(perksItems, tmpPerksItems)
    -- print('DEBUG AMPR renderPerksItems: ', renderPerksItems)

    if AshenMPRanking.Options.uiLayout == "compact" then
        if renderItems or renderPerksItems or AshenMPRanking.forceRender then
            refreshCompactCategoryCombo()
            refreshCompactSelection()
        end
    else
        if renderItems or AshenMPRanking.forceRender then
            AshenMPRanking.mainUI["list"]:setItems(items)
        end

        if AshenMPRanking.sandboxSettings.perkScores and (renderPerksItems or AshenMPRanking.forceRender) then
            AshenMPRanking.mainUI["perksList"]:setItems(perksItems)
        end
    end

    if AshenMPRanking.forceRender then
        AshenMPRanking.forceRender = false
    end

    local writingCondition = renderItems or renderPerksItems
    local receiveData = AshenMPRanking.Options.receiveData
    -- print('DEBUG AMPR writingCondition', writingCondition, renderItems, renderPerksItems, writeSelfS, writeSelfK)
    -- check if receive is nil
    if (receiveData == nil  or receiveData) and writingCondition then
    -- if AshenMPRanking.Options.receiveData and writingCondition then
        writeToFile(ladder)
    end
end

local function onPlayerDeathReset(player)
    local data = {}
    data.username = player:getUsername()
    Events.LevelPerk.Remove(LevelPerkListener)
    sendClientCommand(player, "AshenMPRanking", "PlayerIsDead", data)

    local killer = player:getAttackedBy()
    if not killer then return end
    if killer:isZombie() then return end
    
    -- print("updateSurvivorKills: " .. player:getUsername() .. " was KILLED by " .. killer:getUsername())
    sendClientCommand(getPlayer(), "AshenMPRanking", "ServerUpdateSurvivorKills", {killerOnlineID = killer:getOnlineID()})
end

-- Called on the player to parse its player data and send it to the server every ten (in-game) minutes
local function SendPlayerData()
    local player = getPlayer()
    local username = player:getUsername()
    local forname = player:getDescriptor():getForename()
    local surname = player:getDescriptor():getSurname()

    playerData.username = username
    -- get the steamid of the player
    playerData.steamID = player:getSteamID()
    playerData.charName = forname .. " " .. surname
    -- playerData.profession = player:getDescriptor():getProfession()
    playerData.isAlive = player:isAlive()
    playerData.isZombie = player:isZombie()
    playerData.zombieKills = player:getZombieKills()
    playerData.survivorKills = player:getSurvivorKills()
    playerData.daysSurvived = player:getHoursSurvived() / 24

    -- 260331 temporary fix for LevelPerkListener not being called when a player levels up a perk
    getPerkPoints()

    -- check if receive is nil
    local receiveData = AshenMPRanking.Options.receiveData
    playerData.receiveData = receiveData == nil or receiveData

    sendClientCommand(player, "AshenMPRanking", "PlayerData", playerData)
end

local function initClientConfig()
    -- Read sandbox settings directly from SandboxVars (already synced by PZ Java engine)
    AshenMPRanking.sandboxSettings.mainUiTitle = SandboxVars.AshenMPRanking.mainUiTitle
    AshenMPRanking.sandboxSettings.sKills = SandboxVars.AshenMPRanking.sKills
    AshenMPRanking.sandboxSettings.killsPerDay = SandboxVars.AshenMPRanking.killsPerDay
    AshenMPRanking.sandboxSettings.inactivityPurgeTime = SandboxVars.AshenMPRanking.inactivityPurgeTime
    AshenMPRanking.sandboxSettings.periodicTick = SandboxVars.AshenMPRanking.periodicTick
    AshenMPRanking.sandboxSettings.perkScores = SandboxVars.AshenMPRanking.perkScores
    AshenMPRanking.sandboxSettings.otherPerks = SandboxVars.AshenMPRanking.otherPerks
    if AshenMPRanking.sandboxSettings.otherPerks then
        for token in string.gmatch(SandboxVars.AshenMPRanking.otherPerksList, "[^;%s]+") do
            if AshenMPRanking.sandboxSettings.otherPerksList == nil then
                AshenMPRanking.sandboxSettings.otherPerksList = {}
            end
            table.insert(AshenMPRanking.sandboxSettings.otherPerksList, token)
        end
        if AshenMPRanking.sandboxSettings.otherPerksList == nil then
            AshenMPRanking.sandboxSettings.otherPerks = false
        end
    end
    AshenMPRanking.sandboxSettings.moreDeaths = SandboxVars.AshenMPRanking.moreDeaths
    AshenMPRanking.sandboxSettings.lessDeaths = SandboxVars.AshenMPRanking.lessDeaths
    AshenMPRanking.sandboxSettings.summaryLB = SandboxVars.AshenMPRanking.summaryLB
    AshenMPRanking.sandboxSettings.writeOnFilePeriod = SandboxVars.AshenMPRanking.writeOnFilePeriod
    AshenMPRanking.sandboxSettings.rankStaff = SandboxVars.AshenMPRanking.rankStaff
    AshenMPRanking.sandboxSettings.physicalcategoryMaxScore = SandboxVars.AshenMPRanking.physicalcategoryMaxScore
    AshenMPRanking.sandboxSettings.debugMode = SandboxVars.AshenMPRanking.debugMode
    AshenMPRanking.sandboxSettings.server_name = getServerName()

    labels.daysSurvived = getText("UI_aliveFor")
    labels.daysSurvivedAbs = getText("UI_aliveForAbs")

    labels.zKills = getText("UI_zKills")
    labels.zKillsAbs = getText("UI_zKillsABS")
    labels.zKillsTot = getText("UI_zKillsTOT")

    if AshenMPRanking.sandboxSettings.sKills then
        labels.sKills = getText("UI_sKills")
        labels.sKillsTot = getText("UI_sKillsTOT")
    end

    if AshenMPRanking.sandboxSettings.perkScores then
        labels.physicalcategory = getText("UI_physicalcategory")
        labels.farmingcategory = getText("UI_farmingcategory")
        labels.firearm = getText("UI_firearm")
        labels.crafting = getText("UI_crafting")
        labels.combat = getText("UI_combat")
        labels.survivalist = getText("UI_survivalist")
        if AshenMPRanking.sandboxSettings.otherPerks then
            labels.otherPerks = getText("UI_otherPerks")
        end

        -- get initial level of perks and then add listener to update it
        getPerkPoints()
        Events.LevelPerk.Add(LevelPerkListener)
    end

    if AshenMPRanking.sandboxSettings.summaryLB then
        labels.summaryLB = getText("UI_summaryLB")
    end

    if AshenMPRanking.sandboxSettings.killsPerDay then
        labels.killsPerDay = getText("UI_killsPerDay")
    end

    if AshenMPRanking.sandboxSettings.moreDeaths then
        labels.moreDeaths = getText("UI_moreDeaths")
    end

    if AshenMPRanking.sandboxSettings.lessDeaths then
        labels.lessDeaths = getText("UI_lessDeaths")
    end

    if initUI then
        AshenMPRanking.Options.uiLayout = readInitialUiLayout()
        AshenMPRanking.rebuildUI()
        AshenMPRanking.Options.applyOptions()
        initUI = false
        Events.OnServerCommand.Add(onLadderUpdate)
        Events.EveryHours.Add(refreshSelfSurvived)
        Events.OnPlayerUpdate.Add(refreshSelfKills)

        if AshenMPRanking.sandboxSettings.periodicTick == 1 then
            Events.EveryOneMinute.Add(SendPlayerData)
        elseif AshenMPRanking.sandboxSettings.periodicTick == 2 then
            Events.EveryTenMinutes.Add(SendPlayerData)
        elseif AshenMPRanking.sandboxSettings.periodicTick == 3 then
            Events.EveryHours.Add(SendPlayerData)
        elseif AshenMPRanking.sandboxSettings.periodicTick == 4 then
            Events.EveryDays.Add(SendPlayerData)
        end
    end

    -- Request initial ladder data from server (single unicast)
    -- Vorshim code to optimize data flow
    sendClientCommand(player, "AshenMPRanking", "getLadder", {})

    initVars = false
end

-- Vorshim reworked routine to optimize and fix button positioning
local function onCharReset()
    local inst = ISEquippedItem.instance
    local refBtn = inst.invBtn

    -- Calcola Y dal bottom dell'ultimo bottone visibile (posizione di default)
    local maxBottom = 0
    for _, child in pairs(inst:getChildren()) do
        if child.Type == "ISButton" and child:isVisible() then
            maxBottom = math.max(maxBottom, child:getBottom())
        end
    end

    local btnW = refBtn and refBtn:getWidth() or 50
    local btnH = refBtn and refBtn:getHeight() or 50

    local savedX, savedY = loadIconPosition()
    local btnX, btnY
    if savedX ~= nil then
        btnX, btnY = clampIconToScreen(savedX, savedY, btnW, btnH)
    else
        btnX, btnY = inst:getX(), inst:getY() + maxBottom + 6
    end

    -- onCharReset runs again on every respawn: remove the previous icon before
    -- creating a new one, otherwise the old instance stays orphaned in the UIManager
    if toolbarButton and toolbarButton.removeFromUIManager then
        toolbarButton:removeFromUIManager()
    end

    toolbarButton = ISButton:new(btnX, btnY, btnW, btnH, "", nil, showWindowToolbar)
    toolbarButton:setImage(AshenMPRanking.textureOff)
    toolbarButton:setDisplayBackground(false)
    toolbarButton.internal = "AMPRBtn"
    -- Se l'utente ha già spostato l'icona in passato, non riposizionarla più automaticamente
    toolbarButton.userMoved = savedX ~= nil

    -- Override render: scala texture al bottone (fix 4K/64px)
    function toolbarButton:render()
        local tex = self.image
        if tex then
            local s = math.min(self:getWidth(), self:getHeight())
            local x = (self:getWidth() - s) / 2
            local y = (self:getHeight() - s) / 2
            self:drawTextureScaledAspect(tex, x, y, s, s, 1.0, 1, 1, 1)
        end
    end

    -- Drag & drop: un click rapido apre/chiude la finestra, un trascinamento sposta l'icona.
    -- dragDistance è lo spostamento NETTO dal punto di pressione iniziale, non la somma di
    -- ogni singolo delta: sommare i delta faceva scattare il drag (e annullava il click) anche
    -- per un piccolo tremolio del mouse durante un semplice click (spostamento netto ~0).
    local function applyIconDrag(self, dx, dy)
        if not self.dragging then return end
        local newX, newY = clampIconToScreen(self:getX() + dx, self:getY() + dy, self:getWidth(), self:getHeight())
        self:setX(newX)
        self:setY(newY)
        self.dragDistance = math.abs(newX - self.dragStartX) + math.abs(newY - self.dragStartY)
        if self.dragDistance > ICON_DRAG_THRESHOLD then
            self.pressed = false -- annulla il click: l'utente sta trascinando
        end
    end

    local function endIconDrag(self)
        if self.dragging and self.dragDistance > ICON_DRAG_THRESHOLD then
            self.userMoved = true
            saveIconPosition(self:getX(), self:getY())
        end
        self.dragging = false
        self.dragDistance = 0
    end

    function toolbarButton:onMouseDown(x, y)
        ISButton.onMouseDown(self, x, y)
        self.dragging = true
        self.dragDistance = 0
        self.dragStartX = self:getX()
        self.dragStartY = self:getY()
        self:bringToTop()
    end

    function toolbarButton:onMouseMove(dx, dy)
        ISButton.onMouseMove(self, dx, dy)
        applyIconDrag(self, dx, dy)
    end

    function toolbarButton:onMouseMoveOutside(dx, dy)
        ISButton.onMouseMoveOutside(self, dx, dy)
        applyIconDrag(self, dx, dy)
    end

    function toolbarButton:onMouseUp(x, y)
        endIconDrag(self)
        ISButton.onMouseUp(self, x, y)
    end

    function toolbarButton:onMouseUpOutside(x, y)
        endIconDrag(self)
        ISButton.onMouseUpOutside(self, x, y)
    end

    toolbarButton:addToUIManager()

    player = getSpecificPlayer(0)
    username = player:getUsername()
    initVars = true
    
    local tickCount = 0
    local function delayedInit()
        tickCount = tickCount + 1
        if tickCount >= 200 then
            Events.OnTick.Remove(delayedInit)
            initClientConfig()
            -- update username
            username = player:getUsername()
            -- Fix: impedire auto-apertura mainUI
            if AshenMPRanking.mainUI and type(AshenMPRanking.mainUI.close) == "function" then
                AshenMPRanking.mainUI:close()
                toolbarButton:setImage(AshenMPRanking.textureOff)
            end
            for ladderName,ladderLabel in pairs(customLadders) do
                labels["custom_" .. ladderName] = ladderLabel
            end
        end
    end
    Events.OnTick.Add(delayedInit)
end

local function clientUpdateSurvivorKills(module, command, args)
    if module ~= "AshenMPRanking" or command ~= "ClientUpdateSurvivorKills" then return end

    local thisPlayer = getPlayer();
    thisPlayer:setSurvivorKills(thisPlayer:getSurvivorKills() + 1);
end

-- Prerender: riposizionamento dinamico del bottone AMPR
-- VORSHIM CREDITS
local original_prerender = ISEquippedItem.prerender
function ISEquippedItem:prerender()
    original_prerender(self)
    if self == ISEquippedItem.instance and toolbarButton and toolbarButton:isVisible() then
        -- l'icona è un elemento top-level indipendente: tienila sempre sopra qualsiasi
        -- altro pannello/tooltip che potrebbe finirci sopra e rubarle i click
        toolbarButton:bringToTop()

        -- Se l'utente ha trascinato l'icona altrove, rispetta la sua posizione
        if not toolbarButton.userMoved then
            local maxBottom = 0
            for _, child in pairs(self:getChildren()) do
                if child.Type == "ISButton" and child:isVisible() then
                    maxBottom = math.max(maxBottom, child:getBottom())
                end
            end
            local targetX = self:getX()
            local targetY = self:getY() + maxBottom + 6
            if toolbarButton:getX() ~= targetX or toolbarButton:getY() ~= targetY then
                toolbarButton:setX(targetX)
                toolbarButton:setY(targetY)
            end
        end
    end
end

-- PLUGIN
AshenMPRanking.plugin.addCustomLadder = function (ladderName, ladderLabel)
    -- fallback to the ladder name if a plugin forgets to pass a label, otherwise
    -- customLadders[ladderName] would never be set (nil values are not stored in Lua tables)
    customLadders[ladderName] = ladderLabel or ladderName
    customExtraLadders = customExtraLadders + 1
end

AshenMPRanking.plugin.removeCustomLadder = function (ladderName)
    customLadders[ladderName] = nil
    customExtraLadders = customExtraLadders - 1
end

AshenMPRanking.plugin.updatePlayerData = function (ladderName, value)
    playerData["custom_" .. ladderName] = value
end
-- END PLUGIN

Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnCreatePlayer.Add(onCharReset)
Events.OnServerCommand.Add(clientUpdateSurvivorKills)
