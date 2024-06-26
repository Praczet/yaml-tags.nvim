local M = {}
local config = require("yaml-tags").config

-- Function to get selected text in visual mode
local function get_visual_selection()
	vim.cmd('noau normal! "vy"')
	return vim.fn.getreg("v")
end

-- Function to get word under the cursor
local function get_word_under_cursor()
	return vim.fn.expand("<cword>")
end

-- Function to split text by white characters
local function split_text(text)
	local words = {}
	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end
	return words
end

local function sanitize_elements(elements)
	local sanitized_elements = {}
	local seen = {}
	local allowed_characters = config.tag_formatting.allowed_characters
	local forbidden_words = config.forbidden_words or {}
	local forbidden_set = {}
	for _, word in ipairs(forbidden_words) do
		forbidden_set[word] = true
	end

	for _, element in ipairs(elements) do
		-- Remove non-allowed characters
		local sanitized_element = element:gsub("[^" .. allowed_characters .. "]", "")
		if not config.tag_formatting.allow_camel_case then
			sanitized_element = sanitized_element:lower()
		end
		if sanitized_element ~= "" and not seen[sanitized_element] and not forbidden_set[sanitized_element] then
			seen[sanitized_element] = true
			table.insert(sanitized_elements, sanitized_element)
		end
	end
	return sanitized_elements
end

-- Function to add tags to YAML front matter
local function add_tags_to_yaml(tags)
	if #tags == 0 then
		vim.notify("No tags found in selection or word under cursor", vim.log.WARN)
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local in_yaml = false
	local yaml_start, yaml_end = nil, nil
	local tags_section_start, tags_section_end = nil, nil

	-- Find YAML front matter and tags section
	for i, line in ipairs(lines) do
		if line:match("^%-%-%-") then
			if not yaml_start then
				in_yaml = true
				yaml_start = i
			else
				yaml_end = i
				in_yaml = false
			end
		end
		if in_yaml and line:match("^tags:") then
			tags_section_start = i
		elseif tags_section_start ~= nil and line:match("^%S") and tags_section_end == nil then
			if in_yaml then
				tags_section_end = i
			else
				tags_section_end = yaml_end
			end
		end
	end

	-- If YAML front matter is not found, create it
	if not yaml_start or not yaml_end then
		table.insert(lines, 1, "---")
		table.insert(lines, 2, "tags:")
		table.insert(lines, 3, "---")
		yaml_start = 1
		yaml_end = 3
		tags_section_start = 2
		tags_section_end = 3
	end

	-- If tags section is not found, create it
	if not tags_section_start then
		table.insert(lines, yaml_end, "tags:")
		tags_section_start = yaml_end
		tags_section_end = yaml_end + 1
	end

	-- Add tags to the tags section
	local new_tags = {}
	for _, tag in ipairs(tags) do
		table.insert(new_tags, "  - " .. tag)
	end

	-- Insert new tags lines
	for i, tag_line in ipairs(new_tags) do
		table.insert(lines, tags_section_end + i - 1, tag_line)
	end

	-- Update buffer with new lines
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- Notify user about added tags
	vim.notify("Added tags: " .. table.concat(tags, ", "))
end

-- Main function to convert selection to tags or word under cursor to tag
function M.selection_to_tags()
	local mode = vim.fn.mode()
	local text

	if mode == "v" or mode == "V" or mode == "" then
		text = get_visual_selection()
	else
		text = get_word_under_cursor()
	end

	local words = split_text(text)
	local tags = sanitize_elements(words)
	add_tags_to_yaml(tags)
end

return M
