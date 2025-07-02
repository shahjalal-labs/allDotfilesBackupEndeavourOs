-- ╭──────────── Block Start ────────────╮

-- ╰───────────── Block End ─────────────╯

--w: 1╭──────────── Block Start ────────────╮
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
--
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
-- Generate clean directory tree markdown
local function generate_structure_md()
	local cwd = vim.fn.getcwd()
	local output_file = cwd .. "/structure.md"

	local handle = io.popen("tree -C -I '.git|node_modules|.DS_Store|dist'")
	if not handle then
		print("❌ Failed to run tree command.")
		return
	end

	local result = handle:read("*a")
	handle:close()

	-- Remove ANSI color codes
	result = result:gsub("\27%[[0-9;]*m", "")

	local file = io.open(output_file, "w")
	if not file then
		print("❌ Cannot open structure.md for writing.")
		return
	end

	file:write("# 📁 Project Structure\n\n")
	file:write("```bash\n")
	file:write(result)
	file:write("\n```\n")
	file:close()

	print("✅ structure.md updated successfully.")
end

vim.keymap.set("n", "<leader>ds", generate_structure_md, {
	noremap = true,
	silent = true,
	desc = "🗂️ Generate structure.md",
})
--w: 3╰───────────── Block End ─────────────╯
