local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local lfs = require("lfs")
local read_file = require("yaml-tags.tags_extractor").read_file
local parse_yaml_front_matter = require("yaml-tags.tags_extractor").parse_yaml_front_matter
local get_current_buffer_directory = require("yaml-tags.tags_extractor").get_current_buffer_directory

local function scan_md_files_for_tags(directory)
	local tags = {}
	local function scan_directory(dir)
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				local path = dir .. "/" .. entry
				local attr = lfs.attributes(path)
				if attr.mode == "directory" then
					scan_directory(path)
				elseif attr.mode == "file" and entry:match("%.md$") then
					local content = read_file(path)
					if content then
						local yaml_data = parse_yaml_front_matter(content)
						if yaml_data and yaml_data.tags then
							for _, tag in ipairs(yaml_data.tags) do
								if not tags[tag] then
									tags[tag] = {}
								end
								table.insert(tags[tag], path:sub(#directory + 2)) -- Store relative path
							end
						end
					end
				end
			end
		end
	end
	scan_directory(directory)
	return tags
end

local function telescope_list_tags_and_files()
	local dir = get_current_buffer_directory()
	if not dir then
		vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		return
	end

	local tags = scan_md_files_for_tags(dir)

	pickers
		.new({}, {
			prompt_title = "Tags",
			finder = finders.new_table({
				results = vim.tbl_keys(tags),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = sorters.get_generic_fuzzy_sorter(),
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry, status)
					local files = tags[entry.value] or {}
					table.sort(files)
					local content = "Files containing tag '" .. entry.value .. "':\n\n"
					for _, file in ipairs(files) do
						content = content .. file .. "\n"
					end
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(content, "\n"))
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local files = tags[selection.value]
					pickers
						.new({}, {
							prompt_title = "Files for tag: " .. selection.value,
							finder = finders.new_table({
								results = files,
								entry_maker = function(entry)
									return {
										value = entry,
										display = entry,
										ordinal = entry,
									}
								end,
							}),
							sorter = sorters.get_generic_fuzzy_sorter(),
							previewer = previewers.new_buffer_previewer({
								define_preview = function(self, entry, status)
									local filepath = dir .. "/" .. entry.value
									local bufnr = self.state.bufnr
									vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
									vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
									local lines = read_file(filepath)
									if lines then
										vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(lines, "\n"))
									else
										vim.api.nvim_buf_set_lines(
											bufnr,
											0,
											-1,
											false,
											{ "Error: could not read file " .. filepath }
										)
									end
								end,
							}),
							attach_mappings = function(prompt_bufnr2, map2)
								actions.select_default:replace(function()
									local file_selection = action_state.get_selected_entry()
									actions.close(prompt_bufnr2)
									vim.cmd("edit " .. dir .. "/" .. file_selection.value)
								end)
								return true
							end,
						})
						:find()
				end)
				return true
			end,
		})
		:find()
end

return telescope_list_tags_and_files
