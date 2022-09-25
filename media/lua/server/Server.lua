if not isServer() then return end;
AshenMPRanking = AshenMPRanking or {};
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.server = {};

local parsedPlayers = 0;
local write_required = false;
local ladder = {};
local oLadder = {};
local streamers = {}
local configs = {}
local lastUpdate = {}
local miscellaneous = {}
local lastWrite = 0

-- function fetchSandboxVars()
AshenMPRanking.server.fetchSandboxVars = function()
    AshenMPRanking.sandboxSettings.mainUiTitle = SandboxVars.AshenMPRanking.mainUiTitle
    AshenMPRanking.sandboxSettings.sKills = SandboxVars.AshenMPRanking.sKills
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
end

local function sort_my_ladder(ladder, inverse, daysSurvived)
    inverse = inverse or false
    daysSurvived = daysSurvived or {}
    ordered_ladder={}
    for v,k in pairs(ladder) do
        if not inverse or (daysSurvived[v] > 4 or k > 0) and daysSurvived[v] ~= nil then
            if #ordered_ladder > 0 then
                for i=1,#ordered_ladder do
                    if inverse then
                        if k > ordered_ladder[#ordered_ladder -i+1][2] then
                            table.insert(ordered_ladder,#ordered_ladder-i+2,{v,k})
                            break
                        end
                    else
                        if k < ordered_ladder[#ordered_ladder -i+1][2] then
                            table.insert(ordered_ladder,#ordered_ladder-i+2,{v,k})
                            break
                        end
                    end

                    if i==#ordered_ladder then
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

    line = dataFile:readLine()

    while line ~= nil do
        local username
        local daysSurvived
        local daysSurvivedAbs
        local zKills
        local zKillsAbs
        local sKills
        local sKillsAbs
        local deaths
        local updated

        username,daysSurvived,daysSurvivedAbs,zKills,zKillsAbs,sKills,sKillsAbs,deaths,updated,passiv,agility,firearm,crafting,combat,survivalist,otherPerks = line:match("([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)")
        if otherPerks == nil then
            username,daysSurvived,daysSurvivedAbs,zKills,zKillsAbs,sKills,sKillsAbs,deaths,updated,passiv,agility,firearm,crafting,combat,survivalist = line:match("([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)")
            otherPerks = 0
        end
        line = dataFile:readLine()

        if updated ~= nil then
            lastUpdate[username] = tonumber(updated)
            diff = os.difftime(os.time(), lastUpdate[username]) / (24 * 60 * 60)
        end

        if diff < AshenMPRanking.sandboxSettings.inactivityPurgeTime then
            ladder.daysSurvived[username] = tonumber(daysSurvived)
            ladder.daysSurvivedAbs[username] = tonumber(daysSurvivedAbs)

            ladder.zKills[username] = tonumber(zKills)
            ladder.zKillsAbs[username] = tonumber(zKillsAbs)

            if AshenMPRanking.sandboxSettings.sKills then
                ladder.sKills[username] = tonumber(sKills)
                ladder.sKillsAbs[username] = tonumber(sKillsAbs)
            end

            if AshenMPRanking.sandboxSettings.perkScores then
                ladder.perkScores.passiv[username] = tonumber(passiv)
                ladder.perkScores.agility[username] = tonumber(agility)
                ladder.perkScores.firearm[username] = tonumber(firearm)
                ladder.perkScores.crafting[username] = tonumber(crafting)
                ladder.perkScores.combat[username] = tonumber(combat)
                ladder.perkScores.survivalist[username] = tonumber(survivalist)
                if AshenMPRanking.sandboxSettings.otherPerks then
                    ladder.perkScores.otherPerks[username] = tonumber(otherPerks)
                end
            end

            ladder.deaths[username] = tonumber(deaths)
        else
            -- dropping player for inactiviti, printing in log
            print("dropping player " .. username .. " for inactivity: " .. string.format("%.0f", diff) .. " days " .. lastUpdate[username])
        end

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
    local dataFile = getFileWriter("/AshenMPRanking/" .. getServerName() .. "/ladder.csv", true, false);

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
            text = text .. ";" .. ladder.sKillsAbs[k]
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
            end
        else
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
            text = text .. ";" .. 0
        end

        counter = counter + 1
    end
    dataFile:write(text);
    dataFile:close();

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

    if AshenMPRanking.sandboxSettings.sKills then
        ladder.sKills = {}
        oLadder.sKills = {}
        ladder.sKillsAbs = {}
        oLadder.sKillsAbs = {}
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
    end

    AshenMPRanking.sandboxSettings.server_name = getServerName()

    loadFromFile()
end

-- executed when a client(player) sends its information to the server
local function onPlayerData(player, playerData)
    parsedPlayers = parsedPlayers + 1
    if playerData.isAlive and  player:getAccessLevel() == "None" then
        local username = playerData.username
        if ladder.daysSurvivedAbs[username] == nil then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived
            ladder.zKillsAbs[username] = playerData.zombieKills
            if AshenMPRanking.sandboxSettings.sKills then
                ladder.sKillsAbs[username] = playerData.survivorKills
            end
            ladder.deaths[username] = 0
        end

        ladder.daysSurvived[username] = playerData.daysSurvived
        if playerData.daysSurvived > ladder.daysSurvivedAbs[username] then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived;
        end
        
        ladder.zKills[username] = playerData.zombieKills
        if playerData.zombieKills > ladder.zKillsAbs[username] then
            ladder.zKillsAbs[username] = playerData.zombieKills
        end
        
        if AshenMPRanking.sandboxSettings.sKills then
            if playerData.survivorKills > ladder.sKillsAbs[username] then
                ladder.sKillsAbs[username] = playerData.survivorKills
            end
            ladder.sKills[username] = playerData.survivorKills
        end

        if AshenMPRanking.sandboxSettings.perkScores then
            for k,v in pairs(playerData.perkScores) do
                ladder.perkScores[k][username] = v
            end
        end

        lastUpdate[username] = os.time()
    end
    
    -- send the update when data are received from all clients
    if parsedPlayers >= getOnlinePlayers():size() then
        -- sort ladders
        sort_ladders()

        miscellaneous.onlineplayers = tostring(parsedPlayers)
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
        parsedPlayers = 0;
    end
end

local function sendServerConfig(player)
    local args = {}
    args.onlineplayers = miscellaneous.onlineplayers
    args.ladder = oLadder
    print('sending configs to ' .. player:getUsername())
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

Events.OnServerStarted.Add(initServer);
Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnClientCommand.Add(clientCommandDispatcher)
