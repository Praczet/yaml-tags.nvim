local M = {}
M._Config = {
	max_tags = 10,
}

-- Function to fetch tags from Markdown files in current directory
local function get_tags_from_files()
	local tags = {}
	local current_dir = vim.fn.getcwd()

	local handle = io.popen(
		"find "
			.. current_dir
			.. ' -name "*.md" -exec awk "/tags:/{y=1;next} y" {} \\; | grep -o "#\\w\\+" | sort | uniq'
	)

	if handle ~= nil then
		local result = handle:read("*a")
		handle:close()

		for tag in result:gmatch("#%w+") do
			table.insert(tags, tag)
		end
	end

	return tags
end

-- Completion function for YAML tags
function M.complete_tags(findstart, base)
	if findstart == 1 then
		-- Find the start of the current word
		local line = vim.api.nvim_get_current_line()
		local col = vim.api.nvim_win_get_cursor(0)[2] + 1
		while col > 1 and line:sub(col, col):match("%w") do
			col = col - 1
		end
		return col
	else
		-- Fetch tags from files in current directory
		local tags = get_tags_from_files()

		-- Filter tags based on base
		local matches = {}
		for _, tag in ipairs(tags) do
			if tag:match("^" .. base) then
				table.insert(matches, tag)
			end
		end

		return matches
	end
end

return setmetatable({}, {
	__index = function(_, k)
		if M[k] then
			return M[k]
		else
			error("Invalid method " .. k)
		end
	end,
})
