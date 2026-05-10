# Contributing to heroku-buildpack-bun

This buildpack is a fork of [jakeg/heroku-buildpack-bun](https://github.com/jakeg/heroku-buildpack-bun).

First off, thank you for considering contributing to this buildpack! It's people like you that make the open-source community such a great place to learn, inspire, and create.

## Development Setup

To test changes to the buildpack locally, you just need a standard Unix/Linux environment (or WSL on Windows) with `bash` and `curl`.

1.  **Run the test suite:**
    You can run the buildpack's smoke tests locally via the Makefile:
    ```bash
    make test
    ```
    *(Alternatively, you can just run `bash bin/test` directly).*

## Submitting Pull Requests

1.  **Fork the repository** and create your branch from `main`.
2.  **Add tests** for any new functionality or bug fixes in `bin/test`.
3.  **Run the test suite** to ensure everything passes.
4.  **Keep it clean**: Make sure to adhere to defensive bash scripting (`set -euo pipefail`).
5.  **Submit your PR** with a clear description of the problem and your solution.

## Release Process
- Once changes are merged into `main`, they are immediately available to users pulling directly from the GitHub repository URL.
- Make sure to update the `README.md` if any user-facing features or configuration changes are made.
