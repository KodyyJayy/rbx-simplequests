--[[

SimpleQuests README

You can add quests to your Quests.lua module like so:
{
    Id = 1, -- Must start at 1 and increment by 1 (1, 2, 3, etc). Players progress through quests in this order
    Name = "First Quest",
    Description = "Collect 10 coins",
    Type = "CollectCoins", -- Must match the Type you pass to UpdateProgress()
    Goal = 10,
    Rewards = {
        {
            RewardFunc = function(player, value)
                player.leaderstats.Gold.Value += value
            end,
            Value = 100
        }
    }
}


Updating the quest progress after player actions can be done by calling the :UpdateProgress() method, and passing in the following arguments:
    1. Player : Player (REQUIRED)
    2. Quest Type : string (REQUIRED)
    3. Increment : number (REQUIRED)

Example:
game.ReplicatedStorage.CoinCollected.OnServerEvent:Connect(function(player)
    SimpleQuests:UpdateProgress(player, "CollectCoins", 1)
end)

]]
