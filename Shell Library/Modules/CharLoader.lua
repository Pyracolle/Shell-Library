local CharModule = {}
local InsertService = game:GetService("InsertService")
local Selection = game:GetService("Selection")
local Players = game.Players
local Camera = workspace.CurrentCamera

function CharModule:LoadR6(username, parent)
	local userId = Players:GetUserIdFromNameAsync(username)
	local PlayerApp = Players:GetHumanoidDescriptionFromUserId(userId)
	local RigType = Enum.HumanoidRigType.R6
	
	if PlayerApp ~= nil then
		local Model = Players:CreateHumanoidModelFromDescription(PlayerApp, RigType)
		Model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		Model.PrimaryPart = Model.HumanoidRootPart
		Model.Name = username
		Model.Parent = parent
		
		return Model
	end
end

function CharModule:LoadR15(username, parent)
	local userId = Players:GetUserIdFromNameAsync(username)
	local PlayerApp = Players:GetHumanoidDescriptionFromUserId(userId)
	local RigType = Enum.HumanoidRigType.R15
	
	if PlayerApp ~= nil then
		local Model = Players:CreateHumanoidModelFromDescription(PlayerApp, RigType)
		Model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		Model.PrimaryPart = Model.HumanoidRootPart
		Model.Name = username
		Model.Parent = parent
		
		return Model
	end
end

function CharModule:LoadRthro(username, parent)
	local userId = Players:GetUserIdFromNameAsync(username)
	local PlayerApp = Players:GetHumanoidDescriptionFromUserId(userId)
	local RigType = Enum.HumanoidRigType.R15
	
	if PlayerApp ~= nil then
		local Model = Players:CreateHumanoidModelFromDescription(PlayerApp, RigType)
		Model.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		Model.PrimaryPart = Model.HumanoidRootPart
		
		Model.Humanoid.BodyHeightScale.Value = 1.5
		Model.Humanoid.BodyDepthScale.Value = 1
		Model.Humanoid.HeadScale.Value = 1
		Model.Name = username
		Model.Parent = parent

		return Model
	end
end

function CharModule:LoadBundle(id: number)
	local info = game:GetService("AssetService"):GetBundleDetailsAsync(id)
	
	local bundle
	local function GetBundle()
		local itemId = 0
		for _,item in pairs(info.Items) do
			if item.Type == "UserOutfit" then
				itemId = item.Id
				break
			end
		end
		if itemId > 0 then
			bundle = Players:GetHumanoidDescriptionFromOutfitId(itemId)
			if info.BundleType == "AvatarAnimations" then
				local animTypes = {}
				
				for _,item in pairs(info.Items) do
					if item.Type == "Asset" then
						local animType = item.Name:match("[^ ]+$")
						table.insert(animTypes, animType)
					end
				end
				local animTypesDef = Instance.new("StringValue")
				animTypesDef.Value = table.concat(animTypes, ';')
				animTypesDef.Name = "AnimTypes"
				animTypesDef.Parent = bundle
			end
		end
		return info.BundleType
	end
	
	local bundleType = GetBundle()
	local Model = Players:CreateHumanoidModelFromUserId(4875385576)
	local Humanoid = Model.Humanoid
	Model.Parent = workspace
	
	if Humanoid and bundle then
		local apply
		if bundleType == "AvatarAnimations" then
			local animTypes = bundle.AnimTypes.Value
			local desc = Humanoid:GetAppliedDescription()
			
			local changed = false
			for animType in animTypes:gmatch("[^;]+") do
				local prop = animType .. "Animation"
				local value = bundle[prop]
				
				if desc[prop] ~= value then
					desc[prop] = value
					changed = true
				end
			end
			if changed then
				apply = desc
			end
		else
			apply = bundle
		end
		if apply then
			Humanoid:ApplyDescription(apply)
			Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			Model:MoveTo((Camera.CFrame + (Camera.CFrame.LookVector * 15)).Position)
			Selection:Set({Model}) 
			Model.Name = info.Name
		end
	end
end

return CharModule
