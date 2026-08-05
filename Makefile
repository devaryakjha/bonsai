.PHONY: run check

run:
	cargo run

check:
	cargo fmt --check
	cargo clippy --all-targets --all-features -- -D warnings
