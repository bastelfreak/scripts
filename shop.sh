#!/bin/bash
#
# shop - Show Permissions at all levels of a given path
#
#        With `tree(1)` you start at a trunk and show all leaves that
#        originate from that trunk, optionally showing permissions.
#        `shop` starts at a leaf and shows the permissions back to a
#        trunk.
#
# CREATED:  2009-09-03 17:30
# MODIFIED: 2009-11-17 11:05

# this script comes from the great bluewind (c)

_NAME=$(basename $0)
_VERSION=1.0

# DEFAULTS
unset octal               # use text mode instead of octal mode
level=-1                  # traverse all the way up to /
trunk='/'                 # traverse all the way up to /
pad=17                    # padding for pathname

usage() {
    cat <<EOT
Usage: $_NAME [-L N] [-o] [-t PATH] [PATH1..]

Options:
  -L, --level N      traverse N levels up the tree
  -o, --octal        show octal mode instead of human readable mode 
  -t, --trunk PATH   only traverse up to PATH instead of / (root)
                       - takes precedence over --level
  -p, --pad N        allow USER:GROUP N characters before directory name
                       default: 17

  -h, --help         show this message
      --version      show version info
EOT
}

_shop() {
    [ $octal ] && stat_str="%a" || stat_str="%A"

    stats=( $(stat -c "$stat_str %U:%G %n" "$1") )

    if [ $octal ]; then
        # `stat -c "%a"` only returns a 4 digit mode when the first digit is 
        # nonzero, yet `stat` always returns a 4 digit mode.  how annoying...
        [ ${#stats} -eq 3 ] && echo -n "0"
    fi    

    printf "%s %-${pad}s ${stats[@]:2}\n" "${stats[@]:0:2}"
}

main() {
    arg="$1"
    if [ -z "$arg" ]; then
        # user didn't supply an arg, use current working dir
        arg="$PWD"
    fi

    until [ -z "$arg" ]; do
        if ! [ -a "$arg" ]; then
             echo "error: $arg does not exist"
             return 1
        fi

        # if $arg is a directory, prime the directory stack, else use 
        # the parent dir of $arg to prime the stack
        if [ -d "$arg" ]; then
            cd "$arg" || return 1
            unset file_arg
        else
            cd $(dirname -- "$arg") || return 1
            file_arg=1
            let "level -=1"
        fi

        start_dir=$PWD

        # populate directory stack with $level levels on the path to
        # the $trunk
        while [ "$PWD" != "$trunk" ]; do
            if [ $level -gt 0 ] || [ $level -lt 0 ]; then
                let "level -= 1"
                pushd .. &> /dev/null 
            elif [ $level -eq 0 ]; then
                break;
            fi
        done

        # display the permissions for each level
        while [ "$PWD" != "$start_dir" ]; do
            _shop "$PWD"
            popd &> /dev/null
        done
        _shop "$PWD"

        # leaf was a file, run _shop on this file as well
        if [ $file_arg ]; then
            _shop "${PWD}/$(basename -- "$arg")"
        else
            cd .. || return 1
        fi

        # user passed multiple leafs, separate output for each leaf
        if [ $# -gt 1 ]; then
            echo
        fi

        shift
        arg="$1"
    done
}

declare -a args
until [ -z "$1" ]; do
    case "$1" in
        -L|--level) level="$2"
                    shift 2
                    ;;

        -o|--octal) octal=1
                    shift
                    ;;

        -t|--trunk) trunk="$(readlink -f $2)"
                    shift 2
                    ;;

        -p|--pad) pad="$2"
                  shift 2
                  ;;

        -h|--help) usage
                   exit
                   ;;

        --version) echo "$_NAME v$_VERSION"
                   exit
                   ;;

        --) shift
            args=( "${args[@]}" "$@" )
            break
            ;;

        -*) echo -e "$_NAME: unknown option: $1\n"
            usage
            exit
            ;;

        *) args[${#args[*]}]="$1"
           shift
           ;;
    esac
done

main "${args[@]}"
