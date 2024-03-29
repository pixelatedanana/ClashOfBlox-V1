--[[
	UnsuspectingSawblade 2021-07-13 12:10:42

	BaseData.new(): BaseData
	BaseData.fromSerialization(data: table): BaseData

	BaseData.Changed -> Signal
	BaseData.Janitor -> Janitor

	BaseData:PlaceStructure(structureData: StructureData, position: Vector2): boolean
	BaseData:MoveStructure(structureData: StructureData, position: Vector2): boolean
	BaseData:RemoveStructure(structureData: StructureData): void
	BaseData:Destroy(): void

	-- from CellsMixin
	BaseData:IsLocationOccupied(position: Vector2, size: Vector2): boolean
	BaseData:GetCell(position: Vector2): table|nil
	BaseData:SetObjectLocation(object: table, position: Vector2): Void
	BaseData:ClearObjectLocation(object: table): Void
]]
local CellsMixin, StructureData, Janitor, Signal do
	local Knit = require(game:GetService("ReplicatedStorage").Shared.Knit)
	CellsMixin = require(Knit.Shared.Modules.CellsMixin)
	StructureData = require(Knit.Shared.Modules.StructureData)
	Janitor = require(Knit.Shared.Modules.Janitor)
	Signal = require(Knit.Util.Signal)
end

local BaseData = {}
BaseData.__index = BaseData
CellsMixin.Include(BaseData)


function BaseData.new()
	local self = setmetatable(CellsMixin.Init({
		Structures = {},
		StructurePositions = {},
		KnownStructures = {},
		ActiveCanvas = nil,
		Janitor = Janitor.new(),
		Changed = Signal.new(),
		Skin = "Default",
		Troops = {},
	}), BaseData)
	
	self.Janitor:Add(self.Changed)

	return self
end

function BaseData.fromSerialization(data: data)
	local self = BaseData.new()

	for _structureId, serializedData in pairs(data) do
		-- print("HEY :::::: ", serializedData)
		local position = Vector2.new(serializedData.Position.X, serializedData.Position.Y)
		local structureData = StructureData.fromSerialization(serializedData.Structure)
		
		self.Structures[structureData] = true
		self.StructurePositions[structureData] = position
		self.KnownStructures[structureData.Id] = structureData
		self:SetObjectLocation(structureData, position)
	end

	return self
end

function BaseData:_Changed()
	self.Changed:Fire()
end

function BaseData:RegisterStructure(structureData)
	self.Structures[structureData] = true
	self.StructurePositions[structureData] = Vector2.new()
	self.KnownStructures[structureData.Id] = structureData
end

function BaseData:PlaceStructure(structureData: table, position: Vector2)
	if self:IsLocationOccupied(position, structureData.Size) then
		return false
	end
	-- UnsuspectingSawblade 2021-07-13 12:29:11 Occupation check is complete, place structure down
	self.Structures[structureData] = true
	self.StructurePositions[structureData] = position
	self.KnownStructures[structureData.Id] = structureData
	structureData.Position = position
	self:SetObjectLocation(structureData, position)
	self:_Changed()
	return true
end

function BaseData:MoveStructure(structureData, position: Vector2)
	local OriginalPos = self.StructurePositions[structureData]
	self:ClearObjectLocation(structureData) -- If we're moving a building, consider that space clear so
	
	if self:IsLocationOccupied(position, structureData.Size) then
		self:SetObjectLocation(structureData, OriginalPos)
		return false
	end
	-- UnsuspectingSawblade 2021-07-13 12:29:11 Occupation check is complete, place structure down
	self:SetObjectLocation(structureData, position)
	self.StructurePositions[structureData] = position
	structureData.Position = position

	self:_Changed()
	return true
end

function BaseData:RemoveStructure(structureData)
	self:ClearObjectLocation(structureData)
	self.Structures[structureData] = nil
	self.StructurePositions[structureData] = nil
	self.KnownStructures[structureData.Id] = nil

	self:_Changed()
	return true
end

function BaseData:Serialize()
	local serializedData = {}
	for structureData, _ in pairs(self.Structures) do
		local position = self:GetObjectPosition(structureData)
		serializedData[structureData.Id] = {
			Position = {X = position.X, Y = position.Y},
			Structure = structureData:Serialize()
		}
	end
	
	for troop, troopData in pairs(self.Troops) do
		
	end
	
	return serializedData
end

function BaseData:Destroy()
	self.Janitor:Destroy()
end


return BaseData