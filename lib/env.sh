# shellcheck shell=bash
# lib/env.sh - ENV_DIR export helper (sourced by bin/compile and bin/test)

export_env_dir() {
  local env_dir="$1"
  local entry key filename

  [[ -d "$env_dir" ]] || return 0

  for entry in "$env_dir/"*; do
    [[ -f "$entry" ]] || continue
    filename=${entry##*/}
    # shortcut: valid shell names only, no fork/regex (O(n) glob scan)
    case "${filename:0:1}" in [A-Za-z_]) ;; *) continue ;; esac
    case "$filename" in *[^A-Za-z0-9_]* | "") continue ;; esac
    key=$filename

    case "$key" in
      PATH | HOME | IFS | GIT_DIR | CPATH | CPPATH | LD_PRELOAD | LD_AUDIT | LD_CONFIG | LIBRARY_PATH | LD_LIBRARY_PATH | BASH_ENV | ENV | SHELLOPTS | BUILDPACK_URL | SOURCE_VERSION | PS4 | GLOBIGNORE | TMPDIR | PWD | SHELL)
        continue
        ;;
    esac

    # NOTE: Heroku ENV_DIR files have no trailing-newline encoding, so command
    # substitution intentionally strips trailing newlines. Values containing
    # newlines cannot round-trip through ENV_DIR; prefer single-line values.
    export "$key=$(cat "$entry")"
  done
}
