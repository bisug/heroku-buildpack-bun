<p align="center">
  <img src="https://bun.sh/logo.svg" alt="Bun" height="120">
</p>

# heroku-buildpack-bun

Heroku buildpack for [Bun.js](https://bun.sh/) — allows you to run Bun on Heroku.

> **Note:** This is an unofficial community buildpack for Bun.

## Features

- **Secure by Default:** Downloads official binaries directly from GitHub Releases (no `curl | bash` script execution) and safely isolates core Heroku environment variables.
- **Fast:** Aggressively caches Bun binaries and package cache across builds. Uses GitHub API to resolve the `latest` version with intelligent TTL caching.
- **Architecture Aware:** Automatically detects and installs the correct binary for `x64` and `aarch64` (ARM) architectures.
- **Reproducible:** Automatically detects `bun.lock` and `bun.lockb` to ensure frozen lockfile installations.

## Supported Stacks

- `heroku-22`
- `heroku-24`

## How to use

To add the buildpack to your Heroku app, visit the settings page for your app on Heroku, then under **Buildpacks** add:

```text
https://github.com/bisug/heroku-buildpack-bun
```

### Using with multiple buildpacks

If your app requires multiple buildpacks (e.g., using Bun for a frontend build in a Python or Ruby app), you can add it at a specific index using the Heroku CLI:

```bash
# Add Bun as the first buildpack
heroku buildpacks:add --index 1 https://github.com/bisug/heroku-buildpack-bun
```

### Detection

The buildpack will automatically detect your project as a Bun app if any of the following are present in your project's root:

**Tier 1 (Bun-exclusive files):**
- `bun.lock` or `bun.lockb`
- `.bun-version` or `runtime.bun.txt`
- `bunfig.toml` or `.bunfig.toml`

**Tier 2 (`package.json` config):**
- `"packageManager": "bun@..."`
- `"engines": { "bun": "..." }`

### Defining Process Types

If you have a [`Procfile`](https://devcenter.heroku.com/articles/procfile) (e.g. `web: bun index.js`), Heroku will use it.

If no `Procfile` is present, the buildpack will automatically create default process types based on the scripts in your `package.json`:

- **`web` dyno:** Looks for a `"web"` script, then a `"start"` script.
- **`worker` dyno:** Looks for a `"worker"` script.
- **`release` dyno:** Looks for a `"release"` script.
- **`scheduler` dyno:** Looks for a `"scheduler"` script.

**Fallback:** If absolutely *no* process types are found from the scripts above, the buildpack will scan for common entry files (like `index.ts`, `server.ts`, etc.) and automatically create a `web` dyno.

For example, to run a worker-only app without a Procfile, simply define a `"worker"` script in your `package.json`. The buildpack will detect it and will *not* eagerly create an unnecessary `web` dyno!

## Pinning a Bun version

Pin a specific Bun version using **one** of the following methods (listed in priority order):

| Method | Example |
|--------|---------|
| Heroku Config Var `BUN_VERSION` | `heroku config:set BUN_VERSION=1.3.13` |
| `.bun-version` file in project root | `1.3.13` or `v1.3.13` |
| `engines.bun` in `package.json` | `"engines": { "bun": "1.3.13" }` |
| `runtime.bun.txt` file in project root | `1.3.13` |
| `runtime.txt` file | `1.3.13` or `bun-1.3.13` |

The version can be specified with or without a leading `v`, e.g. `v1.3.13` or `1.3.13`. Any [Bun release tag](https://github.com/oven-sh/bun/releases) is valid.

> **Note:** Only exact versions are supported. Semver ranges like `>=1.0.0` or `^1.3.0` in `engines.bun` will not be resolved and will cause the build to fail.

> **Note:** Avoid using `runtime.txt` if you have other buildpacks (e.g. Ruby or Python) that also use `runtime.txt` for their own version pinning. Use `.bun-version` or `BUN_VERSION` instead.

## Build scripts

This buildpack automatically runs the following commands (in order) if defined in `package.json`:

| Order | Step | Command | Skip with |
|-------|------|---------|-----------|
| 1 | Prebuild | `bun run heroku-prebuild` | `.skip-bun-heroku-prebuild` |
| 2 | Install | `bun install` | `.skip-bun-install` |
| 3 | Build | `bun run build` | `.skip-bun-build` |
| 4 | Postbuild | `bun run heroku-postbuild` | `.skip-bun-heroku-postbuild` |

### Reproducible installs

If a `bun.lock` or `bun.lockb` lockfile is present, dependencies are installed with `--frozen-lockfile` to ensure reproducible builds. If no lockfile exists, a regular `bun install` is run (with a warning).

## Binding to the correct port

Heroku assigns a dynamic port via the `$PORT` environment variable. Your web server **must** bind to this port, or Heroku will crash your dyno with an `R10 Boot Timeout` error after 60 seconds.

Here is an idiomatic example using `Bun.env.PORT`:

```js
const server = Bun.serve({
  port: Bun.env.PORT || 3000,
  fetch(request) {
    return new Response('Welcome to Bun on Heroku!');
  },
});

console.log(`Listening on port ${server.port}`);
```

## Environment Variables

By default, the buildpack sets `NODE_ENV=production` during the build and at runtime to ensure frameworks and libraries are fully optimized. If you need a different environment, you can override it using Heroku config vars:

```bash
heroku config:set NODE_ENV=development
```

## Private Packages & Authentication

If your project depends on private packages (e.g., from npm Enterprise or GitHub Packages), you can authenticate securely without committing secrets to your codebase.

Set your authentication token as a Heroku config var:
```bash
heroku config:set BUN_AUTH_TOKEN=your_token_here
```

Then, reference it via environment variable substitution in your `bunfig.toml`:
```toml
[install.scopes]
"@my-org" = { token = "$BUN_AUTH_TOKEN", url = "https://npm.pkg.github.com/" }
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to set up your environment, run the tests, and submit a pull request.

## Troubleshooting

### 1. `bun install` fails with frozen lockfile error
If you see an error about a lockfile mismatch during `bun install`, it means your `bun.lock` or `bun.lockb` is out of sync with your `package.json`. Run `bun install` locally to update it, and commit the updated lockfile.

### 2. App crashes with R10 (Boot timeout)
Ensure you are binding your web server to the `$PORT` environment variable provided by Heroku (as shown in the port binding example), and not hardcoding a specific port like `3000`.

### 3. Reporting Issues
If you encounter a bug within the buildpack itself, please use the [Issues tab](https://github.com/bisug/heroku-buildpack-bun/issues) to report it. Provide your Heroku build log to help isolate the issue.
