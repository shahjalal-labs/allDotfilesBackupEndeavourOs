--w: 1╭──────────── Block Start ────────────╮
--p: Open current file in browser (firefox/chrome)
local function open_with_firefox_or_chrome(filepath)
	local browser
	if vim.fn.executable("firefox") == 1 then
		browser = "firefox"
	elseif vim.fn.executable("google-chrome") == 1 then
		browser = "google-chrome"
	else
		print("❌ Neither firefox nor google-chrome found.")
		return
	end
	vim.fn.jobstart({ browser, filepath }, { detach = true })
	print("🌐 Opened with " .. browser .. ": " .. filepath)
end

vim.keymap.set({ "n", "i" }, "<space>sa", function()
	local filepath = vim.fn.expand("%:p")
	if filepath == "" then
		print("❌ No file to open.")
		return
	end
	open_with_firefox_or_chrome(filepath)
end, { desc = "Open current file in browser (firefox/chrome)" })

--w: 1╰───────────── Block End ─────────────╯
--
--w: 1╭──────────── Block Start ────────────╮
-- Function to yank file path relative to Git root or CWD
local function yank_relative_path()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	local file_abs = vim.fn.expand("%:p")
	local path

	if git_root and git_root ~= "" then
		path = vim.fn.fnamemodify(file_abs, ":." .. git_root)
		print("Yanked file path relative to Git root: " .. path)
	else
		local cwd = vim.fn.getcwd()
		path = vim.fn.fnamemodify(file_abs, ":." .. cwd)
		print("Yanked file path relative to CWD: " .. path)
	end

	vim.fn.setreg("+", path)
end

-- Keymap with description
vim.keymap.set("n", "<leader>sr", yank_relative_path, {
	noremap = true,
	silent = true,
	desc = "Yank current file's relative path to clipboard",
})

--w: 1╰───────────── Block End ─────────────╯

--
--w: 2╭──────────── Block Start ────────────╮
--t:copy the absolute path of the current file in Neovim using space sj
vim.api.nvim_set_keymap("n", "<space>sj", ":lua CopyAbsolutePath()<CR>", { noremap = true, silent = true })

function CopyAbsolutePath()
	local file_path = vim.fn.expand("%:p") -- Get the absolute path of the current file
	vim.fn.setreg("+", file_path) -- Copy the path to the system clipboard
	print("Copied path: " .. file_path)
end
--w: 2╰───────────── Block End ─────────────╯
--
--
--
--w: 3╭──────────── Block Start ────────────╮
-- Generate clean directory tree markdown with clipboard and open
local function generate_structure_md()
	local cwd = vim.fn.getcwd()
	local output_file = cwd .. "/structure.md"

	local handle = io.popen("tree -C -I '.git|node_modules|.DS_Store|dist'")
	if not handle then
		vim.notify("❌ Failed to run tree command.", vim.log.levels.ERROR)
		return
	end

	local result = handle:read("*a")
	handle:close()

	-- Remove ANSI color codes
	result = result:gsub("\27%[[0-9;]*m", "")

	local md_content = "# 📁 Project Structure\n\n```bash\n" .. result .. "\n```\n"

	-- Write to file
	local file = io.open(output_file, "w")
	if not file then
		vim.notify("❌ Cannot open structure.md for writing.", vim.log.levels.ERROR)
		return
	end

	file:write(md_content)
	file:close()

	-- Open the file in a new tab
	vim.cmd("edit " .. output_file)

	-- Copy to system clipboard
	vim.fn.setreg("+", md_content)
	vim.notify("✅ structure.md created, opened, and copied to clipboard.", vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>ds", generate_structure_md, {
	noremap = true,
	silent = true,
	desc = "🗂️ Generate structure.md and copy",
})
--w: 3╰───────────── Block End ─────────────╯
