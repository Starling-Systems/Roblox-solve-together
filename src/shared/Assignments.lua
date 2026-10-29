--[[
	Assignments: decides which concept each player learns and which one they solve.

	Players are numbered by "slot" (1, 2, 3, ...). With concepts {A, B}:
	  slot 1 learns A, solves B
	  slot 2 learns B, solves A
	  slot 3 learns A, solves B   (and so on)
	Nobody solves the concept they learned, so somebody has to teach them.

	Playing alone? Then you learn everything and solve everything.
]]

local Assignments = {}

local function copy(list)
	local out = {}
	for i, value in ipairs(list) do
		out[i] = value
	end
	return out
end

function Assignments.forSlot(slot, concepts, solo)
	local count = #concepts
	if solo or count < 2 then
		return { learn = copy(concepts), solve = copy(concepts) }
	end
	return {
		learn = { concepts[((slot - 1) % count) + 1] },
		solve = { concepts[(slot % count) + 1] },
	}
end

return Assignments
