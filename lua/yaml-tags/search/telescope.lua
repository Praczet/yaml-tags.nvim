local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local get_current_buffer_directory = require("yaml-tags.extractor").get_current_buffer_directory
local read_file = require("yaml-tags.extractor").read_file

local utils = require("yaml-tags.utils")

--f Function to scan Markdown files and extract tags

-- Function to list tags and files
local function list_tags_and_files(opts)
	local dir = get_current_buffer_directory()
	if not dir then
		vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		return
	end

	local tags = utils.scan_md_files_for_tags(dir)

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
									-- vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
									vim.bo[bufnr].filetype = "markdown"
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

return { list_tags_and_files = list_tags_and_files }
