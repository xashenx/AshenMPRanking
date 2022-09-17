if isServer() then return end;
AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.textureOff = getTexture("media/textures/icon_off.png")
AshenMPRanking.textureOn = getTexture("media/textures/icon_on.png")
AshenMPRanking.mainUI = {}
AshenMPRanking.descUI = {}

-- getGameTime():getModData().test = getGameTime():getModData().test or {}
local items = {}
local perksItems = {}
local player, username
local ladderLength = 5
local labels = {}
local current_ranking = {}

local initUI = true
local toolbarButton = {}

-- player stats
local zombieKills = 0
local daysSurvived = 0
local writeSelfK = false
local writeSelfS = false

local playerData = {}
playerData.perkScores = {}

local laddersToWrite = {}

local BASE_WIDTH = 20

PERKS_PASSIV = {"Fitness", "Strength"}
PERKS_AGILITY = {"Sprinting", "Lightfoot", "Nimble", "Sneak"}
PERKS_FIREARM = {"Aiming", "Reloading"}
PERKS_COMBAT = {"Blunt", "Axe", "Spear", "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt"}
PERKS_CRAFTING = {"Cooking", "Woodwork", "Farming", "Electricity", "Blacksmith", "MetalWelding", "Mechanics", "Tailoring", "Melting", "Doctor"}
PERKS_SURVIVALIST = {"Fishing", "Trapping", "PlantScavenging"}

local function openLadderDesc(_, item)
    AshenMPRanking.descUI:open()
    AshenMPRanking.descUI:setPositionPixel(AshenMPRanking.mainUI:getX() + AshenMPRanking.mainUI:getWidth(), AshenMPRanking.mainUI:getY())
    AshenMPRanking.descUI["ladderText"]:setText(item)
    -- AshenMPRanking.mainUI["ladderText"]:setText(item)
end

local function showWindowToolbar()
    if AshenMPRanking.mainUI and AshenMPRanking.mainUI:getIsVisible() then
        AshenMPRanking.mainUI:close()
        toolbarButton:setImage(AshenMPRanking.textureOff)
    else
        AshenMPRanking.mainUI:open()
        toolbarButton:setImage(AshenMPRanking.textureOn)
    end
end

local function refreshSelfSurvived()
    local tmpSurvive = player:getHoursSurvived() / 24
    tmpSurvive = string.format("%.1f", tmpSurvive)

    if tmpSurvive ~= daysSurvived then
        daysSurvived = tmpSurvive
        AshenMPRanking.mainUI["self_survive"]:setText(getText("UI_Self_Survived") .. ": " .. daysSurvived)
        writeSelfS = true
    end
end

local function refreshSelfKills()
    if zombieKills ~= player:getZombieKills() then
        zombieKills = player:getZombieKills()
        AshenMPRanking.mainUI["self_zkills"]:setText(getText("UI_Self_Zkills") .. ": " .. zombieKills)
        writeSelfK = true
    end
end

function getPerkPoints()
    playerData.perkScores.passiv = 0
    -- add levels of PERKS_PASIV to playerData.perkScores.passiv
    for i, label in ipairs(PERKS_PASSIV) do
        perk = Perks[label]
        level = player:getPerkLevel(perk)
        -- print(perk, level)
        playerData.perkScores.passiv = playerData.perkScores.passiv + player:getPerkLevel(perk)
    end

    -- add levels of PERKS_COMBAT to playerData.perkScores.combat
    playerData.perkScores.combat = 0
    for i, label in ipairs(PERKS_COMBAT) do
        perk = Perks[label]
        level = player:getPerkLevel(perk)
        -- print(perk, level)
        playerData.perkScores.combat = playerData.perkScores.combat + level
    end

    -- add levels of PERKS_FIREARM to playerData.perkScores.firearm
    playerData.perkScores.firearm = 0
    for i, label in ipairs(PERKS_FIREARM) do
        perk = Perks[label]
        level = player:getPerkLevel(perk)
        -- print(perk, level)
        playerData.perkScores.firearm = playerData.perkScores.firearm + level
    end

    -- add levels of PERKS_CRAFTING to playerData.perkScores.crafting
    playerData.perkScores.crafting = 0
    for i, label in ipairs(PERKS_CRAFTING) do
        perk = Perks[label]
        level = player:getPerkLevel(perk)
        -- print(perk, level)
        playerData.perkScores.crafting = playerData.perkScores.crafting + level
    end

    -- add levels of PERKS_SURVIVALIST to playerData.perkScores.survivalist
    playerData.perkScores.survivalist = 0
    for i, label in ipairs(PERKS_SURVIVALIST) do
        perk = Perks[label]
        level = player:getPerkLevel(perk)
        -- print(perk, level)
        playerData.perkScores.survivalist = playerData.perkScores.survivalist + level
    end

    -- add levels of PERKS_AGILITY to playerData.perkScores.agility
    playerData.perkScores.agility = 0
    for i, label in ipairs(PERKS_AGILITY) do
        perk = Perks[label]
        level = player:getPerkLevel(perk)
        -- print(perk, level)
        playerData.perkScores.agility = playerData.perkScores.agility + level
    end
end

local function LevelPerkListener(player, perk, perkLevel, addBuffer)
    local parent = perk:getParent()
    local parent_name = parent:toString():lower()
    -- print('perklevelup', perk, parent_name, perkLevel)
    playerData.perkScores[parent_name] = playerData.perkScores[parent_name] + 1
end

local function onCharReset()
    toolbarButton = {}
    toolbarButton = ISButton:new(0, ISEquippedItem.instance.movableBtn:getY() + ISEquippedItem.instance.movableBtn:getHeight() + 200, 50, 50, "", nil, showWindowToolbar)
    toolbarButton:setImage(AshenMPRanking.textureOff)
    toolbarButton:setDisplayBackground(false)
    -- toolbarButton.borderColor = {r=1, g=1, b=1, a=0.1}

    ISEquippedItem.instance:addChild(toolbarButton)
    ISEquippedItem.instance:setHeight(math.max(ISEquippedItem.instance:getHeight(), toolbarButton:getY() + 400))

    player = getSpecificPlayer(0)
    username = player:getUsername()

    -- get initial level of perks and then add listener to update it
    getPerkPoints()
    Events.LevelPerk.Add(LevelPerkListener)
end

local function onCreateUI()
    -- List UI
    AshenMPRanking.mainUI = NewUI() -- Create UI
    -- AshenMPRanking.mainUI:setTitle(getText("UI_MainWTitle"))
    AshenMPRanking.mainUI:setTitle(AshenMPRanking.sandboxSettings.mainUiTitle)
    -- AshenMPRanking.mainUI:setWidthPercent(0.1)
    AshenMPRanking.mainUI:setWidthPixel(275)
    AshenMPRanking.mainUI:setKeyMN(157)
    AshenMPRanking.mainUI:addText("self_survive", "", "", "Center")
    AshenMPRanking.mainUI:addText("self_zkills", "", "", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("onlinePlayers", getText("UI_WaitingForUpdate"), "", "Center")
    AshenMPRanking.mainUI["onlinePlayers"]:setColor(1, 1, 1, 0)
    AshenMPRanking.mainUI:addText("lastupdate", getText("UI_WaitingForUpdate"), "", "Center")
    AshenMPRanking.mainUI["lastupdate"]:setColor(1, 1, 1, 0)
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("LaddersLabel", getText("UI_LaddersLabel"), "Large", "Center")
    AshenMPRanking.mainUI["LaddersLabel"]:setColor(1, 1, 0, 0)
    AshenMPRanking.mainUI:setLineHeightPixel(30)
    AshenMPRanking.mainUI:nextLine()

    if AshenMPRanking.sandboxSettings.perkScores then
        AshenMPRanking.mainUI:addText("StatsLabel", getText("UI_StatsLabel"), "", "Center")
        AshenMPRanking.mainUI:addText("PerksLabel", getText("UI_PerksLabel"), "", "Center")
    end
    AshenMPRanking.mainUI:nextLine()
    
    -- calculate the proper width for scrolllists
    -- base i calculate with dayS, zKill and relative Absolutes
    local width = BASE_WIDTH * 4
    if AshenMPRanking.sandboxSettings.sKills then
        width = width + BASE_WIDTH * 2
        if AshenMPRanking.sandboxSettings.moreDeaths then
            width = width + BASE_WIDTH
        end

        if AshenMPRanking.sandboxSettings.lessDeaths then
            width = width + BASE_WIDTH
        end

        if AshenMPRanking.sandboxSettings.summaryLB then
            width = width + BASE_WIDTH
        end
    elseif AshenMPRanking.sandboxSettings.moreDeaths or AshenMPRanking.sandboxSettings.lessDeaths then
        if AshenMPRanking.sandboxSettings.moreDeaths then
            width = width + BASE_WIDTH
        end

        if AshenMPRanking.sandboxSettings.lessDeaths then
            width = width + BASE_WIDTH
        end

        if AshenMPRanking.sandboxSettings.summaryLB then
            width = width + BASE_WIDTH
        end
    elseif AshenMPRanking.sandboxSettings.perkScores then
        width = BASE_WIDTH * 6
    end

    -- default scrollList
    AshenMPRanking.mainUI:addScrollList("list", items); -- Create list
    AshenMPRanking.mainUI["list"]:setOnMouseDownFunction(_, openLadderDesc)
    AshenMPRanking.mainUI:setDefaultLineHeightPixel(width)

    if AshenMPRanking.sandboxSettings.perkScores then
        -- perks scrollList
        AshenMPRanking.mainUI:addScrollList("perksList", perksItems); -- Create list
        AshenMPRanking.mainUI["perksList"]:setOnMouseDownFunction(_, openLadderDesc)
        AshenMPRanking.mainUI:setLineHeightPixel(width)
    end

    AshenMPRanking.mainUI:saveLayout() -- Create window
    AshenMPRanking.mainUI:setPositionPercent(0.1, 0.1)
    -- AshenMPRanking.mainUI:setBorderToAllElements(true)
    AshenMPRanking.mainUI:close()
    
    -- Description UI
    AshenMPRanking.descUI = NewUI()
    AshenMPRanking.descUI:setTitle(getText("UI_LadderTitle"))
    AshenMPRanking.descUI:isSubUIOf(AshenMPRanking.mainUI)
    -- AshenMPRanking.descUI:setWidthPercent(0.1)
    AshenMPRanking.descUI:setWidthPixel(250)
    
    AshenMPRanking.descUI:addEmpty(_, _, _, 10) -- Margin only for rich text
    AshenMPRanking.descUI:addRichText("ladderText", "")
    AshenMPRanking.descUI:setLineHeightPercent(0.3)
    AshenMPRanking.descUI:addEmpty(_, _, _, 10) -- Margin only for rich text
    AshenMPRanking.descUI:nextLine()
    
    -- AshenMPRanking.descUI:addButton("b1", "Accept ?", choose);
    AshenMPRanking.descUI:saveLayout()
    AshenMPRanking.descUI:close()
    
    refreshSelfSurvived()
    refreshSelfKills()
    Events.EveryHours.Add(refreshSelfSurvived)
    Events.OnPlayerUpdate.Add(refreshSelfKills)
end

local function writeLadder(ladder, label, ladder_name)
    -- text = label .. "\n\n"
    text = label .. ": "

    for i=1,math.min(#ladder,ladderLength) do
        if i > 1 then
            if i < math.min(#ladder,ladderLength) then
                text = text .. ";"
            end
            -- text = text .. "\n"
            text = text .. " "

        end

        if ladder_name == "daysSurvived" or ladder_name == "daysSurvivedAbs" then
            text = text .. "(" .. i .. ") " .. ladder[i][1] .. " " .. string.format("%." .. 1 .. "f", ladder[i][2])
        else
            text = text .. "(" .. i .. ") " .. ladder[i][1] .. " " .. ladder[i][2]
        end
    end

    local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/" .. ladder_name .. ".txt", true, false)
    dataFile:write(text);
    dataFile:close();
end

local function writeToFile(ladder)
    if writeSelfS then
        -- write file
        text = string.format('%.01f', daysSurvived)
        local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/self_survive.txt", true, false)
        dataFile:write(text)
        dataFile:close()
        writeSelfS = false
    end

    if writeSelfK then
        -- write file
        if  zombieKills > 999 then
            text = string.format("%.1f", zombieKills / 1000) .. 'k'
        else
            text = tostring(zombieKills)
        end
        local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/self_zkills.txt", true, false)
        dataFile:write(text)
        dataFile:close()
        writeSelfK = false
    end

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
            if laddersToWrite[labels[kk]] then
                -- print('DEBUG AMPR write ladder: ',  k, labels[k])
                writeLadder(v, labels[k], k)
                laddersToWrite[labels[kk]] = false
            end
        end

        -- if laddersToWrite[labels[k]] then
        --     print('DEBUG AMPR write ladder: ' .. k)
        --     writeLadder(v, labels[k], k)
        --     laddersToWrite[k] = false
        -- end
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
    if position > 1 then
        list[ladder_label] = list[ladder_label] .. " <LINE>"
    end

    if player_username == username then
        if position > ladderLength then
            list[ladder_label] = list[ladder_label] .. "... <LINE><GREEN>"
        else
            list[ladder_label] = list[ladder_label] .. "<GREEN>"
        end

        if current_ranking[ladder_name] ~= nil and value > 0 and position <= ladderLength then
            if position > current_ranking[ladder_name] then
                onRankChange("down", ladder_label)
            elseif position < current_ranking[ladder_name] then
                onRankChange("up", ladder_label)
            end
        end
        current_ranking[ladder_name] = position
    end

    if ladder_name == "daysSurvived" or ladder_name == "daysSurvivedAbs" then
        list[ladder_label] = list[ladder_label] .. "(" .. position .. ") " .. player_username .. " -> " .. string.format("%." .. 1 .. "f", value)
    else
        list[ladder_label] = list[ladder_label] .. "(" .. position .. ") " .. player_username .. " -> " .. value
    end

    if player_username == username then
        list[ladder_label] = list[ladder_label] .. " <RGB:1,1,1>"
    end
end

local onLadderUpdate = function(module, command, args)
    if module ~= "AshenMPRanking"  or command ~= "LadderUpdate" then
        return
    end

    if args.onlineplayers ~= nil then
        local hour = tonumber(os.date('%H'))
        -- setting hour with timezone setting
        hour = (hour + AshenMPRanking.Options.timezone) % 24
        hour = string.format("%02d", hour)
        local time = hour .. ":" .. os.date('%M')
        AshenMPRanking.mainUI["onlinePlayers"]:setText(getText("UI_OnlinePlayers") .. ": " .. args.onlineplayers)
        AshenMPRanking.mainUI["onlinePlayers"]:setColor(1, 1, 1, 1)
        AshenMPRanking.mainUI["lastupdate"]:setText(getText("UI_LastUpdate") .. ": " .. time)
        AshenMPRanking.mainUI["lastupdate"]:setColor(1, 1, 1, 1)
    end

    local ladder = args.ladder

    local tmpItems = {}
    local renderItems = false
    local tmpPerksItems = {}
    local renderPerksItems = false

    if AshenMPRanking.sandboxSettings.summaryLB then
        tmpItems[labels.summaryLB] = items[labels.summaryLB]
        items[labels.summaryLB] = labels.summaryLB .. " <LINE>"
    end

    for k,v in pairs(ladder) do
        if k == "perkScores" then
            for kk,vv in pairs(v) do
                tmpPerksItems[labels[kk]] = perksItems[labels[kk]]
                perksItems[labels[kk]] = labels[kk] .. " <LINE><LINE>"
            end
        else
            tmpItems[labels[k]] = items[labels[k]]
            items[labels[k]] = labels[k] .. " <LINE><LINE>"
        end
    end

    ladderLength = AshenMPRanking.Options.ladderLength
    
    for i=1,#ladder.daysSurvivedAbs do
        for k,v in pairs(ladder) do
            if k == "perkScores" then
                for kk,vv in pairs(v) do
                    if #vv >= i and (i <= ladderLength or vv[i][1] == username) then
                        updateRankingItems(kk, labels[kk], vv[i][1], i, vv[i][2], perksItems)
                    end

                    if AshenMPRanking.sandboxSettings.summaryLB and i == 1 then
                        items[labels.summaryLB] = items[labels.summaryLB] .. " <LINE>"
                        if username == vv[i][1] then
                            items[labels.summaryLB] = items[labels.summaryLB] .. "<GREEN>"
                        end
                        items[labels.summaryLB] = items[labels.summaryLB] .. labels[kk] .. ": " .. vv[i][1]
                        if username == vv[i][1] then
                            items[labels.summaryLB] = items[labels.summaryLB] .. " <RGB:1,1,1>"
                        end
                    end
                end
            else
                if #v >= i and (i <= ladderLength or v[i][1] == username) then
                    updateRankingItems(k, labels[k], v[i][1], i, v[i][2], items)
                end

                -- if summaryLB and i == 1 add to the list
                if AshenMPRanking.sandboxSettings.summaryLB and i == 1 then
                    items[labels.summaryLB] = items[labels.summaryLB] .. " <LINE>"
                    if username == v[i][1] then
                        items[labels.summaryLB] = items[labels.summaryLB] .. "<GREEN>"
                    end
                    items[labels.summaryLB] = items[labels.summaryLB] .. labels[k] .. ": " .. v[i][1]
                    if username == v[i][1] then
                        items[labels.summaryLB] = items[labels.summaryLB] .. " <RGB:1,1,1>"
                    end
                end
            end
        end
    end

    -- check if there are changes in the ranking
    for k,v in pairs(items) do
        if v ~= tmpItems[k] then
            renderItems = true
            laddersToWrite[k] = true
            -- print('DEBUG AMPR ranking changed: ', k, laddersToWrite[k])
        end
    end

    if renderItems then
        AshenMPRanking.mainUI["list"]:setItems(items)
    end

    -- check if there are changes in the ranking
    for k,v in pairs(perksItems) do
        if v ~= tmpPerksItems[k] then
            renderPerksItems = true
            laddersToWrite[k] = true
            -- print('DEBUG AMPR ranking Perks changed: ', k, laddersToWrite[k])
        end
    end

    if AshenMPRanking.sandboxSettings.perkScores and renderPerksItems then
        AshenMPRanking.mainUI["perksList"]:setItems(perksItems)
    end

    local writingCondition = renderItems or renderPerksItems or writeSelfS or writeSelfK
    -- print('DEBUG AMPR writingCondition', writingCondition, renderItems, renderPerksItems, writeSelfS, writeSelfK)
    if AshenMPRanking.Options.receiveData and writingCondition then
        writeToFile(ladder)
    end
end 

local function onPlayerDeathReset(player)
    local data = {}
    data.username = player:getUsername()
    Events.LevelPerk.Remove(LevelPerkListener)
    sendClientCommand(player, "AshenMPRanking", "PlayerIsDead", data)
end

-- Called on the player to parse its player data and send it to the server every ten (in-game) minutes
local function SendPlayerData()
    local player = getPlayer()
    local username = player:getUsername()
    local forname = player:getDescriptor():getForename()
    local surname = player:getDescriptor():getSurname()

    playerData.username = username
    playerData.steamID = getSteamIDFromUsername(username)
    playerData.charName = forname .. " " .. surname
    playerData.profession = player:getDescriptor():getProfession()
    playerData.isAlive = player:isAlive()
    playerData.isZombie = player:isZombie()
    playerData.zombieKills = player:getZombieKills()
    playerData.survivorKills = player:getSurvivorKills()
    playerData.daysSurvived = player:getHoursSurvived() / 24
    playerData.receiveData = AshenMPRanking.Options.receiveData

    sendClientCommand(player, "AshenMPRanking", "PlayerData", playerData)
end

local function PlayerUpdateGetServerConfigs(player)
    sendClientCommand(player, "AshenMPRanking", "getServerConfig", {})
end

local onServerConfig = function(module, command, sandboxSettings)
    if module ~= "AshenMPRanking" or command ~= "ServerConfigs" then
        return;
    end;
    Events.OnServerCommand.Remove(onServerConfig)
    Events.OnPlayerUpdate.Remove(PlayerUpdateGetServerConfigs)
    
    AshenMPRanking.sandboxSettings = sandboxSettings

    labels.daysSurvived = getText("UI_aliveFor")
    labels.daysSurvivedAbs = getText("UI_aliveForAbs")

    labels.zKills = getText("UI_zKills")
    labels.zKillsAbs = getText("UI_zKillsABS")
    
    if AshenMPRanking.sandboxSettings.sKills then
        labels.sKills = getText("UI_sKills")
        labels.sKillsAbs = getText("UI_sKillsABS")
    end

    if AshenMPRanking.sandboxSettings.perkScores then
        labels.passiv = getText("UI_passiv")
        labels.agility = getText("UI_agility")
        labels.firearm = getText("UI_firearm")
        labels.crafting = getText("UI_crafting")
        labels.combat = getText("UI_combat")
        labels.survivalist = getText("UI_survivalist")
    end

    if AshenMPRanking.sandboxSettings.moreDeaths then
        labels.moreDeaths = getText("UI_moreDeaths")
    end

    if AshenMPRanking.sandboxSettings.lessDeaths then
        labels.lessDeaths = getText("UI_lessDeaths")
    end

    if AshenMPRanking.sandboxSettings.summaryLB then
        labels.summaryLB = getText("UI_summaryLB")
    end
    
    if initUI then
        onCreateUI()
        initUI = false
        Events.OnServerCommand.Add(onLadderUpdate)
    
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
end

Events.OnPlayerUpdate.Add(PlayerUpdateGetServerConfigs)
Events.OnServerCommand.Add(onServerConfig)
Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnCreatePlayer.Add(onCharReset)
