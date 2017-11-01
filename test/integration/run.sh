#!/usr/bin/env bash
#
# This runs tests against Vader running inside a tmux session.

# Use privileged mode to discard CDPATH, -e to exit on errors.
set -ep
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Config.
if [ -n "$CI" ]; then
  TMUX_ATTACH_ON_ERROR=0
else
  : "${TMUX_ATTACH_ON_ERROR:=1}"
fi
: "${TEST_VIM:=vim -X}"

# Remove --headless for Neovim.
TEST_VIM=${TEST_VIM/ --headless/}

: "${TEST_VIM_COMMAND:=env HOME=$PWD $TEST_VIM -Nu ../vimrc}"
# echo "TEST_VIM_COMMAND=$TEST_VIM_COMMAND" >&2

tmux='tmux -L vader_tests'

# Helpers {{{
wait_for_pane_contents() {
  pattern="$1"
  max_wait=10
  while (( --max_wait )); do
    printf '.'

    # Detect if Vim has started up. Do not check for contents in `:intro`, which
    # gets removed on SIGWINCH(?), when run via vim-dispatch.
    if $tmux capture-pane \; show-buffer | grep -q "$pattern"; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

attach_or_print_contents() {
  if [ "$TMUX_ATTACH_ON_ERROR" = 1 ]; then
    echo "Attaching to the tmux session.."
    $tmux attach
  else
    echo '===== tmux pane contents: ====='
    $tmux capture-pane \; show-buffer
    echo '==============================='
    $tmux kill-session
  fi
}

wait_for_vim_to_be_ready() {
  if ! wait_for_pane_contents 'VADER_VIM_READY'; then
    echo "✘ ($TEST_VIM has not become ready)" >&2
    attach_or_print_contents
    exit 3
  fi
}

fail_if_not_exited() {
  max_wait=10
  while (( --max_wait )); do
    if ! $tmux has-session 2>/dev/null; then
      return
    fi
    sleep 0.1
  done
  echo '✘ (did not exit)'
  attach_or_print_contents
  exit 3
}

start_session() {
  printf 'Running %s' "$1"
  $tmux new-session -d "$TEST_VIM_COMMAND \
    +'au VimEnter * echom \"VADER_VIM_READY\"' $1"
  wait_for_vim_to_be_ready
}
# }}}

start_session 'integration.vader'
$tmux send-keys ':Vader' C-m
$tmux send-keys ':if empty(AssertAfterVaderRun()) | qall | endif' C-m
fail_if_not_exited
echo '✔'

start_session 'doesnotexist.vader'
$tmux send-keys ':Vader' C-m
if ! wait_for_pane_contents 'Vader error: Vader: no tests found for patterns (doesnotexist.vader)'; then
  echo '✘'
  attach_or_print_contents
  exit 3
fi
echo '✔'
$tmux send-keys ':qall' C-m
fail_if_not_exited

start_session 'missing-include.vader'
$tmux send-keys ':Vader' C-m
if ! wait_for_pane_contents 'Vader error: Vim(echoerr):Cannot find doesnotexist.vader'; then
  echo '✘'
  attach_or_print_contents
  exit 3
fi
echo '✔'
$tmux send-keys ':qall' C-m
fail_if_not_exited

# vim: set foldmethod=marker
