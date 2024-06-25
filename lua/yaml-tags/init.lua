local M = {}

-- Default configuration
M.config = {
	sanitizer = true,
	tag_formatting = {
		allow_camel_case = false,
		allowed_characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
	},
	forbidden_words = { "and", "is", "or", "a", "the", "not" },
	excluded_directories = {},
	included_directories = {},
}

M.extractor = require("yaml-tags.tags_extractor")
M.completion = require("yaml-tags.tags_completion")
M.sanitizer = require("yaml-tags.tags_sanitizer")

-- Function to check if the current buffer is a Markdown file
local function is_markdown_file()
	return vim.bo.filetype == "markdown"
end

local cmp = require("cmp")

function M.setup_cmp()
	cmp.setup.filetype("markdown", {
		sources = cmp.config.sources({
			{ name = "ytags" },
			{ name = "buffer" },
			{ name = "path" },
			{ name = "nvim_lsp" },
			{ name = "codeium" },
			{ name = "snippets" },
		}),
	})
end
-- Function to get the directory of the current buffer
local function get_current_buffer_directory()
	local buf_path = vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		return nil
	end
	local dir = buf_path:match("(.*/)")
	return vim.fn.expand(dir)
end

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
	for _, included in ipairs(M.config.included_directories) do
		if dir:find(included, 1, true) then
			return true
		end
	end
	return false
end

function M.setup(user_config)
	M.config = vim.tbl_extend("force", M.config, user_config or {})
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
end

function M.initialize()
	local dir = get_current_buffer_directory()
	if not dir or not is_markdown_file() or is_excluded_directory(dir) or not is_included_directory(dir) then
		return
	end

	M.extractor.initialize_plugin()
	M.completion.initialize_plugin()
	M.setup_cmp()

	vim.cmd([[
        augroup MarkdownYAMLTags
            autocmd!
            autocmd FileType markdown lua require'yaml-tags'.setup_cmp()
        augroup END
    ]])

	require("which-key").setup({})
	local wk = require("which-key")

	wk.register({
		n = {
			name = "Y-Tags", -- Prefix group name
			t = {
				'<cmd>lua require("yaml-tags.tags_completion").search_files_by_tag_under_cursor()<CR>',
				"Search Files by Tag Under Cursor",
			},
			l = {
				'<cmd>lua require("yaml-tags.tags_telescope").telescope_list_tags_and_files()<CR>',
				"List Tags and Files",
			},
			a = {
				'<cmd>lua require("yaml-tags.selection_to_tags").selection_to_tags()<CR>',
				"Add tags from selection",
			},
		},
	}, { prefix = "<leader>", mode = "n" })
	wk.register({
		n = {
			name = "Y-Tags", -- Prefix group name
			a = {
				'<cmd>lua require("yaml-tags.selection_to_tags").selection_to_tags()<CR>',
				"Add tags from selection",
			},
		},
	}, { prefix = "<leader>", mode = "v" })

	-- Set up an autocommand to sanitize YAML tags on save
	if M.config.sanitizer then
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.md",
			callback = function()
				M.sanitizer.sanitize_current_buffer()
			end,
		})
	end
end

return M
