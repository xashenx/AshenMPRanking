if isServer() then return end;
AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.textureOff = getTexture("media/textures/icon_off.png")
AshenMPRanking.textureOn = getTexture("media/textures/icon_on.png")
AshenMPRanking.mainUI = {}
AshenMPRanking.descUI = {}

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

PERKS_PASSIV = {"Fitness", "Strength"}
PERKS_AGILITY = {"Sprinting", "Lightfoot", "Nimble", "Sneak"}
PERKS_FIREARM = {"Aiming", "Reloading"}
PERKS_COMBAT = {"Blunt", "Axe", "Spear", "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt"}
PERKS_CRAFTING = {"Cooking", "Woodwork", "Farming", "Electricity", "Blacksmith", "MetalWelding", "Mechanics", "Tailoring", "Melting", "Doctor", "Mansonry"}
PERKS_SURVIVALIST = {"Fishing", "Trapping", "PlantScavenging"}
PERKS_OTHERPERKS = {}

local function openLadderDesc(_, item)
    local title
    local foundSelf = false
    ladderLength = AshenMPRanking.Options.ladderLength

    AshenMPRanking.descUI:open()
    AshenMPRanking.descUI:setPositionPixel(AshenMPRanking.mainUI:getX() + AshenMPRanking.mainUI:getWidth(), AshenMPRanking.mainUI:getY())
    
    i = 1
    for k,v in pairs(item) do
        if i > ladderLength and item.title ~= labels.summaryLB then
            if not foundSelf then
                AshenMPRanking.descUI["position_" .. i]:setText("...")
                AshenMPRanking.descUI["score_" .. i]:setText("")
                AshenMPRanking.descUI["position_" .. i+1]:setText(tostring(item.player.position))
                if title == labels.daysSurvived or title == labels.daysSurvivedAbs  then
                    local text = item.player.user .. " (" .. string.format("%.1f", item.player.score) .. ")"
                    AshenMPRanking.descUI["score_" .. i+1]:setText(text)
                elseif title == labels.lrm or tostring(v.position) == labels.lrm then
                    local value = item.player.score * 1000
                    local text = item.player.user .. " (" .. string.format("%.0f", value) .. ")"
                    AshenMPRanking.descUI["score_" .. i+1]:setText(text)
                else
                    local text = item.player.user .. " (" .. tostring(item.player.score) .. ")"
                    AshenMPRanking.descUI["score_" .. i+1]:setText(text)
                end
                AshenMPRanking.descUI["position_" .. i+1]:setColor(1, 1, 0, 0)
                AshenMPRanking.descUI["score_" .. i+1]:setColor(1, 1, 0, 0)
                i = i + 2
            end

            break
        end

        if k ~= 'title' then
            AshenMPRanking.descUI["position_" .. i]:setText(tostring(v.position))
            if title == labels.daysSurvived or title == labels.daysSurvivedAbs  then
                local text = v.user .. " (" .. string.format("%.1f", v.score) .. ")"
                AshenMPRanking.descUI["score_" .. i]:setText(text)
            elseif tostring(v.position) == labels.daysSurvived or tostring(v.position) == labels.daysSurvivedAbs then
                local text = v.user .. " (" .. string.format("%.1f", v.score) .. ")"
                AshenMPRanking.descUI["score_" .. i]:setText(text)
            elseif title == labels.lrm or tostring(v.position) == labels.lrm then
                local value = v.score * 1000
                local text = v.user .. " (" .. string.format("%.0f", value) .. ")"
                AshenMPRanking.descUI["score_" .. i]:setText(text)
            else
                local text = v.user .. " (" .. tostring(v.score) .. ")"
                AshenMPRanking.descUI["score_" .. i]:setText(text)
            end
            
            if v.user == username then
                AshenMPRanking.descUI["position_" .. i]:setColor(1, 0, 1, 0.2)
                AshenMPRanking.descUI["score_" .. i]:setColor(1, 0, 1, 0.2)
                foundSelf = true
            else
                AshenMPRanking.descUI["position_" .. i]:setColor(1, 1, 1, 1)
                AshenMPRanking.descUI["score_" .. i]:setColor(1, 1, 1, 1)
            end
            i = i + 1
        else
            title = v
            AshenMPRanking.descUI:setTitle(title)
        end
    end

    -- for j = i to 15 set text of position, user and score to ""
    for j = i, 15 do
        AshenMPRanking.descUI["position_" .. j]:setText("")
        AshenMPRanking.descUI["score_" .. j]:setText("")
    end
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
    -- checking the extended survival time
    local tmpSurvive = player:getTimeSurvived()
    if tmpSurvive ~= timeSurvived then
        timeSurvived = tmpSurvive
        AshenMPRanking.mainUI["self_survive"]:setText(timeSurvived)

        if AshenMPRanking.Options.receiveData then
            -- writing to file
            local dataFile = getFileWriter("/AshenMPRanking/self_survive.txt", true, false)
            dataFile:write(timeSurvived)
            dataFile:close()
        end
    end
end

local function refreshSelfKills()
    if zombieKills ~= player:getZombieKills() then
        zombieKills = player:getZombieKills()

        if zombieKills > 0 then
            AshenMPRanking.mainUI["self_zkills"]:setText(getText("UI_Self_Zkills") .. ": " .. zombieKills)
        else
            AshenMPRanking.mainUI["self_zkills"]:setText(getText("UI_Self_0ZKills"))
        end
        
        if AshenMPRanking.Options.receiveData then
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
    -- add levels of PERKS_PASIV to playerData.perkScores.passiv
    playerData.perkScores.passiv = getPerkCategoryScore(PERKS_PASSIV)

    -- add levels of PERKS_AGILITY to playerData.perkScores.agility
    playerData.perkScores.agility = getPerkCategoryScore(PERKS_AGILITY)

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

    -- print('perklevelup', perk, parent_name, perkLevel)
    if AshenMPRanking.sandboxSettings.otherPerks then
        if playerData.perkScores[parent_name] ~= nil then
            playerData.perkScores[parent_name] = playerData.perkScores[parent_name] + 1
        else
            playerData.perkScores.otherPerks = playerData.perkScores.otherPerks + 1
        end
    end
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
    -- AshenMPRanking.mainUI:addText("lastupdate", getText("UI_WaitingForUpdate"), "", "Center")
    -- AshenMPRanking.mainUI["lastupdate"]:setColor(1, 1, 1, 0)
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
    
    -- calculate the proper height for scrolllists
    -- base is calculated with dayS, zKill and relative Absolutes
    local height = BASE_HEIGHT * 4
    if AshenMPRanking.sandboxSettings.sKills then
        height = height + BASE_HEIGHT * 2

        if AshenMPRanking.sandboxSettings.summaryLB then
            height = height + BASE_HEIGHT
        end

        if AshenMPRanking.sandboxSettings.killsPerDay then
            height = height + BASE_HEIGHT
        end        

        if AshenMPRanking.sandboxSettings.moreDeaths then
            height = height + BASE_HEIGHT
        end

        if AshenMPRanking.sandboxSettings.lessDeaths then
            height = height + BASE_HEIGHT
        end
    elseif AshenMPRanking.sandboxSettings.moreDeaths or AshenMPRanking.sandboxSettings.lessDeaths then
        if AshenMPRanking.sandboxSettings.summaryLB then
            height = height + BASE_HEIGHT
        end

        if AshenMPRanking.sandboxSettings.killsPerDay then
            height = height + BASE_HEIGHT
        end

        if AshenMPRanking.sandboxSettings.moreDeaths then
            height = height + BASE_HEIGHT
        end

        if AshenMPRanking.sandboxSettings.lessDeaths then
            height = height + BASE_HEIGHT
        end
    elseif AshenMPRanking.sandboxSettings.perkScores then
        height = BASE_HEIGHT * 6
    end

    -- default scrollList
    AshenMPRanking.mainUI:addScrollList("list", items); -- Create list
    AshenMPRanking.mainUI["list"]:setOnMouseDownFunction(_, openLadderDesc)
    AshenMPRanking.mainUI:setDefaultLineHeightPixel(height)

    if AshenMPRanking.sandboxSettings.perkScores then
        -- perks scrollList
        AshenMPRanking.mainUI:addScrollList("perksList", perksItems); -- Create list
        AshenMPRanking.mainUI["perksList"]:setOnMouseDownFunction(_, openLadderDesc)
        AshenMPRanking.mainUI:setLineHeightPixel(height)
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
    
    for i = 1, AshenMPRanking.sandboxSettings.numLadders do
        AshenMPRanking.descUI:addText("position_" .. i, "", "", "Center")
        AshenMPRanking.descUI:addText("score_" .. i, "", "", "Center")
        AshenMPRanking.descUI:nextLine()
    end
    AshenMPRanking.descUI:saveLayout()
    AshenMPRanking.descUI:close()
    
    refreshSelfSurvived()
    refreshSelfKills()
    Events.EveryHours.Add(refreshSelfSurvived)
    Events.OnPlayerUpdate.Add(refreshSelfKills)

    ladderLength = AshenMPRanking.Options.ladderLength
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
        elseif ladder_name == "lrm" then
            value = ladder[i][2] * 1000
            text = text .. "#" .. i .. " " .. ladder[i][1] .. " (" .. string.format("%.0f", value) .. ")"
        else
            text = text .. "#" .. i .. " " .. ladder[i][1] .. " (" .. ladder[i][2] .. ")"
        end
    end

    local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/" .. ladder_name .. ".txt", true, false)
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

    if player_username == username then
        if position > ladderLength then
            list[ladder_label]["player"] = {}
            list[ladder_label]["player"].position = position
            list[ladder_label]["player"].user = player_username
            list[ladder_label]["player"].score = value
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

    for k,v in pairs(ladder) do
        if k == "perkScores" then
            for kk,vv in pairs(v) do
                tmpPerksItems[labels[kk]] = perksItems[labels[kk]]
                -- perksItems[labels[kk]] = labels[kk] .. " <LINE><LINE>"
                perksItems[labels[kk]] = {}
                perksItems[labels[kk]].title = labels[kk]
            end
        else
            tmpItems[labels[k]] = items[labels[k]]
            -- items[labels[k]] = labels[k] .. " <LINE><LINE>"
            items[labels[k]] = {}
            items[labels[k]].title = labels[k]
        end
    end
    
    for i=1,#ladder.daysSurvivedAbs do
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

    if renderItems then
        AshenMPRanking.mainUI["list"]:setItems(items)
    end

    renderPerksItems = checkForChanges(perksItems, tmpPerksItems)
    -- print('DEBUG AMPR renderPerksItems: ', renderPerksItems)

    if AshenMPRanking.sandboxSettings.perkScores and renderPerksItems then
        AshenMPRanking.mainUI["perksList"]:setItems(perksItems)
    end

    local writingCondition = renderItems or renderPerksItems
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
    -- get the steamid of the player
    playerData.steamID = player:getSteamID()
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
    if module ~= "AshenMPRanking" or command ~= "ServerConfigs" or not initVars then
        return
    end
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

    -- LaResistenzaMarket
    if AshenMPRanking.sandboxSettings.lrm then
        labels.lrm = "LaResistenzaMarket"
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

    initVars = false
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

    initVars = true
    Events.OnPlayerUpdate.Add(PlayerUpdateGetServerConfigs)
    Events.OnServerCommand.Add(onServerConfig)
end

Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnCreatePlayer.Add(onCharReset)
