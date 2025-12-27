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

return utils
