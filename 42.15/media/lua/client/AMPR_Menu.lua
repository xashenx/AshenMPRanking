if isServer() then return end;

MenuActions = MenuActions or {}

function MenuActions:onAddUserClick(button)
    if button.internal == "OK" then
        -- print("Parent Name IT: " .. button.parent.entry:getInternalText())
        -- print("Parent Name Placeholder: " .. button.parent.entry:getPlaceholderText())
        local text = button.parent.entry:getText()
        if text and text ~= "" then
            sendClientCommand("AshenMPRanking", "addToRankings", { username = text })
        end
    end
end

function MenuActions:onRemoveUserClick(button)
    if button.internal == "OK" then
        local text = button.parent.entry:getText()
        if text and text ~= "" then
            sendClientCommand("AshenMPRanking", "removeFromRankings", { username = text })
        end
    end
end

function MenuActions:onA2IClick(button)
    if button.internal == "OK" then
        local text = button.parent.entry:getText()
        if text and text ~= "" then
            sendClientCommand("AshenMPRanking", "activeToInactive", { username = text })
        end
    end
end

function MenuActions:onI2AClick(button)
    if button.internal == "OK" then
        local text = button.parent.entry:getText()
        if text and text ~= "" then
            sendClientCommand("AshenMPRanking", "inactiveToActive", { username = text })
        end
    end
end

function MenuActions:onConfirmReset(button)
    if button.internal == "OK" then
        print("RESET CONFIRMED: " .. button.parent.entry:getText())
        local text = button.parent.entry:getText()
        if text == "YES" then
            sendClientCommand("AshenMPRanking", "ResetRanking", {})
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
    menu:addOption("Add User", nil, function()
        local addUseInput = ISTextBox:new(0, 0, 280, 180, "Enter Player Username:", "", MenuActions, MenuActions.onAddUserClick, playerIndex)
        addUseInput:initialise()
        addUseInput:addToUIManager()
    end)
    menu:addOption("Remove User", nil, function()
        local removeUseInput = ISTextBox:new(0, 0, 280, 180, "Enter Player Username:", "", MenuActions, MenuActions.onRemoveUserClick, playerIndex)
        removeUseInput:initialise()
        removeUseInput:addToUIManager()
    end)
    menu:addOption("Show Inactive", nil, function() sendClientCommand("AshenMPRanking", "showInactive", {}) end)
    menu:addOption("Move User Active2Inactive", nil, function()
        local a2iInput = ISTextBox:new(0, 0, 280, 180, "Enter Player Username:", "", MenuActions, MenuActions.onA2IClick, playerIndex)
        a2iInput:initialise()
        a2iInput:addToUIManager()
    end)
    menu:addOption("Move User Inactive2Active", nil, function()
        local i2aInput = ISTextBox:new(0, 0, 280, 180, "Enter Player Username:", "", MenuActions, MenuActions.onI2AClick, playerIndex)
        i2aInput:initialise()
        i2aInput:addToUIManager()
    end)
    menu:addOption("Reset Ranking", nil, function()
        local resetInput = ISTextBox:new(0, 0, 280, 180, "Confirm Reset (type YES):", "", MenuActions, MenuActions.onConfirmReset, playerIndex)
        resetInput:initialise()
        resetInput:addToUIManager()
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
        if reponseData.username then
            text = string.gsub(getText(reponseData.fail_msg), "%%%%s", reponseData.username)
        else
            text = getText(reponseData.fail_msg)
        end
        processSayMessage(string.format(text, "red"))
    elseif reponseData.success_msg ~= nil then
        if reponseData.username then
            text = string.gsub(getText(reponseData.success_msg), "%%%%s", reponseData.username)
        else
            text = getText(reponseData.success_msg)
        end
        processSayMessage(string.format(text, "green", reponseData.username))
    end
end

Events.OnFillWorldObjectContextMenu.Add(doMenu)
Events.OnServerCommand.Add(onServerResponse)