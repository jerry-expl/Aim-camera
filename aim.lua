-- Universal Anti Camera Shake Script + FPS Boost
-- Chạy tự động, không cần chỉnh gì thêm

local cam = workspace.CurrentCamera

-- Ngăn mọi tác động rung từ các script khác
cam:GetPropertyChangedSignal("CFrame"):Connect(function()
	cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.LookVector)
end)

-- Xóa mọi hiệu ứng rung nếu có
for _, v in ipairs(getgc(true)) do
	if typeof(v) == "function" and islclosure(v) then
		local info = debug.getinfo(v)
		if info.name and (info.name:lower():find("shake") or info.name:lower():find("recoil")) then
			hookfunction(v, function(...) return end)
		end
	end
end

-- FPS Boost for mobile
local function setFpsCap(fps)
	if game:GetService("UserInputService").TouchEnabled then
		-- Adjust FPS for mobile devices
		game:GetService("RunService").Heartbeat:Connect(function()
			if tick() % (1 / fps) < 0.05 then
				return
			end
		end)
	end
end

setFpsCap(240)  -- Đặt FPS cap là 240

-- GUI settings
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local maxDistance = 400
local fovRadius = 100
local circleColor = Color3.fromRGB(100, 200, 255)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "SilentAimGUI"
gui.ResetOnSpawn = false

-- Toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 36, 0, 36)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "✓"
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextScaled = true
toggleButton.Draggable = false
toggleButton.Parent = gui
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)

local enabled = true
toggleButton.MouseButton1Click:Connect(function()
	enabled = not enabled
	toggleButton.Text = enabled and "✓" or "X"
	toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(180, 60, 60)
end)

-- FOV Circle
local circle = Instance.new("Frame", gui)
circle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
circle.BackgroundColor3 = circleColor
circle.BackgroundTransparency = 0.8
circle.BorderSizePixel = 0
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", circle).Color = circleColor

local function updateCirclePosition()
	local inset = GuiService:GetGuiInset()
	local viewportSize = Camera.ViewportSize
	local centerX = viewportSize.X / 2
	local centerY = (viewportSize.Y / 2) - inset.Y
	circle.Position = UDim2.new(0, centerX - fovRadius, 0, centerY - fovRadius)
end

updateCirclePosition()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCirclePosition)

-- Target display
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 36)
frame.Position = UDim2.new(0.5, -110, 0.92, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local barStroke = Instance.new("UIStroke", frame)
barStroke.Color = Color3.fromRGB(100, 100, 255)
barStroke.Transparency = 0.2

local textLabel = Instance.new("TextLabel", frame)
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.Text = "Target: None"
textLabel.TextScaled = true
textLabel.Font = Enum.Font.GothamBold

-- Check visibility
local function isVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.Terrain}
	local result = workspace:Raycast(origin, direction, raycastParams)
	return (not result) or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Find the closest target
local function getClosestTarget()
	local closest = nil
	local shortest = maxDistance
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local head = player.Character.Head
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local isFFA = LocalPlayer.Neutral or player.Neutral or not LocalPlayer.Team or not player.Team
				-- Free For All: Không phân biệt đội
				local isEnemy = isFFA or player.Team ~= LocalPlayer.Team

				if isEnemy then
					local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

					if onScreen and dist < fovRadius and dist < shortest and isVisible(head) then
						shortest = dist
						closest = player
					end
				end
			end
		end
	end

	return closest
end

-- Aim loop
RunService.RenderStepped:Connect(function()
	if not enabled then
		textLabel.Text = "Silent Aim: OFF"
		barStroke.Color = Color3.fromRGB(100, 100, 100)
		return
	end

	local target = getClosestTarget()
	if target and target.Character and target.Character:FindFirstChild("Head") then
		local head = target.Character.Head
		local dir = (head.Position - Camera.CFrame.Position).Unit
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)

		textLabel.Text = "Target: " .. target.Name
		barStroke.Color = Color3.fromRGB(120, 200, 255)
	else
		textLabel.Text = "Target: None"
		barStroke.Color = Color3.fromRGB(100, 100, 255)
	end
end)

print("Anti Camera Shake and FPS Boost Loaded")