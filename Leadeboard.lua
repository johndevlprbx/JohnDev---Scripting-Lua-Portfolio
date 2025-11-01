local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ds = DataStoreService:GetOrderedDataStore("InfamyLeaderboard")
local InfamyModule = require(ReplicatedStorage:WaitForChild("InfamyModule"))

local resetTime = 60
local storedValueName = "InfamyData"

local lbModel = script.Parent.Parent.Parent.Parent.Parent
local dummy1 = lbModel:WaitForChild("Dummy1")
local dummy2 = lbModel:WaitForChild("Dummy2")
local dummy3 = lbModel:WaitForChild("Dummy3")

local dum1Hum = dummy1:WaitForChild("Humanoid")
local dum2Hum = dummy2:WaitForChild("Humanoid")
local dum3Hum = dummy3:WaitForChild("Humanoid")

local characterAppearances = {}
local function getCharacterAppearance(userId)
	if characterAppearances[userId] then return characterAppearances[userId] end
	local desc
	local success = pcall(function()
		desc = Players:GetHumanoidDescriptionFromUserId(userId)
	end)
	if not success then
		repeat
			success = pcall(function()
				desc = Players:GetHumanoidDescriptionFromUserId(userId)
			end)
			wait(3)
		until success
	end
	characterAppearances[userId] = desc
	return desc
end

local cache = {}
local function getUserIdFromUsername(name)
	if cache[name] then return cache[name] end
	local player = Players:FindFirstChild(name)
	if player then
		cache[name] = player.UserId
		return player.UserId
	end
	local id
	local success = pcall(function()
		id = Players:GetUserIdFromNameAsync(name)
	end)
	cache[name] = id
	return id
end

local function formatInfamy(infamy)
	local roman = InfamyModule.ToRoman(infamy)
	return string.format("%s (%d)", roman, infamy)
end

local function updateLeaderboard()
	local success, err = pcall(function()
		local data = ds:GetSortedAsync(false, 100)
		local page = data:GetCurrentPage()

		for _, frame in pairs(script.Parent:GetChildren()) do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end

		for rank, entry in ipairs(page) do
			local name = entry.key
			local infamy = math.floor(entry.value)
			local color = InfamyModule.GetColor(infamy)

			local newObj = script.Template:Clone()
			newObj.PlrName.Text = name
			newObj.Coins.Text = formatInfamy(infamy)
			newObj.Coins.TextColor3 = color
			newObj.Rank.Text = "#" .. rank
			newObj.Parent = script.Parent

			local userId = getUserIdFromUsername(name)
			local desc = getCharacterAppearance(userId)

			if rank == 1 then
				newObj.Rank.TextColor3 = Color3.fromRGB(255, 255, 0)
				dum1Hum:ApplyDescription(desc)
				dum1Hum.DisplayName = name
			elseif rank == 2 then
				newObj.Rank.TextColor3 = Color3.fromRGB(108, 108, 108)
				dum2Hum:ApplyDescription(desc)
				dum2Hum.DisplayName = name
			elseif rank == 3 then
				newObj.Rank.TextColor3 = Color3.fromRGB(180, 120, 0)
				dum3Hum:ApplyDescription(desc)
				dum3Hum.DisplayName = name
			end

			-- Atualiza pasta LeaderboardRanks
			local player = Players:FindFirstChild(name)
			if player then
				local folder = player:FindFirstChild("LeaderboardRanks")
				if not folder then
					folder = Instance.new("Folder")
					folder.Name = "LeaderboardRanks"
					folder.Parent = player
				end

				local position = folder:FindFirstChild("InfamyLb")
				if not position then
					position = Instance.new("IntValue")
					position.Name = "InfamyLb"
					position.Parent = folder
				end

				position.Value = rank
			end
		end
	end)
	if not success then
		warn("Leaderboard update failed:", err)
	end
end

local function playEmoteForDummies()
	for i = 1, 3 do
		local dummy = lbModel:FindFirstChild("Dummy" .. i)
		if dummy then
			for _, part in pairs(dummy:GetChildren()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					if part.Name == "HumanoidRootPart" then
						part.Anchored = true
					else
						part.Anchored = false
					end
				end
			end

			dummy.Humanoid.PlatformStand = false
			local anim = Instance.new("Animation")
			if i == 1 then
				anim.AnimationId = "rbxassetid://3337994105"
			elseif i == 2 then
				anim.AnimationId = "rbxassetid://4841405708"
			elseif i == 3 then
				anim.AnimationId = "rbxassetid://3333499508"
			end
			local track = dummy.Humanoid:LoadAnimation(anim)
			track:Play()
		end
	end
end

playEmoteForDummies()

task.delay(2, updateLeaderboard)

while wait(1) do
	resetTime -= 1
	if resetTime <= 0 then
		resetTime = 60
		for _, player in pairs(Players:GetPlayers()) do
			local infamy = player:FindFirstChild("InfamyData")
			local value = infamy and infamy.Value or 0
			ds:SetAsync(player.Name, value)
		end
		updateLeaderboard()
	end
end

Players.PlayerRemoving:Connect(function(player)
	local infamy = player:FindFirstChild("InfamyData")
	local value = infamy and infamy.Value or 0
	local success = pcall(function()
		ds:SetAsync(player.Name, value)
	end)
	if not success then
		local attempts = 0
		repeat
			success = pcall(function()
				ds:SetAsync(player.Name, value)
			end)
			attempts += 1
			wait(3)
		until success
		print("Saved after", attempts, "attempts.")
	end
end)
