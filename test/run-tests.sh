#!/usr/bin/env bash

# Use privileged mode to discard CDPATH, -e to exit on errors.
set -ep
cd "$( dirname "${BASH_SOURCE[0]}" )"

: "${TEST_VIM:=vim}"

$TEST_VIM -Nu vimrc -c 'Vader! *' > /dev/null

if hash tmux 2>/dev/null; then
  integration/run.sh
else
  echo 'Skipping integration tests: tmux not found.' >&2
fi
