--!strict

------------------------------------------------------------------------------------------
--										SERVICES										--
------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------
--									TYPE DEFINITIONS									--
------------------------------------------------------------------------------------------

local SimpleQuestsFolder = ReplicatedStorage.SimpleQuests
local QuestTypes = require(SimpleQuestsFolder.QuestTypes)

type Quest = QuestTypes.Quest
type QuestType = QuestTypes.QuestType
type UpdateDescriptionData = {
	Progress: number,
	Goal: number,
	QuestType: QuestType,
	Description: string,
}

------------------------------------------------------------------------------------------
--										VARIABLES										--
------------------------------------------------------------------------------------------

local NetworkTopics = require(SimpleQuestsFolder.NetworkTopics)
local QuestUIHandler = require(SimpleQuestsFolder.QuestUIHandler)
local QuestEvent = SimpleQuestsFolder:FindFirstChild("QuestEvent") :: RemoteEvent

------------------------------------------------------------------------------------------
--									   MAIN CODE										--
------------------------------------------------------------------------------------------

QuestUIHandler.Initialize()

QuestEvent.OnClientEvent:Connect(function(topic: string, questData: Quest | UpdateDescriptionData)
	if topic == NetworkTopics.QuestStarted then
		QuestUIHandler.DisplayQuest(questData :: Quest)
	elseif topic == NetworkTopics.QuestCompleted then
		QuestUIHandler.QuestCompleted(questData :: Quest)
	elseif topic == NetworkTopics.ProgressUpdated then
		QuestUIHandler.UpdateQuestDetails(questData :: UpdateDescriptionData)
	else
		warn("[SimpleQuests - Client] Invalid network topic passed through QuestEvent! Got:", topic)
	end
end)