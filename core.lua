local addon_name, addon_shared = ...;

local _G = getfenv(0);

local LibStub = LibStub;
local Addon = LibStub("AceAddon-3.0"):NewAddon(addon_name, "AceEvent-3.0");
_G[addon_name] = Addon;

_G["BINDING_HEADER_DEMONMASTER"] = "DemonMaster";
_G["BINDING_NAME_TOGGLE_DEMONMASTER"] = "Toggle DemonMaster";

StaticPopupDialogs["DEMONMASTER_NO_KEYBIND"] = {
	text = "DemonMaster does not currently have a keybinding. Do you want to open the key binding menu to set it?|n|nOption you are looking for is found under AddOns category.",
	button1 = YES,
	button2 = NO,
	button3 = "Don't Ask Again",
	OnAccept = function(self)
		KeyBindingFrame_LoadUI();
		KeyBindingFrame.mode = 1;
		ShowUIPanel(KeyBindingFrame);
	end,
	OnCancel = function(self)
	end,
	OnAlt = function()
		DemonMasterKeybindAlert = true;
	end,
	hideOnEscape = 1,
	timeout = 0,
}

local DemonSpells = {
	688,	-- Imp
	697,	-- Voidwalker
	712,	-- Succubus
	691,	-- Felhunter
	30146, 	-- Felguard
	1122,	-- Infernal
	18540,	-- Doomguard
};

local MESSAGE_PATTERN = "|cffe8608fDemonMaster|r %s";
function Addon:AddMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(MESSAGE_PATTERN:format(string.format(pattern, ...)));
end

function Addon:OnInitialize()
	
end

local _, PLAYER_CLASS = UnitClass("player");

function Addon:IsBindingSet()
	return GetBindingKey("TOGGLE_DEMONMASTER") ~= nil;
end

function Addon:OnEnable()
	if(PLAYER_CLASS == "WARLOCK") then
		Addon:RegisterEvent("PLAYER_REGEN_DISABLED");
		
		if(not Addon:IsBindingSet() and not DemonMasterKeybindAlert) then
			StaticPopup_Show("DEMONMASTER_NO_KEYBIND");
		end
	
		if(not DemonMasterLastDemon) then
			DemonMasterLastDemon = "";
		end
		
		Addon.NoResult = true;
	end
end

function Addon:GetRealSpellID(spell_id)
	local spell_name = GetSpellInfo(spell_id);
	local name, _, _, _, _, _, realSpellID = GetSpellInfo(spell_name);
	
	return realSpellID or spell_id;
end

function Addon:PLAYER_REGEN_DISABLED()
	Addon:CloseFrame();
end

function Addon:ResetFrame()
	local prefill = DemonMasterLastDemon or "";
	DemonMasterFrameSearch:SetText(prefill);
	DemonMasterFrameSearch:HighlightText(0, strlen(prefill));
	
	DemonMaster_OnTextChanged(DemonMasterFrameSearch);
end

function Addon:ToggleFrame()
	if(InCombatLockdown()) then return end
	if(PLAYER_CLASS ~= "WARLOCK") then Addon:AddMessage("Not a warlock"); return end
	
	if(not DemonMasterFrame:IsShown()) then
		Addon:OpenFrame();
	else
		Addon:CloseFrame();
	end
end

function Addon:OpenFrame()
	if(PLAYER_CLASS ~= "WARLOCK") then return end
	if(DemonMasterFrame:IsShown()) then return end
	
	Addon:ResetFrame();
	DemonMasterFrame:Show();
	
	DemonMasterFrameSearch:Show();
	DemonMasterFrameSearch:SetFocus();
	
	DemonMasterFrameSpellConfirm:Hide();
end

function Addon:CloseFrame()
	if(Addon.CurrentBinding) then
		SetBinding("ENTER", Addon.CurrentBinding);
		Addon.CurrentBinding = nil;
	end
	
	DemonMasterFrame:Hide();
end

function DemonMaster_OnEditFocusLost()
	-- Addon:CloseFrame()
end

function DemonMaster_OnEnterPressed(self)
	if(Addon.NoResult) then return end
	
	local searchText = strtrim(strlower(self:GetText()));
	if(strlen(searchText) == 0) then
		Addon:CloseFrame();
		return;
	end
	
	if(not Addon.CurrentBinding) then
		Addon.CurrentBinding = GetBindingAction("ENTER");
		SetBinding("ENTER", "CLICK DemonMasterFrameSpellButton:LeftButton");
		
		DemonMasterLastDemon = strtrim(self:GetText());
	end
	
	DemonMasterFrameSearch:Hide();
	DemonMasterFrameSpellConfirm:Show();
end

function DemonMaster_OnTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self)
	
	local searchText = strtrim(strlower(self:GetText()));
	
	if(strlen(searchText) > 0) then
		local tokens = { strsplit(" ", searchText) };
		
		for index, spellID in ipairs(DemonSpells) do
			if(IsSpellKnown(spellID)) then
				local spellName = GetSpellInfo(spellID);
				
				local realSpellID = Addon:GetRealSpellID(spellID);
				local realSpellName, _, realIcon = GetSpellInfo(realSpellID);
				
				local searchSpellName = realSpellName;
				
				local spellFound = true;
				for _, token in ipairs(tokens) do
					spellFound = spellFound and (strmatch(strlower(spellName), token) or strmatch(strlower(searchSpellName), token));
				end
				
				if(spellFound) then
					DemonMasterFrameSpellName:SetText(realSpellName);
					
					DemonMasterFrameSpellButton.icon:SetTexture(realIcon);
					DemonMasterFrameSpellButton.iconBorder:SetVertexColor(0.1, 0.1, 0.1);
					
					DemonMasterFrameSpellButton:SetAttribute("type", "spell");
					DemonMasterFrameSpellButton:SetAttribute("spell", realSpellName);
					
					DemonMasterFrameSpellButton:Show();
					
					Addon.NoResult = false;
					
					break;
				else
					Addon.NoResult = true;
					
					DemonMasterFrameSpellName:SetText("No Result");
					DemonMasterFrameSpellButton:Hide();
				end
			end
		end
	else
		DemonMasterFrameSpellName:SetText("Enter Demon Name");
		DemonMasterFrameSpellButton:Hide();
	end
end

function DemonMaster_OnEscapePressed(self)
	self:ClearFocus();
	Addon:CloseFrame();
end

function DemonMaster_CloseFrame()
	Addon:CloseFrame();
end

function Addon:OnDisable()
		
end
