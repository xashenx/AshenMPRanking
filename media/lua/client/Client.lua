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

    sendClientCommand(player, "AshenMPRanking", "PlayerData", playerData);
end

Events.EveryTenMinutes.Add(SendPlayerData)
Events.OnPlayerDeath.Add(SendPlayerData)