--[[
	WorldBuilder: builds every zone out of parts, so you don't have to place
	anything by hand in Studio.

	Each zone (left to right along the X axis) has:
	  * a floor with low rails
	  * a sign and a big chalkboard on the back wall
	  * one glowing lesson stone per concept
	  * a yellow Challenge Gate terminal
	  * a force-field gate, then a bridge to the next zone
	At the end there's a treasure room.
]]

local TweenService = game:GetService("TweenService")

local WorldBuilder = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local INK = Color3.fromRGB(40, 40, 50)
local RAIL_COLOR = Color3.fromRGB(120, 85, 55)
local BRIDGE_WIDTH = 14

local function makePart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local parent = props.Parent
	props.Parent = nil
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = parent
	return part
end

local function addSurfaceText(part, face, text, textColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.PaddingLeft = UDim.new(0, 30)
	padding.PaddingRight = UDim.new(0, 30)
	padding.Parent = label

	return label
end

local function addBillboard(part, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(240, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = billboard
end

local function addPrompt(part, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function addConfetti(part)
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 3, 0)
	attachment.Parent = part

	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = 40
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Speed = NumberRange.new(20, 35)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Acceleration = Vector3.new(0, -25, 0)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-200, 200)
	emitter.Size = NumberSequence.new(0.6)
	emitter.LightEmission = 0.5
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 220, 120)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 255)),
	})
	emitter.Parent = attachment
	return emitter
end

-- Low rails around a platform. The +X side is always open (gate or exit);
-- the -X side gets a gap when a bridge comes in.
local function addRails(parent, centerX, size, hasEntrance)
	local half = size / 2
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "Rail",
			Size = Vector3.new(size, 3, 1),
			Position = Vector3.new(centerX, 1.5, side * (half - 0.5)),
			Color = RAIL_COLOR,
			Material = Enum.Material.Wood,
			Parent = parent,
		})
	end
	local backX = centerX - half + 0.5
	if hasEntrance then
		local pieceLength = (size - BRIDGE_WIDTH) / 2
		for _, side in ipairs({ -1, 1 }) do
			makePart({
				Name = "Rail",
				Size = Vector3.new(1, 3, pieceLength),
				Position = Vector3.new(backX, 1.5, side * (BRIDGE_WIDTH / 2 + pieceLength / 2)),
				Color = RAIL_COLOR,
				Material = Enum.Material.Wood,
				Parent = parent,
			})
		end
	else
		makePart({
			Name = "Rail",
			Size = Vector3.new(1, 3, size),
			Position = Vector3.new(backX, 1.5, 0),
			Color = RAIL_COLOR,
			Material = Enum.Material.Wood,
			Parent = parent,
		})
	end
end

local function addBridge(parent, startX, length)
	local centerX = startX + length / 2
	makePart({
		Name = "Bridge",
		Size = Vector3.new(length, 2, BRIDGE_WIDTH),
		Position = Vector3.new(centerX, -1, 0),
		Color = Color3.fromRGB(160, 110, 70),
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "BridgeRail",
			Size = Vector3.new(length, 3, 1),
			Position = Vector3.new(centerX, 1.5, side * (BRIDGE_WIDTH / 2 + 0.5)),
			Color = RAIL_COLOR,
			Material = Enum.Material.Wood,
			Parent = parent,
		})
	end
end

local function spawnCFrameFor(centerX, size)
	local position = Vector3.new(centerX - size / 2 + 8, 4, 0)
	return CFrame.lookAt(position, position + Vector3.new(1, 0, 0))
end

function WorldBuilder.build(Config, Concepts)
	local folder = Instance.new("Folder")
	folder.Name = "MathQuestWorld"
	folder.Parent = workspace

	local size = Config.ZoneSize
	local spacing = Config.ZoneSpacing
	local half = size / 2
	local world = { zones = {} }

	for index, zoneConfig in ipairs(Config.Zones) do
		local centerX = (index - 1) * spacing
		local model = Instance.new("Model")
		model.Name = string.format("Zone%d_%s", index, zoneConfig.name)
		model.Parent = folder

		local zone = { index = index, stones = {} }

		makePart({
			Name = "Floor",
			Size = Vector3.new(size, 2, size),
			Position = Vector3.new(centerX, -1, 0),
			Color = zoneConfig.color,
			Material = Enum.Material.Grass,
			Parent = model,
		})
		addRails(model, centerX, size, index > 1)

		if index == 1 then
			local spawn = Instance.new("SpawnLocation")
			spawn.Anchored = true
			spawn.Neutral = true
			spawn.Duration = 0
			spawn.Size = Vector3.new(6, 1, 6)
			spawn.Position = Vector3.new(centerX - half + 8, 0.5, 0)
			spawn.Color = WHITE
			spawn.Parent = model
		end

		-- Sign and chalkboard on the back wall.
		local sign = makePart({
			Name = "Sign",
			Size = Vector3.new(36, 6, 1),
			Position = Vector3.new(centerX, 20, -half + 2),
			Color = WHITE,
			Parent = model,
		})
		addSurfaceText(sign, Enum.NormalId.Back, string.format("Zone %d: %s", index, zoneConfig.name), INK)

		local board = makePart({
			Name = "Chalkboard",
			Size = Vector3.new(36, 14, 1),
			Position = Vector3.new(centerX, 9, -half + 2),
			Color = Color3.fromRGB(35, 70, 50),
			Material = Enum.Material.Slate,
			Parent = model,
		})
		zone.chalkboardLabel = addSurfaceText(
			board,
			Enum.NormalId.Back,
			"CHALKBOARD\n\nExperts: open your lesson and press\n\"Show on chalkboard\" to teach with it!",
			Color3.fromRGB(240, 240, 230)
		)

		-- Lesson stones along the front.
		local stoneCount = #zoneConfig.concepts
		for k, conceptId in ipairs(zoneConfig.concepts) do
			local concept = Concepts.get(conceptId)
			assert(concept, "Config.lua mentions an unknown concept: " .. tostring(conceptId))
			local x = centerX - (stoneCount - 1) * 6 + (k - 1) * 12
			local z = half - 12
			makePart({
				Name = "Pedestal",
				Size = Vector3.new(5, 3, 5),
				Position = Vector3.new(x, 1.5, z),
				Color = Color3.fromRGB(150, 150, 160),
				Material = Enum.Material.Cobblestone,
				Parent = model,
			})
			local stone = makePart({
				Name = conceptId .. "Stone",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(4, 4, 4),
				Position = Vector3.new(x, 5, z),
				Color = concept.color,
				Material = Enum.Material.Neon,
				Parent = model,
			})
			addBillboard(stone, "📘 " .. concept.name, concept.color)
			zone.stones[conceptId] = { part = stone, prompt = addPrompt(stone, "Read lesson", concept.name) }
		end

		-- Challenge terminal in front of the gate.
		local terminal = makePart({
			Name = "ChallengeTerminal",
			Size = Vector3.new(4, 5, 4),
			Position = Vector3.new(centerX + half - 10, 2.5, 0),
			Color = Color3.fromRGB(255, 200, 60),
			Material = Enum.Material.Neon,
			Parent = model,
		})
		addBillboard(terminal, "🧩 Challenge Gate", Color3.fromRGB(255, 220, 90))
		zone.terminalPrompt = addPrompt(terminal, "Solve a problem", "Challenge Gate")
		zone.confetti = addConfetti(terminal)

		-- The gate covers the whole +X edge, so nobody can sneak past.
		zone.gate = makePart({
			Name = "Gate",
			Size = Vector3.new(2, 20, size),
			Position = Vector3.new(centerX + half - 1, 10, 0),
			Color = zoneConfig.color,
			Material = Enum.Material.ForceField,
			Parent = model,
		})
		zone.gateLabel = addSurfaceText(
			zone.gate,
			Enum.NormalId.Left,
			"🔒 This gate opens when EVERYONE has solved their problems!",
			WHITE
		)

		addBridge(model, centerX + half, spacing - size)
		zone.spawnCFrame = spawnCFrameFor(centerX, size)
		world.zones[index] = zone
	end

	-- Treasure room at the end.
	local centerX = #Config.Zones * spacing
	local finaleModel = Instance.new("Model")
	finaleModel.Name = "TreasureRoom"
	finaleModel.Parent = folder

	makePart({
		Name = "Floor",
		Size = Vector3.new(size, 2, size),
		Position = Vector3.new(centerX, -1, 0),
		Color = Color3.fromRGB(250, 215, 90),
		Material = Enum.Material.Marble,
		Parent = finaleModel,
	})
	addRails(finaleModel, centerX, size, true)
	makePart({
		Name = "Rail",
		Size = Vector3.new(1, 3, size),
		Position = Vector3.new(centerX + half - 0.5, 1.5, 0),
		Color = RAIL_COLOR,
		Material = Enum.Material.Wood,
		Parent = finaleModel,
	})

	local sign = makePart({
		Name = "Sign",
		Size = Vector3.new(40, 10, 1),
		Position = Vector3.new(centerX, 12, -half + 2),
		Color = WHITE,
		Parent = finaleModel,
	})
	addSurfaceText(sign, Enum.NormalId.Back, "🏆 TREASURE! You did it TOGETHER! 🏆", INK)

	local chest = makePart({
		Name = "Chest",
		Size = Vector3.new(6, 4, 4),
		Position = Vector3.new(centerX + 10, 2, 0),
		Color = Color3.fromRGB(130, 80, 40),
		Material = Enum.Material.WoodPlanks,
		Parent = finaleModel,
	})
	makePart({
		Name = "ChestLid",
		Size = Vector3.new(6, 1.5, 4),
		Position = Vector3.new(centerX + 10, 4.75, 0),
		Color = Color3.fromRGB(255, 205, 50),
		Material = Enum.Material.Neon,
		Parent = finaleModel,
	})

	world.finale = {
		spawnCFrame = spawnCFrameFor(centerX, size),
		confetti = addConfetti(chest),
	}

	return world
end

function WorldBuilder.openGate(zone)
	zone.gate.CanCollide = false
	zone.gateLabel.Parent.Enabled = false
	TweenService:Create(zone.gate, TweenInfo.new(1.5), { Transparency = 1 }):Play()
	zone.confetti:Emit(150)
end

function WorldBuilder.writeChalkboard(zone, text)
	zone.chalkboardLabel.Text = text
end

function WorldBuilder.celebrateFinale(world)
	world.finale.confetti.Enabled = true
end

return WorldBuilder
