local Snacks = require("snacks")

local M = {}

-- Second picker: files for a specific tag
local function files_with_tag(opts)
	local dir = (opts.dir or ""):gsub("/$", "")
	local tag = opts.tag
	local results = opts.results or {}

	if not tag or #results == 0 then
		vim.notify("No files found for the tag: " .. (tag or "unknown"), vim.log.levels.WARN)
		return
	end

	local items = {}
	for _, file in ipairs(results) do
		local rel = file
		if dir ~= "" then
			rel = rel:gsub("^" .. vim.pesc(dir) .. "/?", "")
		end
		table.insert(items, {
			text = rel, -- what Snacks displays
			file = file, -- full path for opening / preview
		})
	end

	Snacks.picker.pick(nil, {
		title = "Files for tag: " .. tag,
		format = "text",
		finder = function()
			return items
		end,
		-- default preview is file preview, which is fine here (items have .file)
		actions = {
			confirm = function(picker, item)
				picker:close()
				if not item or not item.file then
					return
				end
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))
			end,
		},
	})
end

-- First picker: list of tags
function M.show_tags(tags)
	if not tags or vim.tbl_isempty(tags) then
		vim.notify("No tags available.", vim.log.levels.WARN)
		return
	end

	local items = {}
	for _, tag in ipairs(tags) do
		table.insert(items, {
			text = tag,
			tag = tag,
		})
	end

	Snacks.picker.pick(nil, {
		title = "YAML Tags",
		format = "text",
		finder = function()
			return items
		end,
		-- 🔹 Important: tags don't have `file`, so turn off file preview
		preview = function(_ctx)
			return false
		end,
		actions = {
			confirm = function(picker, item)
				if not item or not item.tag then
					return
				end

				local tag = item.tag
				local search = require("yaml-tags.handlers.search")
				local aFiles = search.search_files_by_tag(tag)

				if not aFiles or not aFiles.results or #aFiles.results == 0 then
					vim.notify("No files found for the tag: " .. tag, vim.log.levels.WARN)
					return
				end

				picker:close()

				files_with_tag({
					dir = aFiles.dir or "",
					tag = tag,
					results = aFiles.results,
				})
			end,
		},
	})
end

M.show_files_with_tag = files_with_tag

return M
