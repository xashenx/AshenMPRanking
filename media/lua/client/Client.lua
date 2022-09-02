AshenMPRanking = AshenMPRanking or {}
getGameTime():getModData().test = getGameTime():getModData().test or {}

if isServer() then return end;

-- Called on the player to parse its player data and send it to the server every ten (in-game) minutes
local function SendPlayerData()
    local player = getPlayer();
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
    
    -- print("ASPDClient: Sending " .. username .. " data to server!");
    sendClientCommand(player, "AshenMPRanking", "PlayerData", playerData);
end

-- executed when server request an update
local onPlayerDataRequest = function(module, command, player, args)
    if module ~= "AshenMPRanking" then
        return;
    end;
    
    if command == "PlayerDataRequest" then      
        print("ASPDClient: Update requested");
        SendPlayerData();
    end
end

-- executed when server sends a RankChange
local onRankChange = function(module, command, args)
    if module ~= "AshenMPRanking" then
        return;
    end
    
    if command == "RankChange" then
        print("ASPDClient: RankChange update");
        local player = getPlayer();
        local username = player:getUsername();

        if args.current == username then
            HaloTextHelper.addTextWithArrow(player, args.category, true, HaloTextHelper.getColorGreen());
        elseif args.previous == username then
            HaloTextHelper.addTextWithArrow(player, 'Best zombie killer (run)', false, HaloTextHelper.getColorRed());
        end
    end
end

Events.EveryTenMinutes.Add(SendPlayerData);
Events.OnPlayerDeath.Add(SendPlayerData);
Events.OnServerCommand.Add(onRankChange);