if isServer() then return end;

ClientObj = ClientObj or {}

function ClientObj:onAddUserClick(button)
    if button.internal == "OK" then
        local text = button.parent.entry:getText()
        if text and text ~= "" then
            sendClientCommand("AshenMPRanking", "addToRankings", { username = text })
        end
    end
end

local function doMenu(playerIndex, context, worldobjects, test)
    local player = getSpecificPlayer(playerIndex)
    local isadmin = player:getAccessLevel() == "admin"
    if not isadmin then return true end

    local menu = ISContextMenu:getNew(context)
    
    if not menu then return true end

    local opt = context:addOption("Ashen MP Ranking", worldobjects, nil)
    context:addSubMenu(opt, menu)
    menu:addOption("Reset Ranking", nil, function() sendClientCommand("AshenMPRanking", "ResetRanking", {}) end)
    menu:addOption("Add User", nil, function()
        local modal = ISTextBox:new(0, 0, 280, 180, "Enter Player Username:", "", ClientObj, ClientObj.onAddUserClick, playerIndex)
        modal:initialise()
        modal:addToUIManager()
    end)
    return true
end

local onServerResponse = function(module, command, reponseData)
    -- handles the response from the server
    if module ~= "AshenMPRanking" or command ~= "ccServerResponse" then
        return
    end
    
    local text = ""
    if reponseData.fail_msg ~= nil then
        text = "*%s*" .. getText(reponseData.fail_msg)
        processSayMessage(string.format(text, "red", reponseData.username))
    elseif reponseData.success_msg ~= nil then
        text = "*%s*" .. getText(reponseData.success_msg)
        processSayMessage(string.format(text, "green", reponseData.username))
    end
end

Events.OnFillWorldObjectContextMenu.Add(doMenu)
Events.OnServerCommand.Add(onServerResponse)