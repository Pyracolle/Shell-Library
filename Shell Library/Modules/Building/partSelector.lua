local Selection = game:GetService("Selection")
local partSelector = {}
partSelector.__index = partSelector

-- << Private functions >> --

function MatchParts(PartA, PartB, color, parent)
	if color == true then
		if PartA.Color ~= PartB.Color then
			return false
		end
	end
	if parent == true then
		if PartA.Parent ~= PartB.Parent then
			return false
		end
	end
	return true
end

-- << Plugin Usage >> --

function partSelector.init()
	local self = {}
	self.mouseDown = nil
	setmetatable(self, partSelector)
	
	return self
end

function partSelector:Enabled(mouse: Mouse, sParent: boolean, sColor: boolean, d: string)
	local Distance = 50
	if tonumber(d) ~= nil and tonumber(d) <= 200 then
		Distance = tonumber(d)
	end
	
	mouse.Icon = "rbxasset://SystemCursors/Cross"
	self.mouseDown = mouse.Button1Down:Connect(function()
		local SelectedObjects = Selection:Get()
		
		if mouse.Target then
			if mouse.Target:IsA("BasePart") then
				local Part = mouse.Target
				local Size = Vector3.new(Part.Size.X + Distance, Part.Size.Y + Distance, Part.Size.Z + Distance)
				local PartsInBox = workspace:GetPartBoundsInBox(Part.CFrame, Size)
				table.clear(SelectedObjects)
				
				for i, v in pairs(PartsInBox) do
					if MatchParts(Part, v, sColor, sParent) then
						table.insert(SelectedObjects, v)
					end
				end
				Selection:Set(SelectedObjects)
			end
		else
			warn("[Shell Library]: There are no parts selected, press the button to try again")
		end
		partSelector:Disabled(mouse)
	end)
end

function partSelector:Disabled(mouse: Mouse)
	if self.mouseDown ~= nil then 
		self.mouseDown:Disconnect()
	end
	mouse.Icon = "rbxasset://SystemCursors/Arrow"
end

return partSelector
