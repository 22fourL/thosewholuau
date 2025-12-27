local utils = {}

-- returns nearest hrp and distance
function utils.getNearestHumanoidRootPart(fromPosition)
    local nearestHRP = nil
    local shortestDistance = math.huge

    for _, model in ipairs(workspace:GetChildren()) do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")

        if humanoid and hrp then
            local distance = (hrp.Position - fromPosition).Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                nearestHRP = hrp
            end
        end
    end

    return nearestHRP, shortestDistance
end

return utils
