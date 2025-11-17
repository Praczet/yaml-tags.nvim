local M = {}
local utils = require("yaml-tags.utils")

-- Autocomplete implementation for cmp
local function cmp_setup()
	vim.notify("cmp_setup", vim.log.levels.INFO)
end

-- Autocomplete implementation for blink
local function blink_setup() end

-- Public autocomplete function
function M.setup()
	if utils.is_plugin_installed("cmp") then
		cmp_setup()
	elseif utils.is_plugin_installed("blink.cmp") then
		blink_setup()
	else
		vim.notify("Neither cmp nor blink is installed!", vim.log.levels.ERROR)
	end
end

return M
