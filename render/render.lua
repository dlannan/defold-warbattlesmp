local M  = {}

-- all users of the module will share this table
local state = {}

function M.set_win(width, height)
	-- self is added as first argument when using : notation
	state.width = width
	state.height = height
end

function M.get_win()
	return state.width, state.height
end

return M