local M = {}

M.extractor = require("yaml-tags.tags_extractor")
M.completion = require("yaml-tags.tags_completion")

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

function M.setup()
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
end

-- Autocommand to setup nvim-cmp only for Markdown files
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "markdown",
--   callback = function()
--     require("yaml-tags").setup()
--   end,
-- })
-- M.setup()

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
