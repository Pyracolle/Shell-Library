local Aligner = {}
Aligner.__index = Aligner

-- << Private functions >> --

function Align(part: BasePart, anchorPart: BasePart, partNormalId, anchorPartNormalId, PartOnly: boolean)
	local Model = part:FindFirstAncestorOfClass("Model")
	local PartNormal = Vector3.FromNormalId(partNormalId)
	local anchorPartNormal = Vector3.FromNormalId(anchorPartNormalId)
	local faceCFrame = anchorPart.CFrame * CFrame.new((anchorPart.Size/2) * anchorPartNormal)
	
	local rotation = {
		[Enum.NormalId.Bottom] = CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, part.Size.Y/2, 0),
		[Enum.NormalId.Top] = CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, -part.Size.Y/2, 0),
		[Enum.NormalId.Right] = CFrame.Angles(0, math.rad(90), 0) * CFrame.new(-part.Size.X/2, 0, 0),
		[Enum.NormalId.Left] = CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(part.Size.X/2, 0, 0),
		[Enum.NormalId.Front] = CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(0, 0, part.Size.Z/2),
		[Enum.NormalId.Back] = CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, 0, part.Size.Z/2),
	}
	
	if Model ~= nil and PartOnly == false then
		local PrimaryPart = nil
		local Size = Model:GetExtentsSize()
		
		if Model.PrimaryPart ~= nil then
			PrimaryPart = Model.PrimaryPart
		end
		Model.PrimaryPart = part
		Model:PivotTo(CFrame.new(faceCFrame.Position, faceCFrame.Position - anchorPartNormal)
		* rotation[partNormalId])
		
		local newPos, _ = Model:GetBoundingBox()
		Model.PrimaryPart = PrimaryPart
		Model.WorldPivot = newPos
	else
		part.CFrame = (CFrame.new(faceCFrame.Position, faceCFrame.Position - anchorPartNormal) 
		* rotation[partNormalId])
	end
end

function AxisAlign(part: BasePart, anchorPart: BasePart, AlignTo, PartOnly: boolean)
	local Model = part:FindFirstAncestorOfClass("Model")
	local Normal = Vector3.FromNormalId(AlignTo)
	
	local partSurface = part.CFrame * (math.abs(part.Size:Dot(Normal) / 2) * Normal)
	local anchorSurface = anchorPart.CFrame * (math.abs(anchorPart.Size:Dot(Normal)/2) * Normal)
	local diff = anchorSurface - partSurface
	local anchorPartWorldSpace = anchorPart.CFrame:VectorToWorldSpace(Normal)
	local alpha = diff:Dot(anchorPartWorldSpace)
	
	if Model ~= nil and PartOnly == false then
		local PrimaryPart = nil
		local Size = Model:GetExtentsSize()
		
		if Model.PrimaryPart ~= nil then
			PrimaryPart = Model.PrimaryPart
		end
		Model.PrimaryPart = part
		Model:PivotTo(part.CFrame + (alpha * anchorPartWorldSpace))
		
		local newPos, _ = Model:GetBoundingBox()
		Model.PrimaryPart = PrimaryPart
		Model.WorldPivot = newPos
	else
		part.CFrame = part.CFrame + (alpha * anchorPartWorldSpace)
	end
end

function Adornee(mouse: Mouse, UI: SurfaceGui, part: BasePart)
	local Origin = mouse.Origin
	local result = workspace:Raycast(Origin.Position, Origin.LookVector * 2048)
	
	if result then
		if result.Instance == part then
			local cframe = part.CFrame
			local selectedNormal, maxValue = nil, -1
			
			for _, normalId in ipairs(Enum.NormalId:GetEnumItems()) do
				local worldNormal = cframe:VectorToWorldSpace(Vector3.FromNormalId(normalId))
				local projection = worldNormal:Dot(result.Normal)
				
				if projection > maxValue then
					selectedNormal = normalId
					maxValue = projection
				end
			end
			
			UI.Adornee = part
			UI.Face = selectedNormal
			UI.Parent = part
		end
	end
end

function CreateUI()
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Align_UI"
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(111, 185, 255)
	frame.BackgroundTransparency = 0.4
	frame.Parent = surface
	
	return surface
end

-- << Plugin Usage >> --

function Aligner.init()
	local self = {}
	self.mouseDown = nil
	self.mouseMove = nil
	
	self.FirstPoint = nil
	self.LastPoint = nil
	self.S1 = nil
	self.S2 = nil
	
	setmetatable(self, Aligner)
	return self
end

function Aligner:Enabled(mouse: Mouse, PartOnly: boolean, Axis: boolean)
	mouse.Icon = "rbxasset://SystemCursors/Cross"
	self.S1 = CreateUI()
	self.S2 = CreateUI()
	
	self.mouseDown = mouse.Button1Down:Connect(function()
		if mouse.Target and self.LastPoint == nil then
			if self.FirstPoint == nil and mouse.Target.ClassName ~= "Terrain" then
				self.FirstPoint = mouse.Target
				self.S1.Adornee = mouse.Target
			else
				if mouse.Target ~= self.FirstPoint and mouse.Target.ClassName ~= "Terrain" then
					if self.S2 == nil then self.S2 = CreateUI() end
					self.LastPoint = mouse.Target
					
					if Axis == false then
						Align(self.FirstPoint, self.LastPoint, self.S1.Face, self.S2.Face, PartOnly)
					else
						if self.S1.Face == self.S2.Face then
							AxisAlign(self.FirstPoint, self.LastPoint, self.S1.Face, PartOnly)
						else
							warn("[Shell Library]: Objects must be aligned by same NormalId")
						end
					end
					self.S1:Destroy()
					self.S2:Destroy()
					Aligner:Disabled(mouse)
				end
			end
		end
	end)
	self.mouseMove = mouse.Move:Connect(function()
		if mouse.Target and self.LastPoint == nil then
			if self.FirstPoint == nil then
				Adornee(mouse, self.S1, mouse.Target)
			else
				if self.FirstPoint ~= mouse.Target then
					Adornee(mouse, self.S2, mouse.Target)
				end
			end
		end
	end)
end

function Aligner:Disabled(mouse: Mouse)
	if self.mouseDown ~= nil then self.mouseDown:Disconnect() end
	if self.mouseMove ~= nil then self.mouseMove:Disconnect() end
	
	if self.S1 ~= nil then
		self.S1:Destroy()
	end
	if self.S2 ~= nil then
		self.S2:Destroy()
	end
	
	self.FirstPoint = nil
	self.LastPoint = nil
	self.S1 = nil
	self.S2 = nil
	mouse.Icon = "rbxasset://SystemCursors/Arrow"
end

return Aligner
