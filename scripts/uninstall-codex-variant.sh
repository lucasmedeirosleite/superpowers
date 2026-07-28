#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/codex-variant-common.sh"

REPO_ROOT="$(variant_repo_root)"
CODEX_HOME_PATH="$(variant_codex_home)"
CODEX_BIN_PATH="$(variant_codex_bin)"
STATE_FILE="$CODEX_HOME_PATH/superpowers-variant-state.json"

if [[ ! -e "$STATE_FILE" && ! -L "$STATE_FILE" ]]; then
  printf 'No managed Superpowers Codex variant state found.\n'
  exit 0
fi

[[ -f "$STATE_FILE" && ! -L "$STATE_FILE" ]] ||
  variant_die "managed state is not a regular file: $STATE_FILE"
[[ "$(variant_state_value "$STATE_FILE" schema)" == "1" ]] ||
  variant_die "unsupported managed state schema"
[[ "$(variant_realpath "$(variant_state_value "$STATE_FILE" repo_root)")" == \
  "$(variant_realpath "$REPO_ROOT")" ]] ||
  variant_die "managed state belongs to a different checkout"

AGENTS_TARGET="$(variant_state_value "$STATE_FILE" agents_link)"
AGENTS_SOURCE="$REPO_ROOT/agents"
[[ "$AGENTS_TARGET" == "$CODEX_HOME_PATH/agents/superpowers" ]] ||
  variant_die "managed state names an unexpected agents target"
marketplace_added="$(variant_state_value "$STATE_FILE" marketplace_added)"
plugin_added="$(variant_state_value "$STATE_FILE" plugin_added)"
agents_link_added="$(variant_state_value "$STATE_FILE" agents_link_added)"

plugins_file="$(mktemp)"
marketplaces_file="$(mktemp)"
trap 'rm -f "$plugins_file" "$marketplaces_file"' EXIT
variant_plugins_json >"$plugins_file"
variant_marketplace_json >"$marketplaces_file"

if [[ "$agents_link_added" == "true" &&
  ( -e "$AGENTS_TARGET" || -L "$AGENTS_TARGET" ) ]]; then
  variant_link_is_owned "$AGENTS_TARGET" "$AGENTS_SOURCE" ||
    variant_die "refusing to remove foreign agents target: $AGENTS_TARGET"
fi

marketplace_root="$(variant_marketplace_root "$marketplaces_file" "superpowers-dev")"
if [[ "$marketplace_added" == "true" && -n "$marketplace_root" ]]; then
  [[ "$(variant_realpath "$marketplace_root")" == "$(variant_realpath "$REPO_ROOT")" ]] ||
    variant_die "refusing to remove foreign superpowers-dev marketplace"
fi

if [[ "$agents_link_added" == "true" && -L "$AGENTS_TARGET" ]]; then
  unlink "$AGENTS_TARGET"
fi
if [[ "$plugin_added" == "true" ]] &&
  variant_plugin_is_installed "$plugins_file" "superpowers@superpowers-dev"; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin remove superpowers@superpowers-dev --json
fi
if [[ "$marketplace_added" == "true" && -n "$marketplace_root" ]]; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin marketplace remove superpowers-dev --json
fi
rm -f "$STATE_FILE"

printf '%s\n' \
  "Managed Superpowers Codex variant removed. The official plugin was not installed or restored."
