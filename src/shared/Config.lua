--[[
	Config: the easiest place to change the game!

	Try changing:
	  * the zone names and colors
	  * which math concepts each zone uses (see Concepts.lua for the list)
	  * how many problems you need to get right
]]

local Config = {}

Config.GameTitle = "Teach Together: Math Quest"

-- The world is a path of zones. Each zone has lesson stones for its concepts.
-- Every player becomes the EXPERT on one concept, and has to solve problems
-- about a DIFFERENT concept, so the team has to teach each other.
-- Put at least 2 concepts in each zone.
Config.Zones = {
	{
		name = "Grouping Grove",
		color = Color3.fromRGB(110, 190, 90),
		concepts = { "EqualGroups", "FairSharing" },
	},
	{
		name = "Fraction Falls",
		color = Color3.fromRGB(90, 170, 230),
		concepts = { "FractionParts", "FractionCompare" },
	},
	{
		name = "Garden of Shapes",
		color = Color3.fromRGB(230, 170, 90),
		concepts = { "Area", "Perimeter" },
	},
	{
		name = "Place Value Peaks",
		color = Color3.fromRGB(180, 140, 220),
		concepts = { "PlaceValue", "Rounding" },
	},
}

-- How many problems in a row you must get right to master a concept.
Config.ProblemsPerConcept = 2

-- After this many wrong answers, the game suggests asking your expert.
Config.WrongAnswersBeforeHint = 2

-- Seconds between a gate opening and the next zone's lessons starting.
Config.SecondsBeforeNextZone = 4

-- World layout (in studs). You probably don't need to change these.
Config.ZoneSize = 64
Config.ZoneSpacing = 120
Config.FallResetHeight = -30

return Config
