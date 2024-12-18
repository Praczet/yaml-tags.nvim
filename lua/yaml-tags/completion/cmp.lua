local cmp = require("cmp")
local cjson = require("cjson")
local lfs = require("lfs")

local search = require("yaml-tags.handlers.search")
local utils = require("yaml-tags.utils")

local read_file = require("yaml-tags.extractor").read_file
local parse_yaml_front_matter = require("yaml-tags.extractor").parse_yaml_front_matter

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

	-- Check if current buffer is Markdown
	if not utils.is_markdown_file() then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Get current buffer directory
	local dir = utils.get_current_project_directory()
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
				kind_text = "󰓹 Y-TAG",
				kind_hl_group = "CmpItemKindYamlTag",
			},
		})
	end

	callback({ items = items, isIncomplete = false })
end

-- Gets the tag under the cursor (if line starts with -)
-- TODO: This should be improved (check if the line is in YAML section)

-- Initialize the plugin and register ytags source with nvim-cmp
function M.initialize_plugin()
	local highlight_cmd = string.format("highlight CmpItemKindYamlTag guifg=%s", M.config.kind_hl_group)
	vim.cmd(highlight_cmd)
	cmp.register_source("ytags", M.source.new())
end

return M
