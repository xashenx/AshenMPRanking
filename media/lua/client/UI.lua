AshenMPRanking = AshenMPRanking or {}

local listUI, descUI
local items = {}
local player, username
survLabel = getText("UI_aliveFor")
survAbsLabel = getText("UI_aliveForAbs")
zKillsLabel = getText("UI_zKills")
zKillsAbsLabel = getText("UI_zKillsABS")
sKillsLabel = getText("UI_sKills")
sKillsAbsLabel = getText("UI_sKillsABS")
deathsLabel = getText("UI_deaths")
items[survLabel] = ""
items[survAbsLabel] = ""
items[zKillsLabel] = ""
items[zKillsAbsLabel] = ""
items[sKillsLabel] = ""
items[sKillsAbsLabel] = ""
items[deathsLabel] = ""

current_ranking = {}

-- local function choose(button, args)
--     getPlayer():Say("I accepted this mission !");
--     listUI:close();
-- end

local function openJobDesc(_, item)
    descUI:open()
    descUI:setPositionPixel(listUI:getX() + listUI:getWidth(), listUI:getY())
    descUI["ladderText"]:setText(item)
    -- listUI["ladderText"]:setText(item)
end
    
local function onCreateUI()
    player = getSpecificPlayer(0)
    username = player:getUsername();

    -- List UI
    listUI = NewUI() -- Create UI
    listUI:setTitle(getText("UI_MainWTitle"))
    -- listUI:setWidthPercent(0.1)
    listUI:setWidthPixel(200)
    listUI:setKeyMN(184)
    listUI:setBorderToAllElements(true);
    listUI:addText("onlinePlayers", "", "", "Center")
    listUI:nextLine()
    listUI:addScrollList("list", items); -- Create list
    listUI["list"]:setOnMouseDownFunction(_, openJobDesc)
    -- listUI:addEmpty(_, _, _, 10); -- Margin only for rich text
    -- listUI:addRichText("ladderText", "")
    -- listUI:setLineHeightPercent(0.2)
    -- listUI:addEmpty(_, _, _, 10); -- Margin only for rich text
    -- listUI:nextLine()
    listUI:saveLayout() -- Create window

    -- Description UI
    descUI = NewUI()
    descUI:setTitle(getText("UI_LadderTitle"))
    descUI:isSubUIOf(listUI)
    -- descUI:setWidthPercent(0.1)
    descUI:setWidthPixel(200)

    descUI:addEmpty(_, _, _, 10) -- Margin only for rich text
    descUI:addRichText("ladderText", "")
    descUI:setLineHeightPercent(0.2)
    descUI:addEmpty(_, _, _, 10) -- Margin only for rich text
    descUI:nextLine()

    -- descUI:addButton("b1", "Accept ?", choose);
    descUI:saveLayout()
    descUI:close()
end

local function writeLadder(ladder, label, ladder_name, server_name)
    -- text = label .. "\n\n"
    text = label .. ": "

    -- TODO add an option for the max number of players to show
    for i=1,math.min(#ladder,AshenMPRanking.Options.ladderLength) do
        if i > 1 then
            if i < math.min(#ladder,AshenMPRanking.Options.ladderLength) then
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

    local dataFile = getFileWriter("/AshenMPRanking/" .. server_name .. "/" .. ladder_name .. ".txt", true, false);
    dataFile:write(text);
    dataFile:close();
end

local function writeToFile(ladder)
    local zombieKills = player:getZombieKills()
    local daysSurvived = player:getHoursSurvived() / 24
    -- write file
    text = string.format('%.01f', daysSurvived) .. ' giorni';
    local dataFile = getFileWriter("/AshenMPRanking/" .. ladder.server_name .. "/self_survive.txt", true, false);
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
    local dataFile = getFileWriter("/AshenMPRanking/" .. ladder.server_name .. "/self_zkills.txt", true, false);
    dataFile:write(text);
    dataFile:close();

    -- write ladders
    writeLadder(ladder.daysSurvived, survLabel, 'daysSurvived', ladder.server_name)
    writeLadder(ladder.daysSurvivedAbs, survAbsLabel, 'daysSurvivedAbs', ladder.server_name)
    writeLadder(ladder.zKills, zKillsLabel, 'zKills', ladder.server_name)
    writeLadder(ladder.zKillsAbs, zKillsAbsLabel, 'zKillsAbs', ladder.server_name)
    writeLadder(ladder.sKills, sKillsLabel, 'sKills', ladder.server_name)
    writeLadder(ladder.sKillsAbs, sKillsAbsLabel, 'sKillsAbs', ladder.server_name)
    writeLadder(ladder.deaths, deathsLabel, 'deaths', ladder.server_name)
end

-- executed when a change in the rank of the player is detected
local function onRankChange(movement, ladder_label)
    print("ASPDClient: RankChange update");
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
        items[ladder_label] = items[ladder_label] .. "<GREEN>"
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
    if module ~= "AshenMPRanking" then
        return
    end

    items[survLabel] = survLabel .. " <LINE><LINE>"
    items[survAbsLabel] = survAbsLabel .. " <LINE><LINE>"
    items[zKillsLabel] = zKillsLabel .. " <LINE><LINE>"
    items[zKillsAbsLabel] = zKillsAbsLabel .. " <LINE><LINE>"
    items[sKillsLabel] = sKillsLabel .. " <LINE><LINE>"
    items[sKillsAbsLabel] = sKillsAbsLabel .. " <LINE><LINE>"
    items[deathsLabel] = deathsLabel .. " <LINE><LINE>"

    if command == "LadderUpdate" then
        listUI["onlinePlayers"]:setText(getText("UI_OnlinePlayers") .. ": ".. ladder.onlineplayers)
		for i=1,#ladder.zKills do
            updateRankingItems("daysSurvived", survLabel, ladder.daysSurvived[i][1], i, ladder.daysSurvived[i][2])
            updateRankingItems("daysSurvivedAbs", survAbsLabel, ladder.daysSurvivedAbs[i][1], i, ladder.daysSurvivedAbs[i][2])
            updateRankingItems("zKills", zKillsLabel, ladder.zKills[i][1], i, ladder.zKills[i][2])
            updateRankingItems("zKillsAbs", zKillsAbsLabel, ladder.zKillsAbs[i][1], i, ladder.zKillsAbs[i][2])
            updateRankingItems("sKills", sKillsLabel, ladder.sKills[i][1], i, ladder.sKills[i][2])
            updateRankingItems("sKillsAbs", sKillsAbsLabel, ladder.sKillsAbs[i][1], i, ladder.sKillsAbs[i][2])
            if #ladder.deaths >= i then
                updateRankingItems("deaths", deathsLabel, ladder.deaths[i][1], i, ladder.deaths[i][2])
            end
            -- items[survLabel] = items[survLabel] .. "(" .. i .. ") " .. ladder.daysSurvived[i][1] .. " -> " .. string.format("%." .. 1 .. "f", ladder.daysSurvived[i][2]) .. " <LINE>"
            -- items[survAbsLabel] = items[survAbsLabel] .. "(" .. i .. ") " .. ladder.daysSurvivedAbs[i][1] .. " -> " .. string.format("%." .. 1 .. "f", ladder.daysSurvivedAbs[i][2]) .. " <LINE>"
            -- items[zKillsLabel] = items[zKillsLabel] .. "(" .. i .. ") " .. ladder.zKills[i][1] .. " -> " .. ladder.zKills[i][2] .. " <LINE>"
            -- items[zKillsAbsLabel] = items[zKillsAbsLabel] .. "(" .. i .. ") " .. ladder.zKillsAbs[i][1] .. " -> " .. ladder.zKillsAbs[i][2] .. " <LINE>"
            -- items[sKillsLabel] = items[sKillsLabel] .. "(" .. i .. ") " .. ladder.sKills[i][1] .. " -> " .. ladder.sKills[i][2] .. " <LINE>"
            -- items[sKillsAbsLabel] = items[sKillsAbsLabel] .. "(" .. i .. ") " .. ladder.sKillsAbs[i][1] .. " -> " .. ladder.sKillsAbs[i][2] .. " <LINE>"
            -- items[deathsLabel] = items[deathsLabel] .. "(" .. i .. ") " .. ladder.deaths[i][1] .. " -> " .. ladder.deaths[i][2] .. " <LINE>"
		end
    end

    listUI["list"]:setItems(items)

    if AshenMPRanking.Options.receiveData then
        print('writing data')
        writeToFile(ladder)
    end
end 

local function onPlayerDeathReset(player)
    local data = {};
    data.username = player:getUsername();
    sendClientCommand(player, "AshenMPRanking", "PlayerIsDead", data);
end

Events.OnServerCommand.Add(onLadderUpdate)
Events.OnCreateUI.Add(onCreateUI)
Events.OnPlayerDeath.Add(onPlayerDeathReset)