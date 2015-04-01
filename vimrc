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
