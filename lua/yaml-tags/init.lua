-- local M = {}
-- M._Config = {
-- 	max_tags = 10,
-- }
--
-- local lyaml = require("lyaml")
-- local cjson = require("cjson")
-- local lfs = require("lfs")
--
-- -- Function to get current time
-- local function get_current_time()
-- 	return os.date("%Y-%m-%d %H:%M:%S")
-- end
--
-- -- Function to get current buffer directory
-- local function get_current_buffer_directory()
-- 	local buf_path = vim.api.nvim_buf_get_name(0) -- Get the full path of the current buffer
-- 	if buf_path == "" then
-- 		return nil
-- 	end
-- 	local dir = buf_path:match("(.*/)")
-- 	return dir
-- end
--
-- -- Function to read file content
-- local function read_file(path)
-- 	local file = io.open(path, "r")
-- 	if file then
-- 		local content = file:read("*a")
-- 		file:close()
-- 		return content
-- 	end
-- 	return nil
-- end
--
-- -- Function to parse YAML front matter
-- local function parse_yaml_front_matter(content)
-- 	local front_matter = content:match("^%-%-%-(.-)%-%-%-")
-- 	if front_matter then
-- 		return lyaml.load(front_matter)
-- 	end
-- 	return nil
-- end
--
-- -- Function to scan markdown files and extract tags
-- local function scan_md_files(directory)
-- 	local tags = {}
-- 	-- print("Scanning directory:", directory)
-- 	local function scan_directory(dir)
-- 		for file in lfs.dir(dir) do
-- 			-- print("File:", file)
-- 			if file ~= "." and file ~= ".." then
-- 				local filepath = dir .. "/" .. file
-- 				local attr = lfs.attributes(filepath)
-- 				if attr.mode == "directory" then
-- 					scan_directory(filepath)
-- 				elseif attr.mode == "file" and file:match("%.md$") then
-- 					local content = read_file(filepath)
-- 					if content then
-- 						local yaml_data = parse_yaml_front_matter(content)
-- 						if yaml_data and yaml_data.tags then
-- 							for _, tag in ipairs(yaml_data.tags) do
-- 								tags[tag] = true -- Using the tag as a key ensures uniqueness
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	scan_directory(directory)
-- 	return tags
-- end
--
-- -- Function to convert tags table to list
-- local function tags_table_to_list(tags_table)
-- 	local tags_list = {}
-- 	for tag, _ in pairs(tags_table) do
-- 		table.insert(tags_list, tag)
-- 	end
-- 	return tags_list
-- end
--
-- -- Function to write JSON string to a file
-- local function write_to_file(filename, content)
-- 	local file = io.open(filename, "w")
-- 	if file then
-- 		file:write(content)
-- 		file:close()
-- 	else
-- 		error("Could not open file for writing: " .. filename)
-- 	end
-- end
--
-- -- Function to get the last modification time using lfs
-- local function get_last_modified(folder_name)
-- 	local last_modified_time = 0
-- 	local function scan_directory(dir)
-- 		for file in lfs.dir(dir) do
-- 			if file ~= "." and file ~= ".." then
-- 				local file_path = dir .. "/" .. file
-- 				local attr = lfs.attributes(file_path)
-- 				if attr.mode == "directory" then
-- 					scan_directory(file_path)
-- 				elseif attr.mode == "file" then
-- 					if attr.modification > last_modified_time then
-- 						last_modified_time = attr.modification
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	scan_directory(folder_name)
-- 	if last_modified_time > 0 then
-- 		return os.date("%Y-%m-%d %H:%M:%S", last_modified_time)
-- 	else
-- 		return nil
-- 	end
-- end
--
-- -- Main function to save tags
-- local function save_tags(directory)
-- 	local tags_table = scan_md_files(directory)
-- 	local tags_list = tags_table_to_list(tags_table)
-- 	table.sort(tags_list)
-- 	local my_tags = {
-- 		last_mod = get_current_time(),
-- 		tags = tags_list,
-- 	}
-- 	local json_str = cjson.encode(my_tags)
-- 	local filename = directory .. ".my_tags.json"
-- 	write_to_file(filename, json_str)
-- 	vim.notify("Tags saved to " .. filename, vim.log.levels.INFO)
-- end
--
-- -- Function to read JSON file content
-- local function read_json_file(path)
-- 	local content = read_file(path)
-- 	if content then
-- 		return cjson.decode(content)
-- 	end
-- 	return nil
-- end
--
-- -- Function to initialize the plugin
-- local function initialize_plugin(directory)
-- 	local config_path = directory .. ".my_tags.json"
-- 	local config = read_json_file(config_path)
-- 	if config then
-- 		local last_mod_time = config.last_mod
-- 		local last_modified = get_last_modified(directory)
-- 		if last_modified and last_modified > last_mod_time then
-- 			save_tags(directory)
-- 		end
-- 	else
-- 		save_tags(directory)
-- 	end
-- end
--
-- function M.reload_tags()
-- 	local buffer_directory = get_current_buffer_directory()
-- 	if buffer_directory then
-- 		initialize_plugin(buffer_directory)
-- 	end
-- end
--
-- -- Initialize the tag extractor
-- require("yaml-tags.tags_extractor")
--
-- -- Initialize the tag completion
-- require("yaml-tags.tags_completion")
local M = {}

M.extractor = require("yaml-tags.tags_extractor")
M.completion = require("yaml-tags.tags_completion")
--
-- Function to check if the current buffer is a Markdown file
local function is_markdown_file()
	return vim.bo.filetype == "markdown"
end

-- Load necessary modules
local cmp = require("cmp")

-- Setup nvim-cmp for Markdown files
local function setup_cmp()
	cmp.setup.filetype("markdown", {
		sources = cmp.config.sources({
			{ name = "ytags" },
			{ name = "buffer" },
			{ name = "path" },
		}),
	})

	-- Autocommand to enable completion in YAML front matter tags section
	vim.cmd([[
        augroup MarkdownYAMLTags
            autocmd!
            autocmd FileType markdown lua require'yaml-tags'.setup_cmp()
        augroup END
    ]])
end
function M.setup()
	-- Set up your plugin setup here
	if is_markdown_file() then
		M.extractor.initialize_plugin()
		M.completion.initialize_plugin()
		setup_cmp()
	end
end

M.setup()

return M
-- Set up
--
-- -- Create a command to save tags
-- vim.api.nvim_create_user_command("SaveTags", function()
-- 	save_tags("Notes") -- Replace "Notes" with your desired directory
-- end, {})
--
-- -- Initialize the plugin on startup
-- initialize_plugin("Notes") -- Replace "Notes" with your desired directory
--
-- -- You can also set up an autocommand if needed
-- vim.api.nvim_create_autocmd("BufWritePost", {
-- 	pattern = "*.md",
-- 	callback = function()
-- 		initialize_plugin("Notes") -- Replace "Notes" with your desired directory
-- 	end,
-- })
-- local function write_tags(filename, content)
--   local file = io.open(filename, "w")
--   if file then
--     file:write(content)
--     file:close()
--   else
--     error("Could not open file for writing: " .. filename)
--   end
-- end
--
-- local function get_last_modified(folder_name)
--   local find_command = "find " .. folder_name .. " -type f -exec stat -c '%y' {} \\; | sort -nr | head -n 1"
--   local last_modified = vim.fn.systemlist(find_command)
--   if #last_modified > 0 then
--     return last_modified[1]
--   else
--     return nil
--   end
-- end
--
-- -- Function to fetch tags from Markdown files in current directory
-- local function get_tags_from_files(current_dir)
--   local tags = {}
--   --
--   -- local handle = io.popen(
--   -- 	"find "
--   -- 		.. current_dir
--   -- 		.. ' -name "*.md" -exec awk "/tags:/{y=1;next} y" {} \\; | grep -o "#\\w\\+" | sort | uniq'
--   -- )
--   --
--   -- if handle ~= nil then
--   -- 	local result = handle:read("*a")
--   -- 	handle:close()
--   --
--   -- 	for tag in result:gmatch("#%w+") do
--   -- 		table.insert(tags, tag)
--   -- 	end
--   -- end
--
--   return tags
-- end
--
-- local function reload_tags(current_dir, tags_last_mod)
--   local last_modified = get_last_modified(current_dir)
--   if not (last_modified == nil or tags_last_mod == nil or last_modified > tags_last_mod) then
--     return
--   end
--   print("Reloading tags")
--
--   local find_command = "find  "
--       .. current_dir
--       ..
--       '  -name "*.md" -exec awk \'/^tags:$/ {f=1;next}  /^  -?/ {start=1} /^---$/ {x++;next} !/^  - ?/{ if(f==1) f = 4}  x < 2 && f==1 { sub(/^  - /,""); print} ; f == 4 {exit}  \' {} \\; | sort |  uniq'
--   local tags = vim.fn.systemlist(find_command)
--   print(table.concat(tags, ", "))
-- end
--
-- -- Completion function for YAML tags
-- function M.complete_tags(findstart, base)
--   local current_dir = vim.fn.getcwd()
--   local tags_last_mod = nil
--   reload_tags(current_dir, tags_last_mod)
--   -- if findstart == 1 then
--   -- 	-- Find the start of the current word
--   -- 	local line = vim.api.nvim_get_current_line()
--   -- 	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
--   -- 	while col > 1 and line:sub(col, col):match("%w") do
--   -- 		col = col - 1
--   -- 	end
--   -- 	return col
--   -- else
--   -- 	-- Fetch tags from files in current directory
--   -- 	local tags = get_tags_from_files(current_dir)
--   --
--   -- 	-- Filter tags based on base
--   -- 	local matches = {}
--   -- 	for _, tag in ipairs(tags) do
--   -- 		if tag:match("^" .. base) then
--   -- 			table.insert(matches, tag)
--   -- 		end
--   -- 	end
--   --
--   -- 	return matches
--   -- end
-- end
--
-- return setmetatable({}, {
--   __index = function(_, k)
--     if M[k] then
--       return M[k]
--     else
--       error("Invalid method " .. k)
--     end
--   end,
-- })
