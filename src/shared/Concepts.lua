--[[
	Concepts: every math idea in the game lives here.

	Each concept has:
	  name, topic       what players see
	  color, colorName  the color of its lesson stone
	  lesson            what the EXPERT reads (short paragraphs)
	  example           a worked example the expert can put on the chalkboard
	  tips              ideas for HOW to teach it
	  generate(rng)     makes a new practice problem

	A problem is one of these:
	  { text = "...", answer = 12 }                                -- type a number
	  { text = "...", choices = { "1/3", "1/5" }, answer = "1/3" }  -- tap a button
	It can also have a `picture` (a line of emoji) to help.

	Want to add your own concept? Copy one below, give it a new id, then add
	that id to a zone in Config.lua.
]]

local Concepts = {}
Concepts.all = {}

-- Helpers ------------------------------------------------------------------

local function commas(n)
	local reversed = string.reverse(tostring(n))
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1,")
	local result = string.reverse(grouped)
	if string.sub(result, 1, 1) == "," then
		result = string.sub(result, 2)
	end
	return result
end

local function shuffle(list, rng)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function addUnique(list, value)
	for _, existing in ipairs(list) do
		if existing == value then
			return
		end
	end
	table.insert(list, value)
end

local function pickFrom(list, rng)
	return list[rng:NextInteger(1, #list)]
end

local function grid(emoji, width, height)
	local rows = {}
	for _ = 1, height do
		table.insert(rows, string.rep(emoji, width))
	end
	return table.concat(rows, "\n")
end

local function define(id, concept)
	concept.id = id
	Concepts.all[id] = concept
end

function Concepts.get(id)
	return Concepts.all[id]
end

-- Checks a player's answer (always sent as text) against a problem.
function Concepts.check(problem, input)
	if type(input) ~= "string" then
		return false
	end
	if problem.choices then
		return input == problem.answer
	end
	local cleaned = string.gsub(input, "[%s,]", "")
	return tonumber(cleaned) == problem.answer
end

-- Multiplication --------------------------------------------------------------

local GROUP_THINGS = {
	{ container = "basket", containers = "baskets", items = "apples", emoji = "🍎" },
	{ container = "pond", containers = "ponds", items = "fish", emoji = "🐟" },
	{ container = "tree", containers = "trees", items = "birds", emoji = "🐦" },
	{ container = "box", containers = "boxes", items = "stars", emoji = "⭐" },
}

define("EqualGroups", {
	name = "Equal Groups",
	topic = "Multiplication",
	color = Color3.fromRGB(235, 87, 87),
	colorName = "RED",
	lesson = {
		"Multiplication is a FAST way to count things that come in EQUAL GROUPS.",
		"Ask two questions: How many GROUPS are there? How many are in EACH group?",
		"Then multiply: groups × how many in each. 4 groups of 3 is 4 × 3.",
		"Can't remember the fact? Skip count! For 4 groups of 3, count by 3s four times: 3, 6, 9, 12.",
	},
	example = "3 bags with 5 marbles in each\n\n(●●●●●)  (●●●●●)  (●●●●●)\n\n3 groups × 5 in each = 15 marbles\nSkip count: 5, 10, 15",
	tips = {
		"Draw circles for the groups, then dots inside each circle.",
		"Ask your friend: How many groups? How many in each?",
		"Skip count out loud together.",
	},
	generate = function(rng)
		local groups = rng:NextInteger(2, 6)
		local each = rng:NextInteger(2, 6)
		local thing = pickFrom(GROUP_THINGS, rng)
		local picture = {}
		for _ = 1, groups do
			table.insert(picture, string.rep(thing.emoji, each))
		end
		return {
			text = string.format(
				"There are %d %s. Each %s has %d %s.\nHow many %s are there in all?",
				groups,
				thing.containers,
				thing.container,
				each,
				thing.items,
				thing.items
			),
			picture = table.concat(picture, "   "),
			answer = groups * each,
		}
	end,
})

-- Division --------------------------------------------------------------------

local SHARE_THINGS = {
	{ items = "cookies", emoji = "🍪" },
	{ items = "stickers", emoji = "⭐" },
	{ items = "strawberries", emoji = "🍓" },
	{ items = "marbles", emoji = "🔵" },
}

define("FairSharing", {
	name = "Fair Sharing",
	topic = "Division",
	color = Color3.fromRGB(66, 135, 245),
	colorName = "BLUE",
	lesson = {
		"Division means SHARING FAIRLY: everyone gets the same amount.",
		"Ask: How many things are there in TOTAL? How many friends are SHARING?",
		"Deal them out one at a time, like cards: one for you, one for you, one for you... until they're all gone. Then count one pile.",
		"Shortcut: division is multiplication backwards. 12 shared by 3? Think 3 × ? = 12. The answer is 4!",
	},
	example = "12 cookies shared by 3 friends\n\nFriend A: ●●●●\nFriend B: ●●●●\nFriend C: ●●●●\n\n12 ÷ 3 = 4 each  (because 3 × 4 = 12)",
	tips = {
		"Use real things (coins, LEGO, snacks) and deal them out together.",
		"Ask: \"What times 3 makes 12?\"",
		"Check: does everyone have the same amount?",
	},
	generate = function(rng)
		local friends = rng:NextInteger(2, 5)
		local each = rng:NextInteger(2, 6)
		local thing = pickFrom(SHARE_THINGS, rng)
		local total = friends * each
		return {
			text = string.format(
				"%d %s are shared fairly by %d friends.\nHow many %s does each friend get?",
				total,
				thing.items,
				friends,
				thing.items
			),
			picture = string.rep(thing.emoji, total),
			answer = each,
		}
	end,
})

-- Fractions: parts of a whole ---------------------------------------------------

local WHOLES = {
	{ whole = "pizza", pieces = "slices", action = "eaten" },
	{ whole = "chocolate bar", pieces = "pieces", action = "eaten" },
	{ whole = "garden", pieces = "beds", action = "planted with flowers" },
	{ whole = "flag", pieces = "stripes", action = "colored red" },
}

define("FractionParts", {
	name = "Parts of a Whole",
	topic = "Fractions",
	color = Color3.fromRGB(255, 150, 30),
	colorName = "ORANGE",
	lesson = {
		"A fraction tells about PART of a whole that's cut into EQUAL pieces.",
		"The BOTTOM number (the denominator) = how many equal pieces the whole is cut into.",
		"The TOP number (the numerator) = how many of those pieces we're talking about.",
		"A pizza cut into 8 slices with 3 eaten: 3 out of 8 were eaten. We write 3/8.",
	},
	example = "A bar cut into 4 equal pieces, 3 are colored:\n\n[■] [■] [■] [□]\n\n3 colored pieces → TOP\n4 pieces in all → BOTTOM\n= 3/4",
	tips = {
		"Draw a shape, cut it into equal pieces, and color some in.",
		"Remember: bottom = pieces in ALL, top = pieces we CARE about.",
		"Count the pieces together, out loud.",
	},
	generate = function(rng)
		local denominator = pickFrom({ 2, 3, 4, 5, 6, 8 }, rng)
		local numerator = rng:NextInteger(1, denominator - 1)
		local thing = pickFrom(WHOLES, rng)
		local answer = numerator .. "/" .. denominator
		local choices = { answer }
		addUnique(choices, denominator .. "/" .. numerator)
		addUnique(choices, (denominator - numerator) .. "/" .. denominator)
		addUnique(choices, numerator .. "/" .. (denominator - numerator))
		return {
			text = string.format(
				"A %s is cut into %d equal %s. %d of them are %s.\nWhat fraction of the %s is %s?",
				thing.whole,
				denominator,
				thing.pieces,
				numerator,
				thing.action,
				thing.whole,
				thing.action
			),
			picture = string.rep("🟧", numerator) .. string.rep("⬜", denominator - numerator),
			choices = shuffle(choices, rng),
			answer = answer,
		}
	end,
})

-- Fractions: comparing ----------------------------------------------------------

define("FractionCompare", {
	name = "Comparing Fractions",
	topic = "Fractions",
	color = Color3.fromRGB(160, 90, 230),
	colorName = "PURPLE",
	lesson = {
		"To find the BIGGER fraction, think about the pieces.",
		"SAME BOTTOM number? The pieces are the same size, so MORE pieces is bigger: 3/5 is bigger than 2/5.",
		"SAME TOP number? Look at the bottoms. A SMALLER bottom number means BIGGER pieces. 1/3 of a pizza is bigger than 1/8, because cutting a pizza into 8 makes tiny slices!",
		"Not sure? Draw both fractions on bars that are the same length and compare.",
	},
	example = "Which is bigger: 1/2 or 1/4?\n\n1/2:  [■■■■■■][□□□□□□]\n1/4:  [■■■][□□□][□□□][□□□]\n\nSame top (1). Fewer pieces = bigger pieces.\n1/2 is bigger!",
	tips = {
		"Ask: \"Is the TOP the same, or the BOTTOM?\"",
		"Draw two bars the same length and cut them up.",
		"Would you rather have 1/2 of a cake or 1/10 of a cake? Why?",
	},
	generate = function(rng)
		local first, second, bigger, picture
		if rng:NextInteger(1, 2) == 1 then
			-- Same denominator: more pieces is bigger.
			local denominator = pickFrom({ 4, 5, 6, 8, 10 }, rng)
			local a = rng:NextInteger(1, denominator - 1)
			local b = a
			while b == a do
				b = rng:NextInteger(1, denominator - 1)
			end
			first = a .. "/" .. denominator
			second = b .. "/" .. denominator
			bigger = (a > b) and first or second
			picture = string.rep("🟦", a)
				.. string.rep("⬜", denominator - a)
				.. "\n"
				.. string.rep("🟦", b)
				.. string.rep("⬜", denominator - b)
		else
			-- Same numerator: smaller denominator means bigger pieces.
			local numerator = rng:NextInteger(1, 3)
			local d1 = rng:NextInteger(numerator + 1, 10)
			local d2 = d1
			while d2 == d1 do
				d2 = rng:NextInteger(numerator + 1, 10)
			end
			first = numerator .. "/" .. d1
			second = numerator .. "/" .. d2
			bigger = (d1 < d2) and first or second
		end
		return {
			text = string.format("Which fraction is BIGGER?\n\n%s   or   %s", first, second),
			picture = picture,
			choices = shuffle({ first, second }, rng),
			answer = bigger,
		}
	end,
})

-- Area ------------------------------------------------------------------------

define("Area", {
	name = "Area",
	topic = "Measurement",
	color = Color3.fromRGB(60, 200, 110),
	colorName = "GREEN",
	lesson = {
		"AREA is how much space covers the INSIDE of a flat shape.",
		"We measure area by counting the squares that cover it, like tiles on a floor.",
		"For a rectangle you don't have to count every square. Multiply: number of rows × squares in each row.",
		"A garden 5 squares long and 3 squares wide has 3 rows of 5: 3 × 5 = 15 squares.",
	},
	example = "4 long, 3 wide\n\n■■■■\n■■■■\n■■■■\n\n3 rows × 4 in each row = 12 square units",
	tips = {
		"Area is the INSIDE (like a carpet).",
		"Draw the grid, count one row, then count the rows.",
		"It's just equal groups! Each row is a group.",
	},
	generate = function(rng)
		local long = rng:NextInteger(2, 7)
		local wide = rng:NextInteger(2, 6)
		return {
			text = string.format(
				"A garden is %d squares long and %d squares wide.\nHow many square tiles cover the whole garden?",
				long,
				wide
			),
			picture = grid("🟩", long, wide),
			answer = long * wide,
		}
	end,
})

-- Perimeter -------------------------------------------------------------------

define("Perimeter", {
	name = "Perimeter",
	topic = "Measurement",
	color = Color3.fromRGB(240, 200, 40),
	colorName = "YELLOW",
	lesson = {
		"PERIMETER is the distance all the way AROUND the outside of a shape.",
		"Imagine an ant walking around the edge of a garden. Count every step on every side.",
		"A rectangle has 4 sides: 2 long sides and 2 short sides. Add all 4: long + short + long + short.",
		"A garden 5 long and 3 wide: 5 + 3 + 5 + 3 = 16 fence pieces.",
	},
	example = "6 long, 2 wide\n\n+------+\n|      |  2\n+------+\n    6\n\n6 + 2 + 6 + 2 = 16 units around",
	tips = {
		"Perimeter is the OUTSIDE (like a fence). Area is the INSIDE.",
		"Trace the edge with your finger while you count.",
		"Opposite sides are the same length, even when the number isn't written there!",
	},
	generate = function(rng)
		local long = rng:NextInteger(2, 8)
		local wide = rng:NextInteger(2, 6)
		return {
			text = string.format(
				"A garden is %d squares long and %d squares wide.\nHow many fence pieces go all the way AROUND it?",
				long,
				wide
			),
			picture = grid("🟫", long, wide),
			answer = 2 * (long + wide),
		}
	end,
})

-- Place value -------------------------------------------------------------------

local PLACE_VALUES = { 1000, 100, 10, 1 }

define("PlaceValue", {
	name = "Place Value",
	topic = "Numbers",
	color = Color3.fromRGB(40, 200, 220),
	colorName = "AQUA",
	lesson = {
		"In a number, each digit's VALUE depends on WHERE it sits.",
		"From right to left the places are: ones, tens, hundreds, thousands.",
		"Each place is worth 10 times the place to its right.",
		"In 3,482: the 3 means 3,000. The 4 means 400. The 8 means 80. The 2 means 2.",
	},
	example = "3,482\n\nthousands  hundreds  tens  ones\n    3          4        8      2\n\n3,482 = 3,000 + 400 + 80 + 2\nThe VALUE of the 4 is 400",
	tips = {
		"Write the number in a place-value chart with columns.",
		"Point to the digit and say its place out loud.",
		"Then add zeros: hundreds place means 2 zeros.",
	},
	generate = function(rng)
		while true do
			local number = rng:NextInteger(1000, 9999)
			local digits = tostring(number)
			local position = rng:NextInteger(1, 4)
			local digit = string.sub(digits, position, position)
			local _, count = string.gsub(digits, digit, "")
			-- Pick a digit that isn't 0 and only shows up once, so the question is clear.
			if digit ~= "0" and count == 1 then
				return {
					text = string.format(
						"Look at the number %s.\nWhat is the VALUE of the digit %s?",
						commas(number),
						digit
					),
					answer = tonumber(digit) * PLACE_VALUES[position],
				}
			end
		end
	end,
})

-- Rounding --------------------------------------------------------------------

define("Rounding", {
	name = "Rounding",
	topic = "Numbers",
	color = Color3.fromRGB(240, 110, 200),
	colorName = "PINK",
	lesson = {
		"ROUNDING means finding the nearest \"friendly\" number, like the nearest ten or hundred.",
		"To round to the nearest TEN, look at the ONES digit.",
		"0, 1, 2, 3, 4: round DOWN (stay at this ten). 5, 6, 7, 8, 9: round UP to the next ten.",
		"47: the ones digit is 7, so round up to 50. 43: the ones digit is 3, so round down to 40.",
		"For the nearest HUNDRED, look at the TENS digit and use the same rule.",
	},
	example = "Round 47 to the nearest ten\n\n40 . . . . . . . 47 . . 50\n\nOnes digit is 7 (5 or more) → round UP\n47 rounds to 50",
	tips = {
		"Draw a number line between the two tens.",
		"Ask: which ten is it closer to?",
		"Rhyme: \"Five or more, raise the score. Four or less, let it rest.\"",
	},
	generate = function(rng)
		if rng:NextInteger(1, 2) == 1 then
			local number = rng:NextInteger(11, 99)
			if number % 10 == 0 then
				number += 3
			end
			return {
				text = string.format("Round %d to the nearest TEN.", number),
				answer = math.floor((number + 5) / 10) * 10,
			}
		end
		local number = rng:NextInteger(101, 999)
		if number % 100 == 0 then
			number += 30
		end
		return {
			text = string.format("Round %d to the nearest HUNDRED.", number),
			answer = math.floor((number + 50) / 100) * 100,
		}
	end,
})

return Concepts
