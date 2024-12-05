if not isServer() then return end
AshenMPRanking = AshenMPRanking or {}
AshenMPRanking.sandboxSettings = {}
AshenMPRanking.server = {}
AshenMPRanking.file = nil

local parsedPlayers = 0
local write_required = false
local ladder = {}
local inactiveAccounts = {}
local oLadder = {}
local streamers = {}
local configs = {}
local lastUpdate = {}
local miscellaneous = {}
local lastWrite = 0
-- tags for ModData
local tag_active = 'active'
local tag_inactive = 'inactive'

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
    AshenMPRanking.sandboxSettings.rankStaff = SandboxVars.AshenMPRanking.rankStaff
    AshenMPRanking.sandboxSettings.passivMaxScore = SandboxVars.AshenMPRanking.passivMaxScore

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

-- Parse player data and save it to a .csv file inside Lua/ServerPlayersData/ folder
local function SaveToFile(data, filename, lastUpdateInactive)
    -- write current run csv file
    local dataFile = getFileWriter("/AshenMPRanking/" .. getServerName() .. "/" .. filename, true, false)

    text = ""
    local counter = 0
    for k,v in pairs(data.daysSurvived) do
        -- print('scrivo ' .. k)
        if counter ~= 0 then
            text = text .. "\n" .. k
        else
            text = k
        end

        if data.daysSurvived[k] ~= nil then
            text = text .. ";" .. data.daysSurvived[k]
        else
            text = text .. ";" .. 0
        end
        if data.daysSurvivedAbs[k] ~= nil then
            text = text .. ";" .. data.daysSurvivedAbs[k]
        else
            text = text .. ";" .. 0
        end
        if data.zKills[k] ~= nil then
            text = text .. ";" .. data.zKills[k]
        else
            text = text .. ";" .. 0
        end
        if data.zKillsAbs[k] ~= nil then
            text = text .. ";" .. data.zKillsAbs[k]
        else
            text = text .. ";" .. 0
        end
        -- text = text .. ";" .. data.daysSurvived[k]
        -- text = text .. ";" .. data.daysSurvivedAbs[k]
        -- text = text .. ";" .. data.zKills[k]
        -- text = text .. ";" .. data.zKillsAbs[k]
        
        if AshenMPRanking.sandboxSettings.sKills then
            if data.sKills[k] ~= nil then
                text = text .. ";" .. data.sKills[k]
            else
                text = text .. ";" .. 0
            end
            if data.sKillsTot[k] ~= nil then
                text = text .. ";" .. data.sKillsTot[k]
            else
                text = text .. ";" .. 0
            end
            -- text = text .. ";" .. data.sKills[k]
            -- text = text .. ";" .. data.sKillsTot[k]
        else
            text = text .. ";" .. 0
            text = text .. ";" .. 0
        end
        
        text = text .. ";" .. data.deaths[k]
        if lastUpdate[k] ~= nil then
            text = text .. ";" .. lastUpdate[k]
        else
            text = text .. ";" .. lastUpdateInactive[k]
        end
        
        if AshenMPRanking.sandboxSettings.perkScores then
            text = text .. ";" .. data.perkScores.passiv[k]
            text = text .. ";" .. data.perkScores.agility[k]
            text = text .. ";" .. data.perkScores.firearm[k]
            text = text .. ";" .. data.perkScores.crafting[k]
            text = text .. ";" .. data.perkScores.combat[k]
            text = text .. ";" .. data.perkScores.survivalist[k]
            if AshenMPRanking.sandboxSettings.otherPerks then
                text = text .. ";" .. data.perkScores.otherPerks[k]
            else
                text = text .. ";" .. 0
            end
            if AshenMPRanking.sandboxSettings.lrm then
                text = text .. ";" .. data.perkScores.lrm[k]
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
            if data.killsPerDay[k] ~= nil then
                text = text .. ";" .. data.killsPerDay[k]
            else
                text = text .. ";" .. 0
            end
            -- text = text .. ";" .. data.killsPerDay[k]
        else
            text = text .. ";" .. 0
        end

        text = text .. ";" .. data.zKillsTot[k]
        counter = counter + 1
    end

    if text ~= "" then

        dataFile:write(text)
        dataFile:close()
    
        if filename == "ladder.csv" then
            -- set lastWrite time
            lastWrite = os.time()
        end
    end

    -- save
    ModData.add("AshenMPRanking.ladder", ladder)
end

local function saveModData(tag, data)
    ModData.add(tag, data)
    -- ModData.remove(tag)
end

local function moveBetweenActiveInactive(username, from, to)
    to.daysSurvived[username] = from.daysSurvived[username]
    from.daysSurvived[username] = nil
    to.daysSurvivedAbs[username] = from.daysSurvivedAbs[username]
    from.daysSurvivedAbs[username] = nil

    to.zKills[username] = from.zKills[username]
    from.zKills[username] = nil
    to.zKillsAbs[username] = from.zKillsAbs[username]
    from.zKillsAbs[username] = nil
    to.zKillsTot[username] = from.zKillsTot[username]
    from.zKillsTot[username] = nil
    
    if AshenMPRanking.sandboxSettings.killsPerDay then
        to.killsPerDay[username] = from.killsPerDay[username]
        from.killsPerDay[username] = nil
    end

    if AshenMPRanking.sandboxSettings.sKills then
        to.sKills[username] = from.sKills[username]
        from.sKills[username] = nil
        to.sKillsTot[username] = from.sKillsTot[username]
        from.sKillsTot[username] = nil
    end
    
    if AshenMPRanking.sandboxSettings.perkScores then
        to.perkScores.passiv[username] = from.perkScores.passiv[username]
        from.perkScores.passiv[username] = nil
        to.perkScores.agility[username] = from.perkScores.agility[username]
        from.perkScores.agility[username] = nil
        to.perkScores.firearm[username] = from.perkScores.firearm[username]
        from.perkScores.firearm[username] = nil
        to.perkScores.crafting[username] = from.perkScores.crafting[username]
        from.perkScores.crafting[username] = nil
        to.perkScores.combat[username] = from.perkScores.combat[username]
        from.perkScores.combat[username] = nil
        to.perkScores.survivalist[username] = from.perkScores.survivalist[username]
        from.perkScores.survivalist[username] = nil
        if AshenMPRanking.sandboxSettings.otherPerks then
            to.perkScores.otherPerks[username] = from.perkScores.otherPerks[username]
            from.perkScores.otherPerks[username] = nil
        end
        -- LaResistenzaMarket
        if AshenMPRanking.sandboxSettings.lrm then
            to.perkScores.lrm[username] = from.perkScores.lrm[username]
            from.perkScores.lrm[username] = nil
        end
    end
    
    to.deaths[username] = from.deaths[username]
    from.deaths[username] = nil
end

-- load inactive accounts
local function checkInactive(mode, target_username)
    -- TODO merge loadInactive and loadFromFile
    -- reading current run ladder
    if inactiveAccounts.daysSurvived == nil then
        local file = "/AshenMPRanking/" .. getServerName() .. "/inactive.csv"
        print('AMPR DEBUG: loading inactive from file')
        dataFile = getFileReader(file, false)

        -- local lastUpdateInactive = {}

        -- if dataFile == nil then
        --     print("AMPR DEBUG: No inactive file found!")
        -- end

        inactiveAccounts.daysSurvived = {}
        inactiveAccounts.daysSurvivedAbs = {}
        inactiveAccounts.zKills = {}
        inactiveAccounts.zKillsAbs = {}
        inactiveAccounts.zKillsTot = {}
        inactiveAccounts.updated = {}

        if AshenMPRanking.sandboxSettings.killsPerDay then
            inactiveAccounts.killsPerDay = {}
        end

        if AshenMPRanking.sandboxSettings.sKills then
            inactiveAccounts.sKills = {}
            inactiveAccounts.sKillsTot = {}
        end

        inactiveAccounts.deaths = {}

        if AshenMPRanking.sandboxSettings.perkScores then
            inactiveAccounts.perkScores = {}
            inactiveAccounts.perkScores.passiv = {}
            inactiveAccounts.perkScores.agility = {}
            inactiveAccounts.perkScores.firearm = {}
            inactiveAccounts.perkScores.crafting = {}
            inactiveAccounts.perkScores.combat = {}
            inactiveAccounts.perkScores.survivalist = {}
            if AshenMPRanking.sandboxSettings.otherPerks then
                inactiveAccounts.perkScores.otherPerks = {}
            end
            -- ladder for LaResistenzaMarket
            if getGameTime():getModData().LRMPlayerInventory ~= nil then
                AshenMPRanking.sandboxSettings.lrm = true
            end
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
        
        line = ""
        if dataFile ~= nil then
            line = dataFile:readLine()
        end
        
        -- print("AMPR DEBUG: Loading ladder from file")
        while line ~= nil and line ~= "" do
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

            inactiveAccounts.daysSurvived[username] = player_stats[stats.daysSurvived].value
            inactiveAccounts.daysSurvivedAbs[username] = player_stats[stats.daysSurvivedAbs].value
            
            inactiveAccounts.zKills[username] = player_stats[stats.zKills].value
            inactiveAccounts.zKillsAbs[username] = player_stats[stats.zKillsAbs].value
            inactiveAccounts.zKillsTot[username] = player_stats[stats.zKillsTot].value
            -- lastUpdateInactive[username] = player_stats[stats.updated].value
            -- lastUpdate[username] = player_stats[stats.updated].value
            
            if AshenMPRanking.sandboxSettings.killsPerDay then
                inactiveAccounts.killsPerDay[username] = player_stats[stats.killsPerDay].value
            end

            if AshenMPRanking.sandboxSettings.sKills then
                inactiveAccounts.sKills[username] = player_stats[stats.sKills].value
                inactiveAccounts.sKillsTot[username] = player_stats[stats.sKillsTot].value
            end
            
            if AshenMPRanking.sandboxSettings.perkScores then
                inactiveAccounts.perkScores.passiv[username] = player_stats[stats.passiv].value
                inactiveAccounts.perkScores.agility[username] = player_stats[stats.agility].value
                inactiveAccounts.perkScores.firearm[username] = player_stats[stats.firearm].value
                inactiveAccounts.perkScores.crafting[username] = player_stats[stats.crafting].value
                inactiveAccounts.perkScores.combat[username] = player_stats[stats.combat].value
                inactiveAccounts.perkScores.survivalist[username] = player_stats[stats.survivalist].value
                if AshenMPRanking.sandboxSettings.otherPerks then
                    inactiveAccounts.perkScores.otherPerks[username] = player_stats[stats.otherPerks].value
                end
                -- LaResistenzaMarket
                if AshenMPRanking.sandboxSettings.lrm then
                    inactiveAccounts.perkScores.lrm[username] = player_stats[stats.lrm].value
                end
            end
            
            inactiveAccounts.deaths[username] = player_stats[stats.deaths].value

            inactiveAccounts.updated[username] = player_stats[stats.updated].value
            -- if username == target_username and mode == 1 then
            --     lastUpdate[target_username] = player_stats[stats.updated].value
            -- end

            line = dataFile:readLine()
        end
        if dataFile ~= nil then
            dataFile:close()
        end
    end

    if mode == 1 then -- check if username is in inactiveAccounts
        if inactiveAccounts.daysSurvived[target_username] ~= nil then
            -- inactiveAccounts -> ladder
            moveBetweenActiveInactive(target_username, inactiveAccounts, ladder)
            lastUpdate[target_username] = os.time()
            -- -- write inactive file
            -- SaveToFile(inactiveAccounts, "inactive.csv", lastUpdateInactive)
            saveModData(tag_inactive, inactiveAccounts)
            print("AMPR DEBUG: moving " .. target_username .. " from INACTIVE to ACTIVE")
            return true
        else
            return false
        end
    elseif mode == 2 then -- move account from active to inactive
        if lastUpdate[target_username] ~= nil then
            -- ladder -> inactiveAccounts
            moveBetweenActiveInactive(target_username, ladder, inactiveAccounts)
            -- -- write inactive file
            -- SaveToFile(inactiveAccounts, "inactive.csv", lastUpdateInactive)
            -- save mod data
            lastUpdate[target_username] = nil
            saveModData(tag_inactive, inactiveAccounts)
            print("AMPR DEBUG: moving " .. target_username .. " from ACTIVE to INACTIVE")
            return true
        else
            return false
        end
    end
end

-- add a new player to the ladder
local function addNewUser(username)
    if lastUpdate[username] ~= nil then
        return string.format(getText("UI_ErrorPlayerRanked"), username)
    end
    lastUpdate[username] = os.time()

    -- generate random values for the fields
    ladder.daysSurvived[username] = ZombRand(0, 10)
    ladder.daysSurvivedAbs[username] = ZombRand(0, 10)

    ladder.zKills[username] = ZombRand(0, 1000)
    ladder.zKillsAbs[username] = ZombRand(0, 1000)
    ladder.zKillsTot[username] = ZombRand(0, 1000)
    
    if AshenMPRanking.sandboxSettings.killsPerDay then
        ladder.killsPerDay[username] = ZombRand(0, 150)
    end

    if AshenMPRanking.sandboxSettings.sKills then
        ladder.sKills[username] = ZombRand(0, 150)
        ladder.sKillsTot[username] = ZombRand(0, 150)
    end
    
    if AshenMPRanking.sandboxSettings.perkScores then
        ladder.perkScores.passiv[username] = ZombRand(0, 20)
        ladder.perkScores.agility[username] = ZombRand(0, 30)
        ladder.perkScores.firearm[username] = ZombRand(0, 20)
        ladder.perkScores.crafting[username] = ZombRand(0, 80)
        ladder.perkScores.combat[username] = ZombRand(0, 60)
        ladder.perkScores.survivalist[username] = ZombRand(0, 30)
        if AshenMPRanking.sandboxSettings.otherPerks then
            ladder.perkScores.otherPerks[username] = ZombRand(0, 10)
        end
        -- LaResistenzaMarket
        if AshenMPRanking.sandboxSettings.lrm then
            ladder.perkScores.lrm[username] = ZombRand(0, 1000)
        end
    end
    
    ladder.deaths[username] = ZombRand(0, 10)
end

-- purge Cheater from leaderboards
local function purgeCheater(username)
    if lastUpdate[username] == nil then
        return string.format(getText("UI_ErrorPlayerNotRanked"), username)
    end

    lastUpdate[username] = nil

    ladder.daysSurvived[username] = nil
    ladder.daysSurvivedAbs[username] = nil

    ladder.zKills[username] = nil
    ladder.zKillsAbs[username] = nil
    ladder.zKillsTot[username] = nil
    
    if AshenMPRanking.sandboxSettings.killsPerDay then
        ladder.killsPerDay[username] = nil
    end

    if AshenMPRanking.sandboxSettings.sKills then
        ladder.sKills[username] = nil
        ladder.sKillsTot[username] = nil
    end
    
    if AshenMPRanking.sandboxSettings.perkScores then
        ladder.perkScores.passiv[username] = nil
        ladder.perkScores.agility[username] = nil
        ladder.perkScores.firearm[username] = nil
        ladder.perkScores.crafting[username] = nil
        ladder.perkScores.combat[username] = nil
        ladder.perkScores.survivalist[username] = nil
        if AshenMPRanking.sandboxSettings.otherPerks then
            ladder.perkScores.otherPerks[username] = nil
        end
        -- LaResistenzaMarket
        if AshenMPRanking.sandboxSettings.lrm then
            ladder.perkScores.lrm[username] = nil
        end
    end
    
    ladder.deaths[username] = nil
end

-- load last stats from file on load
local function loadFromFile(stats)
    -- init structures
    ladder.daysSurvived = {}
    ladder.daysSurvivedAbs = {}
    ladder.zKills = {}
    ladder.zKillsAbs = {}
    ladder.zKillsTot = {}
    ladder.deaths = {}
    
    if AshenMPRanking.sandboxSettings.killsPerDay then
            ladder.killsPerDay = {}
    end
    
    if AshenMPRanking.sandboxSettings.sKills then
        ladder.sKills = {}
        ladder.sKillsTot = {}
    end
    
    if AshenMPRanking.sandboxSettings.perkScores then
        ladder.perkScores = {}
        ladder.perkScores.passiv = {}
        ladder.perkScores.agility = {}
        ladder.perkScores.firearm = {}
        ladder.perkScores.crafting = {}
        ladder.perkScores.combat = {}
        ladder.perkScores.survivalist = {}
        if AshenMPRanking.sandboxSettings.otherPerks then
            ladder.perkScores.otherPerks = {}
        end
        -- ladder for LaResistenzaMarket
        if getGameTime():getModData().LRMPlayerInventory ~= nil then
            ladder.perkScores.lrm = {}
        end
    end

    print('AMPR: loading player from ladders.csv file')
    -- reading current run ladder
    local file = "/AshenMPRanking/" .. getServerName() .. "/ladder.csv"
    local dataFile = getFileReader(file, false)


    if dataFile == nil then
        -- print("No ladder file found, the file will be created as soon as the first player connects")
        -- dataFile = getFileWriter(file, true)
        -- dataFile:close()
        return
    end

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

        if diff > AshenMPRanking.sandboxSettings.inactivityPurgeTime then
            -- inactive account
            checkInactive(2, username)
        end
        line = dataFile:readLine()
    end
    dataFile:close()

    -- set lastWrite to now
    lastWrite = os.time()

    -- sort ladders
    sort_ladders()
end

local function initServer()
    AshenMPRanking.server.fetchSandboxVars()

    oLadder.daysSurvived = {}
    oLadder.daysSurvivedAbs = {}
    oLadder.zKills = {}
    oLadder.zKillsAbs = {}
    oLadder.zKillsTot = {}
    
    if AshenMPRanking.sandboxSettings.killsPerDay then
        oLadder.killsPerDay = {}
    end
    
    if AshenMPRanking.sandboxSettings.sKills then
        oLadder.sKills = {}
        oLadder.sKillsTot = {}
    end
    
    if AshenMPRanking.sandboxSettings.moreDeaths then
        oLadder.moreDeaths = {}
    end
    if AshenMPRanking.sandboxSettings.lessDeaths then
        oLadder.lessDeaths = {}
    end
    
    if AshenMPRanking.sandboxSettings.perkScores then
        oLadder.perkScores = {}
        oLadder.perkScores.passiv = {}
        oLadder.perkScores.agility = {}
        oLadder.perkScores.firearm = {}
        oLadder.perkScores.crafting = {}
        oLadder.perkScores.combat = {}
        oLadder.perkScores.survivalist = {}
        if AshenMPRanking.sandboxSettings.otherPerks then
            oLadder.perkScores.otherPerks = {}
        end
        -- ladder for LaResistenzaMarket
        if getGameTime():getModData().LRMPlayerInventory ~= nil then
            oLadder.perkScores.lrm = {}
            AshenMPRanking.sandboxSettings.lrm = true
        end
    end
    
    AshenMPRanking.sandboxSettings.server_name = getServerName()
    
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
    
    -- write current run csv file
    -- local file = "/AshenMPRanking/" .. getServerName() .. "/ladder.csv"
    -- check if ladder.daysSurvived is an empty table
    if ladder.daysSurvived == nil then
        loadFromFile(stats)
    end
    
    -- check if any account is inactive
    for username,v in pairs(lastUpdate) do
        -- first check if the player is a cheater
        if ladder.perkScores.passiv[username] ~= nil then
            if ladder.perkScores.passiv[username] > AshenMPRanking.sandboxSettings.passivMaxScore then
                print("AMPR DEBUG: " .. username .. " is a CHEATER, purging from leaderboards")
                purgeCheater(username)
            end
        else
            diff = os.difftime(os.time(), v) / (24 * 60 * 60)
            if diff > AshenMPRanking.sandboxSettings.inactivityPurgeTime then
                -- inactive account
                checkInactive(2, username)
            end
        end
    end

    -- save to modData
    saveModData(tag_active, ladder)
    saveModData(tag_lastupdate, lastUpdate)
    saveModData(tag_inactive, inactiveAccounts)

    -- set lastWrite to now
    lastWrite = os.time()
end

-- executed when a client(player) sends its information to the server
local function onPlayerData(player, playerData)
    parsedPlayers = parsedPlayers + 1
    local username = playerData.username
    if playerData.isAlive and player:getAccessLevel() == "None" or AshenMPRanking.sandboxSettings.rankStaff then
        if ladder.daysSurvivedAbs[username] == nil then
            if checkInactive(1, username) then
                print("AMPR DEBUG: restoring player " .. username .. " from INACTIVE to ACTIVE")
            else
                ladder.daysSurvivedAbs[username] = playerData.daysSurvived or 0
                ladder.zKillsAbs[username] = playerData.zombieKills or 0
                if AshenMPRanking.sandboxSettings.sKills then
                    ladder.sKillsTot[username] = playerData.survivorKills or 0
                end
                -- ladder.zKillsTot[username] = playerData.zombieKills or 0
                ladder.deaths[username] = 0
            end
        end

        ladder.daysSurvived[username] = playerData.daysSurvived or 0
        if playerData.daysSurvived > ladder.daysSurvivedAbs[username] then
            ladder.daysSurvivedAbs[username] = playerData.daysSurvived or 0
        end

        ladder.zKills[username] = ladder.zKills[username] or 0

        if ladder.zKillsTot[username] == nil then
            ladder.zKillsTot[username] = playerData.zombieKills
        elseif playerData.zombieKills > ladder.zKillsTot[username] then
            ladder.zKillsTot[username] = playerData.zombieKills
        elseif playerData.zombieKills > ladder.zKills[username] then
            ladder.zKillsTot[username] = ladder.zKillsTot[username] + playerData.zombieKills - ladder.zKills[username]
        end

        ladder.zKills[username] = playerData.zombieKills or 0
        if playerData.zombieKills > ladder.zKillsAbs[username] then
            ladder.zKillsAbs[username] = playerData.zombieKills or 0
        end
        
        if AshenMPRanking.sandboxSettings.killsPerDay then
            if ladder.killsPerDay == nil then
                ladder.killsPerDay = {}
            end
            local value =  tonumber(string.format("%.0f", playerData.zombieKills / playerData.daysSurvived))
            ladder.killsPerDay[username] =  value
        elseif ladder.killsPerDay ~= nil then
            ladder.killsPerDay = nil
        end

        if AshenMPRanking.sandboxSettings.sKills then
            if ladder.sKills == nil then
                ladder.sKills = {}
                ladder.sKillsTot = {}
            end
            ladder.sKills[username] = ladder.sKills[username] or 0
            ladder.sKillsTot[username] = ladder.sKillsTot[username] or 0
            if playerData.survivorKills > ladder.sKills[username] then
                ladder.sKillsTot[username] = ladder.sKillsTot[username] + playerData.survivorKills - ladder.sKills[username]
            end
            ladder.sKills[username] = playerData.survivorKills or 0
        elseif ladder.sKills ~= nil then
            ladder.sKills = nil
            ladder.sKillsTot = nil
        end

        if AshenMPRanking.sandboxSettings.perkScores then
            if ladder.perkScores == nil then
                ladder.perkScores = {}
                ladder.perkScores.passiv = {}
                ladder.perkScores.agility = {}
                ladder.perkScores.firearm = {}
                ladder.perkScores.crafting = {}
                ladder.perkScores.combat = {}
                ladder.perkScores.survivalist = {}
                if AshenMPRanking.sandboxSettings.otherPerks then
                    ladder.perkScores.otherPerks = {}
                end
                -- ladder for LaResistenzaMarket
                if getGameTime():getModData().LRMPlayerInventory ~= nil then
                    ladder.perkScores.lrm = {}
                end
            end
            if AshenMPRanking.sandboxSettings.otherPerks and ladder.perkScores.otherPerks == nil then
                ladder.perkScores.otherPerks = {}
            end
            if getGameTime():getModData().LRMPlayerInventory ~= nil and ladder.perkScores.lrm == nil then
                ladder.perkScores.lrm = {}
            end
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
        elseif ladder.perkScores ~= nil then
            ladder.perkScores = nil
        end

        lastUpdate[username] = os.time()
    -- elseif accesslevel not equal to None
    elseif player:getAccessLevel() ~= "None" and ladder.deaths[username] ~= nil then
        -- print("AMPR purging data of elevated account: ", playerData.username)
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
            -- print("AMPR DEBUG: writing ladder to file")
            -- SaveToFile(ladder, "ladder.csv", {})
            -- save to modData
            saveModData(tag_active, ladder)
            saveModData(tag_lastupdate, lastUpdate)
            lastWrite = os.time()
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
    elseif command == "addToRankings" then
        if inactiveAccounts.daysSurvived[args.username] ~= nil then
            args.fail_msg = "UI_ErrorPlayerInactive"
        else 
            local fail_msg = addNewUser(args.username)
            if fail_msg ~= nil then
                args.fail_msg = "UI_ErrorPlayerRanked"
            else
                args.success_msg = "UI_PlayerAdded"
            end         
        end
        sendServerCommand(player, "AshenMPRanking", "ccServerResponse", args)
    elseif command == "removeFromRankings" then
        if inactiveAccounts.daysSurvived[args.username] ~= nil then
            args.fail_msg = "UI_ErrorPlayerInactive"
        else
            local fail_msg = purgeCheater(args.username)
            if fail_msg ~= nil then
                args.fail_msg = "UI_ErrorPlayerNotRanked"
            else
                args.success_msg = "UI_PlayerRemoved"
            end
        end
        sendServerCommand(player, "AshenMPRanking", "ccServerResponse", args)
    elseif command == "showInactive" then
        -- checkInactive(3, "") -- calling checkInactive with mode 3 to populate
        if inactiveAccounts.daysSurvived == nil then
            args.fail_msg = "UI_NoInactive"
            sendServerCommand(player, "AshenMPRanking", "ccServerResponse", args)
        else
            args = {}
            args.success_msg = ""
            for k,v in pairs(inactiveAccounts.daysSurvived) do
                -- add to args
                args.success_msg = args.success_msg  .. " - " .. k
            end
            if args.success_msg == "" then
                args.fail_msg = "UI_NoInactive"
            end
            sendServerCommand(player, "AshenMPRanking", "ccServerResponse", args)
        end 
    elseif command == "activeToInactive" then
        local result = checkInactive(2, args.username)
        if result then
            args.success_msg = "UI_ActiveToInactive"
        else
            args.fail_msg = "UI_ErrorPlayerNotRanked"
        end
        sendServerCommand(player, "AshenMPRanking", "ccServerResponse", args)
    elseif command == "inactiveToActive" then
        local result = checkInactive(1, args.username)
        if result then
            args.success_msg = "UI_InactiveToActive"
        else
            args.fail_msg = "UI_ErrorPlayerNotInactive"
        end
        sendServerCommand(player, "AshenMPRanking", "ccServerResponse", args)
    end
end

-- see if the file exists
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- get/set TotalKills public functions
function getTotalKills(username, value)
    return ladder.zKillsTot[username]
end

function setTotalKills(username, value)
    ladder.zKillsTot[username] = value
end

--get/set Deaths public functions
function getDeaths(username, value)
    return ladder.deaths[username]
end

function setDeaths(username, value)
    ladder.deaths[username] = value
end

local function onInitGlobalModData(isNewGame)
    -- load active players from ModData
    tag_active = "AshenMPRanking." .. getServerName() .. ".ladder"
    ladder = ModData.getOrCreate(tag_active)
    -- print('loading ModData(ACTIVE) -> ' .. tag_active)
    -- ladder = {}
    -- if ladder.daysSurvived ~= nil then
    --     for k,v in pairs(ladder.daysSurvived) do
    --         print('ladder', k,v)
    --     end
    -- end

    -- load active players from ModData
    tag_lastupdate = "AshenMPRanking." .. getServerName() .. ".lastUpdate"
    lastUpdate = ModData.getOrCreate(tag_lastupdate)
    -- print('loading ModData(ACTIVE) -> ' .. tag_active)
    -- lastUpdate = {}
    -- for k,v in pairs(lastUpdate) do
    --     print('lastUpdate', k,v)
    -- end

    -- loading inactive players from ModData
    tag_inactive = "AshenMPRanking." .. getServerName() .. ".inactiveAccounts"
    inactiveAccounts = ModData.getOrCreate(tag_inactive)
    -- print('loading ModData(INACTIVE) -> ' .. tag_inactive)
    -- inactiveAccounts = {}
    -- if inactiveAccounts.daysSurvived ~= nil then
    --     for k,v in pairs(inactiveAccounts.daysSurvived) do
    --         print('inactive', k,v)
    --     end
    -- end
end

AshenMPRanking.api = {}
-- associamo getKills a una variabile di AshenMPRanking
AshenMPRanking.api.getKills = function(username)
    return ladder.zKills[username]
end

AshenMPRanking.api.getPosition = function(laddertype, laddername, position)
    if laddertype == nil then
        -- for k,v in pairs(oLadder[laddername]) do
        --     -- print(k, v)
        --     if k == position then
        --         local result = {}
        --         result.username = v[1]
        --         result.score = v[2]
        --         print(result.username, result.score)
        --     end
        -- end
        if oLadder[laddername] ~= nil then
            if oLadder[laddername][position] ~= nil then
                local result = {}
                result.username = oLadder[laddername][position][1]
                result.score = oLadder[laddername][position][2]
                return result
            end
        else
            return "No data"
        end
    else 
        if oLadder[laddertype][laddername] ~= nil then
            if oLadder[laddertype][laddername][position] ~= nil then
                local result = {}
                result.username = oLadder[laddertype][laddername][position][1]
                result.score = oLadder[laddertype][laddername][position][2]
                return result
            end
        else
            return "No data"
        end
    end
end

Events.OnServerStarted.Add(initServer)
Events.OnPlayerDeath.Add(onPlayerDeathReset)
Events.OnClientCommand.Add(clientCommandDispatcher)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
