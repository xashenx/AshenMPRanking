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

-- function fetchSandboxVars()
AshenMPRanking.server.fetchSandboxVars = function()
    AshenMPRanking.sandboxSettings.mainUiTitle = SandboxVars.AshenMPRanking.mainUiTitle
    AshenMPRanking.sandboxSettings.sKills = SandboxVars.AshenMPRanking.sKills
    AshenMPRanking.sandboxSettings.inactivityPurgeTime = SandboxVars.AshenMPRanking.inactivityPurgeTime
end

local function sort_my_ladder(ladder, inverse, daysSurvived)
    inverse = inverse or false
    daysSurvived = daysSurvived or {}
    ordered_ladder={}
    for v,k in pairs(ladder) do
        if not inverse or (daysSurvived[v] > 4 or k > 0) then
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
        end
        -- print(v,k)
    end

    -- if inverse then
    --     for i=1,#ordered_ladder do
    --         print("(" .. tostring(i) .. ") " .. ordered_ladder[i][1] .. " -> ".. ordered_ladder[i][2])
    --     end
    -- end

    return ordered_ladder
end

local function sort_ladders()
    for k,v in pairs(ladder) do
        oLadder[k] = sort_my_ladder(v, k == "deaths", ladder.daysSurvivedAbs)
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
    -- for line in dataFile:readLine() do
        local username
        local daysSurvived
        local daysSurvivedAbs
        local zKills
        local zKillsAbs
        local sKills
        local sKillsAbs
        local deaths
        local updated

        -- username,daysSurvived,daysSurvivedAbs,zKills,zKillsAbs,sKills,sKillsAbs,deaths,updated  = line:match("([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)");
        username,daysSurvived,daysSurvivedAbs,zKills,zKillsAbs,sKills,sKillsAbs,deaths,updated = line:match("([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)");
        if username == nil then
            username,daysSurvived,daysSurvivedAbs,zKills,zKillsAbs,sKills,sKillsAbs,deaths  = line:match("([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)");
        end
        line = dataFile:readLine()

        if updated ~= nil then
            lastUpdate[username] = tonumber(updated)
            diff = os.difftime(os.time(), lastUpdate[username]) / (24 * 60 * 60)
        else
            -- TODO remove this part when this version become stable
            lastUpdate[username] = os.time()
            diff = 0
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

            ladder.deaths[username] = tonumber(deaths)
        else
            -- dropping player for inactiviti, printing in log
            print("dropping player " .. username .. " for inactivity")
        end

    end
    dataFile:close();

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
        counter = counter + 1
    end
    dataFile:write(text);
    dataFile:close();
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
    oLadder.deaths = {}

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

        lastUpdate[username] = os.time()
    end
    
    -- send the update when data are received from all clients
    if parsedPlayers >= getOnlinePlayers():size() then
        -- sort ladders
        sort_ladders()

        oLadder.onlineplayers = tostring(parsedPlayers)
        sendServerCommand("AshenMPRanking", "LadderUpdate", oLadder);
        SaveToFile()
        -- reset parsedPlayersCounter
        parsedPlayers = 0;
    end
end

local function getServerConfig(player)
    sendServerCommand(player, "AshenMPRanking", "ServerConfigs", AshenMPRanking.sandboxSettings);
    sendServerCommand(player, "AshenMPRanking", "LadderUpdate", oLadder);
end

local function onPlayerDeathReset(player)
    username = player:getUsername()
    if ladder.deaths[username] == nil then
        ladder.deaths[username] = 1
    else
        ladder.deaths[username] = ladder.deaths[username] + 1
    end
    ladder.daysSurvivedAbs[username] = 0
    ladder.zKills[username] = 0
    ladder.sKills[username] = 0
end

local clientCommandDispatcher = function(module, command, player, args)
    if module ~= "AshenMPRanking" then
        return;
    end;
    
    if command == "PlayerData" then 
        onPlayerData(player, args)
    elseif command == "PlayerIsDead" then
        onPlayerDeathReset(player, args)
    elseif command == "getServerConfig" then
        getServerConfig(player)
    end
end

local function updateLadder()
    ladder.onlineplayers = getOnlinePlayers():size();
    for i=0, getOnlinePlayers():size()-1 do
        local current_player = getOnlinePlayers():get(i);
        username = current_player:getUsername();
        iszombie = current_player:isZombie();
        level = current_player:getAccessLevel();
        alive = current_player:isAlive();

        survived = current_player:getHoursSurvived() / 24;
        zKills = current_player:getZombieKills();
        sKills = current_player:getSurvivorKills();

        if alive then
            if ladder.daysSurvivedAbs[username] == nil then
                ladder.daysSurvivedAbs[username] = survived;
                ladder.zKillsAbs[username] = zKills;
                ladder.sKillsAbs[username] = sKills;
            end

            if survived > ladder.daysSurvivedAbs[username] then
                ladder.daysSurvivedAbs[username] = survived;
            end
            if zKills > ladder.zKillsAbs[username] then
                ladder.zKillsAbs[username] = zKills;
            end
            if sKills > ladder.sKillsAbs[username] then
                ladder.sKillsAbs[username] = sKills;
            end

            ladder.daysSurvived[username] = survived;
            ladder.zKills[username] = zKills;
            ladder.sKills[username] = sKills;
        end
    end

    -- send the ladder update to clients
    sendServerCommand("AshenMPRanking", "LadderUpdate", oLadder);
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
