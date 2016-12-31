----------------------------------------------------------------------------------
-- Total RP 3
-- Chat management
--	---------------------------------------------------------------------------
--	Copyright 2014 Sylvain Cossement (telkostrasz@telkostrasz.be)
--
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.
----------------------------------------------------------------------------------

-- imports
local Globals, Utils = TRP3_API.globals, TRP3_API.utils;
local loc = TRP3_API.locale.getText;
local unitIDToInfo, unitInfoToID = Utils.str.unitIDToInfo, Utils.str.unitInfoToID;
local get = TRP3_API.profile.getData;
local IsUnitIDKnown = TRP3_API.register.isUnitIDKnown;
local getUnitIDCurrentProfile, isIDIgnored = TRP3_API.register.getUnitIDCurrentProfile, TRP3_API.register.isIDIgnored;
local strsub, strlen, format, _G, pairs, tinsert, time, strtrim = strsub, strlen, format, _G, pairs, tinsert, time, strtrim;
local GetPlayerInfoByGUID, RemoveExtraSpaces, GetTime, PlaySound = GetPlayerInfoByGUID, RemoveExtraSpaces, GetTime, PlaySound;
local getConfigValue, registerConfigKey, registerHandler = TRP3_API.configuration.getValue, TRP3_API.configuration.registerConfigKey, TRP3_API.configuration.registerHandler;
local ChatFrame_RemoveMessageEventFilter, ChatFrame_AddMessageEventFilter = ChatFrame_RemoveMessageEventFilter, ChatFrame_AddMessageEventFilter;
local ChatEdit_GetActiveWindow, IsAltKeyDown = ChatEdit_GetActiveWindow, IsAltKeyDown;
local oldChatFrameOnEvent;
local handleCharacterMessage, hooking;

TRP3_API.chat = {};

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Config
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local POSSIBLE_CHANNELS

local CONFIG_NAME_METHOD = "chat_name";
local CONFIG_NAME_COLOR = "chat_color";
local CONFIG_NPC_TALK = "chat_npc_talk";
local CONFIG_NPC_TALK_PREFIX = "chat_npc_talk_p";
local CONFIG_EMOTE = "chat_emote";
local CONFIG_EMOTE_PATTERN = "chat_emote_pattern";
local CONFIG_USAGE = "chat_use_";
local CONFIG_OOC = "chat_ooc";
local CONFIG_OOC_PATTERN = "chat_ooc_pattern";
local CONFIG_OOC_COLOR = "chat_ooc_color";
local CONFIG_YELL_NO_EMOTE = "chat_yell_no_emote";
local CONFIG_INSERT_FULL_RP_NAME = "chat_insert_full_rp_name";
local CONFIG_INCREASE_CONTRAST = "chat_color_contrast";

local function configNoYelledEmote()
	return getConfigValue(CONFIG_YELL_NO_EMOTE);
end

local function configNameMethod()
	return getConfigValue(CONFIG_NAME_METHOD);
end

local function configShowNameCustomColors()
	return getConfigValue(CONFIG_NAME_COLOR);
end

local function configIsChannelUsed(channel)
	return getConfigValue(CONFIG_USAGE .. channel);
end

local function configDoHandleNPCTalk()
	return getConfigValue(CONFIG_NPC_TALK);
end

local function configNPCTalkPrefix()
	return getConfigValue(CONFIG_NPC_TALK_PREFIX);
end

local function configDoEmoteDetection()
	return getConfigValue(CONFIG_EMOTE);
end

local function configEmoteDetectionPattern()
	return getConfigValue(CONFIG_EMOTE_PATTERN);
end

local function configDoOOCDetection()
	return getConfigValue(CONFIG_OOC);
end

local function configOOCDetectionPattern()
	return getConfigValue(CONFIG_OOC_PATTERN);
end

local function configOOCDetectionColor()
	return getConfigValue(CONFIG_OOC_COLOR);
end

local function configInsertFullRPName()
    return getConfigValue(CONFIG_INSERT_FULL_RP_NAME);
end

local function createConfigPage()
	-- Config default value
	registerConfigKey(CONFIG_NAME_METHOD, 3);
	registerConfigKey(CONFIG_NAME_COLOR, true);
	registerConfigKey(CONFIG_INCREASE_CONTRAST, false);
	registerConfigKey(CONFIG_NPC_TALK, true);
	registerConfigKey(CONFIG_NPC_TALK_PREFIX, "|| ");
	registerConfigKey(CONFIG_EMOTE, true);
	registerConfigKey(CONFIG_EMOTE_PATTERN, "(%*.-%*)");
	registerConfigKey(CONFIG_OOC, true);
	registerConfigKey(CONFIG_OOC_PATTERN, "(%(.-%))");
	registerConfigKey(CONFIG_OOC_COLOR, "aaaaaa");
	registerConfigKey(CONFIG_YELL_NO_EMOTE, false);
    registerConfigKey(CONFIG_INSERT_FULL_RP_NAME, true);

	local NAMING_METHOD_TAB = {
		{loc("CO_CHAT_MAIN_NAMING_1"), 1},
		{loc("CO_CHAT_MAIN_NAMING_2"), 2},
		{loc("CO_CHAT_MAIN_NAMING_3"), 3},
		{loc("CO_CHAT_MAIN_NAMING_4"), 4},
	}
	
	local EMOTE_PATTERNS = {
		{"* Emote *", "(%*.-%*)"},
		{"** Emote **", "(%*%*.-%*%*)"},
		{"< Emote >", "(%<.-%>)"},
		{"* Emote * + < Emote >", "([%*%<].-[%*%>])"},
	}
	
	local OOC_PATTERNS = {
		{"( OOC )", "(%(.-%))"},
		{"(( OOC ))", "(%(%(.-%)%))"},
	}

	-- Build configuration page
	local CONFIG_STRUCTURE = {
		id = "main_config_chatframe",
		menuText = loc("CO_CHAT"),
		pageText = loc("CO_CHAT"),
		elements = {
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_MAIN"),
			},
			{
				inherit = "TRP3_ConfigDropDown",
				widgetName = "TRP3_ConfigurationTooltip_Chat_NamingMethod",
				title = loc("CO_CHAT_MAIN_NAMING"),
				listContent = NAMING_METHOD_TAB,
				configKey = CONFIG_NAME_METHOD,
				listCancel = true,
			},
            {
                inherit = "TRP3_ConfigCheck",
                title = loc("CO_CHAT_INSERT_FULL_RP_NAME"),
                configKey = CONFIG_INSERT_FULL_RP_NAME,
                help = loc("CO_CHAT_INSERT_FULL_RP_NAME_TT")
            },
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_COLOR"),
				configKey = CONFIG_NAME_COLOR,
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = "Increase color contrast",
				configKey = CONFIG_INCREASE_CONTRAST,
			},
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_MAIN_NPC"),
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_NPC_USE"),
				configKey = CONFIG_NPC_TALK,
			},
			{
				inherit = "TRP3_ConfigEditBox",
				title = loc("CO_CHAT_MAIN_NPC_PREFIX"),
				configKey = CONFIG_NPC_TALK_PREFIX,
				help = loc("CO_CHAT_MAIN_NPC_PREFIX_TT")
			},
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_MAIN_EMOTE"),
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_EMOTE_YELL"),
				help = loc("CO_CHAT_MAIN_EMOTE_YELL_TT"),
				configKey = CONFIG_YELL_NO_EMOTE,
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_EMOTE_USE"),
				configKey = CONFIG_EMOTE,
			},
			{
				inherit = "TRP3_ConfigDropDown",
				widgetName = "TRP3_ConfigurationTooltip_Chat_EmotePattern",
				title = loc("CO_CHAT_MAIN_EMOTE_PATTERN"),
				listContent = EMOTE_PATTERNS,
				configKey = CONFIG_EMOTE_PATTERN,
				listCancel = true,
			},
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_MAIN_OOC"),
			},
			{
				inherit = "TRP3_ConfigCheck",
				title = loc("CO_CHAT_MAIN_OOC_USE"),
				configKey = CONFIG_OOC,
			},
			{
				inherit = "TRP3_ConfigDropDown",
				widgetName = "TRP3_ConfigurationTooltip_Chat_OOCPattern",
				title = loc("CO_CHAT_MAIN_OOC_PATTERN"),
				listContent = OOC_PATTERNS,
				configKey = CONFIG_OOC_PATTERN,
				listCancel = true,
			},
			{
				inherit = "TRP3_ConfigColorPicker",
				title = loc("CO_CHAT_MAIN_OOC_COLOR"),
				configKey = CONFIG_OOC_COLOR,
			},
			{
				inherit = "TRP3_ConfigH1",
				title = loc("CO_CHAT_USE"),
			},
		}
	};

	for _, channel in pairs(POSSIBLE_CHANNELS) do
		registerConfigKey(CONFIG_USAGE .. channel, true);
		registerHandler(CONFIG_USAGE .. channel, hooking);
		tinsert(CONFIG_STRUCTURE.elements, {
			inherit = "TRP3_ConfigCheck",
			title = _G[channel],
			configKey = CONFIG_USAGE .. channel,
		});
	end

	TRP3_API.configuration.registerConfigurationPage(CONFIG_STRUCTURE);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Utils
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function getCharacterClassColor(chatInfo, event, text, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, GUID)
	local color;
	if ( chatInfo and chatInfo.colorNameByClass and GUID ) then
		local localizedClass, englishClass = GetPlayerInfoByGUID(GUID);
		if englishClass and RAID_CLASS_COLORS[englishClass] then
			local classColorTable = RAID_CLASS_COLORS[englishClass];
			return ("|cff%.2x%.2x%.2x"):format(classColorTable.r*255, classColorTable.g*255, classColorTable.b*255);
		end
	end
end

local function getCharacterInfoTab(unitID)
	if unitID == Globals.player_id then
		return get("player");
	elseif IsUnitIDKnown(unitID) then
		return getUnitIDCurrentProfile(unitID) or {};
	end
	return {};
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Emote and OOC detection
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function detectEmoteAndOOC(type, message)
	if configDoEmoteDetection() and message:find(configEmoteDetectionPattern()) then
		local chatInfo = ChatTypeInfo["EMOTE"];
		local color = ("|cff%.2x%.2x%.2x"):format(chatInfo.r*255, chatInfo.g*255, chatInfo.b*255);
		message = message:gsub(configEmoteDetectionPattern(), function(content)
			return color .. content .. "|r";
		end);
	end
	if configDoOOCDetection() and message:find(configOOCDetectionPattern()) then
		message = message:gsub(configOOCDetectionPattern(), function(content)
			return "|cff" .. configOOCDetectionColor() .. content .. "|r";
		end);
	end
	return message;
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- NPC talk detection
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local NPC_TALK_CHANNELS = {
	CHAT_MSG_SAY = 1, CHAT_MSG_EMOTE = 1, CHAT_MSG_PARTY = 1, CHAT_MSG_RAID = 1, CHAT_MSG_PARTY_LEADER = 1, CHAT_MSG_RAID_LEADER = 1
};
local NPC_TALK_PATTERNS;

local function handleNPCEmote(message)
	for TALK_TYPE, TALK_CHANNEL in pairs(NPC_TALK_PATTERNS) do
		if message:find(TALK_TYPE) then
			local chatInfo = ChatTypeInfo[TALK_CHANNEL];
			local name = message:sub(4, message:find(TALK_TYPE) - 2); -- Isolate the name
			local content = message:sub(name:len() + 5);
			return "|cffff9900" ..name.."|r", string.format("|cff%02x%02x%02x%s|r", chatInfo.r*255, chatInfo.g*255, chatInfo.b*255, content);
		end
	end
	local chatInfo = ChatTypeInfo["MONSTER_EMOTE"];
	return string.format("|cff%02x%02x%02x%s|r", chatInfo.r*255, chatInfo.g*255, chatInfo.b*255, message:sub(4)), " ";
end

local function handleNPCTalk(message)
	for TALK_TYPE, TALK_CHANNEL in pairs(NPC_TALK_PATTERNS) do
		if message:find(TALK_TYPE) then
			local chatInfo = ChatTypeInfo[TALK_CHANNEL];
			local name = message:sub(4, message:find(TALK_TYPE) - 2); -- Isolate the name
			local content = message:sub(name:len()+ TALK_TYPE:len() + 5);
			return "|cffff9900" ..name.."|r]"..string.format("|cff%02x%02x%02x", chatInfo.r*255, chatInfo.g*255, chatInfo.b*255).."\0", content.."|r";
			-- the null character prevents the returning ov the closing ] so we can manually add it and place content after it, due to the way player links deal with strings. - Lora
		end
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Chatframe management
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

-- Ideas:
-- Ignored to another chatframe (config)
-- Limit name length (config)

local npcMessageId, npcMessageName, ownershipNameId;

function handleCharacterMessage(chatFrame, event, ...)

	local message, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, arg12, arg13, arg14, arg15, arg16 = ...;

	local type = strsub(event, 10);
	-- Detect NPC talk pattern on authorized channels
	if event == "CHAT_MSG_EMOTE" then
		if message:sub(1, 3) == configNPCTalkPrefix() and configDoHandleNPCTalk() then
			npcMessageId = messageID; -- pass the messageID to the name altering functionality. - Lora
			npcMessageName, message = handleNPCEmote(message);
			return false, message, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, arg12, arg13, arg14, arg15, arg16;
		elseif message:sub(1, 3) == "'s " then
			-- collapse annoying space between name and apostrophy in owned emotes. -Lora
			ownershipNameId = messageID; -- pass the messageID to the name altering functionality. This uses a separate variable to identify wich method should be used. - Lora
			return false, message:sub(4), characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, arg12, arg13, arg14, arg15, arg16;
		end
	elseif message:sub(1, 3) == configNPCTalkPrefix() and configDoHandleNPCTalk() and NPC_TALK_CHANNELS[event] then
		npcMessageId = messageID;
		npcMessageName, message = handleNPCTalk(message, event);
	end

	-- No yelled emote ?
	if event == "CHAT_MSG_YELL" and configNoYelledEmote() then
		message = message:gsub("%*.-%*", "");
		message = message:gsub("%<.-%>", "");
	end

	-- Colorize emote and OOC
	message = detectEmoteAndOOC(type, message);


	return false, message, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, arg12, arg13, arg14, arg15, arg16;
end

local function getFullnameUsingChatMethod(info, characterName)
	local nameMethod = configNameMethod();
	if nameMethod ~= 1 then -- TRP3 names
		local characteristics = info.characteristics or {};
		if characteristics.FN then
			characterName = characteristics.FN;
		end

		if nameMethod == 4 and characteristics.TI then
			characterName = characteristics.TI .. " " .. characterName;
		end

		if (nameMethod == 3 or nameMethod == 4) and characteristics.LN then -- With last name
			characterName = characterName .. " " .. characteristics.LN;
		end
	end
	return characterName;
end
TRP3_API.chat.getFullnameUsingChatMethod = getFullnameUsingChatMethod;

local function getColoredName(info)
	local characterColor;
	if configShowNameCustomColors() and info.characteristics and info.characteristics.CH then
		local color = info.characteristics.CH;
		if getConfigValue(CONFIG_INCREASE_CONTRAST) then
			local r, g, b = Utils.color.hexaToFloat(color);
			local ligthenColor = Utils.color.lightenColorUntilItIsReadable({r = r, g = g, b = b});
			color = Utils.color.numberToHexa(ligthenColor.r * 255) .. Utils.color.numberToHexa(ligthenColor.g * 255) .. Utils.color.numberToHexa(ligthenColor.b * 255);
		end
		characterColor = color;
	end
	return characterColor;
end
TRP3_API.chat.getColoredName = getColoredName;

local tempGetColoredName = GetColoredName;
function Utils.customGetColoredName(event, ...)
	local characterName, characterColor;
	local message, characterID, language, arg4, arg5, arg6, arg7, arg8, arg9, arg10, messageID, arg12, arg13, arg14, arg15, arg16 = ...;
	local character, realm = unitIDToInfo(characterID);
	if not realm then -- Thanks Blizzard to not always send a full character ID
		realm = Globals.player_realm_id;
		if realm == nil then
			-- if realm is nil (i.e. globals haven't been set yet) just run the vanilla version of the code to prevent errors.
			return tempGetColoredName(event, ...);
		end
	end
	characterID = unitInfoToID(character, realm);
	local info = getCharacterInfoTab(characterID);

	-- Get chat type and configuration
	local type = strsub(event, 10);
	local chatInfo = ChatTypeInfo[type];

	-- NPC talk pattern is detected in filter before being passed over here.
	if npcMessageId == messageID then
		return npcMessageName;
	end

	-- WHISPER and WHISPER_INFORM have the same chat info
	if ( strsub(type, 1, 7) == "WHISPER" ) then
		chatInfo = ChatTypeInfo["WHISPER"];
	end

	-- Character name
	if realm == Globals.player_realm_id then
		characterName = character;
	else
		characterName = characterID;
	end

	characterName = getFullnameUsingChatMethod(info, character);

	if ownershipNameId == messageID then
		characterName = characterName.."'s";
	end

	if characterName ~= character and characterName ~= characterID then
		characterColor = getColoredName(info);
		-- Then class color
		if not characterColor then
			characterColor = getCharacterClassColor(chatInfo, event, ...);
		else
			characterColor =  "|cff" .. characterColor;
		end
		if characterColor then
			characterName = characterColor .. characterName .. "|r";
		end
		return characterName;
	else
		return tempGetColoredName(event, ...);
	end
end

function hooking()
	for _, channel in pairs(POSSIBLE_CHANNELS) do
		ChatFrame_RemoveMessageEventFilter(channel, handleCharacterMessage);
		if configIsChannelUsed(channel) then
			ChatFrame_AddMessageEventFilter(channel, handleCharacterMessage);
		end
	end

	GetColoredName = Utils.customGetColoredName;

	-- Hook the ChatEdit_InsertLink() function that is called when the user SHIFT-Click a player name
	-- in the chat frame to insert it into a text field.
	-- We can replace the name inserted by the complete RP name of the player if we have it.
	hooksecurefunc("ChatEdit_InsertLink", function(name)

		-- Do not modify the name inserted if the option is not enabled or if the ALT key is down.
		if not configInsertFullRPName() or IsAltKeyDown() then return end;

		local activeChatFrame = ChatEdit_GetActiveWindow();
		if activeChatFrame and activeChatFrame.chatFrame and activeChatFrame.chatFrame.editBox then
			local editBox = activeChatFrame.chatFrame.editBox;
			local currentText = editBox:GetText();
			local currentCursorPosition = editBox:GetCursorPosition();

			-- Save the text that is before and after the name inserted
			local textBefore = currentText:sub(1, currentCursorPosition - name:len() - 1);
			local textAfter = currentText:sub(currentCursorPosition+1 );

			-- Retreive the info for the character and the naming method to use
			local info = getCharacterInfoTab(name);
			local nameMethod = configNameMethod();

			if info and info.characteristics and nameMethod ~= 1 then -- TRP3 names
			local characteristics = info.characteristics;
			-- Replace the name by the RP name
			if characteristics.FN then
				name = characteristics.FN;
			end

			-- If the naming method is to use titles, add the short title before the name
			if nameMethod == 4 and characteristics.TI then
				name = characteristics.TI .. " " .. name;
			end

			-- If the naming method is to use lastnames, add the lastname behind the name
			if (nameMethod == 3 or nameMethod == 4) and characteristics.LN then -- With last name
			name = name .. " " .. characteristics.LN;
			end

			-- Replace the text of the edit box
			editBox:SetText(textBefore .. name .. textAfter);
			-- Move the cursor to the end of the insertion
			editBox:SetCursorPosition(textBefore:len() + name:len());
			end
		end
	end);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Init
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function onStart()

	POSSIBLE_CHANNELS = {
		"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
		"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM"
	};


	NPC_TALK_PATTERNS = {
		[loc("NPC_TALK_SAY_PATTERN")] = "MONSTER_SAY",
		[loc("NPC_TALK_YELL_PATTERN")] = "MONSTER_YELL",
		[loc("NPC_TALK_WHISPER_PATTERN")] = "MONSTER_WHISPER",
	};
	createConfigPage();
	hooking();
end

local MODULE_STRUCTURE = {
	["name"] = "Chat frames",
	["description"] = "Global enhancement for chat frames. Use roleplay information, detect emotes and OOC sentences and use colors.",
	["version"] = 1.000,
	["id"] = "trp3_chatframes",
	["onStart"] = onStart,
	["minVersion"] = 3,
};

TRP3_API.module.registerModule(MODULE_STRUCTURE);