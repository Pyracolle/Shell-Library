local DataStoreService = game:GetService("DataStoreService")
local Ranure = {}

-- << Private functions >> --

function reloadKeys(Scroll: ScrollingFrame, DataStore)
	local KeysPages = DataStore:ListKeysAsync()
	local SavedKeys = {}
	local btnCounter = 0
	Scroll:ClearAllChildren()
	
	while task.wait() do
		local currentKeypage = KeysPages:GetCurrentPage()
		
		for index, key in pairs(currentKeypage) do
			table.insert(SavedKeys, key.KeyName)
		end
		if KeysPages.IsFinished then break end
		KeysPages:AdvanceToNextPageAsync()
	end
	
	local function NewTextLabel(size: UDim2, color: Color3, txt: string)
		local PlayerFr = Instance.new("TextLabel")
		PlayerFr.BorderSizePixel = 0
		PlayerFr.Size = size
		PlayerFr.Position = UDim2.new(0, 0, 0, btnCounter * PlayerFr.Size.Y.Offset)
		PlayerFr.BackgroundColor3 = color
		PlayerFr.TextSize = 12
		PlayerFr.RichText = true
		PlayerFr.FontFace = Font.new("rbxasset://fonts/families/JosefinSans.json", Enum.FontWeight.SemiBold)
		PlayerFr.Text = txt
		PlayerFr.Parent = Scroll
		
		if PlayerFr.Position.Y.Offset + PlayerFr.Size.Y.Offset > Scroll.AbsoluteSize.Y then
			Scroll.CanvasSize = UDim2.new(0, 0, 0, btnCounter * PlayerFr.Size.Y.Offset + PlayerFr.Size.Y.Offset)
		else
			Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		end
		btnCounter = btnCounter + 1
	end
	
	local function Identify(size: UDim2, data)
		if typeof(data) == "string" then
			NewTextLabel(size, Color3.fromRGB(113, 235, 241), "string: "..data)
		elseif typeof(data) == "number" then
			NewTextLabel(size, Color3.fromRGB(255, 164, 61), "number: "..data)
		elseif typeof(data) == "boolean" then
			NewTextLabel(size, Color3.fromRGB(255, 128, 128), "boolean: "..data)
		elseif typeof(data) == "nil" then
			NewTextLabel(size, Color3.fromRGB(255, 251, 120), "nil")
			
		elseif typeof(data) == "table" then
			NewTextLabel(size, Color3.fromRGB(193, 76, 243), "table: {...}")
			if size.X.Scale > 0.35 then
				for index, key in pairs(data) do
					Identify(UDim2.new(size.X.Scale - 0.1, 0, 0, 30), key)
				end
			end
		end
	end
	
	for index, keyword in pairs(SavedKeys) do
		local data
		local succ, err = pcall(function()
			data = DataStore:GetAsync(keyword)
		end)
		
		if succ then
			NewTextLabel(
				UDim2.new(0.85, 0, 0, 30),
				Color3.fromRGB(136, 211, 116),
				"key: "..keyword
			)
			Identify(UDim2.new(0.75, 0, 0, 30), data)
			task.wait()
		end
	end
	for index, v in pairs(Scroll:GetChildren()) do
		if v.BackgroundColor3 == Color3.fromRGB(136, 211, 116) then
			local Textbtn = Instance.new("TextButton")
			Textbtn.BackgroundColor3 = Color3.fromRGB(255, 128, 128)
			Textbtn.BorderSizePixel = 0
			Textbtn.Size = UDim2.new(0, 30, 0, 30)
			Textbtn.Position = UDim2.new(1, 10, 0, 0)
			Textbtn.Text = "X"
			Textbtn.TextSize = 20
			Textbtn.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
			Textbtn.Parent = v
			
			Textbtn.MouseButton1Click:Connect(function()
				local succ, err = pcall(function()
					DataStore:RemoveAsync(v.Name)
				end)
				if succ then
					reloadKeys(Scroll, DataStore)
				end
			end)
		end
	end
end

-- << Plugin Usage >> --

function Ranure:IsA_Datastore(str: string)
	local Pages = DataStoreService:ListDataStoresAsync()
	
	while task.wait() do
		local currentPage = Pages:GetCurrentPage()
		
		for i, info in pairs(currentPage) do
			if info.DataStoreName == str then
				return true
			end
		end
		if Pages.IsFinished then return false end
		Pages:AdvanceToNextPageAsync()
	end
end

function Ranure:ShowData(Scroll: ScrollingFrame, dataName: string, IsOrdered: boolean)
	local store
	if IsOrdered then
		store = DataStoreService:GetOrderedDataStore(dataName)
	else
		store = DataStoreService:GetDataStore(dataName)
	end
	reloadKeys(Scroll, store)
end

return Ranure
