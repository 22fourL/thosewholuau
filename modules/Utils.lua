local utils = {}

-- returns nearest hrp
function utils.getNearestHumanoidRootPartFromCharacter(fromCharacter: Model)
	local nearestHRP = nil
	local shortestDistance = math.huge
	
	local charCFrame, charSize = fromCharacter:GetBoundingBox()
	local fromPosition = charCFrame.Position

	for _, model in ipairs(workspace:GetDescendants()) do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local hrp = model:FindFirstChild("HumanoidRootPart")

		if humanoid and hrp and model ~= fromCharacter then
			local distance = (hrp.Position - fromPosition).Magnitude

			if distance < shortestDistance then
				shortestDistance = distance
				nearestHRP = hrp
			end
		end
	end

	return nearestHRP
end

-- parent is optional, otherwise is global.
function util.cloneAndPlay(sfx: Sound, optionalParent: Instance?)
	local clone = sfx:Clone()
	
	if optionalParent then
		clone.Parent = optionalParent
	else
		clone.Parent = workspace.Game.Temp
	end
	
	clone:Play()
	Debris:AddItem(clone, clone.TimeLength + 2)
end

-- returns whatever a basepart has hit, nil if none.
function util.getPartThatTouched(objectPart: Part): Instance?
	local objecttable = workspace:GetPartBoundsInBox(objectPart.CFrame, objectPart.Size)
	local humsHit = {}

	for i, v in objecttable do

		if v:IsA("BasePart") and not humsHit[v.Parent.Name] and v.Anchored == false then

			humsHit[v.Parent.Name] = true

			-- ok cool we hit them now
			return v
		end

	end

	return nil
end


-- this only returns true if the part is a humanoidrootpart
function util.isAchildOfACharacter(part: Part)
	if part.Parent == nil then
		return false
	end

	if part.Parent:FindFirstChildOfClass("Humanoid")
		and part:IsA("BasePart")
		and part.Name ~= "Handle"
		and Players:GetPlayerFromCharacter(part.Parent) ~= nil
		and part.Name == "HumanoidRootPart" then
		return true
	else
		return false
	end
end

return utils
