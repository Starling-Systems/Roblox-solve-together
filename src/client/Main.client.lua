--[[
	Main client script: everything you see on your screen.

	  * Mission panel (top left): what YOU should do right now
	  * Team panel (top right): who is done and who still needs help
	  * Messages (bottom): news from the game
	  * Pop-up window: lessons and problems
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Concepts = require(Shared:WaitForChild("Concepts"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateEvent = Remotes:WaitForChild("State")
local ToastEvent = Remotes:WaitForChild("Toast")
local ShowLessonEvent = Remotes:WaitForChild("ShowLesson")
local ShowProblemEvent = Remotes:WaitForChild("ShowProblem")
local SubmitAnswerEvent = Remotes:WaitForChild("SubmitAnswer")
local AnswerResultEvent = Remotes:WaitForChild("AnswerResult")
local AskForHelpEvent = Remotes:WaitForChild("AskForHelp")
local ChalkboardEvent = Remotes:WaitForChild("ShowOnChalkboard")
local CelebrateEvent = Remotes:WaitForChild("Celebrate")

-- Look and feel -----------------------------------------------------------------

local HEADING_FONT = Enum.Font.FredokaOne
local BODY_FONT = Enum.Font.GothamMedium
local COLORS = {
	panel = Color3.fromRGB(255, 251, 240),
	ink = Color3.fromRGB(45, 45, 60),
	soft = Color3.fromRGB(110, 110, 125),
	accent = Color3.fromRGB(255, 160, 40),
	good = Color3.fromRGB(50, 165, 90),
	bad = Color3.fromRGB(215, 75, 75),
	button = Color3.fromRGB(80, 135, 235),
	box = Color3.fromRGB(240, 234, 215),
}

-- UI helpers ------------------------------------------------------------------

local function create(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function padding(pixels)
	local p = UDim.new(0, pixels)
	return create("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

local function list(gap, direction)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function label(text, props)
	local l = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = BODY_FONT,
		TextSize = 18,
		TextColor3 = COLORS.ink,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	})
	for key, value in pairs(props or {}) do
		l[key] = value
	end
	return l
end

local function button(text, color, onClick)
	local b = create("TextButton", {
		Size = UDim2.new(0, 0, 0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		Font = HEADING_FONT,
		TextSize = 20,
		TextColor3 = Color3.new(1, 1, 1),
		Text = text,
		AutoButtonColor = true,
	}, {
		corner(10),
		create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	b.Activated:Connect(onClick)
	return b
end

local function row(children)
	local frame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, { list(10, Enum.FillDirection.Horizontal) })
	for i, child in ipairs(children) do
		child.LayoutOrder = i
		child.Parent = frame
	end
	return frame
end

local function box(title, body, titleColor)
	return create("Frame", {
		BackgroundColor3 = COLORS.box,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		corner(10),
		padding(12),
		list(6),
		label(title, { Font = HEADING_FONT, TextSize = 20, TextColor3 = titleColor or COLORS.ink, LayoutOrder = 1 }),
		label(body, { LayoutOrder = 2 }),
	})
end

local function clear(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Adds children to a frame in order, top to bottom.
local function fill(frame, children)
	for i, child in ipairs(children) do
		child.LayoutOrder = i
		child.Parent = frame
	end
end

local function colorText(text, color)
	return string.format('<font color="#%s">%s</font>', color:ToHex(), text)
end

-- Screen layout -----------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "MathQuestUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = localPlayer:WaitForChild("PlayerGui"),
})

local missionPanel = create("Frame", {
	Name = "Mission",
	Position = UDim2.new(0, 12, 0, 12),
	Size = UDim2.new(0, 300, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.05,
	Parent = gui,
}, { corner(14), padding(12), list(8) })

local teamPanel = create("Frame", {
	Name = "Team",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.new(0, 200, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.05,
	Parent = gui,
}, { corner(14), padding(12), list(4) })

local toastArea = create("Frame", {
	Name = "Messages",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.new(0.6, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}),
})

local modal = create("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.92, 0.8),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
	ZIndex = 10,
	Parent = gui,
}, {
	corner(18),
	create("UISizeConstraint", { MaxSize = Vector2.new(560, 640) }),
	create("UIStroke", { Thickness = 4, Color = COLORS.accent }),
})

local modalContent = create("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
	Parent = modal,
}, { padding(18), list(12) })

local function closeModal()
	modal.Visible = false
end

local function openModal(children)
	clear(modalContent)
	fill(modalContent, children)
	modalContent.CanvasPosition = Vector2.zero
	modal.Visible = true
end

-- Messages ----------------------------------------------------------------------

local toastCount = 0

local function showToast(message)
	toastCount += 1
	local toast = label(message, {
		LayoutOrder = toastCount,
		BackgroundTransparency = 0.15,
		BackgroundColor3 = COLORS.ink,
		TextColor3 = Color3.new(1, 1, 1),
		Font = HEADING_FONT,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	corner(10).Parent = toast
	padding(10).Parent = toast
	toast.Parent = toastArea

	-- Keep only the newest 4 messages.
	local toasts = {}
	for _, child in ipairs(toastArea:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #toasts - 4 do
		toasts[i]:Destroy()
	end

	task.delay(7, function()
		if toast.Parent then
			local fade = TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			toast:Destroy()
		end
	end)
end

ToastEvent.OnClientEvent:Connect(showToast)

-- Mission + team panels ---------------------------------------------------------

StateEvent.OnClientEvent:Connect(function(state)
	clear(missionPanel)
	clear(teamPanel)

	local me
	for _, info in ipairs(state.players) do
		if info.userId == localPlayer.UserId then
			me = info
		end
	end

	local lines = {}
	if state.finished then
		table.insert(lines, label("🏆 Treasure Room", { Font = HEADING_FONT, TextSize = 24 }))
		table.insert(lines, label("You finished the Math Quest TOGETHER! Every gate opened because you taught each other."))
	else
		table.insert(
			lines,
			label(string.format("Zone %d of %d: %s", state.zoneIndex, state.zoneCount, state.zoneName), {
				Font = HEADING_FONT,
				TextSize = 22,
			})
		)
		if not me then
			table.insert(lines, label("Getting your mission ready..."))
		else
			for _, learn in ipairs(me.learn) do
				local concept = Concepts.get(learn.id)
				if learn.read then
					table.insert(
						lines,
						label("✅ You're the expert on <b>" .. concept.name .. "</b>. Teach your friends! Show HOW, don't just tell answers.")
					)
				else
					table.insert(
						lines,
						label(
							"📘 Read the "
								.. colorText("<b>" .. concept.colorName .. "</b>", concept.color)
								.. " stone. You'll become the expert on <b>"
								.. concept.name
								.. "</b>."
						)
					)
				end
			end
			for _, solve in ipairs(me.solve) do
				local concept = Concepts.get(solve.id)
				if solve.solved then
					table.insert(lines, label("⭐ You mastered <b>" .. concept.name .. "</b>!"))
				else
					local who = #solve.experts > 0 and table.concat(solve.experts, ", ") or "read the stone yourself"
					table.insert(
						lines,
						label(
							"🧩 Learn <b>"
								.. concept.name
								.. "</b> from your expert ("
								.. who
								.. "), then solve problems at the yellow Challenge Gate."
						)
					)
				end
			end
			if me.done then
				table.insert(lines, label("🎈 Your part is done! Help your teammates.", { TextColor3 = COLORS.good }))
			end
			table.insert(lines, label("🚪 The gate opens when EVERYONE is done.", { TextColor3 = COLORS.soft, TextSize = 16 }))
		end
	end
	fill(missionPanel, lines)

	local teamLines = { label("Team", { Font = HEADING_FONT, TextSize = 20 }) }
	for _, info in ipairs(state.players) do
		local mark = (info.done or state.finished) and "✅ " or "⏳ "
		local you = info.userId == localPlayer.UserId and " (you)" or ""
		table.insert(teamLines, label(mark .. info.name .. you))
	end
	fill(teamPanel, teamLines)
end)

-- Lessons -----------------------------------------------------------------------

ShowLessonEvent.OnClientEvent:Connect(function(conceptId)
	local concept = Concepts.get(conceptId)
	if not concept then
		return
	end
	local children = {
		label("📘 " .. concept.name, { Font = HEADING_FONT, TextSize = 30, TextColor3 = concept.color }),
		label("Topic: " .. concept.topic .. ". You are now the EXPERT!", { TextColor3 = COLORS.soft, TextSize = 16 }),
	}
	for _, paragraph in ipairs(concept.lesson) do
		table.insert(children, label(paragraph))
	end
	table.insert(children, box("Example", concept.example))
	table.insert(children, box("How to teach it", "• " .. table.concat(concept.tips, "\n• "), COLORS.good))
	table.insert(
		children,
		row({
			button("Show on chalkboard", COLORS.button, function()
				ChalkboardEvent:FireServer(conceptId)
			end),
			button("Got it!", COLORS.good, closeModal),
		})
	)
	openModal(children)
end)

-- Problems ----------------------------------------------------------------------

local feedbackLabel

local function submit(answer)
	if answer ~= "" then
		SubmitAnswerEvent:FireServer(answer)
	end
end

ShowProblemEvent.OnClientEvent:Connect(function(problem)
	local children = {
		label("🧩 " .. problem.title, { Font = HEADING_FONT, TextSize = 30 }),
		label(problem.progress .. ". Topic: " .. problem.topic, { TextColor3 = COLORS.soft, TextSize = 16 }),
		label(problem.text, { Font = HEADING_FONT, TextSize = 24 }),
	}
	if problem.picture then
		table.insert(children, label(problem.picture, { TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center }))
	end

	if problem.choices then
		local buttons = {}
		for _, choice in ipairs(problem.choices) do
			table.insert(
				buttons,
				button(choice, COLORS.button, function()
					submit(choice)
				end)
			)
		end
		table.insert(children, row(buttons))
	else
		local input = create("TextBox", {
			Size = UDim2.new(0, 160, 0, 44),
			BackgroundColor3 = Color3.new(1, 1, 1),
			PlaceholderText = "Your answer",
			Text = "",
			ClearTextOnFocus = false,
			Font = HEADING_FONT,
			TextSize = 24,
			TextColor3 = COLORS.ink,
		}, { corner(10) })
		input.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				submit(input.Text)
			end
		end)
		table.insert(
			children,
			row({
				input,
				button("Check ✔", COLORS.good, function()
					submit(input.Text)
				end),
			})
		)
	end

	feedbackLabel = label(problem.feedback or "", { Font = HEADING_FONT, TextColor3 = COLORS.good })
	table.insert(children, feedbackLabel)

	local experts = problem.experts or {}
	local expertText = #experts > 0 and ("🧑‍🏫 Your expert: " .. table.concat(experts, ", "))
		or "🧑‍🏫 Nobody else knows this one. Read the lesson stone yourself!"
	table.insert(children, label(expertText, { TextColor3 = COLORS.soft }))
	table.insert(
		children,
		row({
			button("🙋 Ask for help", COLORS.accent, function()
				AskForHelpEvent:FireServer()
			end),
			button("Close", COLORS.soft, closeModal),
		})
	)
	openModal(children)
end)

AnswerResultEvent.OnClientEvent:Connect(function(result)
	if feedbackLabel and feedbackLabel.Parent then
		feedbackLabel.Text = result.message
		feedbackLabel.TextColor3 = result.correct and COLORS.good or COLORS.bad
	end
	if result.finished then
		task.delay(2, closeModal)
	end
end)

-- Celebration -------------------------------------------------------------------

CelebrateEvent.OnClientEvent:Connect(function(message)
	local banner = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.35),
		Size = UDim2.fromScale(0.8, 0.15),
		BackgroundTransparency = 1,
		Font = HEADING_FONT,
		TextScaled = true,
		TextColor3 = COLORS.accent,
		TextStrokeTransparency = 0,
		Text = message,
		ZIndex = 20,
		Parent = gui,
	})
	task.delay(2.5, function()
		local fade = TweenService:Create(banner, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		banner:Destroy()
	end)
end)
