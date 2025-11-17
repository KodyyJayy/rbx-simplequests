--!strict

------------------------------------------------------------------------------------------
--										SERVICES										--
------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------------------------------------
--									   VARIABLES	  								 	--
------------------------------------------------------------------------------------------

local Datastore = require(ServerScriptService.DataStore2)
local NetworkTopics = require(ReplicatedStorage.SimpleQuests.NetworkTopics)
local QuestTypes = require(ReplicatedStorage.SimpleQuests.QuestTypes)
local QuestData: {QuestTypes.Quest} = require(ReplicatedStorage.SimpleQuests.Quests)
local QuestEvent: RemoteEvent = ReplicatedStorage.SimpleQuests.QuestEvent :: RemoteEvent

------------------------------------------------------------------------------------------
--									TYPE DEFINITIONS									--
------------------------------------------------------------------------------------------

--// Export types for external use
export type Quest = QuestTypes.Quest
export type QuestType = QuestTypes.QuestType
export type Reward = QuestTypes.Reward
export type PlayerQuestData = QuestTypes.PlayerQuestData

type SimpleQuestsClass = {
	PlayerQuests: {[number]: QuestTypes.PlayerQuestData},
	LoadPlayerData: (self: SimpleQuestsClass, player: Player) -> QuestTypes.SavedQuestData,
	SavePlayerData: (self: SimpleQuestsClass, player: Player) -> (),
	InitializePlayer: (self: SimpleQuestsClass, player: Player) -> (),
	AssignQuest: (self: SimpleQuestsClass, player: Player, questId: number) -> (),
	GetCurrentQuest: (self: SimpleQuestsClass, player: Player) -> QuestTypes.Quest?,
	GetProgress: (self: SimpleQuestsClass, player: Player) -> number,
	UpdateProgress: (self: SimpleQuestsClass, player: Player, questType: QuestTypes.QuestType, amount: number) -> (),
	CompleteQuest: (self: SimpleQuestsClass, player: Player, questId: number) -> (),
}

local SimpleQuests: SimpleQuestsClass = {
	PlayerQuests = {}
} :: any

------------------------------------------------------------------------------------------
--									HELPER FUNCTIONS									--
------------------------------------------------------------------------------------------

--// Helper function to get quest by ID
local function GetQuestById(id: number): QuestTypes.Quest?
	for _, quest in ipairs(QuestData) do
		if quest.Id == id then
			return quest
		end
	end
	return nil
end

------------------------------------------------------------------------------------------
--									SIMPLEQUESTS API									--
------------------------------------------------------------------------------------------

--// Load player quest data
function SimpleQuests:LoadPlayerData(player: Player): QuestTypes.SavedQuestData
	local Store = Datastore("PlayerQuests", player)
	local data: QuestTypes.SavedQuestData = Store:Get({
		CurrentQuestId = 1,
		CompletedQuests = {},
	})

	return data
end

--// Save player quest data
function SimpleQuests:SavePlayerData(player: Player): ()
	local questData: QuestTypes.PlayerQuestData? = self.PlayerQuests[player.UserId]
	if not questData then 
		warn(`[SimpleQuests] No quest data found for {player.Name} during save`)
		return 
	end

	local dataToSave: QuestTypes.SavedQuestData = {
		CurrentQuestId = questData.CurrentQuestId,
		CompletedQuests = questData.CompletedQuests,
	}

	local success: boolean, err: string? = pcall(function()
		local Store = Datastore("PlayerQuests", player)
		Store:Set(dataToSave)
	end)

	if not success then
		warn(`[SimpleQuests] Failed to save data for {player.Name}: {err or "Unknown error"}`)
	end
end

--// Initialize player quest
function SimpleQuests:InitializePlayer(player: Player): ()
	local data: QuestTypes.SavedQuestData = self:LoadPlayerData(player)

	--// Initialize quest data
	self.PlayerQuests[player.UserId] = {
		CurrentQuestId = data.CurrentQuestId,
		CompletedQuests = data.CompletedQuests,
		Progress = 0,
		CurrentQuest = nil,
	}

	--// Assign current quest
	self:AssignQuest(player, data.CurrentQuestId)
	
	player:SetAttribute("QuestDataLoaded", true)
end

--// Assign quest to player
function SimpleQuests:AssignQuest(player: Player, questId: number): ()
	local quest: QuestTypes.Quest? = GetQuestById(questId)
	if not quest then
		print(`[SimpleQuests] {player.Name} has completed all quests!`)
		return
	end

	local questData: QuestTypes.PlayerQuestData? = self.PlayerQuests[player.UserId]
	if not questData then 
		warn(`[SimpleQuests] No quest data found for {player.Name}`)
		return 
	end

	--// Store quest info in memory
	questData.CurrentQuestId = questId
	questData.Progress = 0
	questData.CurrentQuest = {
		Id = quest.Id,
		Name = quest.Name,
		Description = quest.Description,
		Type = quest.Type,
		Goal = quest.Goal,
		Rewards = quest.Rewards,
	}

	--// Send quest data to client
	QuestEvent:FireClient(player, NetworkTopics.QuestStarted, questData.CurrentQuest)

	print(`[SimpleQuests] {player.Name} started quest: {quest.Name} (Progress: 0/{quest.Goal})`)
end

--// Get current quest for player
function SimpleQuests:GetCurrentQuest(player: Player): QuestTypes.Quest?
	local questData: QuestTypes.PlayerQuestData? = self.PlayerQuests[player.UserId]
	if not questData then return nil end
	return questData.CurrentQuest
end

--// Get quest progress
function SimpleQuests:GetProgress(player: Player): number
	local questData: QuestTypes.PlayerQuestData? = self.PlayerQuests[player.UserId]
	if not questData then return 0 end
	return questData.Progress
end

--// Update quest progress
function SimpleQuests:UpdateProgress(player: Player, questType: QuestTypes.QuestType, amount: number): ()
	--// Validate amount is positive
	amount = math.max(0, amount)

	local questData: QuestTypes.PlayerQuestData? = self.PlayerQuests[player.UserId]
	if not questData or not questData.CurrentQuest then return end

	--// Only update if the quest type matches
	if questData.CurrentQuest.Type ~= questType then return end

	questData.Progress = math.min(questData.Progress + amount, questData.CurrentQuest.Goal)

	--// Send progress update to client
	local data = {
		Progress = questData.Progress,
		Goal = questData.CurrentQuest.Goal,
		Type = questData.CurrentQuest.Type,
		Description = questData.CurrentQuest.Description
	}
	
	QuestEvent:FireClient(player, NetworkTopics.ProgressUpdated, data)

	print(`[SimpleQuests] {player.Name} progress: {questData.Progress}/{questData.CurrentQuest.Goal} for quest {questData.CurrentQuest.Name}`)

	--// Check if quest is complete
	if questData.Progress >= questData.CurrentQuest.Goal then
		self:CompleteQuest(player, questData.CurrentQuestId)
	end
end

--// Complete quest and give rewards
function SimpleQuests:CompleteQuest(player: Player, questId: number): ()
	local quest: QuestTypes.Quest? = GetQuestById(questId)
	if not quest then 
		warn(`[SimpleQuests] Quest {questId} not found`)
		return 
	end

	local questData: QuestTypes.PlayerQuestData? = self.PlayerQuests[player.UserId]
	if not questData then 
		warn(`[SimpleQuests] No quest data found for {player.Name}`)
		return 
	end

	--// Check if already completed
	if table.find(questData.CompletedQuests, questId) then 
		warn(`[SimpleQuests] {player.Name} already completed quest {questId}`)
		return 
	end

	--// Add to completed quests
	table.insert(questData.CompletedQuests, questId)

	--// Give rewards
	if quest.Rewards then
		for _, reward: QuestTypes.Reward in quest.Rewards do
			if reward.RewardFunc then
				local success: boolean, err: string? = pcall(function()
					reward.RewardFunc(player, reward.Value)
				end)

				if not success then
					warn(`[SimpleQuests] Failed to give reward to {player.Name}: {err or "Unknown error"}`)
				end
			end
		end
	end

	--// Send completion event to client
	QuestEvent:FireClient(player, NetworkTopics.QuestCompleted, quest)

	print(`[SimpleQuests] {player.Name} completed quest: {quest.Name}`)

	--// Move to next quest ID (even if it doesn't exist yet)
	local nextQuestId: number = questId + 1
	questData.CurrentQuestId = nextQuestId

	local nextQuest: QuestTypes.Quest? = GetQuestById(nextQuestId)

	if nextQuest then
		--// Quest exists, assign it
		self:AssignQuest(player, nextQuestId)
	else
		--// Quest doesn't exist yet, but we've saved the next ID for future updates
		print(`[SimpleQuests] {player.Name} has completed all available quests! CurrentQuestId set to {nextQuestId}`)
		questData.CurrentQuest = nil
		questData.Progress = 0
	end

	--// Save progress
	self:SavePlayerData(player)
end

------------------------------------------------------------------------------------------
--									  		EVENTS										--
------------------------------------------------------------------------------------------

--// Player joined
Players.PlayerAdded:Connect(function(player: Player)
	SimpleQuests:InitializePlayer(player)
end)

--// Player leaving
Players.PlayerRemoving:Connect(function(player: Player)
	SimpleQuests:SavePlayerData(player)
	SimpleQuests.PlayerQuests[player.UserId] = nil
end)

--// Server shutdown - save all player data
game:BindToClose(function()
	for _, player: Player in Players:GetPlayers() do
		SimpleQuests:SavePlayerData(player)
		SimpleQuests.PlayerQuests[player.UserId] = nil
	end
end)

return SimpleQuests