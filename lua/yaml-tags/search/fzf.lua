local fzf = require("fzf-lua")

local function files_with_tag(opts)
	local dir = opts.dir
	local tag = opts.tag
	local results = opts.results

	if not dir or not results or #results == 0 then
		vim.notify("No files found for the tag: " .. (tag or "unknown"), vim.log.levels.WARN)
		return
	end

	-- Convert results to relative paths
	local relative_results = {}
	for _, file in ipairs(results) do
		local rel_path = file:gsub("^" .. dir:gsub("/$", "") .. "/", "") -- Remove dir prefix
		table.insert(relative_results, { rel_path = rel_path, full_path = file })
	end

	-- Launch fzf-lua
	fzf.fzf_exec(
		vim.tbl_map(function(item)
			return item.rel_path
		end, relative_results),
		{
			prompt = "Files for tag: " .. tag .. "> ",
			previewer = {},
			winopts = {
				preview = {
					default = "right:50%", -- Preview window on the right
					scrollbar = "float",
				},
			},
			actions = {
				-- Bind the "Enter" key to open the selected file
				["default"] = function(selected)
					-- Find the full path for the selected relative file
					for _, item in ipairs(relative_results) do
						if item.rel_path == selected[1] then
							vim.cmd("edit " .. vim.fn.fnameescape(item.full_path))
							break
						end
					end
				end,
			},
		}
	)
end

local function list_tags_and_files(tags)
	fzf.fzf_exec(tags, {
		preview = function(query)
			local tag = query[1] -- Selected tag
			local aFiles = require("yaml-tags.handlers.search").search_files_by_tag(tag)

			if not aFiles or not aFiles.results or #aFiles.results == 0 then
				return "\27[1;31mNo files found with tag:\27[0m \27[1;33m" .. tag .. "\27[0m" -- Red and yellow
			end

			local dir = aFiles.dir or ""
			dir = dir:gsub("/$", "") .. "/"
			local files = aFiles.results
			local cleaned_files = {}
			for _, file in ipairs(files) do
				file = file:gsub("^" .. dir, "")
				local cleaned_file = file
				local subdir, filename = file:match("^(.*[/\\])([^/\\]+)$")
				if subdir and filename then
					cleaned_file = "\27[90m" .. subdir .. "\27[0m" .. filename
				end

				cleaned_file = "  " .. cleaned_file
				table.insert(cleaned_files, cleaned_file)
			end
			local header = "\27[1;32mFiles with tag:\27[0m \27[1;33m" .. tag .. "\27[0m\n\n"
			return header .. table.concat(cleaned_files, "\n")
		end,
		winopts = {
			preview = {
				default = "right:50%",
				scrollbar = "float",
			},
		},
		actions = {
			["default"] = function(selected)
				local tag = selected[1]
				local aFiles = require("yaml-tags.handlers.search").search_files_by_tag(tag)

				if not aFiles or not aFiles.results or #aFiles.results == 0 then
					vim.notify("No files found for the tag: " .. tag, vim.log.levels.WARN)
					return
				end

				files_with_tag({
					dir = aFiles.dir or "",
					tag = tag,
					results = aFiles.results,
				})
			end,
		},
	})
end

return {
	show_files_with_tag = files_with_tag,
	show_tags = list_tags_and_files,
}
