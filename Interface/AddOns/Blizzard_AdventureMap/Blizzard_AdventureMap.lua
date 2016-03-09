UIPanelWindows["AdventureMapFrame"] = { area = "center", pushable = 0, showFailedFunc = C_AdventureMap.Close, allowOtherPanels = 1 };

AdventureMapMixin = {};

function AdventureMapMixin:SetupTitle()
	self.BorderFrame.TitleText:SetText(ADVENTURE_MAP_TITLE);
	self.BorderFrame.Bg:SetColorTexture(0, 0, 0, 1);
	self.BorderFrame.Bg:SetParent(self);
	self.BorderFrame.TopTileStreaks:Hide();
	
	SetPortraitToTexture(self.BorderFrame.portrait, [[Interface/Icons/inv_misc_map02]]);
end

-- Override
function AdventureMapMixin:OnLoad()
	MapCanvasMixin.OnLoad(self);

	self.mapInsetPool = CreateFramePool("FRAME", self:GetCanvas(), "AdventureMapInsetTemplate", function(pool, mapInset) mapInset:OnReleased(); end);

	self:RegisterEvent("ADVENTURE_MAP_CLOSE");
	self:RegisterEvent("ADVENTURE_MAP_UPDATE_INSETS");
	self:RegisterEvent("QUEST_LOG_UPDATE");
	
	self:SetupTitle();

	self:AddStandardDataProviders();
end

function AdventureMapMixin:AddStandardDataProviders()
	--self:AddDataProvider(CreateFromMixins(AdventureMap_ZoneLabelDataProviderMixin));
	--self:AddDataProvider(CreateFromMixins(AdventureMap_ZoneSummaryProviderMixin));
	self:AddDataProvider(CreateFromMixins(AdventureMap_QuestChoiceDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(AdventureMap_QuestOfferDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(AdventureMap_WorldQuestDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(AdventureMap_MissionDataProviderMixin));
end

function AdventureMapMixin:ClearAreaTableIDAvailableForInsets()
	self.areaTableIDsToDisplay = {};
end

function AdventureMapMixin:SetAreaTableIDAvailableForInsets(areaID)
	self.areaTableIDsToDisplay[areaID] = true;
end

-- Override
function AdventureMapMixin:OnShow()
	local continentID = C_AdventureMap.GetContinentInfo();
	self:SetMapID(continentID);
	self:ClearAreaTableIDAvailableForInsets();
	MapCanvasMixin.OnShow(self);
end

-- Override
function AdventureMapMixin:OnHide()
	MapCanvasMixin.OnHide(self);

	C_AdventureMap.Close();
end

-- Override
function AdventureMapMixin:OnEvent(event, ...)
	if event == "ADVENTURE_MAP_CLOSE" then
		HideUIPanel(self);
	else
		if event == "QUEST_LOG_UPDATE" then
			if C_AdventureMap.ForceUpdate then
				C_AdventureMap.ForceUpdate();
			end
		elseif event == "ADVENTURE_MAP_UPDATE_INSETS" then
			self:RefreshInsets();
		end

		MapCanvasMixin.OnEvent(self, event, ...);
	end
end

-- Override
function AdventureMapMixin:RefreshInsets()
	MapCanvasMixin.RefreshInsets(self);

	for insetIndex = 1, C_AdventureMap.GetNumMapInsets() do
		local mapID, title, description, collapsedIcon, areaTableID, numDetailTiles, normalizedX, normalizedY = C_AdventureMap.GetMapInsetInfo(insetIndex);
		if (self.areaTableIDsToDisplay[areaTableID]) then
			self:AddInset(insetIndex, mapID, title, description, collapsedIcon, numDetailTiles, normalizedX, normalizedY);
		end
	end
end

function AdventureMapMixin:IsMapInsetExpanded(mapInsetIndex)
	local mapID = C_AdventureMap.GetMapInsetInfo(mapInsetIndex);
	return not not self.expandedMapInsetsByMapID[mapID];
end