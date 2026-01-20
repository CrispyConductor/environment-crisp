-- per nvim-tree: disable netrw at the very start of your init.lua (:help nvim-tree-netrw)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- General options
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
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
-- Don't fold by default
vim.o.foldenable = false

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

-- Define config file for OpenAI key and check if it exists
openaiKeyFile = vim.fn.expand('$HOME/.openai-api-key')
local enableChatGPT = vim.fn.filereadable(openaiKeyFile) == 1

-- Codeium config
if codingAIEngine == 'codeium' then
	vim.g.codeium_enabled = true
	vim.g.codeium_manual = false
end

-- Unfold everything when opening a window
--vim.api.nvim_exec([[
--	augroup foldstuff
--		autocmd BufWinEnter * normal zR
--	augroup END
--]], false)

-- Nvim tree mapping
vim.api.nvim_set_keymap('', '<M-n>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

-- Window maximize mapping
--vim.api.nvim_set_keymap('', '<M-z>', ':Maximize<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('', '<M-z>', ':ZenMode<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<M-z>', [[<C-\><C-n>:ZenMode<CR>]], { noremap = true, silent = true })

-- ChatGPT mapping
if enableChatGPT then
	vim.api.nvim_set_keymap('n', '<M-g>', ':ChatGPT<CR>', {})
end

-- Aider mapping
vim.api.nvim_set_keymap('', '<M-a>', ':Aider toggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<M-a>', [[<C-\><C-n>:Aider toggle<CR>]], { noremap = true, silent = true })

-- Avante mapping
vim.api.nvim_set_keymap('', '<M-v>', ':AvanteToggle<CR>', { noremap = true, silent = true })

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
vim.api.nvim_set_keymap('t', '<M-w>U', [[<C-\><C-n>:call PaneNavTmuxTry("U")<CR>]], {silent = true})
vim.api.nvim_set_keymap('t', '<M-w>D', [[<C-\><C-n>:call PaneNavTmuxTry("D")<CR>]], {silent = true})
vim.api.nvim_set_keymap('t', '<M-w>L', [[<C-\><C-n>:call PaneNavTmuxTry("L")<CR>]], {silent = true})
vim.api.nvim_set_keymap('t', '<M-w>R', [[<C-\><C-n>:call PaneNavTmuxTry("R")<CR>]], {silent = true})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Assemble the list of plugins to be installed
local pluginspec = {}

-- Dependencies
if vim.fn.has('nvim-0.5.0') then
	table.insert(pluginspec, { 'nvim-lua/plenary.nvim', lazy = true })
	table.insert(pluginspec, { 'MunifTanjim/nui.nvim', lazy = true })
end
if vim.fn.has('nvim-0.9.4') then
	table.insert(pluginspec, { 'folke/snacks.nvim', lazy = true })
end
if vim.fn.has('nvim-0.8.0') then
	table.insert(pluginspec, {
		'stevearc/dressing.nvim',
		lazy = true,
		opts = {
			input = {
				enabled = true
			},
			select = {
				enabled = true
			}
		}
	})
end
if vim.fn.has('nvim-0.10.1') then
	table.insert(pluginspec, { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', opts = {} })
end
-- Theme
if vim.fn.has('nvim-0.8.0') then
	table.insert(pluginspec, { "catppuccin/nvim", name = "catppuccin", priority = 1000 })
end
-- Language server
if vim.fn.has('nvim-0.10.0') then
	table.insert(pluginspec, { 'neovim/nvim-lspconfig', tag = 'v2.0.0' })
end
-- File tree
if vim.fn.has('nvim-0.8.0') then
	table.insert(pluginspec, {
		'nvim-tree/nvim-tree.lua',
		opts = {
			view = {
				width = {
					min = 8,
					max = 50
				}
			}
		}
	})
end
-- Indentation detection
table.insert(pluginspec, { 'nmac427/guess-indent.nvim', opts = {} })
-- Git signs
if vim.fn.has('nvim-0.8.0') then
	table.insert(pluginspec, { 'lewis6991/gitsigns.nvim', opts = {} })
end
-- Telescope (Fuzzy find)
if vim.fn.has('nvim-0.9.0') then
	table.insert(pluginspec, { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } })
end
-- Hop (easymotion)
if vim.fn.has('nvim-0.5.0') then
	table.insert(pluginspec, { 'smoka7/hop.nvim', opts = {} })
end
-- Maximize window
if vim.fn.has('nvim-0.8.0') then
	table.insert(pluginspec, { 'declancm/maximize.nvim', opts = {} })
end
-- Zen mode
if vim.fn.has('nvim-0.5.0') then
	table.insert(pluginspec, {
		'folke/zen-mode.nvim',
		opts = {
			window = {
				backdrop = 1,
				width = 0.95,
				height = 1
			}
		}
	})
end
-- CodeiumAI
if vim.fn.has('nvim-0.6.0') and codingAIEngine == 'codeium' then
	table.insert(pluginspec, { 'Exafunction/codeium.vim' })
end
-- CoPilot
if vim.fn.has('nvim-0.6.0') and codingAIEngine == 'copilot' then
	table.insert(pluginspec, { 'github/copilot.vim' })
end
-- GPT
if enableChatGPT then
	table.insert(pluginspec, {
		'jackMort/ChatGPT.nvim',
		opts = { api_key_cmd = "cat " .. openaiKeyFile },
		dependencies = {
			'MunifTanjim/nui.nvim',
			'nvim-lua/plenary.nvim',
			'nvim-telescope/telescope.nvim'
		}
	})
end
-- Aider
if vim.fn.has('nvim-0.9.4') then
	table.insert(pluginspec, {
		"GeorgesAlkhouri/nvim-aider",
		cmd = "Aider",
		keys = {
			{ "<M-a>", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
			{ "<leader>a/", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
			{ "<leader>as", "<cmd>Aider send<cr>", desc = "Send to Aider", mode = { "n", "v" } },
			{ "<leader>ac", "<cmd>Aider command<cr>", desc = "Aider Commands" },
			{ "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Send Buffer" },
			{ "<leader>a+", "<cmd>Aider add<cr>", desc = "Add File" },
			{ "<leader>a-", "<cmd>Aider drop<cr>", desc = "Drop File" },
			{ "<leader>ar", "<cmd>Aider add readonly<cr>", desc = "Add Read-Only" },
			-- nvim-tree.lua integration
			{ "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
			{ "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
		},
		dependencies = {
			"folke/snacks.nvim",
			--- The below dependencies are optional
			"catppuccin/nvim",
			"nvim-tree/nvim-tree.lua"
		},
		opts = {
			args = {
				'--no-auto-commits',
				'--pretty',
				'--stream',
				'--watch-files',
				'--subtree-only'
			}
		}
	})
end
-- Avante
if vim.fn.has('nvim-0.10.1') then
	table.insert(pluginspec, {
		'yetone/avante.nvim',
		event = 'VeryLazy',
		version = false,
		build = 'make',
		dependencies = {
			'nvim-treesitter/nvim-treesitter',
			'stevearc/dressing.nvim',
			'nvim-lua/plenary.nvim',
			'MunifTanjim/nui.nvim',
			'nvim-telescope/telescope.nvim',
		},
		opts = {
			provider = 'claude',
			behavior = {
				enable_claude_text_editor_tool_mode = true
			},
			mappings = {
				diff = {
					ours = "co",
					theirs = "ct",
					all_theirs = "ca",
					both = "cb",
					cursor = "cc",
					next = "]x",
					prev = "[x",
				},
				suggestion = {
					accept = "<M-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
				jump = {
					next = "]]",
					prev = "[[",
				},
				submit = {
					normal = "<CR>",
					insert = "<C-s>",
				},
				cancel = {
					normal = { "<C-c>", "<Esc>", "q" },
					insert = { "<C-c>" },
				},
				ask = '<leader>va',
				edit = '<leader>ve',
				refresh = '<leader>vr',
				focus = '<leader>vf',
				stop = '<leader>vS',
				toggle = {
					default = "<leader>vt",
					debug = "<leader>vd",
					hint = "<leader>vh",
					suggestion = "<leader>vs",
					repomap = "<leader>vR",
				},
				sidebar = {
					apply_all = "A",
					apply_cursor = "a",
					retry_user_request = "r",
					edit_user_request = "e",
					switch_windows = "<Tab>",
					reverse_switch_windows = "<S-Tab>",
					remove_file = "d",
					add_file = "@",
					close = { "q" },
					close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
				},
				files = {
					add_current = "<leader>vc", -- Add current buffer to selected files
					add_all_buffers = "<leader>vB", -- Add all buffer files to selected files
				},
				select_model = "<leader>v?", -- Select model command
				select_history = "<leader>vh", -- Select history command
			}
		}
	})
end


-- Initialize plugins via lazy.nvim
require("lazy").setup({
	spec = pluginspec,
	checker = {
		enabled = true,
		frequency = 86400
	}
})

-- Color scheme
if vim.fn.has('nvim-0.8.0') then
	vim.cmd.colorscheme "catppuccin"
end

-- LSP
if vim.fn.has('nvim-0.10.0') then
	local lspconfig = require('lspconfig')

	if vim.fn.executable('vue-language-server') then
		lspconfig.volar.setup{}
	end
	if vim.fn.executable('typescript-language-server') then
		-- String filename ~/.local/lib/node_modules/@vue/typescript-plugin
		local ts_plugin = vim.fn.glob('~/.local/lib/node_modules/@vue/typescript-plugin')
		-- If the directory exists ...
		if ts_plugin ~= '' then
			-- Initialize ts_ls with vue support
			lspconfig.ts_ls.setup{
				init_options = {
					plugins = {
						{
							name = "@vue/typescript-plugin",
							location = ts_plugin,
							languages = {"javascript", "typescript", "vue"},
						},
					},
				},
				filetypes = {
					"javascript",
					"typescript",
					"vue",
				},
			}
		else
			-- Initialize ts_ls without vue support
			lspconfig.ts_ls.setup{}
		end
	end
	if vim.fn.executable('pyright') then
		lspconfig.pyright.setup({})
	end
	if vim.fn.executable('rust-analyzer') then
		lspconfig.rust_analyzer.setup({})
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


-- Additional events to check for a modified file to reload
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "CursorHold", "WinEnter" }, {
	pattern = "*",
	command = "checktime"
})

-- Check for modified files every 10 seconds as long as there is user activity
vim.g.last_checktime = os.time()
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI", "InsertEnter", "InsertLeave" }, {
	pattern = "*",
	callback = function()
		local current_time = os.time()
		if current_time - vim.g.last_checktime >= 10 then
			vim.cmd("checktime")
			vim.g.last_checktime = current_time
		end
	end
})








