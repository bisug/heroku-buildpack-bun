# lib/json.sh — JSON helper functions (sourced by bin/compile and bin/release)
# Based on: https://github.com/heroku/heroku-buildpack-nodejs/blob/main/lib/json.sh

read_json() {
  local file="$1"
  local key="$2"

  if test -f "$file"; then
    # -c = print on only one line
    # -M = strip any color
    # --raw-output = write string results directly to stdout (no JSON quoting)
    # shellcheck disable=SC2002
    cat "$file" | jq -c -M --raw-output "$key // \"\"" || return 1
  else
    echo ""
  fi
}

has_script() {
  local file="$1"
  local key="$2"

  if test -f "$file"; then
    # shellcheck disable=SC2002
    cat "$file" | jq ".[\"scripts\"] | has(\"$key\")"
  else
    echo "false"
  fi
}

is_invalid_json_file() {
  local file="$1"
  # shellcheck disable=SC2002
  if ! cat "$file" | jq "." 1>/dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}
