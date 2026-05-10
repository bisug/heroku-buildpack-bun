<p align="center">
  <img src="https://bun.sh/logo.svg" alt="Bun" height="120">
</p>

# heroku-buildpack-bun

Heroku buildpack for [Bun.js](https://bun.sh/) — allows you to run Bun on Heroku.

> **Note:** This is an unofficial community buildpack for Bun.

## Supported Stacks

- `heroku-22`
- `heroku-24`

## How to use

To add the buildpack to your Heroku app, visit the settings page for your app on Heroku, then under **Buildpacks** add:

```text
https://github.com/bisug/heroku-buildpack-bun
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

- **`web` dyno:** Looks for a `"web"` script, then a `"start"` script, and finally scans for common entry files (like `index.ts`, `server.ts`, etc.).
- **`worker` dyno:** Looks for a `"worker"` script.
- **`release` dyno:** Looks for a `"release"` script.
- **`scheduler` dyno:** Looks for a `"scheduler"` script.

For example, to run a worker-only app without a Procfile, simply define a `"worker"` script in your `package.json` and deploy!

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

Heroku assigns a port via the `$PORT` environment variable. Example:

```js
import { env } from 'process'

const server = Bun.serve({
  port: env.PORT || 3000,
  fetch(request) {
    return new Response('Welcome to Bun on Heroku!')
  },
})

console.log(`Listening on port ${server.port}`)
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to set up your environment, run the tests, and submit a pull request.

## Potential issues

Use the [Issues tab](https://github.com/bisug/heroku-buildpack-bun/issues) to report any issues.
