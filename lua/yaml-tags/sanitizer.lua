local M = {}

-- Function to check if YAML content is valid
local function is_valid_yaml(yaml_content)
	local valid = true
	local inside_tag_section = false

	for _, line in ipairs(vim.split(yaml_content, "\n")) do
		if line:match("^%s*[^%-%s]") and not line:match("^[%w_-]+:%s") and not line:match("^[%w_-]+:$") then
			valid = false
			break
		end

		if line:match("^[%w_-]+:$") then
			inside_tag_section = true
		elseif inside_tag_section then
			local tag = line:match("^%s*%- (.+)")
			if not tag and not line:match("^%s*$") then
				inside_tag_section = false
			elseif not tag then
				valid = false
				break
			end
		end
	end
	return valid
end

-- Function to parse YAML front matter
local function parse_yaml_front_matter(content)
	local yaml_start, yaml_end = content:find("^%s*%-%-%-%s*\n(.-)\n%s*%-%-%-")
	if not yaml_start or not yaml_end then
		return nil, nil, nil
	end
	local yaml_content = content:sub(yaml_start, yaml_end)
	return yaml_content, yaml_start, yaml_end + 1
end

-- Function to sanitize tags (remove duplicates and sort alphabetically)
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

-- Function to sanitize buffer
-- Gets YAML front matter and sanitizes tags
local function sanitize_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

	local yaml_content, yaml_start, yaml_end = parse_yaml_front_matter(content)
	if not yaml_content or not yaml_start or not yaml_end then
		return
	end

	if not is_valid_yaml(yaml_content) then
		vim.notify("YAML front matter is malformed and was not modified.", vim.log.levels.WARN)
		return
	end

	local lines = vim.split(yaml_content, "\n")

	local lines_without_tags = {}
	local sanitized_lines = {}
	local in_tags_section = false
	local tags = {}

	for _, line in ipairs(lines) do
		if line:match("^tags:%s*$") then
			in_tags_section = true
			table.insert(lines_without_tags, line)
		elseif in_tags_section then
			local tag = line:match("^  %- (.+)")
			if tag then
				table.insert(tags, tag)
			else
				in_tags_section = false
				table.insert(lines_without_tags, line)
			end
		else
			table.insert(lines_without_tags, line)
		end
	end

	if #tags > 0 then
		local sanitized_tags = sanitize_tags(tags)
		for _, line in ipairs(lines_without_tags) do
			table.insert(sanitized_lines, line)
			if line:match("^tags:%s*$") then
				for _, tag in ipairs(sanitized_tags) do
					table.insert(sanitized_lines, "  - " .. tag)
				end
			end
		end
	else
		sanitized_lines = lines_without_tags
	end

	local remaining_lines = vim.split(content:sub(yaml_end), "\n")
	for _, line in ipairs(remaining_lines) do
		table.insert(sanitized_lines, line)
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sanitized_lines)
end

M.sanitize_current_buffer = sanitize_buffer

return M
