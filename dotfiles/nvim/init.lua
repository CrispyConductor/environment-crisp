-- per nvim-tree: disable netrw at the very start of your init.lua (:help nvim-tree-netrw)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- General options
-- Color group
vim.o.background = 'dark'
-- Delay for writing swap file to disk
vim.o.updatetime = 100
-- No GUI cursor
vim.o.guicursor = ''
-- By default, don't set vim options on reading file
vim.o.modeline = false
-- When unloading a buffer, hide it and preserve history
vim.o.hidden = true

-- Execute .nvimrc in working directory
vim.o.exrc = true
-- Don't autoexecute scripts defined in current dir in case it's untrusted
vim.o.secure = true

-- Folding (fold on indent, unfolded by default)
vim.o.foldmethod = 'indent'
-- Don't ignore comments for folding
vim.o.foldignore = ''

vim.o.mouse = ''

-- Code AI config
-- copilot, codeium, none
local codingAIEngine = 'copilot'

-- Codeium config
if codingAIEngine == 'codeium' then
	vim.g.codeium_enabled = true
	vim.g.codeium_manual = false
end

-- Unfold everything when opening a window
vim.api.nvim_exec([[
	augroup foldstuff
		autocmd BufWinEnter * normal zR
	augroup END
]], false)

-- Nvim tree mapping
vim.api.nvim_set_keymap('', '<M-n>', ':NvimTreeToggle<CR>', {})

-- hooks for clipboard syncing
vim.api.nvim_command('source ~/.userenv/clipboard/vimhooks.vim')

-- pane navigation integration
vim.api.nvim_exec([[
	function! PaneNavTmuxTry(d)
		let wid = win_getid()
		if a:d == 'D'
			wincmd j
		elseif a:d == 'U'
			wincmd k
		elseif a:d == 'L'
			wincmd h
		elseif a:d == 'R'
			wincmd l
		endif
		if win_getid() == wid
			call system('tmux select-pane -' . a:d)
		endif
	endfunction
]], false)

vim.api.nvim_set_keymap('n', '<M-w>U', ':call PaneNavTmuxTry("U")<CR>', {silent = true})
vim.api.nvim_set_keymap('n', '<M-w>D', ':call PaneNavTmuxTry("D")<CR>', {silent = true})
vim.api.nvim_set_keymap('n', '<M-w>L', ':call PaneNavTmuxTry("L")<CR>', {silent = true})
vim.api.nvim_set_keymap('n', '<M-w>R', ':call PaneNavTmuxTry("R")<CR>', {silent = true})
vim.api.nvim_set_keymap('i', '<M-w>U', '<Esc>:call PaneNavTmuxTry("U")<CR>', {silent = true})
vim.api.nvim_set_keymap('i', '<M-w>D', '<Esc>:call PaneNavTmuxTry("D")<CR>', {silent = true})
vim.api.nvim_set_keymap('i', '<M-w>L', '<Esc>:call PaneNavTmuxTry("L")<CR>', {silent = true})
vim.api.nvim_set_keymap('i', '<M-w>R', '<Esc>:call PaneNavTmuxTry("R")<CR>', {silent = true})

-- Plugin setup

require('packer').startup(function(use)
	-- Package manager
	use 'wbthomason/packer.nvim'
	-- Language server
	if vim.fn.has('nvim-0.8.0') then
		use 'neovim/nvim-lspconfig'
	end
	-- File tree
	if vim.fn.has('nvim-0.8.0') then
		use 'nvim-tree/nvim-tree.lua'
	end
	-- Indentation detection
	use {
		'nmac427/guess-indent.nvim',
		config = function() require('guess-indent').setup {} end,
	}
	-- Git signs
	if vim.fn.has('nvim-0.8.0') then
		use 'lewis6991/gitsigns.nvim'
	end
	-- Telescope (Fuzzy find)
	if vim.fn.has('nvim-0.9.0') then
		use {
			'nvim-telescope/telescope.nvim',
			tag = '0.1.2',
			requires = { {'nvim-lua/plenary.nvim'} }
		}
	end
	-- Hop (easymotion)
	if vim.fn.has('nvim-0.5.0') then
		use {
			'phaazon/hop.nvim',
			branch = 'v2',
			config = function()
				require'hop'.setup({})
			end
		}
	end
	-- CodeiumAI
	if vim.fn.has('nvim-0.6.0') and codingAIEngine == 'codeium' then
		use 'Exafunction/codeium.vim'
	end
	-- CoPilot
	if vim.fn.has('nvim-0.6.0') and codingAIEngine == 'copilot' then
		use 'github/copilot.vim'
	end

end)


-- LSP
if vim.fn.has('nvim-0.8.0') then
	local lspconfig = require('lspconfig')
	if vim.fn.executable('typescript-language-server') then
		lspconfig.tsserver.setup({})
	end
	if vim.fn.executable('pyright') then
		lspconfig.pyright.setup({})
	end

	-- Global mappings.
	-- See `:help vim.diagnostic.*` for documentation on any of the below functions
	vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
	vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
	vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
	vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

	-- Diagnostics options
	vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
		vim.lsp.diagnostic.on_publish_diagnostics, {
		-- Enable/Disable signs (indicators on left)
		signs = true,
		-- Gray diagnostic text options
		virtual_text = {
			spacing = 2
		},
		-- Severe diagnostics first
		severity_sort = true
	})

	-- Use LspAttach autocommand to only map the following keys
	-- after the language server attaches to the current buffer
	vim.api.nvim_create_autocmd('LspAttach', {
		group = vim.api.nvim_create_augroup('UserLspConfig', {}),
		callback = function(ev)
			-- Enable completion triggered by <c-x><c-o>
			vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

			-- Buffer local mappings.
			-- See `:help vim.lsp.*` for documentation on any of the below functions
			local opts = { buffer = ev.buf }
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
			vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
			vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
			vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
			vim.keymap.set('n', '<space>wl', function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, opts)
			vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
			vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
			vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
			vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
			vim.keymap.set('n', '<space>f', function()
				vim.lsp.buf.format { async = true }
			end, opts)
		end,
	})
end


-- nvim-tree
if vim.fn.has('nvim-0.8.0') then
	require('nvim-tree').setup({})
end


-- Git signs
if vim.fn.has('nvim-0.8.0') then
	require('gitsigns').setup({})
end


-- Fuzzy find/Telescope
if vim.fn.has('nvim-0.9.0') then
	local telescopebuiltin = require('telescope.builtin')
	vim.keymap.set('n', '<leader>ff', telescopebuiltin.find_files, {})
	vim.keymap.set('n', '<M-f>', telescopebuiltin.find_files, {})
	vim.keymap.set('n', '<leader>fg', telescopebuiltin.live_grep, {})
	vim.keymap.set('n', '<leader>fb', telescopebuiltin.buffers, {})
	vim.keymap.set('n', '<leader>fh', telescopebuiltin.help_tags, {})
end


-- Hop
if vim.fn.has('nvim-0.5.0') then
	local hop = require('hop')
	local hopdirections = require('hop.hint').HintDirection
	vim.keymap.set({'n', 'v'}, 's', function() hop.hint_char1({}) end)
	vim.keymap.set({'n', 'v'}, 'SS', function() hop.hint_char2({}) end)
end



-- LSP
--if vim.fn.has('nvim-0.5.0') then
--	vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
--		vim.lsp.diagnostic.on_publish_diagnostics, {
--		-- Disable signs (indicators on left)
--		signs = false,
--		-- Diagnostic text option
--		virtual_text = {
--			spacing = 1
--		}
--	})
--
--	custom_lsp_attach = function(client)
--		-- Keybinds
--		-- See `:help nvim_buf_set_keymap()` for more information
--		vim.api.nvim_buf_set_keymap(0, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', {noremap = true})
--		vim.api.nvim_buf_set_keymap(0, 'n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>', {noremap = true})
--		-- Truncated for brevity...
--	end
--
--	if vim.fn.executable('typescript-language-server') then
--		require('lspconfig').tsserver.setup({on_attach = custom_lsp_attach})
--	end
--
--	if vim.fn.executable('pyright') then
--		require('lspconfig').pyright.setup({on_attach = custom_lsp_attach})
--	end
--end


