if vim.g.started_by_firenvim then
	-- General configuration for Firenvim
	vim.g.firenvim_config = {
		globalSettings = {
			alt = "all",
		},
		localSettings = {
			[".*"] = {
				cmdline = "neovim",
				priority = 0,
				selector = "textarea",
				takeover = "never",
			},
		},
	}

	-- Setup function for Firenvim
	local function setup_firenvim()
		vim.opt.filetype = "markdown"
		vim.opt.ruler = false
		vim.opt.showcmd = false
		vim.opt.laststatus = 0
		vim.opt.showtabline = 0
	end

	-- Autocommand group for Firenvim
	vim.api.nvim_create_augroup("Firenvim", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = "Firenvim",
		pattern = "text",
		callback = setup_firenvim,
	})
end

--w: Map space bk to set lines to 100 for firenvim
vim.api.nvim_set_keymap("n", "<Space>bk", ":set lines=80<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<Space>bk", ":set lines=100<CR>", { noremap = true, silent = true })

--
--
--
--
--
--w: open github live site with  browser dynamically find the live site url and open it in the browser
local function open_github_pages()
	-- Get the remote URL of the GitHub repository
	local handle = io.popen("git config --get remote.origin.url")
	if not handle then
		return
	end
	local repo_url = handle:read("*a"):gsub("%s+", "") -- Trim whitespace
	handle:close()

	-- Extract GitHub username and repo name using pattern matching
	local username, repo = repo_url:match("github%.com[:/]([^/]+)/([^%.]+)")

	if username and repo then
		-- Construct the GitHub Pages URL
		local gh_pages_url = string.format("https://%s.github.io/%s/", username, repo)

		-- Print the URL and open it in Google Chrome
		print("Opening: " .. gh_pages_url)
		-- os.execute("firefox '" .. gh_pages_url .. "' &")
		os.execute("xdg-open '" .. gh_pages_url .. "' &")
	else
		print("❌ Not a valid GitHub repository!")
	end
end

-- Map it to a Neovim command
vim.api.nvim_create_user_command("OpenGitHubPages", open_github_pages, {})

-- Map it to <leader>gu
vim.keymap.set("n", "<leader>gu", open_github_pages, { noremap = true, silent = true })

-- Function to prompt for old_text/new_text in a single input, then run :%s/old_text/new_text/c
local function interactive_replace()
	-- Prompt for input in the format "old_text/new_text"
	local input = vim.fn.input("Enter old_text/new_text: ")
	if input == "" then
		print("No input entered. Aborting.")
		return
	end

	-- Split the input into old_text and new_text
	local old_text, new_text = input:match("([^/]+)/(.+)")
	if not old_text or not new_text then
		print("Invalid input format. Use 'old_text/new_text'.")
		return
	end

	-- Construct and run the substitute command
	local cmd = string.format("%%s/%s/%s/gc", vim.fn.escape(old_text, "/\\"), vim.fn.escape(new_text, "/\\"))
	vim.cmd(cmd)
end

vim.keymap.set(
	{ "n", "i" },
	"<M-f>",
	interactive_replace,
	{ noremap = true, silent = false, desc = "Interactive search and replace" }
)

--w: open the project with vite
-- Add this to your Neovim config (init.lua)
-- Add to your Neovim config (init.lua)
vim.keymap.set("n", "<leader>ai", function()
	-- Check if we're in a project with Vite
	local has_vite = vim.fn.filereadable("node_modules/.bin/vite") == 1

	if not has_vite then
		vim.notify("Vite not found in current project", vim.log.levels.ERROR)
		return
	end

	-- Check if we're in tmux
	if vim.env.TMUX == nil then
		vim.notify("Not in a tmux session", vim.log.levels.ERROR)
		return
	end

	-- List available panes and prompt for selection
	local tmux_panes = vim.fn.system('tmux list-panes -F "#{pane_index}"')
	vim.ui.select(vim.split(tmux_panes, "\n", { trimempty = true }), {
		prompt = "Select tmux pane to run Vite:",
	}, function(pane)
		if pane then
			-- Send command to selected tmux pane
			vim.fn.system(string.format('tmux send-keys -t %s "npx vite" Enter', pane))
			vim.notify("Vite server started in tmux pane " .. pane, vim.log.levels.INFO)
		end
	end)
end, { noremap = true, silent = true, desc = "Start Vite in tmux pane" })

--w: Jump inside next curly braces (insert mode)
-- vim.keymap.set("i", "<leader>k", "<Esc>/{<CR>a<CR><Esc>O")
-- Jump inside next curly braces (normal mode)
vim.keymap.set("n", "<leader>k", "/{<CR>:nohlsearch<CR>a<CR><Esc>O")

-- Jump inside next curly braces (insert mode)
vim.keymap.set("i", "<leader>kk", "<Esc>/{<CR>:nohlsearch<CR>a<CR><Esc>O")

vim.keymap.set("n", "<M-,>", "Iexport <Esc>", {

	noremap = true,
	silent = true,
})
vim.keymap.set("i", "<M-,>", "<C-o>Iexport <Esc>", {

	noremap = true,
	silent = true,
})

local function run_clipboard_command()
	-- Get clipboard content
	local command = vim.fn.getreg("+"):gsub("\n", "") -- Remove newlines

	if command == "" then
		vim.notify("Clipboard is empty!", vim.log.levels.WARN)
		return
	end

	-- Notify user that command is running
	vim.notify("Running: " .. command, vim.log.levels.INFO)

	-- Start job to run command and capture output
	vim.fn.jobstart(command, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
			end
		end,
	})
end

-- Use `vim.keymap.set` which works better with Lua functions
vim.keymap.set("n", "<leader>rr", run_clipboard_command, { noremap = true, silent = true })

-- new verSion
-- Define a function to run a shell command
function RunCommand()
	-- Get the current line (assumed to be the shell command)
	local line = vim.api.nvim_get_current_line()

	-- Execute the command asynchronously
	vim.fn.jobstart(line, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
			end
		end,
	})

	-- Clear the line after execution
	vim.api.nvim_set_current_line("")

	-- Display a notification to indicate command is running
	vim.notify("Executing: " .. line, vim.log.levels.INFO)
end

-- Create a custom command ':RunCommand'
vim.api.nvim_command("command! RunCommand lua RunCommand()")

-- Bind 'Ctrl+A' to the custom command in Normal, Insert, and Visual modes
vim.api.nvim_set_keymap("n", "<C-A>", ":RunCommand<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-A>", ":RunCommand<CR>", { noremap = true, silent = true })

-- b alt
-- Define a function to run a shell command with a new name
function RunAltCommand()
	-- Get the current line (assumed to be the shell command)
	local line = vim.api.nvim_get_current_line()

	-- Execute the command asynchronously
	vim.fn.jobstart(line, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
			end
		end,
	})

	-- Display a notification to indicate command is running
	vim.notify("Executing: " .. line, vim.log.levels.INFO)

	-- The line will not be cleared automatically, leaving the command as is
end

-- Create a custom command ':RunAltCommand'
vim.api.nvim_command("command! RunAltCommand lua RunAltCommand()")

-- Bind 'Alt+A' to the custom command in Normal, Insert, and Visual modes
vim.api.nvim_set_keymap("n", "<A-A>", ":RunAltCommand<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-A>", ":RunAltCommand<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-A>", ":RunAltCommand<CR>", { noremap = true, silent = true })

-- new feature two

-- Function to run the current line or selected text in a Tmux pane
function RunInTmuxPane()
	local mode = vim.fn.mode()
	local command = ""

	-- Check if we are in Visual mode
	if mode == "v" or mode == "V" then
		-- Get selected text in visual mode
		vim.cmd('normal! gv"xy') -- Copy selected text to register "x"
		command = vim.fn.getreg("x")
	else
		-- Get the current line in Normal mode
		command = vim.api.nvim_get_current_line()
	end

	-- Trim whitespace from the command
	command = command:gsub("^%s*(.-)%s*$", "%1")

	-- If there's no command, exit
	if command == "" then
		vim.notify("No command to execute!", vim.log.levels.WARN)
		return
	end

	-- Prompt user for the Tmux pane number
	local pane_number = vim.fn.input("Enter Tmux Pane Number: ")

	-- Ensure pane number is valid
	if pane_number == "" then
		vim.notify("Tmux pane number not provided!", vim.log.levels.ERROR)
		return
	end

	-- Execute the command in the specified Tmux pane
	local tmux_command = string.format('tmux send-keys -t %s "%s" Enter', pane_number, command)
	vim.fn.system(tmux_command)

	-- Show notification
	vim.notify("Sent to Tmux Pane " .. pane_number .. ": " .. command, vim.log.levels.INFO)
end

-- Bind the function to Alt + X for Normal & Visual modes
vim.api.nvim_set_keymap("n", "<A-d>", ":lua RunInTmuxPane()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-d>", "<Esc> :lua RunInTmuxPane()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-d>", ":lua RunInTmuxPane()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>hk", "@r", { noremap = true, silent = false })
-- vim.api.nvim_set_keymap("n", "t", "@r", { noremap = true, silent = false })

-- command from zsh history
-- ~/.config/nvim/lua/custom/zsh_history.lua
return function()
	local history_file = vim.fn.expand("~/.zsh_history")
	local history = vim.fn.readfile(history_file)

	if #history == 0 then
		print("No command history found.")
		return
	end

	require("fzf-lua").fzf_exec(history, {
		prompt = "Select Zsh command: ",
		actions = {
			["default"] = function(selected)
				vim.fn.system(selected[1])
				print("Running: " .. selected[1])
			end,
		},
	})
end

-- go to the react parent component
--
--
--
-- Function to send deploy command to tmux pane 3
-- Function to send a sequence of commands to tmux pane 3
