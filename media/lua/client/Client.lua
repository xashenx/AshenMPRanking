AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
if isServer() then return end;

-- getGameTime():getModData().test = getGameTime():getModData().test or {}
local listUI, descUI
local items = {}
local player, username
local ladderLength = 5
local labels = {}
local current_ranking = {}

local initUI = true

local function openLadderDesc(_, item)
    descUI:open()
    descUI:setPositionPixel(listUI:getX() + listUI:getWidth(), listUI:getY())
    descUI["ladderText"]:setText(item)
    -- listUI["ladderText"]:setText(item)
end
    
local function onCreateUI()
    player = getSpecificPlayer(0)
    username = player:getUsername()

    -- List UI
    listUI = NewUI() -- Create UI
    -- listUI:setTitle(getText("UI_MainWTitle"))
    listUI:setTitle(AshenMPRanking.sandboxSettings.mainUiTitle)
    -- listUI:setWidthPercent(0.1)
    listUI:setWidthPixel(250)
    listUI:setKeyMN(157)
    listUI:setBorderToAllElements(true)
    listUI:addText("onlinePlayers", "", "", "Center")
    listUI:nextLine()
    listUI:addScrollList("list", items); -- Create list
    listUI["list"]:setOnMouseDownFunction(_, openLadderDesc)
    -- listUI:addEmpty(_, _, _, 10); -- Margin only for rich text
    -- listUI:addRichText("ladderText", "")
    -- listUI:setLineHeightPercent(0.2)
    -- listUI:addEmpty(_, _, _, 10); -- Margin only for rich text
    -- listUI:nextLine()
    listUI:saveLayout() -- Create window
    listUI:setPositionPercent(0.1, 0.1)

    -- Description UI
    descUI = NewUI()
    descUI:setTitle(getText("UI_LadderTitle"))
    descUI:isSubUIOf(listUI)
    -- descUI:setWidthPercent(0.1)
    descUI:setWidthPixel(250)

    descUI:addEmpty(_, _, _, 10) -- Margin only for rich text
    descUI:addRichText("ladderText", "")
    descUI:setLineHeightPercent(0.2)
    descUI:addEmpty(_, _, _, 10) -- Margin only for rich text
    descUI:nextLine()

    -- descUI:addButton("b1", "Accept ?", choose);
    descUI:saveLayout()
    descUI:close()
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

    local dataFile = getFileWriter("/AshenMPRanking/" .. AshenMPRanking.sandboxSettings.server_name .. "/" .. ladder_name .. ".txt", true, false);
    dataFile:write(text);
    dataFile:close();
end

local function writeToFile(ladder)
    local zombieKills = player:getZombieKills()
    local daysSurvived = player:getHoursSurvived() / 24
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
        if k ~= "onlineplayers" then
            writeLadder(v, labels[k], k)
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

        if current_ranking[ladder_name] ~= nil then
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

local onLadderUpdate = function(module, command, ladder)
    if module ~= "AshenMPRanking"  or command ~= "LadderUpdate" then
        return
    end

    for k,v in pairs(ladder) do
        if k ~= "onlineplayers" then
            items[labels[k]] = labels[k] .. " <LINE><LINE>"
        end
    end

    ladderLength = tonumber(AshenMPRanking.Options.ladderLength)
    if ladderLength == 1 then ladderLength = 3 elseif ladderLength == 2 then ladderLength = 5 else ladderLength = 10 end

    listUI["onlinePlayers"]:setText(getText("UI_OnlinePlayers") .. ": " .. ladder.onlineplayers)
    for i=1,#ladder.daysSurvivedAbs do
        for k,v in pairs(ladder) do
            if k ~= "onlineplayers" then
                -- if the count of elements in v is greater than 0 then
                if #v >= i and (i <= ladderLength or v[i][1] == username) then
                    updateRankingItems(k, labels[k], v[i][1], i, v[i][2])
                end
            end
        end
    end

    listUI["list"]:setItems(items)

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
    end
    Events.OnServerCommand.Add(onLadderUpdate)
end

Events.OnPlayerUpdate.Add(PlayerUpdateGetServerConfigs)
Events.OnServerCommand.Add(onServerConfig)
Events.EveryTenMinutes.Add(SendPlayerData)
Events.OnPlayerDeath.Add(SendPlayerData)
Events.OnPlayerDeath.Add(onPlayerDeathReset)
