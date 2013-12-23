--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Total RP 3
-- Register : About section
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

-- functions
local stEtN = TRP3_StringEmptyToNil;
local log = TRP3_Log;
local color = TRP3_Color;
local loc = TRP3_L;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- SCHEMA
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

TRP3_GetDefaultProfile().player = {};

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- TAB MANAGEMENT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local tabGroup;

local function createTabBar()
	local frame = CreateFrame("Frame", "TRP3_RegisterMainTabBar", TRP3_RegisterMain);
	frame:SetSize(400, 30);
	frame:SetPoint("TOPLEFT", 17, -5);
	frame:SetFrameLevel(1);
	tabGroup = TRP3_TabBar_Create(frame,
		{
			{loc("REG_PLAYER_CARACT"), 1, 150},
			{loc("REG_PLAYER_ABOUT"), 2, 110},
			{loc("REG_PLAYER_STYLE_RPSTYLE_SHORT"), 3, 105},
			{loc("REG_PLAYER_PEEK"), 4, 130}
		},
		function(tabWidget, value)
			-- Clear all
			TRP3_RegisterCharact:Hide();
			TRP3_RegisterAbout:Hide();
			TRP3_RegisterRPStyle:Hide();
			TRP3_RegisterPeek:Hide();
			if value == 1 then
				TRP3_onCharacteristicsShown();
			elseif value == 2 then
				TRP3_onPlayerAboutShow();
			elseif value == 3 then
				TRP3_onPlayerRPStyleShow();
			elseif value == 4 then
				TRP3_onPlayerPeekShow();
			end
		end
	);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- INIT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_InitRegister()
	
end

function TRP3_UI_InitRegister()
	TRP3_RegisterMenu({
		id = "main_00_player",
		text = TRP3_PLAYER,
		onSelected = function() TRP3_SetPage("player_main"); end,
	});
	
	TRP3_RegisterPage({
		id = "player_main",
		templateName = "TRP3_RegisterMain",
		frameName = "TRP3_RegisterMain",
		frame = TRP3_RegisterMain,
		background = "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated",
		onPagePostShow = function()
			if tabGroup ~= nil and #tabGroup > 0 then
				tabGroup[1]:GetScript("OnClick")(tabGroup[1]); -- Select the first tab
			end
		end,
	});
	
	TRP3_Register_CharInit();
	TRP3_Register_AboutInit();
	TRP3_Register_StyleInit();
	TRP3_Register_PeekInit();
	TRP3_Register_DataExchangeInit();
	TRP3_Register_TooltipInit();
	
	createTabBar();
end