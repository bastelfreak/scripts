" git clone https://github.com/VundleVim/Vundle.vim ~/.vim/bundle/Vundle.vim
" vim +PluginInstall +qall
" mkdir -p ~/.vim/backupdir/
" mkdir ~/.vim/ftplugin
" echo "set colorcolumn=80" >> ~/.vim/ftplugin/tex.vim
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
Bundle 'bastelfreak/Spacegray.vim'
Bundle 'editorconfig/editorconfig-vim'
Bundle 'rodjek/vim-puppet'
Bundle 'junegunn/vim-easy-align'
Bundle 'vim-latex/vim-latex'
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
set incsearch "search while typing
cmap w!! w !sudo tee > /dev/null %

" mark hard tabs
highlight BadTab ctermbg=red guibg=red
match BadTab /\t\+/

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

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" all the tabs and spaces
highlight BadTabsAndSpaces ctermbg=red guibg=red
autocmd BufWinEnter * match BadTabsAndSpaces /\t\+\|\s\+$/

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

" enable spell checking in tex files
" switch between languages for checks: set spell spelllang=en_gb
au FileType tex setlocal spell
"set spell spelllang=en_gb

" all the tabs and spaces
highlight BadTabsAndSpaces ctermbg=red guibg=red
autocmd BufWinEnter * match BadTabsAndSpaces /\t\+\|\s\+$/

" disable folding in latex caused by vim-latex
" https://codeyarns.com/2013/05/01/how-to-disable-folding-in-vim-latex/
let g:Tex_FoldedSections     = ""
let g:Tex_FoldedEnvironments = ""
let g:Tex_FoldedMisc         = ""

" save command history and allow to yank 999 lines
" :help viminfo-!
:set viminfo='100,<1000,s100,h
