local ropeDrawer = {}
ropeDrawer.__index = ropeDrawer

-- << Private functions >> --

function StringToColor(str)
	local split = string.split(str, ", ")
	if tonumber(split[1]) and tonumber(split[2]) and tonumber(split[3]) then
		return Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
	else
		return Color3.fromRGB(165, 138, 95)
	end
end

function CurveVectors(PointA: Vector3, PointB: Vector3, Color: string)
	local curve = PointB:Lerp(PointA, 0.1) + Vector3.new(0, -10, 0)
	local RopeModel = Instance.new("Model")
	RopeModel.Name = "Rope"
	RopeModel.Parent = workspace
	
	local function QuadraticBezier(t, p0, p1, p2)
		return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
	end
	
	for i = 0, 10 do
		local pos = QuadraticBezier(i/10 , PointA, curve, PointB);
		local pointfront = QuadraticBezier((i+1)/10, PointA, curve, PointB) 
		
		local Magnitude = (pointfront - pos).Magnitude
		local CF = CFrame.lookAt(
			(pos + pointfront) / 2,
			pointfront
		)
		
		local Part = Instance.new("Part")
		Part.Anchored = true
		Part.Size = Vector3.new(0.2, 0.2, Magnitude)
		Part.Material = Enum.Material.Plastic
		Part.CFrame = CF
		Part.Color = StringToColor(Color)
		Part.TopSurface = Enum.SurfaceType.Smooth
		Part.BottomSurface = Enum.SurfaceType.Smooth
		Part.Parent = RopeModel
	end
end

-- << Plugin Usage >> --

function ropeDrawer.init()
	local self = {}
	self.mouseDown = nil
	self.mouseMove = nil
	self.CurrentRope = nil
	self.StartPoint = nil
	
	setmetatable(self, ropeDrawer)
	return self
end

function ropeDrawer:Enabled(mouse: Mouse, CurveRope: BoolValue, Color: TextBox)
	mouse.Icon = "rbxasset://SystemCursors/Cross"
	
	self.mouseDown = mouse.Button1Down:Connect(function()
		if not self.StartPoint then
			self.StartPoint = mouse.Hit.Position
			
			-- Rope Creation
			local Part = Instance.new("Part")
			Part.TopSurface = Enum.SurfaceType.Smooth
			Part.BottomSurface = Enum.SurfaceType.Smooth
			Part.Material = Enum.Material.Pebble
			Part.Size = Vector3.new(0.2, 0.2, 0.2)
			Part.Color = StringToColor(Color.Text)
			Part.Anchored = true
			Part.Position = self.StartPoint
			
			self.CurrentRope = Part
			self.CurrentRope.Parent = workspace
		else
			if mouse.Target then
				if CurveRope.Value == false then
					local Center = (self.StartPoint + mouse.Hit.Position) / 2
					self.CurrentRope.Size = Vector3.new(0.2, 0.2, (self.StartPoint - mouse.Hit.Position).Magnitude)
					self.CurrentRope.CFrame = CFrame.new(Center, self.StartPoint)
					
					self.CurrentRope = nil
				else
					CurveVectors(self.StartPoint, mouse.Hit.Position, Color.Text)
					self.CurrentRope:Destroy()
					self.CurrentRope = nil
				end
				self.StartPoint = nil
			end
		end
	end)
	self.mouseMove = mouse.Move:Connect(function()
		if self.StartPoint and self.CurrentRope ~= nil and mouse.Target then
			local Center = (self.StartPoint + mouse.Hit.Position) / 2
			self.CurrentRope.Size = Vector3.new(0.1, 0.1, (self.StartPoint - mouse.Hit.Position).Magnitude)
			self.CurrentRope.CFrame = CFrame.new(Center, self.StartPoint)
		end
	end)
end

function ropeDrawer:Disabled(mouse: Mouse)
	if self.mouseDown ~= nil then self.mouseDown:Disconnect() end
	if self.mouseMove ~= nil then self.mouseMove:Disconnect() end
	
	self.CurrentRope = nil
	self.StartPoint = nil
	mouse.Icon = "rbxasset://SystemCursors/Arrow"
end

return ropeDrawer
