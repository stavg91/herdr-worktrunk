#!/usr/bin/env bash
plugin_root=${HERDR_PLUGIN_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}
source "$plugin_root/config.sh"
source "$plugin_root/helpers.sh"

LOG=/tmp/worktrunk-pane-debug.log
{
  echo "=== $(date) ==="
  echo "TTY stdin: $(test -t 0 && echo YES || echo NO)"
  echo "TTY stdout: $(test -t 1 && echo YES || echo NO)"
  echo "TERM=$TERM"
  echo "SHELL=$SHELL"
  echo "BASH=$BASH"
  echo "PATH=$PATH"
  echo "fzf=$(which fzf 2>&1)"
  echo "wt=$(which wt 2>&1)"
  echo "jq=$(which jq 2>&1)"
  echo "herdr=$(which herdr 2>&1)"
  echo "HERDR_PLUGIN_ROOT=$HERDR_PLUGIN_ROOT"
  echo "HERDR_BIN_PATH=$HERDR_BIN_PATH"
  echo "HERDR_PLUGIN_ENTRYPOINT_ID=$HERDR_PLUGIN_ENTRYPOINT_ID"
  echo "HERDR_WORKSPACE_ID=$HERDR_WORKSPACE_ID"
  echo "HERDR_PANE_ID=$HERDR_PANE_ID"
  echo "PWD=$PWD"
  echo "worktrunk_bin=$(worktrunk_bin 2>&1)"
  echo ""
  echo "=== wt list ==="
  "$(worktrunk_bin)" list --format=json 2>&1 | head -5
  echo ""
  echo "=== git for-each-ref ==="
  git for-each-ref --format='%(refname) %(refname:short)' refs/heads 2>&1 | head -5
  echo ""
  echo "=== done ==="
} > "$LOG" 2>&1
sleep 3
