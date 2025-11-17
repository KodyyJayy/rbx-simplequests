--!strict

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--// Variables
local Datastore = require(ServerScriptService.DataStore2)
local SimpleQuests = require(ServerScriptService.SimpleQuests)

--// Main Code

local DATASTORE_KEY: string = RunService:IsStudio() and "Testing" or "Production"
Datastore.Combine(DATASTORE_KEY, "PlayerQuests")

Players.PlayerAdded:Connect(function(player: Player)	
	player:GetAttributeChangedSignal("QuestDataLoaded"):Connect(function()
		if player:GetAttribute("QuestDataLoaded") then
			task.spawn(function()
				while task.wait(1) do
					if not player.Parent then break end

					local quest: SimpleQuests.Quest? = SimpleQuests:GetCurrentQuest(player)

					if quest and quest.Type == "Wait" then
						SimpleQuests:UpdateProgress(player, "Wait", 1)
					else
						break
					end
				end
			end)
		end
	end)
end)