if not isServer() then return end;

local parsedPlayers = 0;
local write_required = false;
local ladder = {};
local oLadder = {};
local streamers = {};

local function initLadder()
    ladder.daysSurvived = {};
    ladder.daysSurvivedAbs = {};
    ladder.zKills = {};
    ladder.zKillsAbs = {};
    ladder.sKills = {};
    ladder.sKillsAbs = {};
    ladder.deaths = {};
    ladder.onlineplayers = "";
    -- ordered ladders
    oLadder.daysSurvived = {};
    oLadder.daysSurvivedAbs = {};
    oLadder.zKills = {};
    oLadder.zKillsAbs = {};
    oLadder.sKills = {};
    oLadder.sKillsAbs = {};
    oLadder.deaths = {};
    oLadder.onlineplayers = "";
    oLadder.server_name = getServerName();
end

local function sort_my_ladder(ladder, inverse, daysSurvived)
    inverse = inverse or false
    daysSurvived = daysSurvived or {}
    ordered_ladder={}
    for v,k in pairs(ladder) do
        -- tablelenth=tablelenth+1
        if not inverse or (inverse and daysSurvived[v] > 4) then
            if #ordered_ladder > 0 then
                -- local numbertable = #zombierank_clientsucc
                -- print(k)
                for i=1,#ordered_ladder do
                    -- TODO invertire ordinamento per kills!
                    -- if k <= ordered_ladder[#ordered_ladder -i+1][2] then
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

    if inverse then
        for i=1,#ordered_ladder do
            print("(" .. tostring(i) .. ") " .. ordered_ladder[i][1] .. " -> ".. ordered_ladder[i][2])
        end
    end

    return ordered_ladder
end

local function sort_ladders()
    oLadder.daysSurvived = sort_my_ladder(ladder.daysSurvived)
    oLadder.daysSurvivedAbs = sort_my_ladder(ladder.daysSurvivedAbs)
    oLadder.zKills = sort_my_ladder(ladder.zKills)
    oLadder.zKillsAbs = sort_my_ladder(ladder.zKillsAbs)
    oLadder.sKills = sort_my_ladder(ladder.sKills)
    oLadder.sKillsAbs = sort_my_ladder(ladder.sKillsAbs)
    oLadder.deaths = sort_my_ladder(ladder.deaths, true, ladder.daysSurvivedAbs)
end

-- load last stats from file on load
local function loadFromFile()
    -- reading current run ladder
    local file = "/AshenMPRanking/" .. getServerName() .. "/ladder.csv"
    local dataFile = getFileReader(file, true)
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
        username,daysSurvived,daysSurvivedAbs,zKills,zKillsAbs,sKills,sKillsAbs,deaths  = line:match("([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)");

        ladder.daysSurvived[username] = tonumber(daysSurvived)
        ladder.daysSurvivedAbs[username] = tonumber(daysSurvivedAbs)
        ladder.zKills[username] = tonumber(zKills)
        ladder.zKillsAbs[username] = tonumber(zKillsAbs)
        ladder.sKills[username] = tonumber(sKills)
        ladder.sKillsAbs[username] = tonumber(sKillsAbs)
        ladder.deaths[username] = tonumber(deaths)

        line = dataFile:readLine()
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
        print("writing " .. k)
        if counter ~= 0 then
            text = text .. "\n" .. k
        else
            text = k
        end

        text = text .. ";" .. ladder.daysSurvived[k]
        text = text .. ";" .. ladder.daysSurvivedAbs[k]
        text = text .. ";" .. ladder.zKills[k]
        text = text .. ";" .. ladder.zKillsAbs[k]
        text = text .. ";" .. ladder.sKills[k]
        text = text .. ";" .. ladder.sKillsAbs[k]
        text = text .. ";" .. ladder.deaths[k]
        counter = counter + 1
    end
    dataFile:write(text);
    dataFile:close();
end

-- executed when a client(player) sends its information to the server
local function onPlayerData(player, playerData)
    parsedPlayers = parsedPlayers + 1;
    if playerData.isAlive then
        local username = playerData.username;
        print("AMPRServer: Player " .. username .. " received!");
        if ladder.daysSurvivedAbs[username] == nil then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived;
            ladder.zKillsAbs[username] = playerData.zombieKills;
            ladder.sKillsAbs[username] = playerData.survivorKills;
            ladder.deaths[username] = 0
        end

        if playerData.daysSurvived > ladder.daysSurvivedAbs[username] then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived;
        end

        if playerData.zombieKills > ladder.zKillsAbs[username] then
            ladder.zKillsAbs[username] = playerData.zombieKills;
        end

        if playerData.survivorKills > ladder.sKillsAbs[username] then
            ladder.sKillsAbs[username] = playerData.survivorKills;
        end

        ladder.daysSurvived[username] = playerData.daysSurvived;
        ladder.zKills[username] = playerData.zombieKills;
        ladder.sKills[username] = playerData.survivorKills;
    end

    -- sort ladders
    sort_ladders()

    -- send the update when data are received from all clients
    if parsedPlayers == getOnlinePlayers():size() then
        oLadder.onlineplayers = tostring(parsedPlayers)
        print('AMPRServer: sending ladders to players ...');
        sendServerCommand("AshenMPRanking", "LadderUpdate", oLadder);
        SaveToFile()
        -- reset parsedPlayersCounter
        parsedPlayers = 0;
    end
end

local function onConnectUpdate()
    sendServerCommand("AshenMPRanking", "LadderUpdate", oLadder);
end

local function onPlayerDeathReset(player)
    username = player:getUsername();
    print(username .. ' è morto!');
    ladder.deaths[username] = ladder.deaths[username] + 1
    ladder.daysSurvivedAbs[username] = 0
    ladder.zKills[username] = 0
    ladder.sKills[username] = 0
    -- sendClientCommand(player, "AshenServerPlayersData", "PlayerIsDead", data);
end

local clientCommandDispatcher = function(module, command, player, args)
    if module ~= "AshenMPRanking" then
        return;
    end;
    
    if command == "PlayerData" then 
        onPlayerData(player, args);
    elseif command == "PlayerIsDead" then
        onPlayerDeathReset(player, args);
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

-- TODO gestione evento morte personaggio:
-- 1) reset statistiche se del player
-- 1b) effettuare richiesta di aggiornamento
-- Events.EveryTenMinutes.Add(updateLadder);
-- Events.EveryHours.Add(requestUpdate);
-- Events.EveryTenMinutes.Add(requestUpdate);

initLadder();
Events.OnServerStarted.Add(loadFromFile)
Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnClientCommand.Add(clientCommandDispatcher)
Events.OnConnected.Add(onConnectUpdate)