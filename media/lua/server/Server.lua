if not isServer() then return end
AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.server = {}

local parsedPlayers = 0
local write_required = false
local ladder = {}
local oLadder = {}
local streamers = {}
local configs = {}
local lastUpdate = {}
local miscellaneous = {}
local lastWrite = 0

-- function fetchSandboxVars()
AshenMPRanking.server.fetchSandboxVars = function()
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

            -- insert in table the toke
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

    -- LaResistenzaMarket setting
    AshenMPRanking.sandboxSettings.lrm = false
end

local function sort_my_ladder(ladder, inverse, daysSurvived)
    inverse = inverse or false
    daysSurvived = daysSurvived or {}
    ordered_ladder={}
    for v,k in pairs(ladder) do
        local guard = daysSurvived[v] or 0
        if not inverse or (guard > 4 or k > 0) then
            if #ordered_ladder > 0 then
                for i=1,#ordered_ladder do
                    if inverse then
                        if k > ordered_ladder[#ordered_ladder -i+1][2] then
                            table.insert(ordered_ladder,#ordered_ladder-i+2,{v,k})
                            break
                        end
                    elseif k > 0 then
                        if k < ordered_ladder[#ordered_ladder -i+1][2] then
                            table.insert(ordered_ladder,#ordered_ladder-i+2,{v,k})
                            break
                        end
                    end

                    if i==#ordered_ladder and (inverse or k > 0)then
                        table.insert(ordered_ladder,1,{v,k})
                    end
                end
                
            else
                ordered_ladder[1]={v,k}
            end
        elseif daysSurvived[v] == nil then
            print('AMPR debug NIL daysSurvived', v, k, daysSurvived[v])
        end
        -- print(v,k)
    end

    return ordered_ladder
end

local function sort_ladders()
    for k,v in pairs(ladder) do
        if k == "perkScores" then
            for kk,vv in pairs(v) do
                oLadder[k][kk] = sort_my_ladder(vv, false, ladder.daysSurvived)
            end
        else
            if k ~= "deaths" then
                oLadder[k] = sort_my_ladder(v, false, ladder.daysSurvivedAbs)
            else
                if AshenMPRanking.sandboxSettings.moreDeaths then
                    oLadder.moreDeaths = sort_my_ladder(v, false, ladder.daysSurvivedAbs)
                end
                if AshenMPRanking.sandboxSettings.lessDeaths then
                    oLadder.lessDeaths = sort_my_ladder(v, true, ladder.daysSurvivedAbs)
                end
            end
        end
    end
end

-- load last stats from file on load
local function loadFromFile()
    -- reading current run ladder
    local file = "/AshenMPRanking/" .. getServerName() .. "/ladder.csv"
    local dataFile = getFileReader(file, false)
    if dataFile == nil then
        print("No ladder file found, the file will be created as soon as the first player connects")
        return
    end

    local stats = {
                username = 1,
                daysSurvived = 2,
                daysSurvivedAbs = 3,
                zKills = 4,
                zKillsAbs = 5,
                sKills = 6,
                sKillsTot = 7,
                deaths = 8,
                updated = 9,
                passiv = 10,
                agility = 11,
                firearm =  12,
                crafting = 13,
                combat = 14, 
                survivalist = 15,
                otherPerks = 16,
                lrm = 17,
                killsPerDay = 18,
                zKillsTot = 19,
        }
    
    -- get number of elements of stats
    local statsSize = 0
    for k,v in pairs(stats) do
        statsSize = statsSize + 1
    end

    AshenMPRanking.sandboxSettings.numLadders = statsSize
    line = dataFile:readLine()
    
    -- print("AMPR DEBUG: Loading ladder from file")
    while line ~= nil do
        local username
        local player_stats = {}

        for k,v in pairs(stats) do
            -- insert v in table with value 0
            player_stats[v] = {}
            player_stats[v].description = k
            player_stats[v].value = 0
        end
        
        count = 1
        for stat in string.gmatch(line, "[^;]+") do
            if player_stats[count].description == "username" then
                player_stats[count].value = stat
            else
                player_stats[count].value = tonumber(stat)
            end
                
            count = count + 1
        end

        username = player_stats[stats.username].value
        -- print("AMPR DEBUG parsing stats for player: ", username)

        if player_stats[stats.updated].value ~= nil then
            lastUpdate[username] = player_stats[stats.updated].value
            diff = os.difftime(os.time(), lastUpdate[username]) / (24 * 60 * 60)
        end
        
        if diff < AshenMPRanking.sandboxSettings.inactivityPurgeTime then
            ladder.daysSurvived[username] = player_stats[stats.daysSurvived].value
            ladder.daysSurvivedAbs[username] = player_stats[stats.daysSurvivedAbs].value
            
            ladder.zKills[username] = player_stats[stats.zKills].value
            ladder.zKillsAbs[username] = player_stats[stats.zKillsAbs].value
            ladder.zKillsTot[username] = player_stats[stats.zKillsTot].value
            
            if AshenMPRanking.sandboxSettings.killsPerDay then
                ladder.killsPerDay[username] = player_stats[stats.killsPerDay].value
            end

            if AshenMPRanking.sandboxSettings.sKills then
                ladder.sKills[username] = player_stats[stats.sKills].value
                ladder.sKillsTot[username] = player_stats[stats.sKillsTot].value
            end
            
            if AshenMPRanking.sandboxSettings.perkScores then
                ladder.perkScores.passiv[username] = player_stats[stats.passiv].value
                ladder.perkScores.agility[username] = player_stats[stats.agility].value
                ladder.perkScores.firearm[username] = player_stats[stats.firearm].value
                ladder.perkScores.crafting[username] = player_stats[stats.crafting].value
                ladder.perkScores.combat[username] = player_stats[stats.combat].value
                ladder.perkScores.survivalist[username] = player_stats[stats.survivalist].value
                if AshenMPRanking.sandboxSettings.otherPerks then
                    ladder.perkScores.otherPerks[username] = player_stats[stats.otherPerks].value
                end
                -- LaResistenzaMarket
                if AshenMPRanking.sandboxSettings.lrm then
                    ladder.perkScores.lrm[username] = player_stats[stats.lrm].value
                end
            end
            
            ladder.deaths[username] = player_stats[stats.deaths].value
        else
            -- dropping player for inactiviti, printing in log
            print("dropping player " .. username .. " for inactivity: " .. string.format("%.0f", diff) .. " days " .. lastUpdate[username])
        end
        line = dataFile:readLine()
    end
    dataFile:close()

    -- set lastWrite to now
    lastWrite = os.time()

    -- sort ladders
    sort_ladders()
end

-- Parse player data and save it to a .csv file inside Lua/ServerPlayersData/ folder
local function SaveToFile()
    -- write current run csv file
    local dataFile = getFileWriter("/AshenMPRanking/" .. getServerName() .. "/ladder.csv", true, false)

    text = ""
    local counter = 0
    for k,v in pairs(ladder.daysSurvived) do
        -- print('scrivo ' .. k)
        if counter ~= 0 then
            text = text .. "\n" .. k
        else
            text = k
        end

        text = text .. ";" .. ladder.daysSurvived[k]
        text = text .. ";" .. ladder.daysSurvivedAbs[k]
        text = text .. ";" .. ladder.zKills[k]
        text = text .. ";" .. ladder.zKillsAbs[k]
        
        if AshenMPRanking.sandboxSettings.sKills then
            text = text .. ";" .. ladder.sKills[k]
            text = text .. ";" .. ladder.sKillsTot[k]
        else
            text = text .. ";" .. 0
            text = text .. ";" .. 0
        end
        
        text = text .. ";" .. ladder.deaths[k]
        text = text .. ";" .. lastUpdate[k]
        
        if AshenMPRanking.sandboxSettings.perkScores then
            text = text .. ";" .. ladder.perkScores.passiv[k]
            text = text .. ";" .. ladder.perkScores.agility[k]
            text = text .. ";" .. ladder.perkScores.firearm[k]
            text = text .. ";" .. ladder.perkScores.crafting[k]
            text = text .. ";" .. ladder.perkScores.combat[k]
            text = text .. ";" .. ladder.perkScores.survivalist[k]
            if AshenMPRanking.sandboxSettings.otherPerks then
                text = text .. ";" .. ladder.perkScores.otherPerks[k]
            else
                text = text .. ";" .. 0
            end
            if AshenMPRanking.sandboxSettings.lrm then
                text = text .. ";" .. ladder.perkScores.lrm[k]
            else
                text = text .. ";" .. 0
            end
        else
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
        end
        
        if AshenMPRanking.sandboxSettings.killsPerDay then
            text = text .. ";" .. ladder.killsPerDay[k]
        else
            text = text .. ";" .. 0
        end

        text = text .. ";" .. ladder.zKillsTot[k]
        counter = counter + 1
    end
    dataFile:write(text)
    dataFile:close()

    -- set lastWrite time
    lastWrite = os.time()
end

local function initServer()
    AshenMPRanking.server.fetchSandboxVars()

    ladder.daysSurvived = {}
    oLadder.daysSurvived = {}

    ladder.daysSurvivedAbs = {}
    oLadder.daysSurvivedAbs = {}

    ladder.zKills = {}
    oLadder.zKills = {}

    ladder.zKillsAbs = {}
    oLadder.zKillsAbs = {}

    ladder.zKillsTot = {}
    oLadder.zKillsTot = {}

    if AshenMPRanking.sandboxSettings.killsPerDay then
        ladder.killsPerDay = {}
        oLadder.killsPerDay = {}
    end

    if AshenMPRanking.sandboxSettings.sKills then
        ladder.sKills = {}
        oLadder.sKills = {}
        ladder.sKillsTot = {}
        oLadder.sKillsTot = {}
    end
    
    ladder.deaths = {}
    if AshenMPRanking.sandboxSettings.moreDeaths then
        oLadder.moreDeaths = {}
    end
    if AshenMPRanking.sandboxSettings.lessDeaths then
        oLadder.lessDeaths = {}
    end

    if AshenMPRanking.sandboxSettings.perkScores then
        ladder.perkScores = {}
        ladder.perkScores.passiv = {}
        ladder.perkScores.agility = {}
        ladder.perkScores.firearm = {}
        ladder.perkScores.crafting = {}
        ladder.perkScores.combat = {}
        ladder.perkScores.survivalist = {}
        oLadder.perkScores = {}
        oLadder.perkScores.passiv = {}
        oLadder.perkScores.agility = {}
        oLadder.perkScores.firearm = {}
        oLadder.perkScores.crafting = {}
        oLadder.perkScores.combat = {}
        oLadder.perkScores.survivalist = {}
        if AshenMPRanking.sandboxSettings.otherPerks then
            ladder.perkScores.otherPerks = {}
            oLadder.perkScores.otherPerks = {}
        end
        -- ladder for LaResistenzaMarket
        if getGameTime():getModData().LRMPlayerInventory ~= nil then
            ladder.perkScores.lrm = {}
            oLadder.perkScores.lrm = {}
            AshenMPRanking.sandboxSettings.lrm = true
        end
    end

    AshenMPRanking.sandboxSettings.server_name = getServerName()

    loadFromFile()
    SaveToFile()
end

-- executed when a client(player) sends its information to the server
local function onPlayerData(player, playerData)
    parsedPlayers = parsedPlayers + 1
    local username = playerData.username
    if playerData.isAlive and player:getAccessLevel() == "None" then
        if ladder.daysSurvivedAbs[username] == nil then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived or 0
            ladder.zKillsAbs[username] = playerData.zombieKills or 0
            if AshenMPRanking.sandboxSettings.sKills then
                ladder.sKillsTot[username] = playerData.survivorKills or 0
            end
            ladder.zKillsTot[username] = playerData.zombieKills or 0
            ladder.deaths[username] = 0
        end

        ladder.daysSurvived[username] = playerData.daysSurvived or 0
        if playerData.daysSurvived > ladder.daysSurvivedAbs[username] then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived or 0
        end

        ladder.zKills[username] = ladder.zKills[username] or 0

        if playerData.zombieKills > ladder.zKills[username] then
            if playerData.zombieKills > ladder.zKillsTot[username] then
                ladder.zKillsTot[username] = playerData.zombieKills
            else
                ladder.zKillsTot[username] = ladder.zKillsTot[username] + playerData.zombieKills - ladder.zKills[username]
            end
        end

        ladder.zKills[username] = playerData.zombieKills or 0
        if playerData.zombieKills > ladder.zKillsAbs[username] then
            ladder.zKillsAbs[username] = playerData.zombieKills or 0
        end
        
        if AshenMPRanking.sandboxSettings.killsPerDay then
            local value =  tonumber(string.format("%.0f", playerData.zombieKills / playerData.daysSurvived))
            ladder.killsPerDay[username] =  value
        end

        if AshenMPRanking.sandboxSettings.sKills then
            ladder.sKills[username] = ladder.sKills[username] or 0
            if playerData.survivorKills > ladder.sKills[username] then
                ladder.sKillsTot[username] = ladder.sKillsTot[username] + playerData.survivorKills - ladder.sKills[username]
            end
            ladder.sKills[username] = playerData.survivorKills or 0
        end

        if AshenMPRanking.sandboxSettings.perkScores then
            for k,v in pairs(playerData.perkScores) do
                ladder.perkScores[k][username] = v or 0
            end
            -- get deposited $$ on LaResistenzaMarket
            if AshenMPRanking.sandboxSettings.lrm then
                if getGameTime():getModData().LRMPlayerInventory.players ~= nil then
                    local money = 0
                    -- print("AMPR DEBUG - checking balance for: ", playerData.username, playerData.steamID)
                    if getGameTime():getModData().LRMPlayerInventory.players[playerData.steamID] ~= nil then
                        money = getGameTime():getModData().LRMPlayerInventory.players[playerData.steamID].score
                        -- print("AMPR DEBUG BALANCE FOR ", username, money)
                    else
                        -- print("AMPR DEBUG no entry for ", username, playerData.steamID)
                        money = 0
                    end
                    ladder.perkScores.lrm[username] = money
                else
                    -- print("AMPR DEBUG players not initialized ", username, playerData.steamID)
                    ladder.perkScores.lrm[username] = 0
                end
            end
        end

        lastUpdate[username] = os.time()
    -- elseif accesslevel not equal to None
    elseif player:getAccessLevel() ~= "None" and ladder.deaths[username] ~= nil then
        print("AMPR purging data of elevated account: ", playerData.username)
        -- remove username from drop_player
        for k,v in pairs(ladder) do
            if k ~= "perkScores" then
                ladder[k][username] = nil
            else
                for k2,v2 in pairs(ladder.perkScores) do
                    ladder.perkScores[k2][username] = nil
                end
            end
        end
    end
    
    -- send the update when data are received from all clients
    if parsedPlayers >= getOnlinePlayers():size() then
        -- sort ladders
        sort_ladders()

        miscellaneous.onlineplayers = tostring(getOnlinePlayers():size())
        local args = {}
        args.onlineplayers = miscellaneous.onlineplayers
        args.ladder = oLadder
        sendServerCommand("AshenMPRanking", "LadderUpdate", args)

        -- time difference in minutes from the last write
        diff = os.difftime(os.time(), lastWrite) / 60
        if diff > AshenMPRanking.sandboxSettings.writeOnFilePeriod then
            SaveToFile()
        end
        -- reset parsedPlayersCounter
        parsedPlayers = 0
    end
end

local function sendServerConfig(player)
    local args = {}
    args.onlineplayers = miscellaneous.onlineplayers
    args.ladder = oLadder
    sendServerCommand(player, "AshenMPRanking", "ServerConfigs", AshenMPRanking.sandboxSettings)
    sendServerCommand(player, "AshenMPRanking", "LadderUpdate", args)
end

local function onPlayerDeathReset(player)
    username = player:getUsername()
    if ladder.deaths[username] == nil then
        ladder.deaths[username] = 1
    else
        ladder.deaths[username] = ladder.deaths[username] + 1
    end
    ladder.daysSurvived[username] = 0
    ladder.zKills[username] = 0

    if AshenMPRanking.sandboxSettings.killsPerDay then   
        ladder.killsPerDay[username] = 0
    end

    if AshenMPRanking.sandboxSettings.sKills then
        ladder.sKills[username] = 0
    end

    -- resetting perks ladders
    if AshenMPRanking.sandboxSettings.perkScores then
        for k,v in pairs(ladder.perkScores) do
            ladder.perkScores[k][username] = 0
        end
    end
end

local clientCommandDispatcher = function(module, command, player, args)
    if module ~= "AshenMPRanking" then
        return
    end

    if command == "PlayerData" then 
        onPlayerData(player, args)
    elseif command == "PlayerIsDead" then
        onPlayerDeathReset(player, args)
    elseif command == "getServerConfig" then
        sendServerConfig(player)
    end
end

-- see if the file exists
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

Events.OnServerStarted.Add(initServer)
Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnClientCommand.Add(clientCommandDispatcher)
