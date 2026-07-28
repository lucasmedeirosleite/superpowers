#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/codex-variant-common.sh"

REPO_ROOT="$(variant_repo_root)"
CODEX_HOME_PATH="$(variant_codex_home)"
CODEX_BIN_PATH="$(variant_codex_bin)"
AGENTS_SOURCE="$REPO_ROOT/agents"
AGENTS_TARGET="$CODEX_HOME_PATH/agents/superpowers"
STATE_FILE="$CODEX_HOME_PATH/superpowers-variant-state.json"

command -v "$CODEX_BIN_PATH" >/dev/null 2>&1 ||
  variant_die "Codex executable not found: $CODEX_BIN_PATH"
command -v python3 >/dev/null 2>&1 ||
  variant_die "python3 is required"
[[ -d "$AGENTS_SOURCE" ]] ||
  variant_die "agents directory not found: $AGENTS_SOURCE"

version_output="$("$CODEX_BIN_PATH" --version)"
variant_version_at_least_0145 "$version_output" ||
  variant_die "Codex 0.145.0 or newer is required; found: $version_output"

catalog_file="$(mktemp)"
marketplaces_file="$(mktemp)"
plugins_file="$(mktemp)"
trap 'rm -f "$catalog_file" "$marketplaces_file" "$plugins_file"' EXIT
env CODEX_HOME="$CODEX_HOME_PATH" \
  "$CODEX_BIN_PATH" debug models >"$catalog_file"
python3 "$REPO_ROOT/scripts/validate-codex-ai-roles.py" \
  --roles-dir "$AGENTS_SOURCE" --catalog "$catalog_file" ||
  variant_die "configured Codex models or reasoning levels are unavailable"

variant_marketplace_json >"$marketplaces_file"
variant_plugins_json >"$plugins_file"

marketplace_added=false
plugin_added=false
agents_link_added=false

if [[ -e "$STATE_FILE" || -L "$STATE_FILE" ]]; then
  [[ -f "$STATE_FILE" && ! -L "$STATE_FILE" ]] ||
    variant_die "managed state is not a regular file: $STATE_FILE"
  [[ "$(variant_state_value "$STATE_FILE" schema)" == "1" ]] ||
    variant_die "unsupported managed state schema"
  [[ "$(variant_realpath "$(variant_state_value "$STATE_FILE" repo_root)")" == \
    "$(variant_realpath "$REPO_ROOT")" ]] ||
    variant_die "managed state belongs to a different checkout"
  [[ "$(variant_state_value "$STATE_FILE" agents_link)" == "$AGENTS_TARGET" ]] ||
    variant_die "managed state names an unexpected agents target"
  marketplace_added="$(variant_state_value "$STATE_FILE" marketplace_added)"
  plugin_added="$(variant_state_value "$STATE_FILE" plugin_added)"
  agents_link_added="$(variant_state_value "$STATE_FILE" agents_link_added)"
fi

while IFS= read -r plugin_id; do
  [[ -z "$plugin_id" || "$plugin_id" == "superpowers@superpowers-dev" ]] ||
    variant_die "installed Superpowers conflict: $plugin_id. Remove it only after explicit user approval; this installer will not remove it."
done < <(variant_installed_superpowers_ids "$plugins_file")

marketplace_root="$(variant_marketplace_root "$marketplaces_file" "superpowers-dev")"
if [[ -n "$marketplace_root" ]]; then
  [[ "$(variant_realpath "$marketplace_root")" == "$(variant_realpath "$REPO_ROOT")" ]] ||
    variant_die "superpowers-dev marketplace belongs to a different checkout: $marketplace_root"
fi

if [[ -e "$AGENTS_TARGET" || -L "$AGENTS_TARGET" ]]; then
  variant_link_is_owned "$AGENTS_TARGET" "$AGENTS_SOURCE" ||
    variant_die "agents target is not owned by this checkout: $AGENTS_TARGET"
fi

mkdir -p "$CODEX_HOME_PATH" "$CODEX_HOME_PATH/agents"

if [[ -z "$marketplace_root" ]]; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin marketplace add "$REPO_ROOT" --json
  marketplace_added=true
  variant_write_state_atomically "$STATE_FILE" "$REPO_ROOT" "$AGENTS_TARGET" \
    "$marketplace_added" "$plugin_added" "$agents_link_added"
fi

if ! variant_plugin_is_installed "$plugins_file" "superpowers@superpowers-dev"; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin add superpowers@superpowers-dev --json
  plugin_added=true
  variant_write_state_atomically "$STATE_FILE" "$REPO_ROOT" "$AGENTS_TARGET" \
    "$marketplace_added" "$plugin_added" "$agents_link_added"
fi

if [[ ! -L "$AGENTS_TARGET" ]]; then
  ln -s "$AGENTS_SOURCE" "$AGENTS_TARGET"
  agents_link_added=true
fi

variant_write_state_atomically "$STATE_FILE" "$REPO_ROOT" "$AGENTS_TARGET" \
  "$marketplace_added" "$plugin_added" "$agents_link_added"

printf 'Superpowers Codex variant installed from: %s\n' "$REPO_ROOT"
printf 'Plugin: superpowers@superpowers-dev\n'
printf 'Agents: %s -> %s\n' "$AGENTS_TARGET" "$AGENTS_SOURCE"
printf 'Start a new Codex session to load the roles.\n'
