# SimpleQuests

## Adding Quests

Add quests to your Quests.lua module like so:

    {
        Id = 1,
        Name = "First Quest",
        Description = "Collect 10 coins",
        Type = "CollectCoins",
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

Properties:

- Id (number, required) - Must start at 1 and increment by 1 (1, 2, 3, etc). Players progress through quests in this order
- Name (string, required) - The quest name
- Description (string, required) - The quest description
- Type (string, required) - Must match the Type you pass to UpdateProgress()
- Goal (number, required) - The target value to complete the quest
- Rewards (table, required) - Array of reward tables containing RewardFunc and Value

## Updating Quest Progress

### :UpdateProgress()

Call this method after player actions to update quest progress.

Syntax:

    SimpleQuests:UpdateProgress(player, questType, increment)

Arguments:

- player (Player, required) - The player to update progress for
- questType (string, required) - The quest Type to update
- increment (number, required) - The amount to increment progress by

Example:

    game.ReplicatedStorage.CoinCollected.OnServerEvent:Connect(function(player)
        SimpleQuests:UpdateProgress(player, "CollectCoins", 1)
    end)
