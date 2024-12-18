local lfs = require("lfs")
local lyaml = require("lyaml")

M = {}

local function log_message(message)
	local log_file = vim.fn.expand("~/.config/nvim/nvim.log")
	local log_entry = os.date("%Y-%m-%d %H:%M:%S") .. "\t[yaml-tags]\n" .. message .. "\n"
	local file = io.open(log_file, "a")
	if file then
		file:write(log_entry)
		file:close()
	end
end

function M.is_plugin_installed(name)
	local ok, _ = pcall(require, name)
	return ok
end

function M.log(message)
	log_message(message)
end

function M.get_current_project_directory()
	local buf_path = vim.api.nvim_buf_get_name(0)

	-- Check if we are in a term buffer and fallback to the current working directory
	if buf_path == "" or buf_path:match("^term://") then
		buf_path = vim.fn.getcwd()
	end

	-- Resolve the project root directory
	local root = vim.fn.finddir(".git", ".;") -- Search for .git folder upwards
	if root ~= "" then
		return vim.fn.fnamemodify(root, ":p:h:h") -- Remove '/.git' and make it absolute
	end

	-- Fallback to directory of the current buffer
	local dir = buf_path:match("(.*/)")
	return vim.fn.expand(dir) or vim.fn.getcwd()
end

-- Normalize the path by adding a trailing slash if it is missing
-- @param path Path to normalize
function M.normalize_path(path)
	if not path:match("/$") then
		return path .. "/"
	end
	return path
end

function M.scan_md_files_for_tags(directory)
	local tags = {}
	local function scan_directory(dir)
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				local path = dir .. "/" .. entry
				local attr = lfs.attributes(path)
				if attr.mode == "directory" then
					scan_directory(path)
				elseif attr.mode == "file" and entry:match("%.md$") then
					local content = M.read_file(path)
					if content then
						local yaml_data = M.parse_yaml_front_matter(content)
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

function M.parse_yaml_front_matter(content)
	local front_matter = content:match("^%-%-%-(.-)%-%-%-")
	if front_matter then
		return lyaml.load(front_matter)
	end
	return nil
end

function M.read_file(path)
	local file = io.open(path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		return content
	end
	return nil
end

function M.is_markdown_file()
	return vim.bo.filetype == "markdown"
end

function M.in_tags_section()
	local cursor_line = vim.api.nvim_get_current_line()
	-- Check if the current line starts with 'tags:' or is part of its list
	if cursor_line:match("^%s*tags:%s*") or cursor_line:match("^%s*-%s+.*") then
		-- Also ensure we are in YAML block
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		for _, line in ipairs(lines) do
			if line:match("^%-%-%-$") then -- Start of YAML
				return true
			elseif line:match("^%.%-%-%-$") then -- End of YAML
				return false
			end
		end
	end
	return false
end

return M
