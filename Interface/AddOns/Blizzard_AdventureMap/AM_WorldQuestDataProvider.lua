AdventureMap_WorldQuestDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function AdventureMap_WorldQuestDataProviderMixin:OnAdded(mapCanvas)
	MapCanvasDataProviderMixin.OnAdded(self, mapCanvas);
end

function AdventureMap_WorldQuestDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("AdventureMap_WorldQuestPinTemplate");
end

function AdventureMap_WorldQuestDataProviderMixin:OnShow()
	assert(self.ticker == nil);
	self.ticker = C_Timer.NewTicker(1, function() self:RefreshAllData() end);
end

function AdventureMap_WorldQuestDataProviderMixin:OnHide()
	self.ticker:Cancel();
	self.ticker = nil;
end

function AdventureMap_WorldQuestDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();

	local mapAreaID = C_AdventureMap.GetContinentInfo();
	for zoneIndex = 1, C_MapCanvas.GetNumZones(mapAreaID) do
		local zoneMapID, zoneName, left, right, top, bottom = C_MapCanvas.GetZoneInfo(mapAreaID, zoneIndex);
		local taskInfo = C_TaskQuest.GetQuestsForPlayerByMapID(zoneMapID, mapAreaID);

		if taskInfo then
			for i, info in ipairs(taskInfo) do
				if HaveQuestData(info.questId) then
					if QuestMapFrame_IsQuestWorldQuest(info.questId) then
						local timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(info.questId);
						if not timeLeftMinutes or timeLeftMinutes > WORLD_QUESTS_TIME_CRITICAL_MINUTES or info.inProgress then
							self:AddQuest(info);
						end
					end
				end
			end
		end
	end
end

function AdventureMap_WorldQuestDataProviderMixin:AddQuest(info)
	local pin = self:GetMap():AcquirePin("AdventureMap_WorldQuestPinTemplate");
	pin.questID = info.questId;
	pin.worldQuest = true;
	pin.numObjectives = info.numObjectives;
	pin:SetFrameLevel(1000 + self:GetMap():GetNumActivePinsByTemplate("AdventureMap_WorldQuestPinTemplate"));

	local tagID, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex = GetQuestTagInfo(info.questId);
	local tradeskillLineID = tradeskillLineIndex and select(7, GetProfessionInfo(tradeskillLineIndex));

	if isRare and not worldQuestType == LE_QUEST_TAG_TYPE_PVP then
		pin.Background:SetTexCoord(0, 1, 0, 1);
		pin.Highlight:SetTexCoord(0, 1, 0, 1);

		pin.Background:SetSize(45, 45);
		pin.Highlight:SetSize(45, 45);

		pin.Background:SetAtlas("worldquest-questmarker-epic");
		pin.Highlight:SetAtlas("worldquest-questmarker-epic");
	else
		pin.Background:SetSize(75, 75);
		pin.Highlight:SetSize(75, 75);

		pin.Background:SetTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");	
		pin.Highlight:SetTexture("Interface/WorldMap/UI-QuestPoi-NumberIcons");

		pin.Background:SetTexCoord(0.875, 1, 0.375, 0.5);
		pin.Highlight:SetTexCoord(0.625, 0.750, 0.875, 1);
	end

	if isElite then
		pin.Underlay:SetAtlas("worldquest-questmarker-dragon");
		pin.Underlay:Show();
	else
		pin.Underlay:Hide();
	end

	if worldQuestType == LE_QUEST_TAG_TYPE_PVP then
		pin.Texture:SetAtlas("worldquest-icon-pvp-ffa");
		pin.Texture:SetSize(24, 34);
	elseif worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE then
		pin.Texture:SetAtlas("worldquest-icon-petbattle");
		pin.Texture:SetSize(26, 22);
	elseif worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION and WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID] then
		local _, width, height = GetAtlasInfo(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID]);
		pin.Texture:SetAtlas(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID]);
		pin.Texture:SetSize(width * 2, height * 2);
	elseif worldQuestType == LE_QUEST_TAG_TYPE_WORLD_BOSS then
		local _, width, height = GetAtlasInfo("worldquest-icon-boss");
		pin.Texture:SetAtlas("worldquest-icon-boss");
		pin.Texture:SetSize(width * 2, height * 2);
	else
		pin.Texture:SetAtlas("worldquest-questmarker-questbang");
		pin.Texture:SetSize(12, 30);
	end

	local timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(info.questId);
	if timeLeftMinutes and timeLeftMinutes <= WORLD_QUESTS_TIME_LOW_MINUTES then
		pin.TimeLowFrame:Show();
	else
		pin.TimeLowFrame:Hide();
	end

	pin:SetPosition(info.x, info.y);
	pin:Show();
end

--[[ World Quest Pin ]]--
AdventureMap_WorldQuestPinMixin = CreateFromMixins(MapCanvasPinMixin);

function AdventureMap_WorldQuestPinMixin:OnLoad()
	self:SetAlphaStyle(AM_PIN_ALPHA_STYLE_VISIBLE_WHEN_ZOOMED_IN);
	self:SetScaleStyle(AM_PIN_SCALE_STYLE_WITH_TERRAIN);

	self.UpdateTooltip = self.OnMouseEnter;
end

function AdventureMap_WorldQuestPinMixin:OnMouseEnter()
	WorldMapTooltip:SetParent(self:GetMap());
	WorldMapTooltip:SetFrameStrata("TOOLTIP");
	TaskPOI_OnEnter(self);
end

function AdventureMap_WorldQuestPinMixin:OnMouseLeave()
	TaskPOI_OnLeave(self);
	WorldMapTooltip:SetParent(WorldMapFrame);
	WorldMapTooltip:SetFrameStrata("TOOLTIP");
end