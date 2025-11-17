---@module 'blink.cmp'

local utils = require("yaml-tags.utils")
local extractor = require("yaml-tags.extractor")

---@type blink.cmp.Source
local M = {}

function M.new()
	-- vim.notify("blink.cmp.Source.new called", vim.log.levels.INFO)
	return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
	return { "-", " " }
end

function M:enabled()
	local filetypes = { "markdown", "md" }
	return vim.tbl_contains(filetypes, vim.bo.filetype)
end

function M:get_completions(ctx, callback)
	local transformed_callback = function(items)
		callback({
			context = ctx,
			is_incomplete_forward = false,
			is_incomplete_backward = false,
			items = items,
		})
	end

	if not utils.in_tags_section() then
		transformed_callback({})
		return function() end
	end

	local results = extractor.get_tags()

	if not results or #results == 0 then
		transformed_callback({})
		return function() end
	end

	---@type table<string,lsp.CompletionItem>
	local items = {}

	for _, item in ipairs(results) do
		table.insert(items, {
			label = item,
			dup = 1,
			insertText = item,
			labelDetails = "Y-tag",
			documentation = "",
			-- kind = vim.lsp.protocol.CompletionItemKind.Text,
		})
	end

	transformed_callback(vim.tbl_values(items))

	return function() end
end

return M
