local M = {}

local defaults = {
	root = '~/journal',
	journal = {
		args = {
			title = 'string',
		},
		format = function(date, args) return '%d-%m-%Y-' .. args.title end,
		template = function(date, args) return '# %d-%m-%Y ' .. args.title end,
	}
}

M.get = function()
	return defaults
end

local function merge_config(user_config, config)
	if user_config == nil then
		user_config = {}
	end
	for key, value in pairs(user_config) do
		if type(value) == string then
			config[key] = function() return value end
		end
		config[key] = value
	end
end

local function is_dict_like(tbl)
	return type(tbl) == 'table' and not vim.islist(tbl)
end

local function convert_strings_to_functions(config, include_keys)
	for key, value in pairs(config) do
		for include_key in include_keys do
			if key ~= include_key then
				goto continue
			end
		end

		if is_dict_like(config[key]) then
			convert_strings_to_functions(config[key], include_keys)
		else
			if type(value) == "string" then
				config[key] = function() return value end
			end
		end

		::continue::
	end
end

M.setup = function(user_config)
	merge_config(user_config, defaults)
	convert_strings_to_functions(defaults, { 'template', 'format' })
end

return M
