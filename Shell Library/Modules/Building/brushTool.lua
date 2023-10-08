local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Selection = game:GetService("Selection")
local Camera = workspace.CurrentCamera

local BrushModule = {}
BrushModule.__index = BrushModule

local PlacedObjects = {}
local Brushing = false
local onWait = false

-- << Private functions >> --

function CreateBrush()
	local brush = Instance.new("Part")    brush.Name = "BRUSH_TOOL"
	brush.Material = Enum.Material.Glass  brush.CanCollide = false
	brush.Transparency = 0.4              brush.Size = Vector3.new(0.3, 12, 12)
	brush.Shape = Enum.PartType.Cylinder  brush.Rotation = Vector3.new(0, 0, 90)
	brush.Anchored = true                 brush.Parent = workspace     
	
	return brush
end

-- << Plugin Usage >> --

local RayParams = RaycastParams.new()
RayParams.IgnoreWater = true
RayParams.FilterType = Enum.RaycastFilterType.Exclude

function BrushModule.init()
	local self = {}
	self.InputBegan = nil
	self.InputEnded = nil
	self.InputChanged = nil
	
	setmetatable(self, BrushModule)
	return self
end

function BrushModule:Enabled(_delay: TextBox, _eraser: BoolValue)
	local BrushDelay = tonumber(_delay.Text)
	local Brush = CreateBrush()
	table.insert(PlacedObjects, Brush)
	
	RayParams.FilterDescendantsInstances = {Brush}
	if BrushDelay < 0.03 or BrushDelay >= 4 then
		BrushDelay = 0.03
		_delay.Text = 0.03
	end
	
	self.InputBegan = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Brushing = true
		end
	end)
	self.InputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Brushing = false
		end
	end)
	self.InputChanged = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and #Selection:Get() ~= 0 then
			local MouseLocation = UserInputService:GetMouseLocation()
			local SPR =  Camera:ScreenPointToRay(MouseLocation.X, MouseLocation.Y)
			local rayCast = workspace:Raycast(SPR.Origin, SPR.Direction * 1024, RayParams)
			
			if rayCast ~= nil then
				Brush.CFrame = (CFrame.new(rayCast.Position, rayCast.Position - rayCast.Normal) 
					* CFrame.Angles(0, math.rad(90), 0)) * CFrame.new(0, Brush.Size.Y/2,0)
			end
			if _eraser.Value then
				Brush.Color = Color3.fromRGB(255, 52, 52)
			else
				Brush.Color = Color3.fromRGB(0, 255, 255)
			end
			
			if Brushing and onWait == false then
				local Result = workspace:Raycast(
					SPR.Origin, 
					SPR.Direction * 2048, 
					RayParams
				)
				
				if _eraser.Value then
					for _, object in pairs(PlacedObjects) do
						if object ~= Brush and (Brush.Position - object:GetPivot().Position).Magnitude <= 12 then
							table.remove(PlacedObjects, PlacedObjects[object])
							object:Destroy()
						end
					end
				else
					if Result ~= nil then
						local object = Selection:Get()[math.random(1, #Selection:Get())]
						if object.Name ~= "BRUSH_TOOL" then
							if object:IsA("BasePart") and object.ClassName ~= "Terrain" then
								local Clone = object:Clone()
								if Clone.Shape ~= Enum.PartType.Cylinder then
									Clone.CFrame = (CFrame.new(rayCast.Position, rayCast.Position - rayCast.Normal) 
										* CFrame.Angles(math.rad(90), 0, 0)) * CFrame.new(0, Clone.Size.Y/2,0)
								else
									Clone.CFrame = (CFrame.new(rayCast.Position, rayCast.Position - rayCast.Normal) 
										* CFrame.Angles(0, math.rad(90), 0)) * CFrame.new(0, Clone.Size.Y/2,0)
								end
								Clone.Parent = workspace
								table.insert(PlacedObjects, Clone)
							end
							if object:IsA("Model") then
								local Clone = object:Clone()
								local CF, Size  = Clone:GetBoundingBox()
								Clone:PivotTo((CFrame.new(rayCast.Position, rayCast.Position - rayCast.Normal) 
									* CFrame.Angles(math.rad(90), 0, 0)) * CFrame.new(0, Size.Y/2,0))
								
								Clone.Parent = workspace
								table.insert(PlacedObjects, Clone)
							end
							onWait = true
							task.wait(BrushDelay)
							onWait = false
						end
					end
					RayParams.FilterDescendantsInstances = PlacedObjects
				end
			end
		end
	end)
end

function BrushModule:Disabled()
	if self.InputBegan ~= nil then self.InputBegan:Disconnect() end
	if self.InputEnded ~= nil then self.InputEnded:Disconnect() end
	if self.InputChanged ~= nil then self.InputChanged:Disconnect() end
	
	local Brush = workspace:FindFirstChild("BRUSH_TOOL")
	if Brush then
		Brush:Destroy()
	end
	Brushing = false
	table.clear(PlacedObjects)
end

return BrushModule
