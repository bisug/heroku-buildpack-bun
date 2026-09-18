# shellcheck shell=bash
# lib/version.sh - Bun version normalization (sourced by bin/compile and bin/test)
# Accepts exact versions (1.3.13, v1.3.13, bun-v1.3.13), "latest", "canary".
# Rejects ranges (^, ~, >=) so builds stay repeatable.

normalize_bun_version() {
  local raw="$1"

  raw=${raw//[[:space:]]/}
  case "$raw" in
    "") return 1 ;;
    latest|canary)
      printf "%s\n" "$raw"
      return 0
      ;;
    bun-*)
      raw="${raw#bun-}"
      ;;
  esac

  if [[ "$raw" =~ ^[0-9] ]]; then
    raw="v${raw}"
  fi

  if [[ "$raw" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$ ]]; then
    printf "%s\n" "$raw"
    return 0
  fi

  return 1
}
