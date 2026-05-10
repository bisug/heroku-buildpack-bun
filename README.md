# heroku-buildpack-bun

Heroku buildpack for [Bun.js](https://bun.sh/) — allows you to run Bun on Heroku.

Based on the [Deno buildpack](https://github.com/chibat/heroku-buildpack-deno) and [Node.js buildpack](https://github.com/heroku/heroku-buildpack-nodejs).

## Supported Stacks

- `heroku-22`
- `heroku-24`

## How to use

To add the buildpack to your Heroku app, visit the settings page for your app on Heroku, then under **Buildpacks** add:

```
https://github.com/bisug/heroku-buildpack-bun
```

You'll either need a [`Procfile`](https://devcenter.heroku.com/articles/procfile) in the root folder of your app (e.g. `web: bun index.js`), or a `package.json` with a `start` script.

## Pinning a Bun version

Pin a specific Bun version using **one** of the following methods (listed in priority order):

| Method | Example |
|--------|---------|
| Heroku Config Var `BUN_VERSION` | `heroku config:set BUN_VERSION=1.1.20` |
| `.bun-version` file in project root | `1.1.20` or `v1.1.20` |
| `runtime.bun.txt` file in project root | `1.1.20` |
| `runtime.txt` file (bare version only) | `1.1.20` |

The version can be specified with or without a leading `v`, e.g. `v1.1.20` or `1.1.20`. Any [Bun release tag](https://github.com/oven-sh/bun/releases) is valid.

> **Note:** Avoid using `runtime.txt` if you have other buildpacks (e.g. Ruby or Python) that also use `runtime.txt` for their own version pinning. Use `.bun-version` or `BUN_VERSION` instead.

## Build scripts

This buildpack automatically runs the following commands if defined in `package.json`:

| Step | Command | Skip with |
|------|---------|-----------|
| Install | `bun install` | `.skip-bun-install` |
| Prebuild | `bun run heroku-prebuild` | `.skip-bun-heroku-prebuild` |
| Build | `bun run build` | `.skip-bun-build` |
| Postbuild | `bun run heroku-postbuild` | `.skip-bun-heroku-postbuild` |

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

## Potential issues

Use the [Issues tab](https://github.com/bisug/heroku-buildpack-bun/issues) to report any issues.
