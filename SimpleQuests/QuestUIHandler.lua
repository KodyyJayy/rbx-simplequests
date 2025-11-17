--!strict

------------------------------------------------------------------------------------------
--										SERVICES										--
------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------
--									TYPE DEFINITIONS									--
------------------------------------------------------------------------------------------

local QuestTypes = require(ReplicatedStorage.SimpleQuests.QuestTypes)

export type Quest = QuestTypes.Quest
export type Reward = QuestTypes.Reward
export type QuestType = QuestTypes.QuestType

type UpdateDescriptionData = {
	Progress: number,
	Goal: number,
	QuestType: QuestType,
	Description: string,
}

type QuestUIHandlerClass = {
	Initialize: () -> (),
	DisplayQuest: (questData: Quest) -> (),
	UpdateQuestDetails: (questData: UpdateDescriptionData) -> (),
	Hide: () -> (),
	QuestCompleted: (questData: Quest) -> (),
	_ProcessNext: () -> (),
	_RunQuestCompletedAnimation: (questData: Quest) -> (),
}

------------------------------------------------------------------------------------------
--										VARIABLES										--
------------------------------------------------------------------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local UI = script.QuestUI
local MainFrame = UI:FindFirstChild("Main") :: Frame
local CompletedFrame = UI:FindFirstChild("CompletedFrame") :: Frame
local DetailsFrame = CompletedFrame:FindFirstChild("Details") :: Frame
local UIListLayout = DetailsFrame:FindFirstChild("UIListLayout") :: UIListLayout
local RewardTemplate = UIListLayout:FindFirstChild("Reward") :: TextLabel

local completionQueue: {Quest} = {}
local isProcessing: boolean = false

local QuestUIHandler: QuestUIHandlerClass = {} :: any

------------------------------------------------------------------------------------------
--									HELPER FUNCTIONS									--
------------------------------------------------------------------------------------------

--// Formats seconds into MM:SS format for time-based quests
local function FormatTime(seconds: number): string
	local minutes: number = math.floor(seconds / 60)
	local secs: number = math.floor(seconds % 60)
	return string.format("%02d:%02d", minutes, secs)
end

--// Updates the quest description text with current progress
local function UpdateDescription(data: UpdateDescriptionData): ()
	local progressText: string = ""

	if data.QuestType == "Wait" then
		progressText = FormatTime(data.Progress)
	else
		progressText = math.floor(data.Progress) .. "/" .. data.Goal
	end

	local descriptionLabel = MainFrame:FindFirstChild("Description") :: TextLabel
	descriptionLabel.Text = data.Description .. " (" .. progressText .. ")"
end

--// Updates the rewards display with a list of quest rewards
local function UpdateRewards(rewards: {Reward}?): ()
	local rewardsLabel = MainFrame:FindFirstChild("Rewards") :: TextLabel
	rewardsLabel.Text = "Rewards:"

	if not rewards then return end

	for _, reward: Reward in rewards do
		if not reward.Description then continue end

		rewardsLabel.Text = rewardsLabel.Text .. "\n- " .. reward.Description
	end
end

--// Helper function to create a tween animation
local function createTween(frame: GuiObject, tweenInfo: TweenInfo, goal: {[string]: any}): Tween
	return TweenService:Create(frame, tweenInfo, goal)
end

--// Fades text transparency from current value to target value (including UIStroke)
local function fadeText(textLabel: TextLabel, target: number, increment: number): ()
	for i = textLabel.TextTransparency, target, increment do
		print(i)
		textLabel.TextTransparency = i

		local uiStroke = textLabel:FindFirstChildOfClass("UIStroke") :: UIStroke?
		if uiStroke then
			uiStroke.Transparency = i
		end

		task.wait(0.001)
	end
end

------------------------------------------------------------------------------------------
--									QUESTUIHANDLER API									--
------------------------------------------------------------------------------------------

--// Initializes the quest UI by parenting it to PlayerGui
function QuestUIHandler.Initialize(): ()
	UI.Parent = PlayerGui
end

--// Displays a new quest with its title, description, and rewards
function QuestUIHandler.DisplayQuest(questData: Quest): ()
	assert(questData, "[QuestUIHandler.DisplayQuest] questData is missing or nil.")

	MainFrame.Visible = true

	local titleLabel = MainFrame:FindFirstChild("Title") :: TextLabel
	local descriptionLabel = MainFrame:FindFirstChild("Description") :: TextLabel

	titleLabel.Text = questData.Name
	descriptionLabel.Text = questData.Description

	UpdateDescription({
		Progress = 0,
		Goal = questData.Goal,
		QuestType = questData.Type,
		Description = questData.Description
	})

	UpdateRewards(questData.Rewards)
end

--// Updates the quest progress display with new progress data
function QuestUIHandler.UpdateQuestDetails(questData: UpdateDescriptionData): ()
	assert(questData, "[QuestUIHandler.UpdateQuestDetails] questData is missing or nil.")

	UpdateDescription({
		Progress = questData.Progress,
		Goal = questData.Goal,
		QuestType = questData.QuestType,
		Description = questData.Description
	})
end

--// Hides the main quest UI frame
function QuestUIHandler.Hide(): ()
	MainFrame.Visible = false
end

--// Queues a completed quest for animation and starts processing if not already running
function QuestUIHandler.QuestCompleted(questData: Quest): ()
	QuestUIHandler.Hide()
	assert(questData, "[QuestUIHandler.QuestCompleted] questData is missing or nil.")

	table.insert(completionQueue, questData)

	--// If nothing is processing, start the chain
	if not isProcessing then
		QuestUIHandler._ProcessNext()
	end
end

--// Processes the next quest in the completion queue
function QuestUIHandler._ProcessNext(): ()
	if #completionQueue == 0 then
		isProcessing = false
		return
	end

	isProcessing = true

	local questData: Quest = table.remove(completionQueue, 1) :: Quest
	QuestUIHandler._RunQuestCompletedAnimation(questData)
end

--// Runs the full quest completion animation including reward reveal
function QuestUIHandler._RunQuestCompletedAnimation(questData: Quest): ()
	--// Reset completed frame state
	CompletedFrame.Size = UDim2.new(0.4, 0, 0, 100)

	local completedTextLabel = CompletedFrame:FindFirstChild("TextLabel") :: TextLabel
	completedTextLabel.Visible = true
	completedTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	completedTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	completedTextLabel.Size = UDim2.new(0, 0, 0, 0)

	--// Animate "Quest Completed" text label appearing
	local textTweenInfo: TweenInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out
	)

	local textTween: Tween = createTween(
		completedTextLabel,
		textTweenInfo,
		{Size = UDim2.new(1, 0, 0, 100)}
	)

	textTween:Play()
	textTween.Completed:Wait()
	task.wait(1)

	--// Expand frame and display rewards only if they exist in questData.
	if questData and questData.Rewards then

		--// Reposition "Quest Completed" text label for frame expansion
		completedTextLabel.AnchorPoint = Vector2.new(0.5, 0)
		completedTextLabel.Position = UDim2.new(0.5, 0, 0, 0)

		--// Animate frame expanding
		local frameTweenInfo: TweenInfo = TweenInfo.new(
			0.5,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		)

		local frameTween: Tween = createTween(
			CompletedFrame,
			frameTweenInfo,
			{Size = UDim2.new(0.4, 0, 0, 500)}
		)

		frameTween:Play()
		frameTween.Completed:Wait()

		task.wait(0.5)

		local detailsTitle = DetailsFrame:FindFirstChild("Title") :: TextLabel
		local rewardsLabel = DetailsFrame:FindFirstChild("RewardsLabel") :: TextLabel

		detailsTitle.Text = questData.Name

		fadeText(detailsTitle, 0, -0.01)
		fadeText(rewardsLabel, 0, -0.01)

		local rewardLabels: {TextLabel} = {}

		for _, reward: Reward in questData.Rewards do
			local newReward: TextLabel = RewardTemplate:Clone()
			newReward.Text = " - " .. reward.Description
			newReward.Parent = DetailsFrame

			table.insert(rewardLabels, newReward)

			fadeText(newReward, 0, -0.01)
		end

		task.wait(3)

		for _, rewardLabel: TextLabel in rewardLabels do
			rewardLabel:Destroy()
		end

		detailsTitle.TextTransparency = 1
		local titleStroke = detailsTitle:FindFirstChildOfClass("UIStroke") :: UIStroke?
		if titleStroke then
			titleStroke.Transparency = 1
		end

		rewardsLabel.TextTransparency = 1
		local rewardsStroke = rewardsLabel:FindFirstChildOfClass("UIStroke") :: UIStroke?
		if rewardsStroke then
			rewardsStroke.Transparency = 1
		end

		completedTextLabel.Visible = false
	end

	QuestUIHandler._ProcessNext()
end

return QuestUIHandler
