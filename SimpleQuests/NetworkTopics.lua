local RewardsModule = require(game.ServerScriptService.RewardsModule)
local QuestTypes = require(script.Parent.QuestTypes)

local Quests: {QuestTypes.Quest} = {
	{
		Id = 1,
		Name = "Welcome Adventurer",
		Description = "Stay in the game for 10 seconds!",
		Type = "Wait",
		Goal = 10,
		Rewards = {
			{
				Description = "Desert Plot",
				RewardFunc = RewardsModule.Give,
				Value = "Desert"
			},
			{
				Description = "Phoenix Buddy",
				RewardFunc = RewardsModule.Give,
				Value = "Phoenix"
			},
		}
	},
}

return Quests
