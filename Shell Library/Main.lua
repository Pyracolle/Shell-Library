--[[                                                                               
 _____                           _ _                                               
 |  __ \                         | | |                  Released: February 08, 2022
 | |__) |   _ _ __ __ _  ___ ___ | | | ___              Updated: September 23, 2023
 |  ___/ | | | '__/ _` |/ __/ _ \| | |/ _ \                                        
 | |   | |_| | | | (_| | (_| (_) | | |  __/             Shell Library v2           
 |_|    \__, |_|  \__,_|\___\___/|_|_|\___|             @mari230899                
         __/ |                                                                     
        |___/                                                                      
                                                                                   
Roblox profile:                      https://www.roblox.com/users/811183920/profile
Devforum post:                       https://devforum.roblox.com/t/1663040         
Twitter:                             https://twitter.com/ExtraLuminus              
                                                                                   
                                                                               ]]--

local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")
local InsertService = game:GetService("InsertService")
local HistoryService = game:GetService("ChangeHistoryService")

local Library = script.Parent
local Camera = workspace.CurrentCamera
local CharModule = require(Library.Modules.CharLoader)
local TerrainConverter = require(Library.Modules.PartToTerrain)
local DraggableObject = require(Library.Modules.DraggableObject)
local DataModule = require(Library.Modules.Datastore)
local IsActive = false
local Reduced = false

local Brush_ = require(Library.Modules.Building.brushTool).init()
local Rope_ = require(Library.Modules.Building.ropeDrawer).init()
local PSelector_ = require(Library.Modules.Building.partSelector).init()
local threeDtext_ = require(Library.Modules.Building.DimensionalText).init()
local Aligner_ = require(Library.Modules.Building.Aligner).init()
local Welder_ = require(Library.Modules.Building.welder)
local mouse = plugin:GetMouse()

function CheckForUpdate()
	local v = script.Version
	local succ, response = pcall(function()
		return InsertService:LoadAsset(7610875679)
	end)
	if succ then
		local asset = response["Shell Library"].Main.Version
		if asset.Value > v.Value then
			local ver = string.split(tostring(asset.Value), "")
			warn("[Shell Library]: v"..ver[1].."."..ver[2].." released! Update it by going to your plugin's tab")
		end
		response:Destroy()
	end
end

-- // UI Creation \\ --

local ShellGui = Library.ShellGui
local Frame = ShellGui:FindFirstChild("MainFrame")
local MakeDraggable = DraggableObject.new(Frame)
local ToolBar = plugin:CreateToolbar("Pyracolle")
local Button = ToolBar:CreateButton(
	"Shell Library", 
	"Multi-plugin Library : Building and Scripting", 
	"rbxassetid://10270641832"
)

local Cleaner = Frame.Container.Cleaner
local Inserter = Frame.Container.Inserter
local CharLoader = Frame.Container.CharLoader
local Building = Frame.Container.Building
local Terrain = Frame.Container.Terrain
local DatastoreFr = Frame.Container.Datastore

-- // Buttons Pressed \\ --

for index, button in pairs(Frame.Buttons:GetChildren()) do
	if button:IsA("TextButton") then
		button.MouseButton1Click:Connect(function()
			for index, frame in pairs(Frame.Container:GetChildren()) do
				frame.Visible = false 
			end
			local container = Frame.Container:FindFirstChild(button.Name)
			if container then
				container.Visible = true
			end
		end)
	end
end

for index, v in pairs(Frame.Container:GetDescendants()) do
	if v:IsA("TextButton") and v:FindFirstChild("Boolean") then
		v.MouseButton1Click:Connect(function()
			if v.Boolean.Value == true then 
				v.Boolean.Value = false
				v.Text = ""
			else
				v.Boolean.Value = true
				v.Text = "X"
			end
		end)
	end
end

--//====================================================\\--
--||			  SHELL LIBRARY * CLEANER                   
--\\====================================================//--

Cleaner.Clean.MouseButton1Click:Connect(function()
	if #Selection:Get() == 0 then
		warn("[Shell Library]: Cleaner needs a selected object")
	else
		local Class = Cleaner.Class
		local Descendants = Cleaner.Descendants.Boolean
		
		for index, selection in pairs(Selection:Get()) do
			if Descendants.Value == false then
				for i, v in pairs(selection:GetChildren()) do
					if v.ClassName == Class.Text then
						v:Remove()
					end
				end
			else
				for i, v in pairs(selection:GetDescendants()) do
					if v.ClassName == Class.Text then
						v:Remove()
					end
				end
			end
		end
		HistoryService:SetWaypoint('Cleaner command')
	end
end)

--//====================================================\\--
--||			  SHELL LIBRARY * INSERTER                  
--\\====================================================//--

Inserter.Upload.MouseButton1Click:Connect(function()
	local id = tonumber(Inserter.Id.Text)
	local objects
	
	if string.find(Inserter.Id.Text, "0x") then
		if string.format("%d", Inserter.Id.Text) then
			id = string.format("%d", string.format("%d", Inserter.Id.Text))
		end
	end
	
	local function CheckIfBundle()
		local IsBundle = nil
		local succ, err = pcall(function()
			IsBundle = game:GetService("AssetService"):GetBundleDetailsAsync(id)
		end)
		
		if IsBundle then
			CharModule:LoadBundle(id)
			return true
		else
			return false
		end
	end
	if CheckIfBundle() then 
		return 
	end
	
	pcall(function()
		objects = game:GetObjects("rbxassetid://"..id)
	end)
	if not objects then 
		warn("[Shell Library]: Can't insert "..Inserter.Id.Text) 
		return 
	end
	
	local Asset = Instance.new("Model")
	Asset.Name = "Inserted Asset"
	Asset.Parent = game.Workspace
	
	for _, obj in pairs(objects) do obj.Parent = Asset end
	HistoryService:SetWaypoint('Inserter command')
	Selection:Set({Asset})
	
	if Inserter.Accept.Boolean.Value == false then
		for index, v in pairs(Asset:GetDescendants()) do
			if v:IsA("BaseScript") then 
				v:Destroy() 
			end
		end
	end
end)

--//====================================================\\--
--||		   SHELL LIBRARY * CHAR LOADER                  
--\\====================================================//--

CharLoader.R6.MouseButton1Click:Connect(function()
	local succ, chr = pcall(function()
		return CharModule:LoadR6(CharLoader.Id.Text, workspace)
	end)
	if not succ then
		warn("[Shell Library]: Can't insert character")
	else 
		chr:MoveTo((Camera.CFrame + (Camera.CFrame.LookVector * 15)).Position)
		Selection:Set({chr})
		HistoryService:SetWaypoint('Character command')
		
		for index, part in pairs(chr:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Locked = false
			end
		end
	end
end)

CharLoader.R15.MouseButton1Click:Connect(function()
	local succ, chr = pcall(function()
		return CharModule:LoadR15(CharLoader.Id.Text, workspace)
	end)
	if not succ then
		warn("[Shell Library]: Can't insert character")
	else 
		chr:MoveTo((Camera.CFrame + (Camera.CFrame.LookVector * 15)).Position)
		Selection:Set({chr})
		HistoryService:SetWaypoint('Character command')
		
		for index, part in pairs(chr:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Locked = false
			end
		end
	end
end)

CharLoader.Rthro.MouseButton1Click:Connect(function()
	local succ, chr = pcall(function()
		return CharModule:LoadRthro(CharLoader.Id.Text, workspace)
	end)
	if not succ then
		warn("[Shell Library]: Can't insert character")
	else 
		chr:MoveTo((Camera.CFrame + (Camera.CFrame.LookVector * 15)).Position)
		Selection:Set({chr})
		HistoryService:SetWaypoint('Character command')
		
		for index, part in pairs(chr:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Locked = false
			end
		end
	end
end)

CharLoader:WaitForChild("Id").Changed:Connect(function()
	local playerid
	pcall(function()
		playerid = game.Players:GetUserIdFromNameAsync(CharLoader.Id.Text)
	end)
	if playerid then
		CharLoader.AvatarBust.Image = game.Players:GetUserThumbnailAsync(
			playerid, 
			Enum.ThumbnailType.AvatarBust, 
			Enum.ThumbnailSize.Size150x150
		)
	end
end)

--//====================================================\\--
--||			  SHELL LIBRARY * BUILDING                  
--\\====================================================//--

function stringToColor(str: string)
	local data = string.split(str, ", ")
	if tonumber(data[1]) and tonumber(data[2]) and tonumber(data[3]) then
		return Color3.fromRGB(tonumber(data[1]), tonumber(data[2]), tonumber(data[3]))
	else
		return nil
	end
end

function NegateTools()
	Rope_:Disabled(mouse)
	PSelector_:Disabled(mouse)
	threeDtext_:Disabled(mouse)
	Aligner_:Disabled(mouse)
	Brush_:Disabled()
	plugin:Activate(true)
end

-- // Rig Editor \\ --
Building.ScrollTools.RigEditor.Joint.MouseButton1Click:Connect(function()
	local SelectedObjects = Selection:Get()
	if #SelectedObjects ~= 2 then
		warn("[Shell Library]: Keep two parts in selection, then run the command")
	else
		if SelectedObjects[1]:IsA("BasePart") and SelectedObjects[2]:IsA("BasePart") then
			local Part0, Part1 = SelectedObjects[1], SelectedObjects[2]
			
			if Part0.ClassName ~= "Terrain" and Part1.ClassName ~= "Terrain" then
				local Motor6D = Instance.new("Motor6D")
				Motor6D.C0 = Part0.CFrame:toObjectSpace(Part1.CFrame)
				Motor6D.Part0 = Part0
				Motor6D.Part1 = Part1
				Motor6D.Parent = Part1
				
				HistoryService:SetWaypoint('Motor6D command')
			end
		end
	end
end)

Building.ScrollTools.RigEditor.Reset.MouseButton1Click:Connect(function()
	local SelectedObjects = Selection:Get()
	if #SelectedObjects == 0 then
		warn("[Shell Library]: Keep a rig in selection, then run the command")
	else
		for index, joint in pairs(SelectedObjects[1]:GetDescendants()) do
			if joint:IsA("Motor6D") then
				joint:Remove()
			end
		end
		HistoryService:SetWaypoint('Motor6D command')
	end
end)

Building.ScrollTools.RigEditor.Develop.MouseButton1Click:Connect(function()
	local SelectedObjects = Selection:Get()
	if #SelectedObjects == 0 then
		warn("[Shell Library]: Keep a Character in selection, then run the command")
	else
		if SelectedObjects[1]:IsA("Model") then
			if SelectedObjects[1]:FindFirstChildOfClass("HumanoidRootPart") then
				Welder_:DevelopRig(SelectedObjects[1])
				HistoryService:SetWaypoint('Rig command')
			else
				warn("[Shell Library]: Rig doesn't have HumanoidRootPart")
			end
		end
	end
end)

Building.ScrollTools.RigEditor.WeldToCPart.MouseButton1Click:Connect(function()
	if #Selection:Get() == 0 then
		warn("[Shell Library]: Select one part, then run the command")
	else
		Welder_:weldToClosestPart(Selection:Get())
		HistoryService:SetWaypoint('Weld command')
	end
end)

Building.ScrollTools.RigEditor.WeldToPPart.MouseButton1Click:Connect(function()
	if #Selection:Get() == 0 then
		warn("[Shell Library]: Hold a roblox Model, then run the command")
	else
		Welder_:weldToPrimaryPart(Selection:Get())
		HistoryService:SetWaypoint('Weld command')
	end
end)

-- // Aligner \\ --
Building.ScrollTools.Aligner.Align.MouseButton1Click:Connect(function()
	NegateTools()
	plugin:Activate(false)
	Aligner_:Enabled(mouse,
		Building.ScrollTools.Aligner.PartOnly.Boolean.Value,
		Building.ScrollTools.Aligner.Axis.Boolean.Value
	)
	HistoryService:SetWaypoint('Aligner command')
end)

Building.ScrollTools.Aligner.Pivot.MouseButton1Click:Connect(function()
	local SelectedObjects = Selection:Get()
	if #SelectedObjects ~= 2 then
		warn("[Shell Library]: Select two objects to align their pivots")
	else
		local obj1, obj2 = SelectedObjects[1], SelectedObjects[2]
		if obj1:IsA("Model") or obj1:IsA("BasePart") then
			if obj2:IsA("Model") or obj2:IsA("BasePart") then
				obj1:PivotTo(obj2:GetPivot())
				HistoryService:SetWaypoint('Pivot command')
			end
		end
	end
end)

-- // 3D Text \\ --
Building.ScrollTools.ThreeDText.Write.MouseButton1Click:Connect(function()
	NegateTools()
	if not workspace:FindFirstChild("WRITER_TOOL") then
		plugin:Activate(false)
		threeDtext_:Enabled(mouse,
			Building.ScrollTools.ThreeDText.Input,
			Building.ScrollTools.ThreeDText.ColorText
		)
	end
end)

Building.ScrollTools.ThreeDText:WaitForChild("ColorText").Changed:Connect(function()
	local color = stringToColor(
		Building.ScrollTools.ThreeDText.ColorText.Text
	) or Color3.fromRGB(25, 25, 25)
	
	Building.ScrollTools.ThreeDText.colorpick.BackgroundColor3 = color
end)

-- // BrushTool \\ --
Building.ScrollTools.BrushTool.Brush.MouseButton1Click:Connect(function()
	NegateTools()
	if #Selection:Get() ~= 0 then
		if not workspace:FindFirstChild("BRUSH_TOOL") then
			plugin:Activate(false)
			Brush_:Enabled(
				Building.ScrollTools.BrushTool.delay, 
				Building.ScrollTools.BrushTool.Eraser.Boolean
			)
			HistoryService:SetWaypoint('Brush command')
		end
	end
end)

-- // Part Drawer \\ --
Building.ScrollTools.RopeDrawer.Draw.MouseButton1Click:Connect(function()
	NegateTools()
	plugin:Activate(false)
	Rope_:Enabled(mouse,
		Building.ScrollTools.RopeDrawer.Curve.Boolean, 
		Building.ScrollTools.RopeDrawer.RopeColor
	)
end)

Building.ScrollTools.RopeDrawer:WaitForChild("RopeColor").Changed:Connect(function()
	local color = stringToColor(
		Building.ScrollTools.RopeDrawer.RopeColor.Text
	) or Color3.fromRGB(165, 138, 95)
	
	Building.ScrollTools.RopeDrawer.colorpick.BackgroundColor3 = color
end)

-- // Part Selector \\ --
Building.ScrollTools.PartSelector.Search.MouseButton1Click:Connect(function()
	NegateTools()
	plugin:Activate(false)
	PSelector_:Enabled(mouse, 
		Building.ScrollTools.PartSelector.sameParent.Boolean.Value,
		Building.ScrollTools.PartSelector.sameColor.Boolean.Value,
		Building.ScrollTools.PartSelector.Distance.Text
	)
end)

Building.ScrollTools.BrushTool.Cancel.MouseButton1Click:Connect(function() 
	Brush_:Disabled()
end)
Building.ScrollTools.RopeDrawer.Stop.MouseButton1Click:Connect(function() 
	plugin:Activate(true)
	Rope_:Disabled(mouse)
end)
Building.ScrollTools.ThreeDText.Cancel.MouseButton1Click:Connect(function()
	plugin:Activate(true)
	threeDtext_:Disabled(mouse)
end)

--//====================================================\\--
--||			  SHELL LIBRARY * TERRAIN                   
--\\====================================================//--

for index, button in pairs(Terrain:GetChildren()) do
	if button:IsA("ImageButton") then
		button.MouseButton1Click:Connect(function()
			for index, rest in pairs(Terrain:GetChildren()) do
				if rest:IsA("ImageButton") then rest.BorderColor3 = Color3.fromRGB(0, 0, 0) end
			end
			Terrain.Material.Value = button.Name
			button.BorderColor3 = Color3.fromRGB(255, 255, 255)
		end)
	end
end

Terrain.Convert.MouseButton1Click:Connect(function()
	local SelectedObjects = Selection:Get()
	if #SelectedObjects == 0 then
		warn("[Shell Library]: Before Convert, you need a selected part first")
	else
		if Terrain.DestroyPart.Boolean.Value == true then
			TerrainConverter(Terrain.Material.Value, true)
		else
			TerrainConverter(Terrain.Material.Value, false)
		end
		HistoryService:SetWaypoint('Part Converted')
	end
end)

--//====================================================\\--
--||			 SHELL LIBRARY * DATASTORE                  
--\\====================================================//--

DatastoreFr:WaitForChild("DataName").Changed:Connect(function()
	if game.GameId ~= 0 then
		DatastoreFr.API_Access.Visible = false
	else
		DatastoreFr.API_Access.Visible = true
	end
end)

DatastoreFr.Connect.MouseButton1Click:Connect(function()
	if game.GameId ~= 0 then
		if DataModule:IsA_Datastore(DatastoreFr.DataName.Text) then
			DataModule:ShowData(
				DatastoreFr.Scrolldata,
				DatastoreFr.DataName.Text, 
				DatastoreFr.Ordered.Boolean.Value
			)
		else
			warn("[Shell Library]: Cannot connect or does not exist")
		end
	else
		warn("[Shell Library]: Publish and enable the Roblox API")
	end
end)

-- // Open and Close Plugin \\ --

function ClosePlugin()
	IsActive = false
	Button:SetActive(false)
	ShellGui.Enabled = false
	ShellGui.Parent = Library
	
	DatastoreFr.Scrolldata:ClearAllChildren()
	DatastoreFr.Scrolldata.CanvasSize = UDim2.new(0, 0, 0, 0)
	CharLoader.AvatarBust.Image = "https://www.roblox.com/bust-thumbnail/image?userId=811183920&width=150&height=150&format=png"
	CharLoader.Id.Text = "mari230899"
	NegateTools()
end

function Enlarge()
	Frame.bar1.Visible = true
	Frame.Icon.Visible = true
	Frame.txt.Visible = true
	Frame.Buttons.Visible = true
	Frame.Container.Visible = true
	
	Frame.Size = UDim2.new(0, 287, 0, 378)
	Reduced = false
end

HistoryService.OnUndo:Connect(function(change)
	if change == "Action" then
		game.Selection:Set({})
	end
end)

Frame.Close.MouseButton1Click:Connect(function()
	ClosePlugin()
end)

Frame.Reduce.MouseButton1Click:Connect(function()
	if Reduced == false then
		Reduced = true
		Frame.bar1.Visible = false
		Frame.Icon.Visible = false
		Frame.txt.Visible = false
		Frame.Buttons.Visible = false
		Frame.Container.Visible = false
		
		Frame.Size = UDim2.new(0, 287, 0, 56)
	else
		Enlarge()
	end
end)

Button.Click:Connect(function()
	if IsActive == false then
		IsActive = true
		Button:SetActive(true)
		ShellGui.Enabled = true
		ShellGui.Parent = CoreGui
		MakeDraggable:Enable()
		Enlarge()
	else
		ClosePlugin()
		MakeDraggable:Disable()
	end
end)

CheckForUpdate()
