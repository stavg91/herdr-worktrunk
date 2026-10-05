#!/usr/bin/env bash
# Shared entrypoint for the plugin's workspace actions. Resolves the repo to run
# in, then opens a pane running the entrypoint's script.
#
# On Windows, herdr cannot spawn a relative pane command from a [[panes]] entry
# (CreateProcessW resolves it against herdr's own directory, not the plugin
# root or --cwd). So instead of `herdr plugin pane open` (which spawns the
# manifest's pane command), we use `herdr pane split` + `herdr pane run` with
# an absolute path to the script. This is the same pattern used by
# herdr-file-viewer (see its scripts/open-file-viewer.ps1).
#
# Plugin panes default their cwd to the plugin root, so the workspace's repo
# (from the injected context JSON) has to be passed explicitly. Otherwise `wt`
# runs in the plugin dir, not the repo you're in.

entrypoint=${1:?usage: open.sh <entrypoint>}

plugin_root=${HERDR_PLUGIN_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}
# shellcheck source=./config.sh
source "$plugin_root/config.sh"

cwd=$(jq -r '.workspace_cwd // .focused_pane_cwd' <<<"$HERDR_PLUGIN_CONTEXT_JSON" | tr -d '\r')
herdr=${HERDR_BIN_PATH:-herdr}

# Map entrypoint id to script + args. Use absolute paths so the pane script
# is found regardless of cwd (the pane cwd is the workspace repo, not the
# plugin root).
case "$entrypoint" in
  picker-default)      script=("$plugin_root/picker.sh" --create-base=default) ;;
  picker-current)      script=("$plugin_root/picker.sh" --create-base=current) ;;
  picker-with-remotes) script=("$plugin_root/picker.sh" --show-with-remotes) ;;
  remover)             script=("$plugin_root/remove.sh") ;;
  merger)              script=("$plugin_root/merge.sh") ;;
  merger-no-squash)    script=("$plugin_root/merge.sh" --no-squash) ;;
  *) printf '\033[31m%s\033[0m\n' "Unknown entrypoint: $entrypoint" >&2; exit 1 ;;
esac

# Label for the pane.
case "$entrypoint" in
  picker-default)      label="Worktrunk — default branch" ;;
  picker-current)      label="Worktrunk — current branch" ;;
  picker-with-remotes) label="Worktrunk — local and remote branches" ;;
  remover)             label="Worktrunk — remove" ;;
  merger)              label="Worktrunk — merge" ;;
  merger-no-squash)    label="Worktrunk — merge (no squash)" ;;
esac

# herdr pane split creates a new pane. --cwd sets the working directory.
# --env passes HERDR_PLUGIN_ROOT and other vars the pane script needs.
split_args=(pane split --current --direction down --cwd "$cwd" --focus)
[[ -n ${HERDR_WORKSPACE_ID:-} ]] && split_args+=(--env "HERDR_WORKSPACE_ID=$HERDR_WORKSPACE_ID")
split_args+=(--env "HERDR_PLUGIN_ROOT=$plugin_root")
split_args+=(--env "HERDR_PLUGIN_ID=${HERDR_PLUGIN_ID:-worktrunk}")
split_args+=(--env "HERDR_BIN_PATH=$herdr")
split_args+=(--env "HERDR_PLUGIN_ENTRYPOINT_ID=$entrypoint")
[[ -n ${HERDR_TAB_ID:-} ]] && split_args+=(--env "HERDR_TAB_ID=$HERDR_TAB_ID")
[[ -n ${HERDR_PANE_ID:-} ]] && split_args+=(--env "HERDR_PANE_ID=$HERDR_PANE_ID")

# Context JSON: pass it through so the pane script can read workspace_cwd etc.
if [[ -n ${HERDR_PLUGIN_CONTEXT_JSON:-} ]]; then
  split_args+=(--env "HERDR_PLUGIN_CONTEXT_JSON=$HERDR_PLUGIN_CONTEXT_JSON")
fi

split_json=$("$herdr" "${split_args[@]}" 2>&1)
if [[ $? -ne 0 ]]; then
  printf '\033[31m%s\033[0m\n' "herdr pane split failed: $split_json" >&2
  exit 1
fi

# Extract the new pane id from the JSON reply.
# herdr pane split returns {"result":{"pane":{"pane_id":"...",...}}}
pane_id=$(printf '%s\n' "$split_json" | jq -r '.result.pane.pane_id // .pane.pane_id // .pane_id // empty' | tr -d '\r')
if [[ -z $pane_id ]]; then
  printf '\033[31m%s\033[0m\n' "could not find pane_id in: $split_json" >&2
  exit 1
fi

# Rename the pane.
"$herdr" pane rename "$pane_id" "$label" >/dev/null 2>&1

# Run the script in the pane. herdr pane run sends the command as text to the
# pane's shell (Git Bash on Windows). Use bash with the absolute script path.
# The pane inherits HERDR_PLUGIN_ROOT and other env vars from pane split --env
# above, so the script can source config.sh and helpers.sh from the plugin root.
"$herdr" pane run "$pane_id" bash "${script[@]}"
