" General options
set background=dark
set updatetime=100
set guicursor=
set nomodeline

" Execute .nvimrc in working directory
set exrc
set secure

" Folding (fold on indent, unfolded by default)
set foldmethod=indent
" Don't ignore comments for folding
set foldignore=
augroup foldstuff
	autocmd BufWinEnter * normal zR
augroup END

" Mappings
map <M-n> :NERDTreeToggle<CR>
map <M-f> :FZF<CR>

" Far configuration
let g:far#source = 'rg'
let g:far#debug = 1
let g:far#glob_mode = 'native'
let g:far#auto_preview = 0
let g:far#auto_preview_on_start = 0
let g:far#open_in_parent_window = 1


" Far aliases
" command! -nargs=1 Fjs F <args> **/*.js --ignore node_modules
" command! -nargs=* Farjs Far <args> **/*.js --ignore node_modules
" command! -nargs=1 Fpy F <args> **/*.py
" command! -nargs=* Farpy Far <args> **/*.py

" EasyMotion mappings and settings
let g:EasyMotion_do_mapping = 0 " disable easymotion default mappings
let g:EasyMotion_smartcase = 1
" nmap s <Plug>(easymotion-overwin-f2)
nmap s <Plug>(easymotion-s)
vmap s <Plug>(easymotion-s)
nmap SS <Plug>(easymotion-s2)
vmap SS <Plug>(easymotion-s2)
map Sj <Plug>(easymotion-j)
map Sk <Plug>(easymotion-k)

" hooks for clipboard syncing
source ~/.userenv/clipboard/vimhooks.vim

" pane navigation integration
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
map <silent> <M-w>U :call PaneNavTmuxTry('U')<CR>
map <silent> <M-w>D :call PaneNavTmuxTry('D')<CR>
map <silent> <M-w>L :call PaneNavTmuxTry('L')<CR>
map <silent> <M-w>R :call PaneNavTmuxTry('R')<CR>
imap <silent> <M-w>U <Esc>:call PaneNavTmuxTry('U')<CR>
imap <silent> <M-w>D <Esc>:call PaneNavTmuxTry('D')<CR>
imap <silent> <M-w>L <Esc>:call PaneNavTmuxTry('L')<CR>
imap <silent> <M-w>R <Esc>:call PaneNavTmuxTry('R')<CR>

" VimPlug plugins
call plug#begin('~/.local/share/nvim/plugged')
Plug 'brooth/far.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-sleuth'
Plug 'airblade/vim-gitgutter'
Plug '~/.fzf'
call plug#end()


" Vundle Plugins (and extra options required by Vundle)
set nocompatible
filetype off
set rtp+=~/.local/share/nvim/bundle/Vundle.vim
call vundle#begin('~/.local/share/nvim/bundle')
Plugin 'VundleVim/Vundle.vim'
Plugin 'easymotion/vim-easymotion'
call vundle#end()
filetype plugin indent on
" To ignore plugin indent changes, instead use:
"filetype plugin on



