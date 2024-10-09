local M = {}

M.config = {
	commands = {},
	tmux_pane_height = 15,
}

local function get_command()
	local filetype = vim.bo.filetype
	local command = M.config.commands[filetype]
	if command then
		return command:gsub("{file}", vim.fn.expand("%:p"))
	end
	return nil
end

local function ensure_tmux_pane()
	if vim.fn.exists("$TMUX") == 0 then
		vim.notify("Not in a tmux session. Please run Neovim inside tmux.", vim.log.levels.ERROR)
		return false
	end

	local pane_id =
		vim.fn.system("tmux list-panes -F '#{pane_id}:#{pane_title}' | grep ZedRun | cut -d: -f1"):gsub("%s+", "")

	if pane_id == "" then
		vim.fn.system(
			string.format(
				"tmux split-window -v -l %d -d -P -F '#{pane_id}' 'printf \"\\033]2;ZedRun\\033\\\\\" && $SHELL'",
				M.config.tmux_pane_height
			)
		)
	else
		vim.fn.system("tmux select-pane -t " .. pane_id)
	end

	return true
end

function M.run()
	local command = get_command()
	if not command then
		vim.notify("No command configured for this filetype.", vim.log.levels.WARN)
		return
	end

	if ensure_tmux_pane() then
		vim.fn.system(
			string.format(
				"tmux send-keys -t $(tmux list-panes -F '#{pane_id}:#{pane_title}' | grep ZedRun | cut -d: -f1) '%s' C-m",
				command
			)
		)
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command("ZedRun", M.run, {})
end

return M
