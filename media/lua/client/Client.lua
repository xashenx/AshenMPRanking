if isServer() then return end;
AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.textureOff = getTexture("media/textures/icon_off.png")
AshenMPRanking.textureOn = getTexture("media/textures/icon_on.png")
AshenMPRanking.mainUI = {}
AshenMPRanking.descUI = {}

-- getGameTime():getModData().test = getGameTime():getModData().test or {}
local items = {}
local player, username
local ladderLength = 5
local labels = {}
local current_ranking = {}

local initUI = true
local toolbarButton = {}

-- player stats
local zombieKills = 0
local daysSurvived = 0

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

local function createToolbarButton()
    toolbarButton = {}
	toolbarButton = ISButton:new(0, ISEquippedItem.instance.movableBtn:getY() + ISEquippedItem.instance.movableBtn:getHeight() + 200, 50, 50, "", nil, showWindowToolbar)
	toolbarButton:setImage(AshenMPRanking.textureOff)
	toolbarButton:setDisplayBackground(false)
	toolbarButton.borderColor = {r=1, g=1, b=1, a=0.1}

	ISEquippedItem.instance:addChild(toolbarButton)
	ISEquippedItem.instance:setHeight(math.max(ISEquippedItem.instance:getHeight(), toolbarButton:getY() + 400))
end

local function refreshSelfSurvived()
    daysSurvived = player:getHoursSurvived() / 24
    daysSurvived = string.format("%.1f", daysSurvived)
    AshenMPRanking.mainUI["self_survive"]:setText(getText("UI_Self_Survived") .. ": " .. daysSurvived .. " " .. getText("UI_days"))
end

local function refreshSelfKills()
    zombieKills = player:getZombieKills()
    AshenMPRanking.mainUI["self_zkills"]:setText(getText("UI_Self_Zkills") .. ": " .. zombieKills)
end

local function onCreateUI()
    player = getSpecificPlayer(0)
    username = player:getUsername()

    -- List UI
    AshenMPRanking.mainUI = NewUI() -- Create UI
    -- AshenMPRanking.mainUI:setTitle(getText("UI_MainWTitle"))
    AshenMPRanking.mainUI:setTitle(AshenMPRanking.sandboxSettings.mainUiTitle)
    -- AshenMPRanking.mainUI:setWidthPercent(0.1)
    AshenMPRanking.mainUI:setWidthPixel(250)
    AshenMPRanking.mainUI:setKeyMN(157)
    AshenMPRanking.mainUI:addText("self_survive", "", "", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("self_zkills", "", "", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("onlinePlayers", "", "", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("lastupdate", "", "", "Center")
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addText("LaddersLabel", getText("UI_LaddersLabel"), "Large", "Center")
    AshenMPRanking.mainUI["LaddersLabel"]:setColor(1, 1, 0, 0)
    AshenMPRanking.mainUI:setLineHeightPixel(40)
    AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:addScrollList("list", items); -- Create list
    AshenMPRanking.mainUI["list"]:setOnMouseDownFunction(_, openLadderDesc)
    -- AshenMPRanking.mainUI:addEmpty(_, _, _, 10); -- Margin only for rich text
    -- AshenMPRanking.mainUI:addRichText("ladderText", "")
    -- AshenMPRanking.mainUI:setLineHeightPercent(0.2)
    -- AshenMPRanking.mainUI:addEmpty(_, _, _, 10); -- Margin only for rich text
    -- AshenMPRanking.mainUI:nextLine()
    AshenMPRanking.mainUI:saveLayout() -- Create window
    AshenMPRanking.mainUI:setPositionPercent(0.1, 0.1)
    AshenMPRanking.mainUI:setBorderToAllElements(true)
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
    
    -- creating toolbar button
    createToolbarButton()
    -- starting refreshing self stats
    refreshSelfSurvived()
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
    -- write file
    text = string.format('%.01f', daysSurvived) .. ' ' .. getText("UI_days");
    local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/self_survive.txt", true, false);
    dataFile:write(text);
    dataFile:close();
    -- write file
    if  zombieKills > 0 then
        if  zombieKills > 999 then
            text = string.format("%.1f", zombieKills / 1000) .. 'k kills';
        else
            text = zombieKills .. ' kills';
        end
    else
        text = '-';
    end
    local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/self_zkills.txt", true, false);
    dataFile:write(text);
    dataFile:close();

    -- write ladders
    for k,v in pairs(ladder) do
        -- if k ~= "onlineplayers" then
        --     writeLadder(v, labels[k], k)
        -- end
        writeLadder(v, labels[k], k)
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

local function updateRankingItems(ladder_name, ladder_label, player_username, position, value)
    if position > 1 then
        items[ladder_label] = items[ladder_label] .. " <LINE>"
    end

    if player_username == username then
        if position > ladderLength then
            items[ladder_label] = items[ladder_label] .. "... <LINE><GREEN>"
        else
            items[ladder_label] = items[ladder_label] .. "<GREEN>"
        end

        if current_ranking[ladder_name] ~= nil and value > 0 then
            if position > current_ranking[ladder_name] then
                onRankChange("down", ladder_label)
            elseif position < current_ranking[ladder_name] then
                onRankChange("up", ladder_label)
            end
        end
        current_ranking[ladder_name] = position
    end

    if ladder_name == "daysSurvived" or ladder_name == "daysSurvivedAbs" then
        items[ladder_label] = items[ladder_label] .. "(" .. position .. ") " .. player_username .. " -> " .. string.format("%." .. 1 .. "f", value)
    else
        items[ladder_label] = items[ladder_label] .. "(" .. position .. ") " .. player_username .. " -> " .. value
    end

    if player_username == username then
        items[ladder_label] = items[ladder_label] .. " <RGB:1,1,1>"
    end
    
end

local onLadderUpdate = function(module, command, args)
    if module ~= "AshenMPRanking"  or command ~= "LadderUpdate" then
        return
    end

    local ladder = args.ladder

    for k,v in pairs(ladder) do
        -- if k ~= "onlineplayers" then
        --     items[labels[k]] = labels[k] .. " <LINE><LINE>"
        -- end
        items[labels[k]] = labels[k] .. " <LINE><LINE>"
    end

    ladderLength = tonumber(AshenMPRanking.Options.ladderLength)
    if ladderLength == 1 then ladderLength = 3 elseif ladderLength == 2 then ladderLength = 5 else ladderLength = 10 end
    
    if args.onlineplayers ~= nil then
        local hour = tonumber(os.date('%H'))
        -- setting hour with timezone setting
        hour = (hour + AshenMPRanking.Options.timezone) % 24
        hour = string.format("%02d", hour)
        local time = hour .. ":" .. os.date('%M')
        AshenMPRanking.mainUI["onlinePlayers"]:setText(getText("UI_OnlinePlayers") .. ": " .. args.onlineplayers)
        AshenMPRanking.mainUI["lastupdate"]:setText(getText("UI_LastUpdate") .. ": " .. time)
    end
    for i=1,#ladder.daysSurvivedAbs do
        for k,v in pairs(ladder) do
            -- if k ~= "onlineplayers" then
            --     -- if the count of elements in v is greater than 0 then
            --     if #v >= i and (i <= ladderLength or v[i][1] == username) then
            --         updateRankingItems(k, labels[k], v[i][1], i, v[i][2])
            --     end
            -- end
            if #v >= i and (i <= ladderLength or v[i][1] == username) then
                updateRankingItems(k, labels[k], v[i][1], i, v[i][2])
            end
        end
    end

    AshenMPRanking.mainUI["list"]:setItems(items)

    if AshenMPRanking.Options.receiveData then
        writeToFile(ladder)
    end
end 

local function onPlayerDeathReset(player)
    local data = {};
    data.username = player:getUsername();
    sendClientCommand(player, "AshenMPRanking", "PlayerIsDead", data);
end

-- Called on the player to parse its player data and send it to the server every ten (in-game) minutes
local function SendPlayerData()
    local player = getPlayer()
    local username = player:getUsername();
    local forname = player:getDescriptor():getForename();
    local surname = player:getDescriptor():getSurname();
    
    local playerData = {}

    playerData.username = username;
    playerData.steamID = getSteamIDFromUsername(username);
    playerData.charName = forname .. " " .. surname;
    playerData.profession = player:getDescriptor():getProfession();
    playerData.isAlive = player:isAlive();
    playerData.isZombie = player:isZombie();
    playerData.zombieKills = player:getZombieKills();
    playerData.survivorKills = player:getSurvivorKills();
    playerData.daysSurvived = player:getHoursSurvived() / 24;
    playerData.receiveData = AshenMPRanking.Options.receiveData;

    sendClientCommand(player, "AshenMPRanking", "PlayerData", playerData);
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

    labels.deaths = getText("UI_deaths")
    
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
-- Events.EveryTenMinutes.Add(SendPlayerData)
Events.OnPlayerDeath.Add(SendPlayerData)
Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnCreatePlayer.Add(createToolbarButton)
