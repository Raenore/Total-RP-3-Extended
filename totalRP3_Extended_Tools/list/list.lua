----------------------------------------------------------------------------------
-- Total RP 3: Extended features
--	---------------------------------------------------------------------------
--	Copyright 2015 Sylvain Cossement (telkostrasz@totalrp3.info)
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

local Globals, Events, Utils, EMPTY = TRP3_API.globals, TRP3_API.events, TRP3_API.utils, TRP3_API.globals.empty;
local wipe, pairs, strsplit, tinsert, table = wipe, pairs, strsplit, tinsert, table;
local tsize = Utils.table.size;
local getClass = TRP3_API.extended.getClass;
local getTypeLocale = TRP3_API.extended.tools.getTypeLocale;
local loc = TRP3_API.locale.getText;
local Log = Utils.log;
local setTooltipForSameFrame = TRP3_API.ui.tooltip.setTooltipForSameFrame;
local refreshTooltipForFrame = TRP3_RefreshTooltipForFrame;
local showItemTooltip = TRP3_API.inventory.showItemTooltip;

local ToolFrame;
local ID_SEPARATOR = TRP3_API.extended.ID_SEPARATOR;
local TRP3_MainTooltip, TRP3_ItemTooltip = TRP3_MainTooltip, TRP3_ItemTooltip;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- List management: util methods
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local TABS = {
	MY_DB = "MY_DB",
	OTHERS_DB = "OTHERS_DB",
	BACKERS_DB = "BACKERS_DB",
	FULL_DB = "FULL_DB",
}

local currentTab, onLineRightClick;
local refresh;
local linesWidget = {};
local idData = {};
local idList = {};
local LINE_TOP_MARGIN = 25;
local LEFT_DEPTH_STEP_MARGIN = 30;

local function getDB(dbType)
	if dbType == TABS.MY_DB then
		return TRP3_DB.my;
	elseif dbType == TABS.OTHERS_DB then
		return TRP3_DB.exchange;
	elseif dbType == TABS.BACKERS_DB then
		return TRP3_DB.inner;
	end
	return TRP3_DB.global;
end

local function objectHasChildren(class)
	if class then
		if class.IN and tsize(class.IN) > 0 then
			return true;
		end
		if class.TY == TRP3_DB.types.CAMPAIGN and class.QE and tsize(class.QE) > 0 then
			return true;
		end
		if class.TY == TRP3_DB.types.QUEST and class.ST and tsize(class.ST) > 0 then
			return true;
		end
	end
	return false;
end

local function isFirstLevelChild(parentID, childID)
	return childID ~= parentID and childID:sub(1, parentID:len()) == parentID and not childID:sub(parentID:len() + 2):find("%s");
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- List management: lists
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function addChildrenToPool(parentID)
	for objectID, _ in pairs(TRP3_DB.global) do
		if isFirstLevelChild(parentID, objectID) then
			tinsert(idList, objectID);
		end
	end
	refresh();
end

local function removeChildrenFromPool(parentID)
	for objectID, _ in pairs(getDB(currentTab)) do
		if objectID ~= parentID and objectID:sub(1, parentID:len()) == parentID then
			Utils.table.remove(idList, objectID);
		end
	end
	refresh();
end

local function onLineClick(self, button)
	local data = self:GetParent().idData;
	if button == "RightButton" then
		onLineRightClick(self:GetParent(), data);
	else
		if data.type == TRP3_DB.types.ITEM and data.mode == TRP3_DB.modes.QUICK then
			TRP3_API.extended.tools.openItemQuickEditor(self, nil, data.fullID);
		else
			TRP3_API.extended.tools.goToPage(data.fullID);
		end
	end
end

local color = "|cffffff00";
local fieldFormat = "%s: " .. color .. "%s|r";

local function getMetadataTooltipText(rootID, metadata)
	local text =  fieldFormat:format(loc("ROOT_TITLE"), rootID);
	text = text .. "\n" .. fieldFormat:format(loc("ROOT_VERSION"), metadata.V or 1);
	text = text .. "\n" .. fieldFormat:format(loc("ROOT_CREATED_BY"), metadata.CB or "?");
	text = text .. "\n" .. fieldFormat:format(loc("ROOT_CREATED_ON"), metadata.CD or "?");
	text = text .. "\n" .. fieldFormat:format(loc("SPECIFIC_MODE"), TRP3_API.extended.tools.getModeLocale(metadata.MO) or "?");
	return text;
end

local function onLineEnter(self)
	refreshTooltipForFrame(self);
	if self:GetParent().idData.type == TRP3_DB.types.ITEM then
		local class = getClass(self:GetParent().idData.fullID);
		showItemTooltip(self:GetParent(), Globals.empty, class, true, "ANCHOR_RIGHT");
	end
end

local function onLineLeave(self)
	TRP3_MainTooltip:Hide();
	TRP3_ItemTooltip:Hide();
end

local function onLineExpandClick(self)
	if not self.isOpen then
		addChildrenToPool(self:GetParent().idData.fullID);
	else
		removeChildrenFromPool(self:GetParent().idData.fullID);
	end
end

function refresh()
	for _, lineWidget in pairs(linesWidget) do
		lineWidget:Hide();
	end

	table.sort(idList);
	wipe(idData);
	for index, objectID in pairs(idList) do
		local class = getClass(objectID);
		local parts = {strsplit(ID_SEPARATOR, objectID)};
		local rootClass = getClass(parts[1]);
		local depth = #parts;
		local isOpen = idList[index + 1] and idList[index + 1]:sub(1, objectID:len()) == objectID;
		local hasChildren = isOpen or objectHasChildren(class);
		local icon, name, description = TRP3_API.extended.tools.getClassDataSafeByType(class);

		-- idData is wipe frequently: DO NOT STORE PERSISTENT DATA IN IT !!!
		idData[index] = {
			type = class.TY,
			mode = (class.MD and class.MD.MO) or TRP3_DB.modes.NORMAL,
			icon = icon,
			text = name,
			text2 = description,
			depth = depth,
			ID = parts[#parts],
			fullID = objectID,
			isOpen = isOpen,
			hasChildren = hasChildren,
			metadataTooltip = getMetadataTooltipText(parts[1], rootClass.MD or EMPTY),
		}

	end

	for index, idData in pairs(idData) do

		local lineWidget = linesWidget[index];
		if not lineWidget then
			lineWidget = CreateFrame("Frame", "TRP3_ToolFrameListLine" .. index, ToolFrame.list.container.scroll.child, "TRP3_Tools_ListLineTemplate");
			lineWidget.Click:RegisterForClicks("LeftButtonUp", "RightButtonUp");
			lineWidget.Click:SetScript("OnClick", onLineClick);
			lineWidget.Click:SetScript("OnEnter", onLineEnter);
			lineWidget.Click:SetScript("OnLeave", onLineLeave);
			lineWidget.Expand:SetScript("OnClick", onLineExpandClick);
			tinsert(linesWidget, lineWidget);
		end

		lineWidget.Text:SetText(("|cff00ff00%s: |r\"%s|r\" |cff00ffff(ID: %s)"):format(getTypeLocale(idData.type) or UNKNOWN, idData.text or UNKNOWN, idData.ID));

		lineWidget.Expand:Hide();
		if idData.hasChildren then
			lineWidget.Expand:Show();
			lineWidget.Expand.isOpen = idData.isOpen;
			if idData.isOpen then
				lineWidget.Expand:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP");
				lineWidget.Expand:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN");
			else
				lineWidget.Expand:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP");
				lineWidget.Expand:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN");
			end
		end

		setTooltipForSameFrame(lineWidget.Click, "BOTTOMRIGHT", 0, 0, idData.ID, idData.metadataTooltip);

		lineWidget:ClearAllPoints();
		lineWidget:SetPoint("LEFT", LEFT_DEPTH_STEP_MARGIN * (idData.depth - 1), 0);
		lineWidget:SetPoint("RIGHT", -15, 0);
		lineWidget:SetPoint("TOP", 0, (-LINE_TOP_MARGIN) * (index - 1));

		lineWidget.idData = idData;
		lineWidget:Show();
	end

	if #idData == 0 then
		ToolFrame.list.container.Empty:Show();
	else
		ToolFrame.list.container.Empty:Hide();
	end
end

local function filterList()
	-- Here we will filter
	wipe(idList);

	for objectID, object in pairs(getDB(currentTab)) do
		-- Only take the first level objects
		if not objectID:find("%s") and not object.hideFromList then
			tinsert(idList, objectID);
		end
	end

	ToolFrame.list:Show();
	refresh();
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- TABS
-- Tabs in the list section are just pre-filters
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local tabGroup;

local function getDBSize(dbType)
	local DB = getDB(dbType);
	local count = 0;
	for objectID, object in pairs(DB) do
		-- Only take the first level objects
		if not objectID:find("%s") and not object.hideFromList then
			count = count + 1;
		end
	end
	return count;
end

local function onTabChanged(tabWidget, tab)
	tabGroup.tabs[1]:SetText(loc("DB_MY"):format(getDBSize(TABS.MY_DB)));
	tabGroup.tabs[2]:SetText(loc("DB_OTHERS"):format(getDBSize(TABS.OTHERS_DB)));
	tabGroup.tabs[3]:SetText(loc("DB_BACKERS"):format(getDBSize(TABS.BACKERS_DB)));
	tabGroup.tabs[4]:SetText(loc("DB_FULL"):format(getDBSize()));

	TRP3_ItemQuickEditor:Hide();
	ToolFrame.list.bottom.item:Hide();
	ToolFrame.list.bottom.campaign:Hide();
	ToolFrame.list.bottom.item.templates:Hide();

	currentTab = tab or TABS.MY_DB;

	if currentTab == TABS.MY_DB then
		ToolFrame.list.bottom.item:Show();
		ToolFrame.list.bottom.campaign:Show();
		ToolFrame.list.container.Empty:SetText(loc("DB_MY_EMPTY") .. "\n\n\n" .. Utils.str.icon("misc_arrowdown", 50));
	elseif currentTab == TABS.OTHERS_DB then
		ToolFrame.list.container.Empty:SetText(loc("DB_OTHERS_EMPTY"));
	elseif currentTab == TABS.BACKERS_DB then
	else
	end

	filterList();
end

local function createTabBar()
	local frame = CreateFrame("Frame", "TRP3_ToolFrameListTabPanel", ToolFrame.list);
	frame:SetSize(400, 30);
	frame:SetPoint("BOTTOMLEFT", frame:GetParent(), "TOPLEFT", 15, 0);

	tabGroup = TRP3_API.ui.frame.createTabPanel(frame,
		{
			{ "", TABS.MY_DB, 150 },
			{ "", TABS.OTHERS_DB, 150 },
			{ "", TABS.BACKERS_DB, 150 },
			{ "", TABS.FULL_DB, 150 },
		},
		onTabChanged
	);
end

function TRP3_API.extended.tools.toList()
	tabGroup:SelectTab(1);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- List management: Right click
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local ACTION_FLAG_DELETE = "1";
local ACTION_FLAG_ADD = "2";

local function onLineActionSelected(value, button)
	local action = value:sub(1, 1);
	local objectID = value:sub(2);
	if action == ACTION_FLAG_DELETE then
		TRP3_API.extended.unregisterObject(objectID);
		onTabChanged(nil, currentTab);
	elseif action == ACTION_FLAG_ADD then
		TRP3_API.inventory.addItem(nil, objectID);
	end
end

function onLineRightClick(lineWidget, data)
	local values = {};
	tinsert(values, {data.text, nil});
	if currentTab == TABS.MY_DB then
		if not data.fullID:find(TRP3_API.extended.ID_SEPARATOR) then
			tinsert(values, {DELETE, ACTION_FLAG_DELETE .. data.fullID});
		end
	end
	if data.type == TRP3_DB.types.ITEM then
		tinsert(values, {loc("DB_ADD_ITEM"), ACTION_FLAG_ADD .. data.fullID});
	end
	TRP3_API.ui.listbox.displayDropDown(lineWidget, values, onLineActionSelected, 0, true);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- INIT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_API.extended.tools.initList(toolFrame)
	ToolFrame = toolFrame;
	TRP3_API.ui.frame.setupFieldPanel(ToolFrame.list.container, loc("DB_LIST"), 150);
	TRP3_API.ui.frame.setupFieldPanel(ToolFrame.list.filters, loc("DB_FILTERS"), 150);
	TRP3_API.ui.frame.setupFieldPanel(ToolFrame.list.bottom, loc("DB_ACTIONS"), 150);

	createTabBar();

	TRP3_API.events.listenToEvent(TRP3_API.events.NAVIGATION_EXTENDED_RESIZED, function(containerwidth, containerHeight)
		ToolFrame.list.container.scroll.child:SetWidth(containerwidth - 100);
	end);

	-- Button on target bar
	TRP3_API.events.listenToEvent(TRP3_API.events.WORKFLOW_ON_LOADED, function()
		if TRP3_API.toolbar then
			local toolbarButton = {
				id = "bb_extended_tools",
				icon = "Inv_gizmo_01",
				configText = loc("TB_TOOLS"),
				tooltip = loc("TB_TOOLS"),
				tooltipSub = loc("TB_TOOLS_TT"),
				onClick = function()
					TRP3_API.extended.tools.showFrame(true);
				end,
				visible = 1
			};
			TRP3_API.toolbar.toolbarAddButton(toolbarButton);
		end
	end);

	-- My creation tab
	ToolFrame.list.bottom.campaign.Name:SetText(loc("DB_CREATE_CAMPAIGN"));
	ToolFrame.list.bottom.campaign.InfoText:SetText(loc("DB_CREATE_CAMPAIGN_TT"));
	TRP3_API.ui.frame.setupIconButton(ToolFrame.list.bottom.campaign, "achievement_quests_completed_07");

	-- Events
	Events.listenToEvent(Events.ON_OBJECT_UPDATED, function(objectID, objectType)
		onTabChanged(nil, currentTab);
	end);
end