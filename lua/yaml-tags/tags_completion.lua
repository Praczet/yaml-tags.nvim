local cmp = require("cmp")
local cjson = require("cjson")

local function read_json_file(path)
	local file = io.open(path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		return cjson.decode(content)
	end
	return nil
end

local function get_current_buffer_directory()
	local buf_path = vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		return nil
	end
	local dir = buf_path:match("(.*/)")
	return dir
end

local function is_markdown_file(filename)
	return filename:match("%.md$")
end

local function is_in_yaml_tags_section(lines, cursor)
	local in_yaml = false
	local in_tags_section = false

	for i = cursor, 1, -1 do
		local line = lines[i]
		if line:match("^%-%-%-") then
			in_yaml = true
			break
		elseif line:match("^tags:%s*$") then
			in_tags_section = true
			break
		elseif line:match("^%S") then
			break
		end
	end

	return in_yaml and in_tags_section
end

local M = {}

M.source = {}

M.source.new = function()
	return setmetatable({}, { __index = M.source })
end

M.source.get_metadata = function()
	return {
		priority = 1000,
		dup = 1,
		menu = "[ytags]",
	}
end

M.source.complete = function(self, request, callback)
	local bufnr = vim.api.nvim_get_current_buf()
	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	if not is_markdown_file(buf_name) then
		callback({ items = {}, isIncomplete = false })
		return
	end

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

	local cursor = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
	if not is_in_yaml_tags_section(lines, cursor[1]) then
		callback({ items = {}, isIncomplete = false })
		return
	end

	local tags = tags_data.tags or {}
	local items = {}
	for _, tag in ipairs(tags) do
		table.insert(items, {
			label = tag,
			kind = cmp.lsp.CompletionItemKind.Keyword,
			insertText = tag,
			filterText = tag,
		})
	end

	callback({ items = items, isIncomplete = false })
end

function M.initalize_plugin()
	print("Initializing ytags plugin")
	cmp.register_source("ytags", M.source.new())
end

return M
