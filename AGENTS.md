# Git SemVer Release AI Agent Instructions

This file provides guidance to AI agents working with code in this repository.

## Project Overview

git-semver-release is a single Bash script (`git-semver-release`, ~370 lines) that calculates and creates semantic version tags from Git history. It supports manual bumps (major/minor/patch), Conventional Commits-based bumps, and pre-release channels.

## Prerequisites

- Git 2.13+ (uses `git describe --exclude`)
- Bash 4+

## Testing

Tests use the [Bats](https://github.com/bats-core/bats-core) framework (v1.5.0+). Test helpers are Git submodules under `test/`.

```bash
# Run full test suite
bats test/test.bats

# Run a single test by name
bats test/test.bats --filter "test name pattern"

# Initialize submodules if test helpers are missing
git submodule update --init --recursive
```

## Releasing

```bash
git-semver-release (major|minor|patch) [--push] [--dry-run] [--channel <name>] [MESSAGE]
```

## Architecture

The entire tool is a single Bash script with no external dependencies beyond Git. There is no build step.

**Command dispatch:** `main()` parses `.git-semver-release.properties` (if present), processes CLI flags (`--push`, `--channel`, `--dry-run`), then routes to a command function.

**Commands:** `version` (calculates version without tagging), `major`/`minor`/`patch` (create release tags), `conventional` (auto-detect bump type from commit messages), `release-tag` (prints the tag at HEAD when on a release, or an empty string otherwise). `--help`/`-h` prints usage to stdout and exits 0; it short-circuits before the repo check, so it works outside a Git repo. Any unrecognized command (or no command) falls through to `version`.

**Version calculation flow:** `get_latest_release_tag()` finds the last stable tag → `get_describe_output()` gets distance from that tag → `version()` computes the pre-release version string incorporating branch name, commit count, and channel.

**Release flow:** `release()` calls `version()` for the next version, generates a changelog via `get_changelog_since_tag()`, creates an annotated Git tag, and optionally pushes.

**Conventional Commits:** `get_bump_type_for_commits_since_tag()` uses regex to scan commit messages for `feat`/`fix`/`BREAKING CHANGE` patterns to determine the bump type, then delegates to `release()`.

## Exit Codes

These are the return codes from `main()`:

- 0 = success
- 4 = `version` command failed
- 5 = dirty working tree (for `major`/`minor`/`patch` and `conventional`)
- 6 = `release` failed (for `major`/`minor`/`patch`)
- 7 = `conventional` failed (e.g. no releasable commits)

Internal helper functions (`is_git_repo`, `has_commits`, etc.) return 0/1 but those propagate through the calling command's exit code, not as distinct top-level codes.
