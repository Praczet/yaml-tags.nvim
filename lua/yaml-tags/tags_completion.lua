local cmp = require("cmp")
local cjson = require("cjson")

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
	print("Line, cursor", lines, cursor)

	for i = cursor, 1, -1 do
		local line = lines[i]
		if line:match("^%-%-%-") then
			in_yaml = true
			break
		end
	end
	print("in_yaml", in_yaml)

	-- If not in YAML, return false
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
	print("in_tags_section", in_tags_section)
	return in_tags_section
end

-- Module table
local M = {}

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
	print("-- Check if current buffer is Markdown--")
	if not is_markdown_file(buf_name) then
		callback({ items = {}, isIncomplete = false })
		return
	end

	print("-- Get current buffer directory")
	-- Get current buffer directory
	local dir = get_current_buffer_directory()
	if not dir then
		callback({ items = {}, isIncomplete = false })
		return
	end

	print("-- Path to .my_tags.json")
	-- Path to .my_tags.json
	local json_path = dir .. "/.my_tags.json"
	local tags_data = read_json_file(json_path)
	if not tags_data or not tags_data.tags then
		callback({ items = {}, isIncomplete = false })
		return
	end

	print("-- Check if cursor is in YAML tags section")
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
			kind = cmp.lsp.CompletionItemKind.Enum,
			insertText = tag,
			filterText = tag,
			labelDetails = {
				description = "YAML Tag: " .. tag,
			},
		})
	end

	callback({ items = items, isIncomplete = false })
end

-- Initialize the plugin and register ytags source with nvim-cmp
function M.initialize_plugin()
	print("Initializing ytags plugin")
	cmp.register_source("ytags", M.source.new())
end

return M
-- local cmp = require("cmp")
-- local cjson = require("cjson")
--
-- -- Function to read JSON file
-- local function read_json_file(path)
-- 	local file = io.open(path, "r")
-- 	if file then
-- 		local content = file:read("*a")
-- 		file:close()
-- 		return cjson.decode(content)
-- 	end
-- 	return nil
-- end
--
-- -- Function to get current buffer directory
-- local function get_current_buffer_directory()
-- 	local buf_path = vim.api.nvim_buf_get_name(0)
-- 	if buf_path == "" then
-- 		return nil
-- 	end
-- 	local dir = buf_path:match("(.*/)")
-- 	return dir
-- end
--
-- -- Function to check if file is Markdown
-- local function is_markdown_file(filename)
-- 	return filename:match("%.md$")
-- end
--
-- -- Function to check if cursor is in YAML tags section
-- local function is_in_yaml_tags_section(lines, cursor)
-- 	return true
-- 	-- local in_yaml = false
-- 	-- local in_tags_section = false
-- 	--
-- 	-- for i = cursor, 1, -1 do
-- 	-- 	local line = lines[i]
-- 	-- 	if line:match("^%-%-%-") then
-- 	-- 		in_yaml = true
-- 	-- 		break
-- 	-- 	elseif line:match("^tags:%s*$") then
-- 	-- 		in_tags_section = true
-- 	-- 		break
-- 	-- 	elseif line:match("^%S") then
-- 	-- 		break
-- 	-- 	end
-- 	-- end
-- 	--
-- 	-- return in_yaml and in_tags_section
-- end
--
-- -- Module table
-- local M = {}
--
-- -- Custom completion source methods
-- M.source = {}
--
-- -- Constructor for source
-- M.source.new = function()
-- 	return setmetatable({}, { __index = M.source })
-- end
--
-- -- Metadata for source
-- M.source.get_metadata = function()
-- 	return {
-- 		priority = 1000,
-- 		dup = 1,
-- 		menu = "[ytags]",
-- 	}
-- end
--
-- -- Completion function for source
-- M.source.complete = function(self, request, callback)
-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 	local buf_name = vim.api.nvim_buf_get_name(bufnr)
--
-- 	-- Check if current buffer is Markdown
-- 	if not is_markdown_file(buf_name) then
-- 		callback({ items = {}, isIncomplete = false })
-- 		return
-- 	end
--
-- 	-- Get current buffer directory
-- 	local dir = get_current_buffer_directory()
-- 	if not dir then
-- 		callback({ items = {}, isIncomplete = false })
-- 		return
-- 	end
--
-- 	-- Path to .my_tags.json
-- 	local json_path = dir .. "/.my_tags.json"
-- 	local tags_data = read_json_file(json_path)
-- 	if not tags_data or not tags_data.tags then
-- 		callback({ items = {}, isIncomplete = false })
-- 		return
-- 	end
--
-- 	-- Check if cursor is in YAML tags section
-- 	local cursor = vim.api.nvim_win_get_cursor(0)
-- 	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
-- 	if not is_in_yaml_tags_section(lines, cursor[1]) then
-- 		callback({ items = {}, isIncomplete = false })
-- 		return
-- 	end
--
-- 	-- Prepare completion items from tags
-- 	local tags = tags_data.tags
-- 	local items = {}
-- 	for _, tag in ipairs(tags) do
-- 		table.insert(items, {
-- 			label = tag,
-- 			kind = cmp.lsp.CompletionItemKind.Keyword,
-- 			insertText = tag,
-- 			filterText = tag,
-- 		})
-- 	end
--
-- 	callback({ items = items, isIncomplete = false })
-- end
--
-- -- Initialize the plugin and register ytags source with nvim-cmp
-- function M.initialize_plugin()
-- 	print("Initializing ytags plugin")
-- 	cmp.register_source("ytags", M.source.new())
-- end
--
-- return setmetatable({}, {
-- 	__index = function(_, k)
-- 		if M[k] then
-- 			return M[k]
-- 		else
-- 			error("Invalid method " .. k)
-- 		end
-- 	end,
-- })
-- -- return M
