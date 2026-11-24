.PHONY: test lint

test:
	@echo "Running buildpack tests natively..."
	@bash bin/test

lint:
	@echo "Running shellcheck..."
	shellcheck bin/compile bin/detect bin/release bin/test lib/env.sh lib/version.sh
