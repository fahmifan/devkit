.PHONY: install-tools
install-tools:
	# generate gorm model struct from db
	go install github.com/smallnest/gen@latest
	# generate erd from db
	go install github.com/KarnerTh/mermerd@latest
	# sql migrations
	go install github.com/rubenv/sql-migrate/...@latest
	# auto reload
	go install github.com/cortesi/modd/cmd/modd@latest

run-server:
	modd -f server.modd.conf

migrate-up:
	sql-migrate up -env=postgres
