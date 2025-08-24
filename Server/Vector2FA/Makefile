# Use bash for a slightly nicer shell
SHELL := /bin/bash

# Load env vars from .env if it exists (and export to all recipes)
-include .env
export

DB := vector.sqlite

.PHONY: deps build migrate db-wal dev clean reset-deps tree

deps:
	@swift package update

build:
	@echo "→ Building…"
	@swift build

migrate: build
	@echo "→ Running migrations…"
	@swift run Run migrate --yes

db-wal:
	@echo "→ Enabling SQLite WAL mode for $(DB)…"
	@sqlite3 $(DB) 'PRAGMA journal_mode=WAL;' >/dev/null

dev: db-wal migrate
	@echo "→ Starting server…"
	@swift run Run

clean:
	@echo "→ Cleaning build artifacts…"
	@rm -rf .build .swiftpm Package.resolved

reset-deps: clean
	@echo "→ Resetting and re-resolving packages…"
	@swift package reset
	@swift package update

tree:
	@echo "→ Project tree (top levels)…"
	@find . -maxdepth 3 -print
