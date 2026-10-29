--[[
	Main server script: runs the game.

	How a zone works:
	  1. Every player is given a concept to LEARN (only they can read that lesson
	     stone) and a different concept to SOLVE.
	  2. Players teach each other, then solve problems at the Challenge Gate.
	  3. When EVERYONE has solved their problems, the gate opens and the whole
	     team moves on to the next zone together.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Concepts = require(Shared:WaitForChild("Concepts"))
local Assignments = require(Shared:WaitForChild("Assignments"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

-- Remote events: how the server and each player's screen talk to each other.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end
local StateEvent = makeRemote("State")
local ToastEvent = makeRemote("Toast")
local ShowLessonEvent = makeRemote("ShowLesson")
local ShowProblemEvent = makeRemote("ShowProblem")
local SubmitAnswerEvent = makeRemote("SubmitAnswer")
local AnswerResultEvent = makeRemote("AnswerResult")
local AskForHelpEvent = makeRemote("AskForHelp")
local ChalkboardEvent = makeRemote("ShowOnChalkboard")
local CelebrateEvent = makeRemote("Celebrate")
remotes.Parent = ReplicatedStorage

-- The default Baseplate would let players walk around the gates.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local world = WorldBuilder.build(Config, Concepts)
local rng = Random.new()

local state = {
	zoneIndex = 1,
	finished = false,
	opening = false,
	nextSlot = 0,
	-- players[player] = { slot, learn = {[id]=true}, read = {[id]=true}, solve = {ids},
	--                     solved = {[id]=true}, progress = {[id]=count}, problem, problemConcept,
	--                     wrong, lastHelp }
	players = {},
}

-- Helpers -------------------------------------------------------------------

local function toast(player, message)
	ToastEvent:FireClient(player, message)
end

local function toastAll(message)
	ToastEvent:FireAllClients(message)
end

local function expertPlayers(conceptId, exceptPlayer)
	local experts = {}
	for player, record in pairs(state.players) do
		if player ~= exceptPlayer and record.learn[conceptId] then
			table.insert(experts, player)
		end
	end
	return experts
end

local function expertNames(conceptId, exceptPlayer)
	local names = {}
	for _, player in ipairs(expertPlayers(conceptId, exceptPlayer)) do
		table.insert(names, player.DisplayName)
	end
	table.sort(names)
	return names
end

local function joinNames(names)
	if #names == 0 then
		return "nobody"
	elseif #names == 1 then
		return names[1]
	end
	return table.concat(names, ", ", 1, #names - 1) .. " or " .. names[#names]
end

local function isDone(record)
	for _, conceptId in ipairs(record.solve) do
		if not record.solved[conceptId] then
			return false
		end
	end
	return true
end

local function hasProgress()
	for _, record in pairs(state.players) do
		if next(record.read) or next(record.solved) or next(record.progress) or record.problem then
			return true
		end
	end
	return false
end

local function currentSpawn()
	local zone = world.zones[state.zoneIndex]
	if zone then
		return zone.spawnCFrame
	end
	return world.finale.spawnCFrame
end

-- Tell every player what's going on, so their screens can show missions.
local function broadcastState()
	local zoneConfig = Config.Zones[state.zoneIndex]
	local payload = {
		zoneIndex = state.zoneIndex,
		zoneCount = #Config.Zones,
		zoneName = zoneConfig and zoneConfig.name or "Treasure Room",
		finished = state.finished,
		players = {},
	}
	for player, record in pairs(state.players) do
		local learn = {}
		for conceptId in pairs(record.learn) do
			table.insert(learn, { id = conceptId, read = record.read[conceptId] == true })
		end
		table.sort(learn, function(a, b)
			return a.id < b.id
		end)
		local solve = {}
		for _, conceptId in ipairs(record.solve) do
			table.insert(solve, {
				id = conceptId,
				solved = record.solved[conceptId] == true,
				experts = expertNames(conceptId, player),
			})
		end
		table.insert(payload.players, {
			userId = player.UserId,
			name = player.DisplayName,
			slot = record.slot,
			learn = learn,
			solve = solve,
			done = isDone(record),
		})
	end
	table.sort(payload.players, function(a, b)
		return a.slot < b.slot
	end)
	StateEvent:FireAllClients(payload)
end

-- Zones -----------------------------------------------------------------------

local function assignPlayer(player, solo)
	local zoneConfig = Config.Zones[state.zoneIndex]
	if not zoneConfig then
		return
	end
	state.nextSlot += 1
	local plan = Assignments.forSlot(state.nextSlot, zoneConfig.concepts, solo)
	local record = {
		slot = state.nextSlot,
		learn = {},
		read = {},
		solve = plan.solve,
		solved = {},
		progress = {},
		wrong = 0,
		lastHelp = 0,
	}
	for _, conceptId in ipairs(plan.learn) do
		record.learn[conceptId] = true
	end
	state.players[player] = record
end

-- If nobody left in the game knows a concept someone still needs, let that
-- person read the lesson themselves so nobody gets stuck.
local function ensureExperts()
	for player, record in pairs(state.players) do
		for _, conceptId in ipairs(record.solve) do
			if not record.solved[conceptId] and not record.learn[conceptId] and #expertPlayers(conceptId, player) == 0 then
				record.learn[conceptId] = true
				local concept = Concepts.get(conceptId)
				toast(
					player,
					string.format(
						"Nobody here knows %s, so the %s stone is open for you now. Read it, then teach it to someone!",
						concept.name,
						concept.colorName
					)
				)
			end
		end
	end
end

local function startZone(index)
	state.zoneIndex = index
	state.nextSlot = 0
	state.players = {}

	if index > #Config.Zones then
		state.finished = true
		WorldBuilder.celebrateFinale(world)
		toastAll("🏆 You reached the treasure together! Amazing teamwork!")
		broadcastState()
		return
	end

	local everyone = Players:GetPlayers()
	local solo = #everyone == 1
	for _, player in ipairs(everyone) do
		assignPlayer(player, solo)
	end
	ensureExperts()
	broadcastState()
	if #everyone > 0 then
		toastAll("📍 Welcome to " .. Config.Zones[index].name .. "! Find the lesson stone in your color.")
	end
end

local function checkZoneComplete()
	if state.finished or state.opening then
		return
	end
	local count = 0
	for _, record in pairs(state.players) do
		count += 1
		if not isDone(record) then
			return
		end
	end
	if count == 0 then
		return
	end

	state.opening = true
	WorldBuilder.openGate(world.zones[state.zoneIndex])
	CelebrateEvent:FireAllClients("🎉 GATE OPEN! 🎉")
	toastAll("Everyone solved their problems! Cross the bridge TOGETHER.")
	task.delay(Config.SecondsBeforeNextZone, function()
		state.opening = false
		startZone(state.zoneIndex + 1)
	end)
end

-- Lesson stones ---------------------------------------------------------------

local function onStone(player, conceptId)
	local record = state.players[player]
	local concept = Concepts.get(conceptId)
	if not record then
		return
	end
	if record.learn[conceptId] then
		record.read[conceptId] = true
		ShowLessonEvent:FireClient(player, conceptId)
		broadcastState()
	else
		toast(
			player,
			string.format(
				"The %s stone's lesson is for %s. Ask them to teach you %s!",
				concept.colorName,
				joinNames(expertNames(conceptId, player)),
				concept.name
			)
		)
	end
end

-- Problems --------------------------------------------------------------------

local function sendProblem(player, record, feedback)
	local conceptId = record.problemConcept
	local concept = Concepts.get(conceptId)
	local problem = record.problem
	ShowProblemEvent:FireClient(player, {
		conceptId = conceptId,
		title = concept.name,
		topic = concept.topic,
		text = problem.text,
		picture = problem.picture,
		choices = problem.choices,
		progress = string.format("Problem %d of %d", (record.progress[conceptId] or 0) + 1, Config.ProblemsPerConcept),
		experts = expertNames(conceptId, player),
		feedback = feedback,
	})
end

local function onTerminal(player)
	local record = state.players[player]
	if not record then
		return
	end
	local conceptId
	for _, id in ipairs(record.solve) do
		if not record.solved[id] then
			conceptId = id
			break
		end
	end
	if not conceptId then
		toast(player, "✅ You've done your part! Now help your teammates finish theirs.")
		return
	end
	if record.problemConcept ~= conceptId or not record.problem then
		record.problemConcept = conceptId
		record.problem = Concepts.get(conceptId).generate(rng)
		record.wrong = 0
	end
	sendProblem(player, record)
end

SubmitAnswerEvent.OnServerEvent:Connect(function(player, answer)
	local record = state.players[player]
	if not record or not record.problem or type(answer) ~= "string" or #answer > 20 then
		return
	end
	local conceptId = record.problemConcept
	local concept = Concepts.get(conceptId)

	if not Concepts.check(record.problem, answer) then
		record.wrong += 1
		local message = "Not quite. Try again!"
		if record.wrong >= Config.WrongAnswersBeforeHint then
			local experts = expertNames(conceptId, player)
			if #experts > 0 then
				message = "Not quite. Ask " .. joinNames(experts) .. " to show you HOW to solve it!"
			else
				message = "Not quite. Read the lesson stone again and try once more!"
			end
		end
		AnswerResultEvent:FireClient(player, { correct = false, message = message })
		return
	end

	record.wrong = 0
	record.progress[conceptId] = (record.progress[conceptId] or 0) + 1
	if record.progress[conceptId] < Config.ProblemsPerConcept then
		record.problem = concept.generate(rng)
		sendProblem(player, record, "✅ Correct! Here's another one.")
		return
	end

	record.solved[conceptId] = true
	record.problem = nil
	record.problemConcept = nil
	AnswerResultEvent:FireClient(player, { correct = true, finished = true, message = "⭐ You mastered " .. concept.name .. "!" })
	local teachers = expertNames(conceptId, player)
	if #teachers > 0 then
		toastAll(string.format("⭐ %s mastered %s! Great teaching, %s!", player.DisplayName, concept.name, table.concat(teachers, " and ")))
	else
		toastAll(string.format("⭐ %s mastered %s!", player.DisplayName, concept.name))
	end
	broadcastState()
	checkZoneComplete()
end)

AskForHelpEvent.OnServerEvent:Connect(function(player)
	local record = state.players[player]
	if not record or not record.problemConcept then
		return
	end
	local now = os.clock()
	if now - record.lastHelp < 5 then
		return
	end
	record.lastHelp = now

	local concept = Concepts.get(record.problemConcept)
	local experts = expertPlayers(record.problemConcept, player)
	for _, expert in ipairs(experts) do
		toast(
			expert,
			string.format(
				"🙋 %s needs help with %s. You're the expert! Show them HOW (don't just tell the answer).",
				player.DisplayName,
				concept.name
			)
		)
	end
	if #experts > 0 then
		toast(player, "📣 Asked " .. joinNames(expertNames(record.problemConcept, player)) .. " for help!")
	else
		toast(player, "Nobody else knows this one yet. Read the " .. concept.colorName .. " stone yourself!")
	end
end)

ChalkboardEvent.OnServerEvent:Connect(function(player, conceptId)
	local record = state.players[player]
	if type(conceptId) ~= "string" or not record or not record.learn[conceptId] then
		return
	end
	local concept = Concepts.get(conceptId)
	local zone = world.zones[state.zoneIndex]
	if not concept or not zone then
		return
	end
	WorldBuilder.writeChalkboard(
		zone,
		string.format("%s\n\n%s\n\n(shared by %s)", concept.name, concept.example, player.DisplayName)
	)
	toastAll(player.DisplayName .. " put a " .. concept.name .. " example on the chalkboard!")
end)

-- Hook up the stones and terminals in every zone.
for index, zone in ipairs(world.zones) do
	for conceptId, stone in pairs(zone.stones) do
		stone.prompt.Triggered:Connect(function(player)
			if index == state.zoneIndex and not state.opening then
				onStone(player, conceptId)
			end
		end)
	end
	zone.terminalPrompt.Triggered:Connect(function(player)
		if index == state.zoneIndex and not state.opening then
			onTerminal(player)
		end
	end)
end

-- Players ---------------------------------------------------------------------

local function onCharacterAdded(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		task.wait()
		character:PivotTo(currentSpawn())
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	if state.finished or state.players[player] then
		broadcastState()
		return
	end
	if hasProgress() then
		-- The zone is already going: join in with a new slot.
		assignPlayer(player, false)
		ensureExperts()
		broadcastState()
	else
		-- Nobody has started yet, so hand out the jobs again for the whole team.
		startZone(state.zoneIndex)
	end
end

startZone(1)
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	state.players[player] = nil
	ensureExperts()
	broadcastState()
	checkZoneComplete()
end)

-- Fell off the world? Pop back to the start of the current zone.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < Config.FallResetHeight then
				character:PivotTo(currentSpawn())
				root.AssemblyLinearVelocity = Vector3.zero
				toast(player, "Whoops! Back to the start of this zone.")
			end
		end
	end
end)

