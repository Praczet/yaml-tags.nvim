local M = {}
-- Default configuration
M.config = {
	sanitizer = true,
}

M.extractor = require("yaml-tags.tags_extractor")
M.completion = require("yaml-tags.tags_completion")
M.sanitizer = require("yaml-tags.tags_sanitizer")

-- Function to check if the current buffer is a Markdown file
local function is_markdown_file()
	return vim.bo.filetype == "markdown"
end

-- Load necessary modules
local cmp = require("cmp")

-- Setup nvim-cmp for Markdown files
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

function M.setup(user_config)
	M.config = vim.tbl_extend("force", M.config, user_config or {})
end

function M.initialize()
	-- Set up your plugin setup here
	if is_markdown_file() then
		M.extractor.initialize_plugin()
		M.completion.initialize_plugin()
		M.setup_cmp()
	end

	-- Autocommand to setup nvim-cmp only for Markdown files
	vim.cmd([[
        augroup MarkdownYAMLTags
            autocmd!
            autocmd FileType markdown lua require'yaml-tags'.setup_cmp()
        augroup END
    ]])
	-- vim.api.nvim_set_keymap(
	-- 	"n",
	-- 	"<leader>nt",
	-- 	'<cmd>lua require("yaml-tags.tags_completion").search_files_by_tag_under_cursor()<CR>',
	-- 	{ noremap = true, silent = true }
	-- )
	-- vim.api.nvim_set_keymap(
	-- 	"n",
	-- 	"<leader>nl",
	-- 	'<cmd>lua require("yaml-tags.tags_telescope")()<CR>',
	-- 	{ noremap = true, silent = true }
	-- )
	-- Configure which-key
	require("which-key").setup({})

	-- Register your custom mappings
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
		},
	}, { prefix = "<leader>" })

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

-- M.initialize()

return M
-- local M = {}
--
-- M.extractor = require("yaml-tags.tags_extractor")
-- M.completion = require("yaml-tags.tags_completion")
-- --
-- -- Function to check if the current buffer is a Markdown file
-- local function is_markdown_file()
-- 	return vim.bo.filetype == "markdown"
-- end
--
-- -- Load necessary modules
-- local cmp = require("cmp")
--
-- -- Setup nvim-cmp for Markdown files
-- function M.setup_cmp()
-- 	M.completion.initialize_plugin()
-- 	cmp.setup.filetype("markdown", {
-- 		sources = cmp.config.sources({
-- 			{ name = "ytags" },
-- 			{ name = "buffer" },
-- 			{ name = "path" },
-- 		}),
-- 	})
--
-- 	-- Autocommand to enable completion in YAML front matter tags section
-- 	vim.cmd([[
--         augroup MarkdownYAMLTags
--             autocmd!
--             autocmd FileType markdown lua require'yaml-tags'.setup_cmp()
--         augroup END
--     ]])
-- end
--
-- function M.setup()
-- 	-- Set up your plugin setup here
-- 	if is_markdown_file() then
-- 		M.extractor.initialize_plugin()
-- 		M.completion.initialize_plugin()
-- 		M.setup_cmp()
-- 	end
-- end
--
-- M.setup()
--
-- return M
