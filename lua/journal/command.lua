local M = {}

local fs = require('journal.filesystem')
local config = require('journal.config').get()
local log = require('journal.logging')

local parse_entry = function(args)
	local current_type = config.journal

	while current_type ~= nil and args.len() > 0 and current_type.entries ~= nil do
		local next_type = current_type.entries[args[1]]

		if next_type == nil then
			break
		end

		current_type = next_type
		table.remove(args, 1)
	end

	return current_type
end

local function parse_entry_arg_array(array_str)
	local array = {}

	for word in string.gmatch(array_str, '([^,]+)') do
		table.insert(array, word)
	end

	return array
end

local function parse_entry_arg_string(string_str)
	return string_str
end

local function parse_entry_args(entry, args)
	local entry_args = {}

	while args.len() > 0 do
		local arg = args[1]
		local arg_name = ''

		if arg:sub(1, 1) ~= '-' then
			log.warn('Invalid - in arguments')
			return nil
		end

		local i = 1
		local c = arg:sub(i, i)
		while c ~= '=' do
			arg_name = arg_name .. c
			i = i + 1
			c = arg:sub(i, i)
		end

		i = i + 1
		local arg_length = arg.len()
		local str_left = arg:sub(i, arg_length)
		local entry_arg_type = entry.args[arg_name]

		if entry_arg_type == 'string' then
			entry_args[arg_name] = parse_entry_arg_string(str_left)
		elseif entry_arg_type == 'array' then
			entry_args[arg_name] = parse_entry_arg_array(str_left)
		end
	end

	return entry_args
end

M.execute = function(args)
	local entry_config, entry_args = M.parse_command(args)

	if entry_config == nil or entry_args == nil then
		log.warn('Parsing failed')
		return false
	end

	fs.open_entry(Date:today(), entry_config, entry_args)

	return true
end

M.parse_command = function(args)
	local entry = parse_entry(args)
	local entry_args = parse_entry_args(entry, args)

	if (entry_args == nil) then
		log.warn('Invalid entry arguments')
		return nil, nil
	end

	return entry, entry_args
end


return M
