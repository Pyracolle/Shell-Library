local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local SavedKeys = {}
local ThreeDText = {}
ThreeDText.__index = ThreeDText

-- << Private functions >> --

local offset = {
	["g"] = -0.3,
	["j"] = -0.3,
	["y"] = -0.4,
	["p"] = -0.5,
	["q"] = -0.5,
	['"'] = 2,
	["^"] = 2,
	["~"] = 0.9,
	["-"] = 0.9,
	["'"] = 2,
	["*"] = 1.8,
	["="] = 0.3,
	[","] = -0.1,
}

function InstanceWriter(pos, rotation)
	local Part = Instance.new("Part")              Part.Name = "WRITER_TOOL"
	Part.Color = Color3.fromRGB(108, 255, 250)     Part.Size = Vector3.new(2, 2, 0.3)
	Part.Anchored = true                           Part.CanCollide = false
	Part.CFrame = CFrame.new(pos, pos + rotation)  Part.Transparency = 0.2
	Part.Parent = workspace
	
	return Part
end

function stringToColor(str: string)
	local split = string.split(str, ", ")
	if tonumber(split[1]) and tonumber(split[2]) and tonumber(split[3]) then
		return Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
	else
		return Color3.fromRGB(25, 25, 25)
	end
end

function InvokeKey(key, writer, Keyboard)
	if Keyboard:FindFirstChild(key) then
		local letter = Keyboard[key]:Clone()
		letter.CFrame = writer.CFrame 
			* CFrame.new(0, (-writer.Size.Y/2 + letter.Size.Y/2), 0)
		
		if offset[letter.Name] ~= nil then
			letter.CFrame = letter.CFrame * CFrame.new(0, offset[letter.Name], 0)
		end
		
		letter.Name = "MeshPart"
		letter.Parent = workspace
		return letter
	else
		return nil
	end
end

-- << Plugin Usage >> --

function ThreeDText.init()
	local self = {}
	self.BoxChanged = nil
	self.PrincipalCframe = CFrame.new()
	self.Keyboard = nil
	self.InputBegan = nil
	self.Writer = nil
	
	setmetatable(self, ThreeDText)
	return self
end

function ThreeDText:Enabled(mouse: Mouse, Input: TextBox, color: TextBox)
	mouse.Icon = "rbxasset://textures/DeveloperFramework/slider_knob_light.png"
	local succ, data = pcall(function()
		return game:GetObjects("rbxassetid://6398398970")
	end)
	
	if succ then
		self.Keyboard = data[1]
	else
		warn("[Shell Library]: Roblox may be down // Error: "..data)
	end
	
	self.InputBegan = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.Writer == nil and self.Keyboard then
				local MouseLocation = UserInputService:GetMouseLocation()
				local SPR =  Camera:ScreenPointToRay(MouseLocation.X, MouseLocation.Y)
				local rayCast = workspace:Raycast(SPR.Origin,SPR.Direction * 2048)

				if rayCast ~= nil then
					self.Writer = InstanceWriter(rayCast.Position, rayCast.Normal)
					self.PrincipalCframe = self.Writer.CFrame
					mouse.Icon = "rbxasset://SystemCursors/Arrow"
				end
			end
		end
	end)
	self.BoxChanged = Input:GetPropertyChangedSignal("Text"):Connect(function()
		if self.Writer and self.Keyboard then
			for index, v in pairs(SavedKeys) do
				v:Destroy()
			end
			table.clear(SavedKeys)
			self.Writer.CFrame = self.PrincipalCframe
			
			for index, v in pairs(string.split(Input.Text, "")) do
				local letter = InvokeKey(v, self.Writer, self.Keyboard)
				
				if letter ~= nil then
					letter.Color = stringToColor(color.Text)

					table.insert(SavedKeys, letter)
					self.Writer.CFrame = self.Writer.CFrame 
						+ (-self.Writer.CFrame.RightVector * 2.3)
				end
			end
		end
	end)
end

function ThreeDText:Disabled(mouse: Mouse)
	if self.InputBegan ~= nil then self.InputBegan:Disconnect() end
	if self.BoxChanged ~= nil then self.BoxChanged:Disconnect() end
	if self.Keyboard ~= nil then self.Keyboard:Destroy() self.Keyboard = nil end
	self.PrincipalCframe = CFrame.new()
	self.Writer = nil
	
	if #SavedKeys ~= 0 then
		local Model = Instance.new("Model")
		Model.Name = "3dModel"
		Model.Parent = workspace
		
		for index, key in pairs(SavedKeys) do
			key.Parent = Model
		end
	end
	
	local WriterTool = workspace:FindFirstChild("WRITER_TOOL")
	if WriterTool then
		WriterTool:Destroy()
	end
	mouse.Icon = "rbxasset://SystemCursors/Arrow"
	table.clear(SavedKeys)
end

return ThreeDText
