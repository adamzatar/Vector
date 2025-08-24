SHELL := /bin/bash
.PHONY: build migrate db-wal dev clean
build:
	swift build
migrate:
	swift run Run migrate --yes
db-wal:
	sqlite3 vector.sqlite 'PRAGMA journal_mode=WAL;'
dev:
	swift run Run
clean:
	rm -f vector.sqlite vector.sqlite-shm vector.sqlite-wal
	swift package clean
