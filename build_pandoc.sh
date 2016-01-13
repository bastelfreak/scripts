#!/bin/bash

##
# this is intended to run on Arch
# written by bastelfreak
##

pacman -Syu cabal-install
cabal sandbox init
cabal update
cabal install pandoc
