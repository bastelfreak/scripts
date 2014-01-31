#!/bin/bash
echo "running emerge --sync"
sleep 5
emerge --sync --quiet
echo "running emerge --update -nd world"
sleep 5
emerge --update --ask --verbose --quiet-build -nd world
emerge --update --newuse --ask --verbose --quiet-build --deep --with-bdeps=y @world
echo "running emerge --depclean"
sleep 5
emerge --ask --verbose --depclean
echo "running revdep-rebuild"
sleep 5
revdep-rebuild
echo "running emerge -av @preserved-rebuild"
sleep 5
emerge -av @preserved-rebuild

