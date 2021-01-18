" General options
set background=dark
set updatetime=100
set guicursor=

" Folding (fold on indent, unfolded by default)
set foldmethod=indent
" Don't ignore comments for folding
set foldignore=
augroup foldstuff
	autocmd BufWinEnter * normal zR
augroup END

" Mappings
map <M-n> :NERDTreeToggle<CR>

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


" VimPlug plugins
call plug#begin('~/.local/share/nvim/plugged')
Plug 'brooth/far.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-sleuth'
Plug 'airblade/vim-gitgutter'
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



