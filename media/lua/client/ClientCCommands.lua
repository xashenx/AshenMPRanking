if isServer() then return end;

require "Chat/ISChat"

-- The or is necessary for reloading to keep prior commands and not cause an infinite loop with ISChat.onCommandEntered referring to itself.
Commandeer_CommandHandler = Commandeer_CommandHandler or {}
Commandeer_CommandHandler.commands = Commandeer_CommandHandler.commands or {}
Commandeer_CommandHandler.oldCommandHandler = Commandeer_CommandHandler.oldCommandHandler or ISChat.onCommandEntered

ISChat.onCommandEntered = function(self)
	local commandText = ISChat.instance.textEntry:getText();
	local player = getPlayer();
	
	if string.len(commandText) >= 2048 then
		player:addLineChatElement("Your message was too long. Try again.", 1, 0, 0);
		return;
	end
	
	for command, commandfunc in pairs(Commandeer_CommandHandler.commands) do
		-- it's too bad that lua regex lacks \b for word boundaries
		if (#commandText == #command and luautils.stringStarts(commandText, command)) or luautils.stringStarts(commandText, command.." ") then
			ISChat.instance:unfocus(); -- unfocus must be done here since it sets text to ""
			-- if we do it earlier, we can't call oldCommandHandler
			local fail_message = commandfunc(commandText:sub(#command+2)); -- +1 because sub is inclusive, +1 because of the space
			-- it's fine if the argument to sub is over, that just returns an empty string
			
			if fail_message then
				player:addLineChatElement(fail_message, 1, 0, 0);
			end
			
			-- a bit of copy-pasted code, but we can't risk sending it to the server
			doKeyPress(false); -- and getting a bad command message when it isn't recognised
			ISChat.instance.timerTextEntry = 20; -- too bad TIS doesn't have an api for adding commands that would make
			return; -- this mod totally unnecessary!
		end
	end
	Commandeer_CommandHandler.oldCommandHandler(self);
end

Commandeer_CommandHandler.oldCreateChildren = ISChat.createChildren;
function ISChat.createChildren(self)
	Commandeer_CommandHandler.oldCreateChildren(self)
	self.textEntry.onCommandEntered = ISChat.onCommandEntered;
end

Commandeer_CommandHandler.commands["/removeranking"] = function(param)
    local player = getPlayer()
    
    if player:getAccessLevel() ~= "Admin" then
        local text = string.format("%s %s: ((%s))", player:getUsername(), "is trying to use /removeranking without rights", player:getAccessLevel())
        return
    end

	if not param or param == "" then
		return "Usage: /removeranking [username]";
	end

    local data = {}
    -- param might be string with spaces, so we need to split it
    for toRemove in string.gmatch(param, "%S+") do
        data.username = toRemove
        sendClientCommand(player, "AshenMPRanking", "removeFromRankings", data)
    end
end

Commandeer_CommandHandler.commands["/addranking"] = function(param)
    local player = getPlayer()
    if player:getAccessLevel() ~= "Admin" then
        local text = string.format("%s %s: ((%s))", player:getUsername(), "is trying to use /addranking without rights", player:getAccessLevel())
        return
    end
    
	if not param or param == "" then
		return "Usage: /addranking [username]";
	end

    -- param might be string with spaces, so we need to split it
    local data = {}
    for toAdd in string.gmatch(param, "%S+") do
        data.username = toAdd
        sendClientCommand(player, "AshenMPRanking", "addToRankings", data)
    end
end

Commandeer_CommandHandler.commands["/ar"] = Commandeer_CommandHandler.commands["/addranking"]
Commandeer_CommandHandler.commands["/rr"] = Commandeer_CommandHandler.commands["/removeranking"]

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

Events.OnServerCommand.Add(onServerResponse)