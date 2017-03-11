#!/usr/bin/env bash

# Use privileged mode to discard CDPATH, -e to exit on errors.
set -ep
cd "$( dirname "${BASH_SOURCE[0]}" )"

: "${TEST_VIM:=vim}"

ret=0

echo '• Running vader tests..'
if ! $TEST_VIM -Nu vimrc -c 'Vader! *' > /dev/null; then
  ret=1
fi

if hash tmux 2>/dev/null; then
  echo '• Running integration tests..'
  if ! integration/run.sh; then
    (( ret+= 2 ))
  fi
else
  echo '• Skipping integration tests: tmux not found.'
fi
exit $ret
