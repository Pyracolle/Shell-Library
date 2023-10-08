local W = {}

-- << Private functions >> --

function GetClosestPart(Selected: BasePart)
	local Closest
	for index, v in pairs(workspace:GetDescendants()) do 
		if v:IsA("BasePart") and v ~= Selected then 
			if Closest == nil then 
				Closest = v
			else 
				if (Selected.Position - v.Position).magnitude < (Closest.Position - Selected.Position).magnitude then 
					Closest = v 
				end 
			end
		end 
	end 
	if Closest ~= nil then 
		for i,v in pairs(workspace:GetDescendants()) do
			if v == Closest then return v end 
		end 
	end
end

-- << Plugin Usage >> --

function W:weldToPrimaryPart(SelectedObjects)
	for index, selection in pairs(SelectedObjects) do
		if selection:IsA("Model") then
			if selection.PrimaryPart == nil then
				warn("[Shell Library]: Selected model doesn't contain PrimaryPart")
			else
				for index, v in pairs(selection:GetChildren()) do
					if v:IsA("BasePart") and v ~= selection.PrimaryPart then
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = selection.PrimaryPart 
						weld.Part1 = v
						weld.Parent = v
					end
				end
			end
		else
			warn("[Shell Library]: Selected object must be a model")
		end
	end
end

function W:weldToClosestPart(SelectedObjects)
	for index, selection in pairs(SelectedObjects) do
		local ClosestPart = GetClosestPart(selection)
		if ClosestPart ~= nil then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = ClosestPart
			weld.Part1 = selection
			weld.Parent = ClosestPart
		else
			warn("[Shell Library]: No parts nearby")
		end
	end
end

local system = {
	["R6"] = {
		["Torso"] = {"HumanoidRootPart", "RootJoint"};
		["Right Arm"] = {"Torso", "Right Hip"};
		["Right Leg"] = {"Torso", "Left Hip"};
		["Left Arm"] = {"Torso", "Left Shoulder"};
		["Left Leg"] = {"Torso", "Right Shoulder"};
		["Head"] = {"Torso", "Neck"}
	};
	["R15"] = {
		["LowerTorso"] = {"HumanoidRootPart", "Root"};
		["UpperTorso"] = {"LowerTorso", "Waist"};
		["RightUpperLeg"] = {"LowerTorso", "RightHip"};
		["LeftUpperLeg"] = {"LowerTorso", "LeftHip"};
		["Head"] = {"UpperTorso", "Neck"};
		["RightUpperArm"] = {"UpperTorso", "RightShoulder"};
		["LeftUpperArm"] = {"UpperTorso", "LeftShoulder"};
		
		["RightLowerArm"] = {"RightUpperArm", "RightElbow"};
		["LeftLowerArm"] = {"LeftUpperArm", "LeftElbow"};
		["RightHand"] = {"RightLowerArm", "RightWrist"};
		["LeftHand"] = {"LeftLowerArm", "LeftWrist"};
		["RightLowerLeg"] = {"RightUpperLeg", "RightKnee"};
		["LeftLowerLeg"] = {"LeftUpperLeg", "LeftKnee"};
		["RightFoot"] = {"RightLowerLeg", "RightAnkle"};
		["LeftFoot"] = {"LeftLowerLeg", "LeftAnkle"}
	}
}

function W:DevelopRig(Figure: Model)
	local function CreateMotor(A, B)
		local CF = B.CFrame:toObjectSpace(A.CFrame)
		local Motor6D = Instance.new("Motor6D")
		Motor6D.Part0 = B
		Motor6D.Part1 = A
		Motor6D.C0 = CF
		Motor6D.MaxVelocity = 0
		
		return Motor6D
	end
	
	if Figure:FindFirstChild("Torso") then
		for index, part in pairs(Figure:GetChildren()) do
			local T = table.find(system["R6"], part.Name)
			
			if T ~= nil and part:IsA("BasePart") then
				local motor = CreateMotor(part, Figure[T[1]])
				motor.Name = T[2]
				motor.Parent = Figure[T[1]]
			end
		end
	else
		for index, part in pairs(Figure:GetChildren()) do
			local T = table.find(system["R15"], part.Name)
			
			if T ~= nil and part:IsA("BasePart") then
				local motor = CreateMotor(part, Figure[T[1]])
				motor.Name = T[2]
				motor.Parent = part
			end
		end
	end
end

return W
