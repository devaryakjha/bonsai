SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help app-icon run run-verify validate validate-scripts test perf perf-ui \
	release-verify release-verify-archive release-verify-artifacts \
	release-doctor release-check-credentials release-github-doctor \
	release-secret-template release-secrets-dry-run release-secrets-upload \
	release-runner release-runner-workflow release-notarize release-draft \
	release-archive release-dry-run release

help:
	@printf '%s\n' \
		'Bonsai targets:' \
		'  make app-icon                    Export Bonsai.icns from Bonsai.icon' \
		'  make validate                    Run source, test, and perf gates' \
		'  make run                         Build and launch the app' \
		'  make run-verify                  Build, launch, and verify process state' \
		'  make release-verify              Build and validate an ad-hoc app bundle' \
		'  make release-verify-archive      Build and validate an ad-hoc zip' \
		'  make release-verify-artifacts    Verify dist/release zip and manifest' \
		'  make release-doctor              Check local release credentials' \
		'  make release-github-doctor       Check GitHub release environment' \
		'  make release-archive             Build a Developer ID signed zip' \
		'  make release-dry-run             Dispatch Jarvis release dry run' \
		'  make release                     Dispatch protected notarized release'

run:
	./script/build_and_run.sh

app-icon:
	./script/export_app_icon.sh

run-verify:
	./script/build_and_run.sh --verify

validate: validate-scripts test perf

validate-scripts:
	@for script in \
		script/build_and_run.sh \
		script/check_release_runner.sh \
		script/configure_github_release_secrets.sh \
		script/create_github_draft_release.sh \
		script/export_app_icon.sh \
		script/package_release.sh \
		script/perf_large_repo.sh \
		script/perf_ui_sample.sh; do \
		bash -n "$$script"; \
	done

test:
	git diff --check
	swift test

perf:
	./script/perf_large_repo.sh

perf-ui:
	./script/perf_ui_sample.sh

release-verify:
	./script/package_release.sh --verify

release-verify-archive:
	./script/package_release.sh --verify-archive

release-verify-artifacts:
	./script/package_release.sh --verify-artifacts

release-doctor:
	./script/package_release.sh --doctor

release-check-credentials:
	./script/package_release.sh --check-credentials

release-github-doctor:
	./script/package_release.sh --github-doctor

release-secret-template:
	./script/configure_github_release_secrets.sh --print-template

release-secrets-dry-run:
	./script/configure_github_release_secrets.sh --dry-run

release-secrets-upload:
	./script/configure_github_release_secrets.sh

release-runner:
	./script/check_release_runner.sh

release-runner-workflow:
	./script/check_release_runner.sh --workflow

release-notarize:
	./script/package_release.sh --notarize

release-archive:
	./script/package_release.sh --archive

release-draft:
	./script/create_github_draft_release.sh

release-dry-run:
	gh workflow run Release --repo devaryakjha/bonsai --ref main -f dry_run=true

release:
	gh workflow run Release --repo devaryakjha/bonsai --ref main -f dry_run=false
