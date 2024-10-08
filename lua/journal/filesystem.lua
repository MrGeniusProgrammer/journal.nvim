local M = {}

local config = require('journal.config').get()
local log = require('journal.logging')
local utils = require('journal.utils')

local function get_entry_path(date, format)
	local dir = config.root()

	if dir == nil then
		return
	end

	local journal_dir = vim.fn.expand(dir)
	local filepath = journal_dir .. '/' .. os.date(format, os.time(date.date)) .. '.' .. config.filetype()

	if utils.is_windows() then
		filepath = utils.translate_to_windows_path(filepath)
	end

	return vim.fn.expand(filepath)
end

local function entry_exists(entry)
	return vim.fn.filereadable(entry) == 1
end

local function create_directories(entry)
	local dirname = vim.fs.dirname(entry)
	return vim.fn.mkdir(dirname, 'p')
end

local function create_entry(entry, date, template_function, args)
	local template_string = date:to_format(template_function(date, args))

	local file = io.open(entry, 'w')

	if file == nil then
		log.warn('Error creating file')
		return
	end

	file:write(template_string)
	file:close()
end


local function create_if_not_exists(entry, date, template_function, args)
	if not entry_exists(entry) then
		create_directories(entry)
		create_entry(entry, date, template_function, args)
	end
end

local function open_file(file)
	vim.cmd('e ' .. file)
end

M.open_entry = function(date, entry_config, entry_args)
	local template_function = entry_config.template or function() return '' end
	local journal_file = get_entry_path(date, entry_config.format(date, entry_args))

	if journal_file == nil then
		return
	end

	create_if_not_exists(journal_file, date, template_function, entry_args)
	open_file(journal_file)
end

return M
