local Selection = game:GetService("Selection")
local Terrain = workspace.Terrain
local PreserveTerrain = require(script.PreserveTerrain)

local TerrainDictonary = {
	["air"] = Enum.Material.Air,
	["basalt"] = Enum.Material.Basalt,
	["brick"] = Enum.Material.Asphalt,
	["cobblestone"] = Enum.Material.Asphalt,
	["concrete"] = Enum.Material.Asphalt,
	["crackedlava"] = Enum.Material.CrackedLava,
	["glacier"] = Enum.Material.Glacier,
	["grass"] = Enum.Material.Grass,
	["ground"] = Enum.Material.Ground,
	["ice"] = Enum.Material.Ice,
	["leafygrass"] = Enum.Material.LeafyGrass,
	["limestone"] = Enum.Material.Limestone,
	["mud"] = Enum.Material.Mud,
	["pavement"] = Enum.Material.Pavement,
	["rock"] = Enum.Material.Rock,
	["salt"] = Enum.Material.Salt,
	["sand"] = Enum.Material.Sand,
	["sandstone"] = Enum.Material.Sandstone,
	["slate"] = Enum.Material.Slate,
	["snow"] = Enum.Material.Snow,
	["water"] = Enum.Material.Water,
}

local function getForm(part: BasePart)
	if part:IsA("Part") then
		if part.Shape == Enum.PartType.Block then
			return "Block"
		elseif part.Shape == Enum.PartType.Ball then
			return "Ball"
		elseif part.Shape == Enum.PartType.Wedge then
			return "Wedge"
		elseif part.Shape == Enum.PartType.CornerWedge then
			return "CornerWedge"
		elseif part.Shape == Enum.PartType.Cylinder then
			return "Cylinder"
		end
	end
	if part:IsA("TrussPart") or part:IsA("VehicleSeat") or part:FindFirstChildOfClass("BlockMesh") then
		return "Block"
	end
	if part:IsA("MeshPart") then
		return "Mesh"
	end
	if part:IsA("PartOperation") then
		return "Operation"
	end
	if part:IsA("WedgePart") then
		return "Wedge"
	end
	if part:IsA("CornerWedgePart") then
		return "CornerWedge"
	end
	return "Block"
end

local function FillWedge(part: BasePart, Material)
	local Size = part.Size
	local x = Size.Z
	local y = Size.Y
	local hypotenuse = math.sqrt(x^2 + y^2)
	local theta = math.atan(y/x)
	
	local cutoffSize = Vector3.new(Size.X, Size.Y, hypotenuse)
	local cutoffCFRaw = CFrame.fromAxisAngle(Vector3.new(-1,0,0), theta) * CFrame.new(0, cutoffSize.Y/2, 0)
	local cutoffCF = part.CFrame:toWorldSpace(cutoffCFRaw)
	
	Terrain:FillBlock(part.CFrame, Size, Material)
	Terrain:FillBlock(cutoffCF, cutoffSize, Enum.Material.Air)
end

local function FillCornerWedge(part: BasePart, Material)
	local function naturalWedge(CF, Size, override)
		local x = Size.Z
		local y = Size.Y
		local hypotenuse = math.sqrt(x^2 + y^2)
		local theta = math.atan(y/x)
		
		local cutoffSize = Vector3.new(Size.X, Size.Y, hypotenuse)
		local cutoffCFRaw = CFrame.fromAxisAngle(Vector3.new(-1,0,0), theta) * CFrame.new(0, cutoffSize.Y/2, 0)
		local cutoffCF = CF:toWorldSpace(cutoffCFRaw)
		
		if not override then
			Terrain:FillBlock(CF, Size, Material)
		end
		Terrain:FillBlock(cutoffCF, cutoffSize, Enum.Material.Air)
	end
	
	local cwCF = part.CFrame
	local cwSize = part.Size
	
	local wedge1CF = cwCF * CFrame.fromAxisAngle(Vector3.new(0,1,0), math.pi/2)
	local wedge1Size = Vector3.new(cwSize.Z, cwSize.Y, cwSize.X)
	local wedge2CF = cwCF * CFrame.fromAxisAngle(Vector3.new(0,1,0), math.pi)
	local wedge2Size = cwSize
	
	naturalWedge(wedge1CF, wedge1Size)
	naturalWedge(wedge2CF, wedge2Size, true) 
end

return function(material, partRemove)
	local function ConvertPart(obj)
		local Cframe = obj.CFrame
		local Size = obj.Size
		
		if getForm(obj) == "Block" then
			if material ~= "air" then 
				PreserveTerrain:PreserveCubeSpace(Cframe, Size, TerrainDictonary[material])
			else 
				Terrain:FillBlock(Cframe, Size, TerrainDictonary[material]) 
			end
		elseif getForm(obj) == "Ball" then
			if material ~= "air" then
				local radius = math.min(Size.X, Size.Y, Size.Z)/2
				PreserveTerrain:PreserveBallSpace(Cframe, radius, TerrainDictonary[material])
			else
				Terrain:FillBall(obj.Position, obj.Size.X/2, TerrainDictonary[material])
			end
		elseif getForm(obj) == "Wedge" then
			FillWedge(obj, TerrainDictonary[material])
		elseif getForm(obj) == "CornerWedge" then
			FillCornerWedge(obj, TerrainDictonary[material])
		elseif getForm(obj) == "Cylinder" then
			local newCFrame = Cframe * CFrame.Angles(0, 0, math.rad(90))
			local height = Size.X
			local radius = math.min(Size.Y, Size.Z) / 2
			
			Terrain:FillCylinder(newCFrame, height, radius, TerrainDictonary[material])
		elseif getForm(obj) == "Operation" then
			warn("[Shell Library]: Can't convert PartOperations | "..obj.Name)
		end
		
		if partRemove then
			obj:Remove()
		end
	end
	
	for index, obj in pairs(Selection:Get()) do
		if obj:IsA("BasePart") and obj.ClassName ~= "Terrain" then
			ConvertPart(obj)
		end
		for i, v in pairs(obj:GetDescendants()) do
			if v:IsA("BasePart") and obj.ClassName ~= "Terrain" then
				ConvertPart(v)
			end
		end
	end
end
