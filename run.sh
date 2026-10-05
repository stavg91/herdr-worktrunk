#!/usr/bin/env bash
# Cross-platform launcher: exec the action script with the right shell.
#
# On macOS and Linux, bash is the system shell and inherits env vars natively.
# On Windows, bare "bash" resolves to WSL bash (C:\Windows\System32\bash.exe),
# which does NOT inherit Windows process env vars unless they are listed in
# WSLENV. Herdr sets HERDR_PLUGIN_ROOT, HERDR_PLUGIN_CONTEXT_JSON,
# HERDR_PLUGIN_CONFIG_DIR, HERDR_WORKSPACE_ID, and HERDR_BIN_PATH as Windows
# process env vars, so WSL bash never sees them. git-bash.cmd finds Git Bash
# (C:\Program Files\Git\usr\bin\bash.exe), which inherits Windows env vars
# natively, and launches the script with --login so /usr/bin (jq, fzf, etc.)
# is on PATH.
#
# Usage: run.sh <script.sh> [args...]
#   run.sh open.sh picker-default
#   run.sh picker.sh --create-base=default
#   run.sh remove.sh
#   run.sh merge.sh --no-squash

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Windows: use git-bash.cmd to find and launch Git Bash.
    exec "$(dirname -- "$0")/git-bash.cmd" "$@"
    ;;
  *)
    # macOS, Linux, and anything else: bash is the system shell.
    exec bash "$@"
    ;;
esac
