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
set undofile
set undodir=~/.vim/undodir
set undolevels=1000 "maximum number of changes that can be undone
set undoreload=10000 "maximum number lines to save for undo on a buffer reload
cmap w!! w !sudo tee > /dev/null %
