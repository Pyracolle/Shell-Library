local PreserveTerrain = {}

local Resolution = 4
local MaxVoxelWrite = 4194304
local MaxVoxelFill = 67108864

function GetRegion(Space, size)
	local inv = Space:Inverse()
	local x = size * inv.RightVector
    local z = size * inv.LookVector
	local y = size * inv.UpVector
	local w = math.abs(x.X) + math.abs(x.Y) + math.abs(x.Z)
	local h = math.abs(y.X) + math.abs(y.Y) + math.abs(y.Z)
	local d = math.abs(z.X) + math.abs(z.Y) + math.abs(z.Z)
    
	local pos = Space.Position
	local halfSize = Vector3.new(w, h, d) / 2
	local region = Region3.new(pos - halfSize, pos + halfSize):ExpandToGrid(Resolution)
	local regionVolume = (region.Size.X/Resolution)*(region.Size.Y/Resolution)*(region.Size.Z/Resolution)

	return region, regionVolume
end

function PreserveTerrain:PreserveBallSpace(Cframe, radius, Material)
	local center = Cframe.Position
	local diameter3 = Vector3.new(radius, radius, radius) * 2
	local region, regionVolume = GetRegion(Cframe, diameter3)
	
	if Material == Enum.Material.Air then
		if MaxVoxelFill < regionVolume then
			return workspace.Terrain:FillBall(center, radius, Material) 
		end
	end
	if MaxVoxelWrite < regionVolume then return end
	
	local materialVoxels, occupancyVoxels = workspace.Terrain:ReadVoxels(region, Resolution)
	local regionSize = materialVoxels.Size
	local min = region.CFrame.Position - region.Size / 2
	
	for x = 1, regionSize.X do
		local cellX = min.X + (x - 0.5)*Resolution - center.X
		for y = 1, regionSize.Y do
			local cellY = min.Y + (y - 0.5)*Resolution - center.Y
			for z = 1, regionSize.Z do
				local cellZ = min.Z + (z - 0.5)*Resolution - center.Z
				local cellMaterial = materialVoxels[x][y][z]
				local cellOccupancy = occupancyVoxels[x][y][z]
				local distance = math.sqrt(cellX * cellX + cellY * cellY + cellZ * cellZ)
				local brushOcc = math.max(0, math.min(1, (radius + 0.5*Resolution - distance)/Resolution))
                
				if brushOcc > cellOccupancy then occupancyVoxels[x][y][z] = brushOcc end
				if brushOcc >= 0.1 and cellMaterial == Enum.Material.Air then materialVoxels[x][y][z] = Material end
			end
		end
	end
	workspace.Terrain:WriteVoxels(region, Resolution, materialVoxels, occupancyVoxels)
	return true
end

function PreserveTerrain:PreserveCubeSpace(Cframe, Size, Material)
	local region, regionVolume = GetRegion(Cframe, Size)
	if Material == Enum.Material.Air then
		if MaxVoxelFill < regionVolume then
			return workspace.Terrain:FillBlock(Cframe, Size, Material)
		end
	end
	if MaxVoxelWrite < regionVolume then return end
	
	local min = region.CFrame.Position - region.Size / 2
	local materialVoxels, occupancyVoxels = workspace.Terrain:ReadVoxels(region, Resolution)
	local regionSize = materialVoxels.Size
	
	local sizeCellClamped = Size/Resolution
	sizeCellClamped = Vector3.new(
		math.min(1, sizeCellClamped.X),
		math.min(1, sizeCellClamped.Y),
		math.min(1, sizeCellClamped.Z))
	local sizeCellsHalfOffset = Size*(0.5/Resolution) + Vector3.new(0.5, 0.5, 0.5)
	
	for x = 1, regionSize.X do
		local cellPosX = min.X + (x - 0.5) * Resolution
		for y = 1, regionSize.Y do
			local cellPosY = min.Y + (y - 0.5) * Resolution
			for z = 1, regionSize.Z do
				local cellPosZ = min.Z + (z - 0.5) * Resolution
				local cellPosition = Vector3.new(cellPosX, cellPosY, cellPosZ)
				local offset = Cframe:PointToObjectSpace(cellPosition) / Resolution
				local distX = sizeCellsHalfOffset.X - math.abs(offset.X)
				local distY = sizeCellsHalfOffset.Y - math.abs(offset.Y)
				local distZ = sizeCellsHalfOffset.Z - math.abs(offset.Z)
				local factorX = math.max(0, math.min(distX, sizeCellClamped.X))
				local factorY = math.max(0, math.min(distY, sizeCellClamped.Y))
				local factorZ = math.max(0, math.min(distZ, sizeCellClamped.Z))
				local brushOcc = math.min(factorX, factorY, factorZ)
                
				local cellMaterial = materialVoxels[x][y][z]
				local cellOccupancy = occupancyVoxels[x][y][z]
				
				if brushOcc > cellOccupancy then occupancyVoxels[x][y][z] = brushOcc end
				if brushOcc >= 0.1 and cellMaterial == Enum.Material.Air then materialVoxels[x][y][z] = Material end
			end
		end
	end
	workspace.Terrain:WriteVoxels(region, Resolution, materialVoxels, occupancyVoxels)
	return true
end

return PreserveTerrain
