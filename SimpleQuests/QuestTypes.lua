--!strict

export type QuestType = "Wait"

export type Reward = {
	Description: string,
	Value: number,
	RewardFunc: ((player: Player, value: number) -> ())?,
}

export type Quest = {
	Id: number,
	Name: string,
	Description: string,
	Type: QuestType,
	Goal: number,
	Rewards: {Reward}?,
}

export type PlayerQuestData = {
	CurrentQuestId: number,
	CompletedQuests: {number},
	Progress: number,
	CurrentQuest: Quest?,
}

export type SavedQuestData = {
	CurrentQuestId: number,
	CompletedQuests: {number},
}

return {}
