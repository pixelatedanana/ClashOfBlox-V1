--[[
	UnsuspectingSawblade 2021-07-13 12:23:43
]]
export type DataTable = {Level: number, Skin: string}
export type GlobalDataTable = {Id: string, Properties: any?, Name: string, Level: number, Skin: string}

local HttpService = game:GetService("HttpService")
local BuildingData = require(game.ReplicatedStorage.Shared.Systems.BuildingData)
local StructureData = {}
StructureData.__index = StructureData

local function PurifyString(str: string)
	
end

local function GetData(buildingReferenceData)
	local returnTbl = {}

	for i, v in pairs(buildingReferenceData) do
		returnTbl[i] = v
	end

	return returnTbl
end

function StructureData.new(Name: string, Data)
	--print(Data)
	local name = ("%s Level %s"):format(Name, tostring(Data.Level))
	local buildingReferenceData = BuildingData:FindBuildingData(Name)[("Level_%s"):format(tostring(Data.Level))]
	
	local self = setmetatable({
		Name = Name;
		Level = Data.Level;
		Skin = "Default";
		Id = HttpService:GenerateGUID(false),
		Properties = GetData(buildingReferenceData);
		Size = buildingReferenceData.Size;
		Upgrading = false; 
		UpgradeData = {};
		LastLeave = Data.LastLeave or os.time();
	}, StructureData)
	
	if self.Size == nil then
		self.Size = BuildingData.CalculateStructureSize(Name)
	end

	return self
end

function StructureData.fromSerialization(Data: GlobalDataTable)
	local self = StructureData.new(Data.Name, Data)

	self.Id = Data.Id
	self.Properties = Data.Properties

	return self
end

function StructureData:Serialize()
	-- print(self)
	return {
		Name = self.Name;
		Id = self.Id,
		Properties = self.Properties;
		Upgrading = self.Upgrading;
		UpgradeData = self.UpgradeData;
		Level = self.Level;
		Skin = self.Skin;
		LastLeave = os.time();
	}
end


function StructureData:Destroy()
	
end


return StructureData