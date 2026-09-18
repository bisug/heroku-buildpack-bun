# shellcheck shell=bash
# lib/json.sh - JSON helpers (sourced by bin/release and bin/test)
# Based on: https://github.com/heroku/heroku-buildpack-nodejs/blob/main/lib/json.sh

# Single jq parse of package.json scripts: prints space-separated script keys.
# Empty output = no scripts object. Nonzero exit = missing/invalid JSON.
json_script_keys() {
  jq -rj '(if (.scripts? | type) == "object" then (.scripts | keys_unsorted | join(" ")) else "" end), "\n"' "$1" 2>/dev/null
}

has_script() {
  local file="$1"
  local key="$2"

  if test -f "$file"; then
    # Use --arg to safely bind $key, preventing jq filter injection
    jq --arg key "$key" '(.scripts? | objects | has($key)) // false' "$file"
  else
    echo "false"
  fi
}

is_invalid_json_file() {
  local file="$1"
  if ! jq "." "$file" 1>/dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}
