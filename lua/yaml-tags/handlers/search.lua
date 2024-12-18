local cjson = require("cjson")
local lfs = require("lfs")
local utils = require("yaml-tags.utils")

local M = {}

-- Utility function to detect plugins
local function is_plugin_installed(name)
	local ok, _ = pcall(require, name)
	return ok
end

local function get_tag_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local tag = line:match("%- (.+)")
	return tag
end

-- Get files containing the specified tag
local function search_files_by_tag(tag)
	local dir = utils.get_current_project_directory()
	if not dir then
		vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		return
	end

	local results = {}
	local function scan_directory_for_tag(dir, tag)
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				local path = dir:gsub("/$", "") .. "/" .. entry
				local attr = lfs.attributes(path)
				if attr.mode == "directory" then
					scan_directory_for_tag(path, tag)
				elseif attr.mode == "file" and entry:match("%.md$") then
					local content = utils.read_file(path)
					if content and content:find("tags:") then
						local yaml_data = utils.parse_yaml_front_matter(content)
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
	return { dir = dir, tag = tag, results = results }
end
-- Gets the tag under the cursor and searches for files with the tag
local function files_by_tag_under_cursor()
	local tag = get_tag_under_cursor()
	if tag then
		return search_files_by_tag(tag)
	else
		vim.notify(
			"No tag found under cursor.\n\nNote:\nThis function works only if you are in the YAML section and the cursor is on the line with the tag.",
			vim.log.levels.WARN
		)
		return nil
	end
end

-- Public search function
function M.list_tags_and_files(opts)
	tags = require("yaml-tags.extractor").get_tags()
	if is_plugin_installed("telescope") then
		local telescope = require("yaml-tags.search.telescope")
		telescope.list_tags_and_files(opts)
	elseif is_plugin_installed("fzf-lua") then
		local fzf = require("yaml-tags.search.fzf")
		fzf.show_tags(tags)
	else
		vim.notify("Neither Telescope nor fzf-lua is installed!", vim.log.levels.ERROR)
	end
end

-- Public search function
function M.search_files_by_tag_under_cursor(opts)
	local files = files_by_tag_under_cursor()
	if not files then
		vim.notify("No tag found under cursor.", vim.log.levels.WARN)
		return
	end

	if is_plugin_installed("telescope") then
		local telescope = require("yaml-tags.search.telescope")
		telescope.list_tags_and_files(files)
	elseif is_plugin_installed("fzf-lua") then
		local fzf = require("yaml-tags.search.fzf")
		fzf.show_files_with_tag(files)
	else
		vim.notify("Neither Telescope nor fzf-lua is installed!", vim.log.levels.ERROR)
	end
end
M.search_files_by_tag = search_files_by_tag

return M
