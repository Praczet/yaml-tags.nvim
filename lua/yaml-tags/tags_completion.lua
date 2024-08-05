local cmp = require("cmp")
local cjson = require("cjson")
local telescope = require("telescope.builtin")
local lfs = require("lfs")

local read_file = require("yaml-tags.tags_extractor").read_file
local parse_yaml_front_matter = require("yaml-tags.tags_extractor").parse_yaml_front_matter

-- Function to read JSON file
local function read_json_file(path)
	local file = io.open(path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		return cjson.decode(content)
	end
	return nil
end

-- Function to get current buffer directory
local function get_current_buffer_directory()
	local buf_path = vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		return nil
	end
	local dir = buf_path:match("(.*/)")
	return dir
end

-- Function to check if file is Markdown
local function is_markdown_file(filename)
	return filename:match("%.md$")
end

-- Function to check if cursor is in YAML tags section
local function is_in_yaml_tags_section(lines, cursor)
	local in_yaml = false
	local in_tags_section = false

	for i = cursor, 1, -1 do
		local line = lines[i]
		if line:match("^%-%-%-") then
			in_yaml = true
			break
		end
	end

	if not in_yaml then
		return false
	end

	-- Check for tags: section
	for i = cursor, 1, -1 do
		local line = lines[i]
		if line:match("^tags:%s*$") then
			in_tags_section = true
			break
		elseif line:match("^%-%-%-") then
			break
		end
	end
	return in_tags_section
end

local M = {}
M.config = {
	kind_hl_group = "#ffc777", -- Default color, you can override this when setting up the plugin
}

-- Custom completion source methods
M.source = {}

-- Constructor for source
M.source.new = function()
	return setmetatable({}, { __index = M.source })
end

-- Metadata for source
M.source.get_metadata = function()
	return {
		priority = 1000,
		dup = 1,
		menu = "[ytags]",
	}
end

-- Completion function for source
M.source.complete = function(self, request, callback)
	local bufnr = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(bufnr)

	-- Check if current buffer is Markdown
	if not is_markdown_file(buf_name) then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Get current buffer directory
	local dir = get_current_buffer_directory()
	if not dir then
		callback({ items = {}, isIncomplete = false })
		return
	end

	local json_path = dir .. "/.my_tags.json"
	local tags_data = read_json_file(json_path)
	if not tags_data or not tags_data.tags then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Check if cursor is in YAML tags section
	local cursor = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
	if not is_in_yaml_tags_section(lines, cursor[1]) then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Prepare completion items from tags
	local tags = tags_data.tags
	local items = {}
	for _, tag in ipairs(tags) do
		table.insert(items, {
			label = tag,
			insertText = tag,
			filterText = tag,
			cmp = {
				kind_text = "# Y-TAG",
				kind_hl_group = "CmpItemKindYamlTag",
			},
		})
	end

	callback({ items = items, isIncomplete = false })
end

-- Get files containing the specified tag
local function search_files_by_tag(tag)
	local dir = get_current_buffer_directory()
	if not dir then
		vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		return
	end

	local results = {}
	local function scan_directory_for_tag(dir, tag)
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				local path = dir .. "/" .. entry
				local attr = lfs.attributes(path)
				if attr.mode == "directory" then
					scan_directory_for_tag(path, tag)
				elseif attr.mode == "file" and entry:match("%.md$") then
					local content = read_file(path)
					if content and content:find("tags:") then
						local yaml_data = parse_yaml_front_matter(content)
						if yaml_data and yaml_data.tags then
							for _, file_tag in ipairs(yaml_data.tags) do
								if file_tag == tag then
									table.insert(results, path)
									break
								end
							end
						end
					end
				end
			end
		end
	end

	scan_directory_for_tag(dir, tag)

	-- Here I do not like the way how it is displayed
	telescope.find_files({
		prompt_title = "Files containing tag: " .. tag,
		results_title = "Files",
		cwd = dir,
		search_dirs = results,
	})
end

-- Gets the tag under the cursor (if line starts with -)
-- TODO: This should be improved (check if the line is in YAML section)
local function get_tag_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local tag = line:match("%- (.+)")
	return tag
end

-- Gets the tag under the cursor and searches for files with the tag
function M.search_files_by_tag_under_cursor()
	local tag = get_tag_under_cursor()
	if tag then
		search_files_by_tag(tag)
	else
		vim.notify(
			"No tag found under cursor.\n\nNote:\nThis function works only if you are in the YAML section and the cursor is on the line with the tag.",
			vim.log.levels.WARN
		)
	end
end

-- Initialize the plugin and register ytags source with nvim-cmp
function M.initialize_plugin()
	local highlight_cmd = string.format("highlight CmpItemKindYamlTag guifg=%s", M.config.kind_hl_group)
	vim.cmd(highlight_cmd)
	cmp.register_source("ytags", M.source.new())
end

return M
