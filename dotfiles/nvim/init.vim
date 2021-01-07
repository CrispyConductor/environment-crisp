" General options
set background=dark
set updatetime=100
set guicursor=

" Mappings
map <M-n> :NERDTreeToggle<CR>

" EasyMotion mappings and settings
let g:EasyMotion_do_mapping = 0 " disable easymotion default mappings
let g:EasyMotion_smartcase = 1
nmap s <Plug>(easymotion-overwin-f2)
vmap s <Plug>(easymotion-f2)
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)

" VimPlug plugins
call plug#begin('~/.local/share/nvim/plugged')
Plug 'brooth/far.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-sleuth'
Plug 'airblade/vim-gitgutter'
call plug#end()

" hooks for clipboard syncing
source ~/.userenv/clipboard/vimhooks.vim

" Vundle Plugins (and extra options required by Vundle)
set nocompatible
filetype off
set rtp+=~/.local/share/nvim/Vundle.vim
call vundle#begin('~/.local/share/nvim/bundle')
Plugin 'VundleVim/Vundle.vim'
Plugin 'easymotion/vim-easymotion'
call vundle#end()
filetype plugin indent on
" To ignore plugin indent changes, instead use:
"filetype plugin on



