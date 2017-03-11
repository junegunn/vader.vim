#!/usr/bin/env bash

# Do not "cd" to any existing "test" dir from CDPATH!
unset CDPATH

: "${TEST_VIM:=vim}"

cd "$( dirname "${BASH_SOURCE[0]}" )" && $TEST_VIM -Nu vimrc -c 'Vader! *' > /dev/null
