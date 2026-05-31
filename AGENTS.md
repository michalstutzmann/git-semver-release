# Agent Instructions

This file is for AI/code agents working in this repository. Keep it focused on implementation context, local workflows, and project-specific traps. User-facing usage belongs in `README.md`.

## Project Shape

- The product is a single Bash executable: `git-semver-release`.
- There is no build step and no runtime dependency beyond Bash and Git.
- Tests are Bats tests in `test/test.bats`; helpers are Git submodules under `test/test_helper/`.
- Release packaging also touches `publish` and `Dockerfile`, which bake the script version into release artifacts.

## Required Local Tools

- Bash 4+
- Git 2.13+ (`git describe --exclude` is used)
- Bats 1.5.0+ for tests

## Common Commands

```bash
# Syntax check
bash -n git-semver-release

# Full test suite
bats test/test.bats

# One focused test
bats test/test.bats --filter "test name pattern"

# Initialize test helper submodules if missing
git submodule update --init --recursive
```

Prefer `bash -n git-semver-release` plus the focused Bats test while iterating, then run the full Bats suite before finishing behavior changes.

## Architecture Map

- `main()` handles global `--help`/`--version` before repository checks, reads `.git-semver-release.properties`, parses flags, then dispatches.
- `version()` computes the displayed or releasable SemVer from `git describe`, dirty state, configured tag prefix, and pre-release formatting.
- `release()` calls `version()` with an explicit bump type, creates an annotated Git tag, and optionally pushes branch and tag.
- `conventional()` determines `major`/`minor`/`patch` from commit messages, then delegates to `release()`.
- `release_tag()` prints the stable release tag at `HEAD`, or an empty line when `HEAD` is not on a release.
- `get_describe_output()` is for version calculation and may return a short SHA when no release exists.
- `get_latest_release_tag()` is for history ranges in changelog/conventional release logic.

## Behavior Invariants

- Stable release tags are `vMAJOR.MINOR.PATCH` by default. `tag_prefix` can be configured, including to an empty string.
- Pre-release tags such as `v1.2.3-rc.1` must not become stable release anchors.
- With no prior release:
  - `version` reports `0.1.0-CHANNEL.N.sha` by default.
  - `patch` and `minor` release `v0.1.0`.
  - `major` releases `v1.0.0`.
- After a release tag, commits or a dirty worktree make `version` project the next patch pre-release.
- A clean checkout exactly on a stable release tag prints the stable version without a pre-release suffix.
- Explicit `major`, `minor`, and `patch` releases always create plain stable tags; `--channel` is accepted but has no effect there.
- The default pre-release channel is the current branch name normalized for SemVer, not a fixed `alpha`.
- `pre_release_format` supports `$channel`, `$branch`, `$commit_count`, `$commit_short_sha`, `$dirty_indicator`, and `$separator`.
- `$branch` is retained for backwards compatibility even though `$channel` is the preferred template variable.
- `render_pre_release()` collapses repeated dots and trims leading/trailing dots after template substitution.
- `major`/`minor`/`patch` and `conventional` must fail on a dirty working tree.
- `release-tag` should work even when the working tree is dirty, and should ignore pre-release tags.

## Conventional Commit Rules

`get_bump_type_for_commits_since_tag()` scans commits since the latest stable release tag, or all history if none exists.

- `type!:` and `BREAKING CHANGE:` trigger `major`.
- `feat:` triggers `minor` unless a breaking change is found.
- `fix:` and `perf:` trigger `patch` unless a feature or breaking change is found.
- Non-releasable commits produce no bump; top-level `conventional` exits with code `7`.

## Configuration File

`.git-semver-release.properties` is deliberately simple: one `key=value` per line. Supported keys:

- `channel`
- `dirty_indicator`
- `pre_release_format`
- `tag_prefix`

Do not add complex parsing unless the change is explicitly requested and tested; current behavior does not handle quoting, escaping, comments, or multi-line values.

## Version Baking

Keep this exact source line unchanged:

```bash
readonly VERSION='dev'
```

Both `publish` and `Dockerfile` substitute that line using a regex anchored to the literal `dev` value.

## Exit Codes From `main()`

- `0` success
- `1` Git not installed
- `2` not a Git repository
- `3` no commits yet
- `4` `version` command failed
- `5` dirty working tree for release commands
- `6` explicit release failed
- `7` conventional release failed

Helper functions use normal shell truthiness internally; do not expose their return codes as new top-level meanings without updating tests and docs.

## Editing Guidance

- Keep the implementation in one Bash file unless there is a strong reason to split it.
- Prefer small, explicit Bash over clever one-liners.
- Quote variables used in Git commands and string substitutions.
- Use `local`/`local -r` consistently inside functions.
- When changing version behavior, add or update Bats coverage near the related existing tests.
- Preserve `--help` and `--version` behavior outside a Git repository.
- Avoid changing release packaging (`publish`, `Dockerfile`) unless the version-baking flow is part of the task.
