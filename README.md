<p align="center">
  <img src="https://bun.sh/logo.svg" alt="Bun" height="120">
</p>

# heroku-buildpack-bun

Unofficial Heroku classic buildpack for running [Bun](https://bun.sh/) applications on the Heroku Common Runtime.

This buildpack installs an official Bun Linux binary during the build, exposes `bun` on the runtime `PATH`, installs dependencies with Bun, and optionally runs Bun-backed build scripts before release.

> This is a community buildpack. It is not maintained by Heroku or the Bun team.

## Contents

- [Features](#features)
- [Supported Platforms](#supported-platforms)
- [Quick Start](#quick-start)
- [Example App](#example-app)
- [Detection](#detection)
- [Bun Version Selection](#bun-version-selection)
- [Build Lifecycle](#build-lifecycle)
- [Process Types](#process-types)
- [Configuration](#configuration)
- [Multiple Buildpacks](#multiple-buildpacks)
- [Private Packages](#private-packages)
- [Caching](#caching)
- [Security Model](#security-model)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Features

- Installs Bun directly from official GitHub release artifacts.
- Avoids `curl | bash` installer execution.
- Supports exact Bun version pinning, `latest`, and `canary`.
- Caches the Bun binary and Bun package cache between Heroku builds.
- Supports Linux `x64` and `aarch64` binaries.
- Supports the x64 `baseline` Bun binary for older CPUs.
- Runs `bun install --frozen-lockfile` when `bun.lock` or `bun.lockb` exists.
- Exports Bun to later buildpacks in a multi-buildpack pipeline.
- Creates runtime profile settings in `.profile.d/bun.sh`.

## Supported Platforms

This buildpack targets Heroku classic buildpacks on the Heroku Common Runtime.

Supported Heroku stacks:

| Stack | Status |
|-------|--------|
| `heroku-22` | Supported |
| `heroku-24` | Supported |
| `heroku-26` | Supported |

Supported Bun release artifacts:

| Dyno architecture | Bun artifact | Notes |
|-------------------|--------------|-------|
| `x86_64` | `bun-linux-x64.zip` | Default x64 binary. |
| `x86_64` | `bun-linux-x64-baseline.zip` | Enable with `BUN_BINARY_VARIANT=baseline`. |
| `aarch64` / `arm64` | `bun-linux-aarch64.zip` | ARM64 binary. |

Required build-time tools on the stack:

- `bash`
- `curl`
- `jq`
- `unzip`

## Quick Start

Add the buildpack:

```bash
heroku buildpacks:set https://github.com/bisug/heroku-buildpack-bun
```

Pin Bun to an exact version:

```bash
heroku config:set BUN_VERSION=1.3.14
```

Deploy:

```bash
git push heroku main
```

For production apps, prefer an exact `BUN_VERSION` instead of `latest`. Exact versions make builds repeatable and avoid surprises when Bun releases change behavior.

## Example App

Minimal `package.json`:

```json
{
  "packageManager": "bun@1.3.14",
  "engines": {
    "bun": "1.3.14"
  },
  "scripts": {
    "start": "bun run src/server.ts",
    "build": "bun build src/server.ts --outdir dist"
  }
}
```

Minimal Bun web server:

```ts
const port = Number(Bun.env.PORT || 3000);

Bun.serve({
  port,
  fetch() {
    return new Response("Hello from Bun on Heroku");
  },
});

console.log(`Listening on ${port}`);
```

Heroku assigns a dynamic `$PORT`. A web process must listen on that port or the dyno will fail with an R10 boot timeout.

## Detection

The buildpack detects a Bun app when one of these files or fields exists in the app root.

High-confidence Bun files:

- `bun.lock`
- `bun.lockb`
- `.bun-version`
- `runtime.bun.txt`
- `bunfig.toml`
- `.bunfig.toml`

`package.json` signals:

- `"packageManager": "bun@..."`
- `"engines": { "bun": "..." }`

If your app is not detected, add either `.bun-version` or `"packageManager": "bun@<version>"` to the app root.

## Bun Version Selection

Version resolution priority:

| Priority | Source | Example |
|----------|--------|---------|
| 1 | Heroku config var `BUN_VERSION` | `heroku config:set BUN_VERSION=1.3.14` |
| 2 | `.bun-version` | `1.3.14` |
| 3 | `package.json` `engines.bun` | `"engines": { "bun": "1.3.14" }` |
| 4 | `runtime.bun.txt` | `1.3.14` |
| 5 | `runtime.txt` | `bun-1.3.14` |
| 6 | Default | `latest` |

Accepted version values:

- `1.3.14`
- `v1.3.14`
- `bun-v1.3.14`
- `latest`
- `canary`

Only exact release versions are supported for pinned installs. Semver ranges such as `>=1.0.0`, `^1.3.0`, and `~1.3.0` are intentionally rejected during compile.

Use `runtime.txt` only when Bun is the primary runtime. Ruby, Python, Node.js, and other buildpacks may also read `runtime.txt`, so multi-buildpack apps should prefer `BUN_VERSION`, `.bun-version`, or `runtime.bun.txt`.

## Build Lifecycle

The buildpack runs these steps during `bin/compile`:

| Order | Step | Behavior |
|-------|------|----------|
| 1 | Load config vars | Reads Heroku `ENV_DIR` while protecting critical runtime variables. |
| 2 | Set environment | Defaults `NODE_ENV` to `production` when it is not already set. |
| 3 | Resolve Bun version | Uses the configured priority order and validates the version. |
| 4 | Install Bun | Downloads or restores the matching Bun binary. |
| 5 | Write runtime profile | Creates `.profile.d/bun.sh` for dyno startup. |
| 6 | Export for later buildpacks | Writes build-time env exports for multi-buildpack workflows. |
| 7 | Run `heroku-prebuild` | Runs only when defined in `package.json`. |
| 8 | Install dependencies | Runs `bun install`, using `--frozen-lockfile` when a Bun lockfile exists. |
| 9 | Run `build` | Runs only when defined in `package.json`. |
| 10 | Run `heroku-postbuild` | Runs only when defined in `package.json`. |

Script hooks:

| Hook | Command | Skip with file | Skip with config var |
|------|---------|----------------|----------------------|
| Prebuild | `bun run heroku-prebuild` | `.skip-bun-heroku-prebuild` | `BUN_SKIP_HEROKU_PREBUILD=true` |
| Install | `bun install` | `.skip-bun-install` | `BUN_SKIP_INSTALL=true` |
| Build | `bun run build` | `.skip-bun-build` | `BUN_SKIP_BUILD=true` |
| Postbuild | `bun run heroku-postbuild` | `.skip-bun-heroku-postbuild` | `BUN_SKIP_HEROKU_POSTBUILD=true` |

If `bun.lock` or `bun.lockb` is present, dependency installation uses:

```bash
bun install --frozen-lockfile
```

If no lockfile exists, the buildpack runs:

```bash
bun install
```

## Process Types

If a `Procfile` exists, Heroku uses it and the buildpack does not emit default process types.

Example `Procfile`:

```Procfile
web: bun run start
worker: bun run worker
```

If no `Procfile` exists, `bin/release` creates default process types from `package.json` scripts:

| Script | Process type | Command |
|--------|--------------|---------|
| `web` | `web` | `bun run web` |
| `start` | `web` | `bun run start` |
| `worker` | `worker` | `bun run worker` |
| `release` | `release` | `bun run release` |
| `scheduler` | `scheduler` | `bun run scheduler` |

The `web` script takes priority over `start`.

Heroku only runs process types that are scaled. A generated `worker` or `scheduler` process type is available to scale, but it is not automatically started unless your app formation scales it.

If no matching scripts exist, the buildpack scans for common entry files and creates a `web` process when one is found:

- `index.ts`
- `index.js`
- `src/index.ts`
- `src/index.js`
- `main.ts`
- `main.js`
- `app.ts`
- `app.js`
- `server.ts`
- `server.js`

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `BUN_VERSION` | `latest` | Exact Bun version, `latest`, or `canary`. |
| `BUN_BINARY_VARIANT` | `standard` | Set to `baseline` to use `bun-linux-x64-baseline.zip` on x64 dynos. |
| `BUN_LATEST_TTL_SECONDS` | `3600` | Cache TTL for resolving `latest` from the GitHub releases API. |
| `BUN_INSTALL_FLAGS` | empty | Extra space-separated flags appended to `bun install`. |
| `BUN_SKIP_INSTALL` | `false` | Skip dependency installation. |
| `BUN_SKIP_BUILD` | `false` | Skip the `build` script. |
| `BUN_SKIP_HEROKU_PREBUILD` | `false` | Skip the `heroku-prebuild` script. |
| `BUN_SKIP_HEROKU_POSTBUILD` | `false` | Skip the `heroku-postbuild` script. |
| `NODE_ENV` | `production` | Build-time and runtime default when not already configured. |

Examples:

```bash
heroku config:set BUN_VERSION=1.3.14
heroku config:set BUN_BINARY_VARIANT=baseline
heroku config:set BUN_INSTALL_FLAGS="--ignore-scripts"
heroku config:set BUN_SKIP_BUILD=true
```

`BUN_INSTALL_FLAGS` is intentionally simple. For registry configuration, scopes, auth, and other structured install behavior, prefer `bunfig.toml`.

## Multiple Buildpacks

Use Bun before another buildpack when Bun builds assets consumed by another runtime:

```bash
heroku buildpacks:clear
heroku buildpacks:add --index 1 https://github.com/bisug/heroku-buildpack-bun
heroku buildpacks:add --index 2 heroku/python
```

The buildpack writes an `export` file so later buildpacks can use:

- `bun`
- `BUN_INSTALL`
- `BUN_INSTALL_CACHE_DIR`
- `NODE_ENV`

Avoid `runtime.txt` in multi-buildpack apps unless every buildpack in the pipeline expects the same runtime file format.

## Private Packages

Store package tokens as Heroku config vars, not in source control:

```bash
heroku config:set BUN_AUTH_TOKEN=your_token_here
```

Reference the token from `bunfig.toml`:

```toml
[install.scopes]
"@my-org" = { token = "$BUN_AUTH_TOKEN", url = "https://npm.pkg.github.com/" }
```

## Caching

The buildpack uses the Heroku build cache for:

- Resolved `latest` Bun version metadata.
- Bun binary cache.
- Bun package cache.

Binary cache keys include:

- Bun version.
- CPU architecture.
- Bun binary variant.

`canary` binaries are not cached because the `canary` tag is mutable.

The Bun package cache is pruned when it grows beyond 800 MB to avoid excessive Heroku cache usage.

## Security Model

This buildpack is designed to be conservative by default:

- Downloads release ZIPs directly from `https://github.com/oven-sh/bun/releases`.
- Does not execute remote installer scripts.
- Validates that the downloaded artifact is a ZIP archive before extracting.
- Copies only the expected `bun` binary from the release archive.
- Does not allow `ENV_DIR` config vars to overwrite critical values such as `PATH`, `HOME`, `LD_PRELOAD`, or `BASH_ENV`.
- Shell-quotes generated runtime defaults before writing profile/export files.

You are still responsible for auditing application dependencies, lockfiles, package scripts, and private registry configuration.

## Troubleshooting

### App is not detected as a Bun app

Add one of these files or fields:

```bash
echo "1.3.14" > .bun-version
```

or:

```json
{
  "packageManager": "bun@1.3.14"
}
```

### Invalid Bun version

The buildpack accepts exact versions only. Replace semver ranges with an exact release:

```json
{
  "engines": {
    "bun": "1.3.14"
  }
}
```

### Download fails with HTTP 404

Check that the Bun release exists and that the selected binary variant is available for your architecture.

For x64 baseline builds:

```bash
heroku config:set BUN_BINARY_VARIANT=baseline
```

For ARM64, use the default `standard` variant.

### `bun install` fails with a frozen lockfile error

Your lockfile is out of sync with `package.json`. Update it locally and commit it:

```bash
bun install
git add bun.lock
git commit -m "Update Bun lockfile"
```

### App crashes with R10 boot timeout

Make sure the web server binds to Heroku's `$PORT`:

```ts
Bun.serve({
  port: Number(Bun.env.PORT || 3000),
  fetch() {
    return new Response("ok");
  },
});
```

### `Illegal instruction` when starting Bun

Use the baseline x64 binary:

```bash
heroku config:set BUN_BINARY_VARIANT=baseline
```

Then redeploy.

### Private package install fails

Confirm the token is set:

```bash
heroku config:get BUN_AUTH_TOKEN
```

Confirm `bunfig.toml` references the environment variable rather than a hardcoded token.

### Latest version cannot be resolved

Pin an exact Bun version:

```bash
heroku config:set BUN_VERSION=1.3.14
```

This avoids dependency on the GitHub releases API during version resolution.

## Development

Run linting:

```bash
make lint
```

Run tests:

```bash
make test
```

The test suite expects a Unix-like environment with:

- `bash`
- `curl`
- `jq`
- `unzip`
- network access to GitHub releases

On Windows, use WSL or another Linux shell environment for local test execution.

## Contributing

This project is a fork of [jakeg/heroku-buildpack-bun](https://github.com/jakeg/heroku-buildpack-bun).

Before opening a pull request:

1. Add or update tests in `bin/test` for behavior changes.
2. Run `make lint`.
3. Run `make test`.
4. Update this README for user-facing changes.

## License

MIT. See [LICENSE](LICENSE).
