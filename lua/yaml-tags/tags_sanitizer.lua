local lyaml = require("lyaml")

local M = {}

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local function write_file(path, content)
	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(content)
	file:close()
	return true
end

local function parse_yaml_front_matter(content)
	local yaml_start, yaml_end = content:match("()---\n().-()\n---\n()")
	if not yaml_start or not yaml_end then
		return nil, nil, nil
	end
	local yaml_content = content:sub(yaml_start, yaml_end)
	return yaml_content, yaml_start, yaml_end
end

local function sanitize_tags(tags)
	local unique_tags = {}
	local seen = {}
	for _, tag in ipairs(tags) do
		if not seen[tag] then
			seen[tag] = true
			table.insert(unique_tags, tag)
		end
	end
	table.sort(unique_tags)
	return unique_tags
end

local function sanitize_file(filepath)
	local content = read_file(filepath)
	if not content then
		return
	end

	local yaml_content, yaml_start, yaml_end = parse_yaml_front_matter(content)
	if not yaml_content then
		return
	end

	local yaml_data = lyaml.load(yaml_content)
	if not yaml_data or not yaml_data.tags then
		return
	end

	local sanitized_tags = sanitize_tags(yaml_data.tags)

	yaml_data.tags = sanitized_tags

	local new_yaml_content = lyaml.dump({ yaml_data })
	local new_content = content:sub(1, yaml_start - 1) .. new_yaml_content .. content:sub(yaml_end)

	write_file(filepath, new_content)
end

M.sanitize_current_buffer = function()
	local filepath = vim.api.nvim_buf_get_name(0)
	sanitize_file(filepath)
end

return M
