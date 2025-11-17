local M = {}

-- Default configuration
M.config = {
	sanitizer = true,
	tag_formatting = {
		allow_camel_case = false,
		allowed_characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
	},
	forbidden_words = { "and", "is", "or", "a", "the", "not", "an" },
	excluded_directories = {},
	included_directories = {},
	search_engine = "auto", -- options: "telescope", "fzf-lua", "auto"
	autocomplete_engine = "auto", -- options: "cmp", "blink", "auto"
}

M.sanitizer = require("yaml-tags.sanitizer")
M.extractor = require("yaml-tags.extractor")

local search_handler = require("yaml-tags.handlers.search")
local autocomplete_handler = require("yaml-tags.handlers.autocomplete")
local utils = require("yaml-tags.utils")

-- Function to check if a directory is excluded
local function is_excluded_directory(dir)
	for _, excluded in ipairs(M.config.excluded_directories) do
		if dir:find(excluded, 1, true) then
			return true
		end
	end
	return false
end

-- Function to check if a directory is included
local function is_included_directory(dir)
	if #M.config.included_directories == 0 then
		return true
	end

	local normalized_dir = utils.normalize_path(dir)
	for _, included in ipairs(M.config.included_directories) do
		local normalized_included = utils.normalize_path(included)
		if normalized_dir:find(normalized_included, 1, true) then
			return true
		end
	end
	return false
end

function M.setup(user_config)
	if user_config then
		if user_config.forbidden_words then
			if user_config.extend_forbidden_words then
				M.config.forbidden_words = vim.list_extend(M.config.forbidden_words, user_config.forbidden_words)
			else
				M.config.forbidden_words = user_config.forbidden_words
			end
			user_config.forbidden_words = nil
		end
		M.config = vim.tbl_extend("force", M.config, user_config)
	end
	-- Expand directories
	local expand_directory = function(dir)
		return vim.fn.expand(dir)
	end

	for i, dir in ipairs(M.config.excluded_directories) do
		M.config.excluded_directories[i] = expand_directory(dir)
	end

	for i, dir in ipairs(M.config.included_directories) do
		M.config.included_directories[i] = expand_directory(dir)
	end

	-- Notify user if configured plugins are missing
	if M.config.search_engine == "telescope" and not utils.is_plugin_installed("telescope") then
		vim.notify("Telescope is configured but not installed!", vim.log.levels.WARN)
	elseif M.config.search_engine == "fzf-lua" and not utils.is_plugin_installed("fzf-lua") then
		vim.notify("fzf-lua is configured but not installed!", vim.log.levels.WARN)
	elseif M.config.search_engine == "snacks" and not utils.is_plugin_installed("snacks") then
		vim.notify("fzf-lua is configured but not installed!", vim.log.levels.WARN)
	end

	if M.config.autocomplete_engine == "cmp" and not utils.is_plugin_installed("cmp") then
		vim.notify("cmp is configured but not installed!", vim.log.levels.WARN)
	elseif M.config.autocomplete_engine == "blink" and not utils.is_plugin_installed("blink") then
		vim.notify("blink is configured but not installed!", vim.log.levels.WARN)
	end
end

function M.initialize()
	local dir = utils.get_current_project_directory()
	if not dir or not utils.is_markdown_file() or is_excluded_directory(dir) or not is_included_directory(dir) then
		utils.log("Directory: [" .. (dir or "nul") .. "] not in a Markdown file or excluded directory")
		return
	end

	local wk = require("which-key")

	wk.add({
		mode = "n",
		{ "<leader>y", group = "+Y-Tags" },
		{
			"<leader>yt",
			function()
				search_handler.search_files_by_tag_under_cursor()
			end,
			desc = "Search Files by Tag Under Cursor",
		},
		{
			"<leader>yl",
			function()
				search_handler.list_tags_and_files()
			end,
			desc = "List Tags and Files",
		},
		{
			"<leader>ya",
			function()
				require("yaml-tags.selection_to_tags").selection_to_tags()
			end,
			desc = "Add tags from selection",
		},
	})
	wk.add({
		mode = "v",
		{ "<leader>y", group = "+Y-Tags" },
		{
			"<leader>ya",
			function()
				require("yaml-tags.selection_to_tags").selection_to_tags()
			end,
			desc = "Add tags from selection",
		},
	})

	-- Creating User Commands **SaveTags**
	vim.api.nvim_create_user_command("SaveTags", function()
		local directory = utils.get_current_project_directory()
		if directory then
			M.extractor.save_tags(directory)
		else
			vim.notify("Could not determine the current buffer directory.", vim.log.levels.ERROR)
		end
	end, {})

	-- Adding an action for WritePost event
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*.md",
		callback = function()
			M.extractor.initialize_plugin()
		end,
	})
	-- vim.api.nvim_create_autocmd("FileType", {
	-- 	pattern = "markdown",
	-- 	callback = function()
	-- 		require("yaml-tags.handlers.autocomplete").setup()
	-- 	end,
	-- })

	-- Set up an autocommand to sanitize YAML tags on save
	if M.config.sanitizer then
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.md",
			callback = function()
				M.sanitizer.sanitize_current_buffer()
			end,
		})
	end
	autocomplete_handler.setup()
end

-- function M.autocomplete(...)
-- 	autocomplete_handler.complete(...)
-- end

return M
