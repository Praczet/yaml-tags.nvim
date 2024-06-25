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

function M.setup(user_config)
	M.config = vim.tbl_extend("force", M.config, user_config or {})
end

function M.initialize()
	if is_markdown_file() then
		M.extractor.initialize_plugin()
		M.completion.initialize_plugin()
		M.setup_cmp()
	end

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

return M
