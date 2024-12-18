local cjson = require("cjson")
local lfs = require("lfs")
local utils = require("yaml-tags.utils")

-- Function to get current time
local function get_current_time()
	return os.date("%Y-%m-%d %H:%M:%S")
end

-- Function to scan markdown files and extract tags
local function scan_md_files(directory)
	local tags = {}
	directory = utils.normalize_path(directory)
	local function scan_directory(dir)
		for file in lfs.dir(dir) do
			if file ~= "." and file ~= ".." then
				local filepath = dir .. "/" .. file
				local attr = lfs.attributes(filepath)
				if attr.mode == "directory" then
					scan_directory(filepath)
				elseif attr.mode == "file" and file:match("%.md$") then
					local content = utils.read_file(filepath)
					if content then
						local yaml_data = utils.parse_yaml_front_matter(content)
						if yaml_data and yaml_data.tags then
							for _, tag in ipairs(yaml_data.tags) do
								if tag == nil then
									tag = "nil"
								end
								tags[tag] = true
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

-- Function to convert tags table to list
local function tags_table_to_list(tags_table)
	local tags_list = {}
	for tag, _ in pairs(tags_table) do
		table.insert(tags_list, tag)
	end
	return tags_list
end

-- Function to write JSON string to a file
local function write_to_file(filename, content)
	local file = io.open(filename, "w")
	if file then
		file:write(content)
		file:close()
	else
		error("Could not open file for writing: " .. filename)
	end
end

-- Function to get the last modification time using lfs
local function get_last_modified(folder_name)
	local last_modified_time = 0
	local function scan_directory(dir)
		for file in lfs.dir(dir) do
			if file ~= "." and file ~= ".." then
				local file_path = dir .. "/" .. file
				local attr = lfs.attributes(file_path)
				if attr then
					if attr.mode == "directory" then
						scan_directory(file_path)
					elseif attr.mode == "file" then
						if attr.modification > last_modified_time then
							last_modified_time = attr.modification
						end
					end
				else
					vim.notify("Could not get attributes for file: " .. file_path, vim.log.levels.ERROR)
				end
			end
		end
	end
	scan_directory(folder_name)
	if last_modified_time > 0 then
		return os.date("%Y-%m-%d %H:%M:%S", last_modified_time)
	else
		return nil
	end
end

-- Main function to save tags
local function save_tags(directory)
	if not directory then
		vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		return
	end
	directory = utils.normalize_path(directory)
	local tags_table = scan_md_files(directory)
	local tags_list = tags_table_to_list(tags_table)
	table.sort(tags_list)
	local my_tags = {
		last_mod = get_current_time(),
		tags = tags_list,
	}
	local json_str = cjson.encode(my_tags)
	local filename = directory .. ".my_tags.json"
	write_to_file(filename, json_str)
	vim.notify("Tags saved to " .. filename, vim.log.levels.TRACE)
end

-- Function to read JSON file content
local function read_json_file(path)
	local content = utils.read_file(path)
	if content then
		return cjson.decode(content)
	end
	return nil
end

-- Function to initialize the plugin
local function initialize_plugin()
	local directory = utils.get_current_project_directory()
	if not directory then
		vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		return
	end
	local config_path = directory .. ".my_tags.json"
	local config = read_json_file(config_path)
	if config then
		local last_mod_time = config.last_mod
		local last_modified = get_last_modified(directory)
		if last_modified and last_modified > last_mod_time then
			save_tags(directory)
		end
	else
		save_tags(directory)
	end
end

local function get_tags()
	local directory = utils.get_current_project_directory()
	local config_path = directory .. ".my_tags.json"
	local config = read_json_file(config_path)
	if config then
		return config.tags
	end
	local tags_table = scan_md_files(directory)
	return tags_table_to_list(tags_table)
end

-- initialize_plugin()
return {
	initialize_plugin = initialize_plugin,
	save_tags = save_tags,
	parse_yaml_front_matter = utils.parse_yaml_front_matter,
	get_tags = get_tags,
}
