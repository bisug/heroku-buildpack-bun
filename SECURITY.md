# Security policy for heroku-buildpack-bun

## Supported versions

Only the `main` branch is supported with security updates.

## Reporting a vulnerability

Open a GitHub Security Advisory
(<https://github.com/bisug/heroku-buildpack-bun/security/advisories/new>)
or an issue with minimal reproduction details. Do not include secrets or
tokens in reports.

Please allow up to 7 days for an initial response.

## Scope

This buildpack downloads official Bun release ZIPs over HTTPS, never runs
remote installers, validates archives before extraction, and smoke-tests the
binary before use. Reports about Bun itself belong upstream at
<https://github.com/oven-sh/bun>.
