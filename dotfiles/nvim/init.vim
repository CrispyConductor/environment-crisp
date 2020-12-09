set background=dark
set updatetime=100
set guicursor=

map <M-n> :NERDTreeToggle<CR>

call plug#begin('~/.local/share/nvim/plugged')
Plug 'brooth/far.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-sleuth'
Plug 'airblade/vim-gitgutter'
call plug#end()

