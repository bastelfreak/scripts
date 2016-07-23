" git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
" vim +PluginInstall +qall
" mkdir ~/.vim/backupdir/
set nocompatible              " be iMproved, required
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin()
"Vundles
Bundle 'gmarik/vundle'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/syntastic'
Bundle 'scrooloose/nerdcommenter'
Bundle 'bling/vim-airline'
Bundle 'fs111/pydoc.vim'
Bundle 'tpope/vim-fugitive'
Bundle 'ajh17/Spacegray.vim'
Bundle 'rodjek/vim-puppet'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required


syntax on
set tabstop=2
set shiftwidth=2
set number
set backup
set expandtab
set softtabstop=2
set backupdir=~/.vim/backupdir/
set backupskip=~/.vim/backupdir/*
"set directory=/tmp
set writebackup
set autoindent
set hlsearch
set laststatus=2
set hidden
"set undofile
set undodir=~/.vim/undodir
set undolevels=1000 "maximum number of changes that can be undone
set undoreload=10000 "maximum number lines to save for undo on a buffer reload
cmap w!! w !sudo tee > /dev/null %

" Put plugins and dictionaries in this dir (also on Windows)
let vimDir = '$HOME/.vim'
let &runtimepath.=','.vimDir

" Keep undo history across sessions by storing it in a file
if has('persistent_undo')
    let myUndoDir = expand(vimDir . '/undodir')
    " Create dirs
    call system('mkdir ' . vimDir)
    call system('mkdir ' . myUndoDir)
    let &undodir = myUndoDir
    set undofile
endif

" Syntastic
let g:syntastic_error_symbol   = '✗'
let g:syntastic_warning_symbol = '?'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
nnoremap <leader>l :lcl<cr>
let g:syntastic_cpp_compiler_options = '-std=c++11'
set lcs=tab:⁞\ ,trail:X,nbsp:—,eol:·,precedes:<,extends:>
