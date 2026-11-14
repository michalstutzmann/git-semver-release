# Contributing

This guide is for anyone changing this repository, human or AI agent (`AGENTS.md` is a symlink to this file). It covers implementation context, local workflows, and project-specific traps. User-facing usage belongs in `README.md`.

## Project Shape

- The product is a single Bash executable: `git-semver-release`.
- There is no build step and no runtime dependency beyond Bash and Git.
- Tests are Bats tests in `test/test.bats`; helpers are Git submodules under `test/test_helper/`.
- Release packaging also touches `publish` and `Dockerfile`, which bake the script version into release artifacts.
- The Homebrew formula lives in a separate tap repository, [`michalstutzmann/homebrew-git-semver-release`](https://github.com/michalstutzmann/homebrew-git-semver-release), and is updated by hand after each release (see [Releasing](#releasing)).

## Required Local Tools

- Bash 4+
- Git 2.13+ (`git describe --exclude` is used)
- Bats 1.5.0+ for tests
- ShellCheck for linting

On macOS, `/bin/bash` is Bash 3.2. Install a newer Bash (e.g. `brew install bash`) and put it first in your `PATH`, because the script and the tests run through `#!/usr/bin/env bash`. The test "Fail with explicit error on Bash older than 4" runs the script with `/bin/bash` on purpose; it is skipped where `/bin/bash` is already Bash 4+, such as in CI.

## Common Commands

```bash
# Syntax check
bash -n git-semver-release

# Lint (should report nothing)
shellcheck git-semver-release publish

# Full test suite
bats test/test.bats

# One focused test
bats test/test.bats --filter "test name pattern"

# Initialize test helper submodules if missing
git submodule update --init --recursive
```

Prefer `bash -n git-semver-release` plus the focused Bats test while iterating, then run ShellCheck and the full Bats suite before finishing behavior changes.

## Architecture Map

- `main()` runs in this order: global `--help`/`--version`, the Bash 4+ and Git checks, command-line parsing and validation, repository checks, reading `.git-semver-release.properties`, then dispatch. Help, version, and usage errors therefore work outside a Git repository.
- `version()` computes the displayed or releasable SemVer from `git describe`, dirty state, configured tag prefix, and pre-release formatting.
- `release()` calls `version()` with an explicit bump type, creates an annotated Git tag, and optionally pushes branch and tag.
- `conventional()` determines `major`/`minor`/`patch` from commit messages, then delegates to `release()`.
- `release_tag()` prints the stable release tag at `HEAD`, or an empty line when `HEAD` is not on a release or the working tree is dirty.
- `get_describe_output()` is for version calculation and may return a short SHA when no release exists.
- `get_latest_release_tag()` is for history ranges in changelog/conventional release logic.
- `get_highest_release_tag_at()` picks the highest stable release tag on a commit. `version()` and `release_tag()` share it so they always agree when several tags point at one commit.
- `is_shallow()` detects shallow clones through the `shallow` file, because `git rev-parse --is-shallow-repository` needs Git 2.15.

## Behavior Invariants

- Stable release tags are `vMAJOR.MINOR.PATCH` by default. `tag_prefix` can be configured, including to an empty string.
- Pre-release tags such as `v1.2.3-rc.1` and build-metadata tags such as `v1.2.3+build.7` must not become stable release anchors. Every `git describe` call that looks for releases must exclude both `${tag_prefix}*-*` and `${tag_prefix}*+*`.
- Annotated and lightweight stable tags are equally valid release anchors. Every `git describe` call that looks for releases must pass `--tags`; `git tag --points-at` already includes both kinds, but needs a commit (not an annotated tag name) to see them all. Tags the tool creates are still annotated.
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
- `release-tag` must print an empty line on a dirty working tree (consistent with `version` reporting a dirty pre-release), and should ignore pre-release tags.
- A release must never report success for a tag it did not create: every `git tag` and `git push` in `release()` must propagate failure.
- When no release tag is found and the clone is shallow, `version` warns on stderr but still prints a version, while `major`/`minor`/`patch` and `conventional` refuse to release. The missing tags may just not have been fetched, and the `0.1.0` fallback would restart versioning.
- Unknown commands, unknown options (anything starting with `-`), a `--channel` without a value, and extra positional arguments are usage errors. They must fail before any Git call instead of falling back to `version` or becoming the tag `MESSAGE`.
- Release commands print the released version (without the tag prefix) on stdout. Everything else (`--dry-run` output, errors, warnings, `git push` output) goes to stderr, so callers can capture the version.
- Error and warning messages end with a newline.

## Conventional Commit Rules

`get_bump_type_for_commits_since_tag()` scans commits since the latest stable release tag, or all history if none exists.

- `type!:` / `type(scope)!:` at the start of the message, and `BREAKING CHANGE:` or `BREAKING-CHANGE:` anywhere in it, trigger `major`.
- `feat:` triggers `minor` unless a breaking change is found.
- `fix:` and `perf:` trigger `patch` unless a feature or breaking change is found.
- Non-releasable commits produce no bump; top-level `conventional` exits with code `9`. That code is reserved for "nothing to release" so CI can tolerate it; every other `conventional` failure exits with `8`, like explicit releases.
- The patterns match the whole message (Bash regex `^`/`$` anchor the string, not lines). `feat`, `fix`, and `perf` are lowercase, and the colon must be followed by a space and a description.

## Configuration File

`.git-semver-release.properties` is read from the current working directory, not the repository root. It is deliberately simple: one `key=value` per line. Blank lines and lines starting with `#` are skipped, and a last line without a trailing newline is still read. Supported keys:

- `channel`
- `dirty_indicator`
- `pre_release_format`
- `tag_prefix`

Do not add complex parsing unless the change is explicitly requested and tested; current behavior does not handle quoting, escaping, inline comments, whitespace around `=`, or multi-line values.

An empty `channel` or `dirty_indicator` falls back to its default (`:-`), while an empty `tag_prefix` is respected (`-`), which allows unprefixed tags.

## Version Baking

Keep this exact source line unchanged:

```bash
readonly VERSION='dev'
```

Both `publish` and `Dockerfile` substitute that line using a regex anchored to the literal `dev` value.

## Exit Codes From `main()`

Codes are numbered in the order `main()` checks them, from "cannot run at all" to "nothing to release", so reading `main()` top to bottom shows them in ascending order. Keep it that way when adding a code, renumbering if needed, and update the tests, `README.md`, and the Homebrew formula's `test do` block with it.

- `0` success
- `1` Bash older than 4
- `2` Git not installed
- `3` usage error: unknown command or option, missing `--channel` value, or extra argument
- `4` not a Git repository
- `5` no commits yet
- `6` `version` command failed
- `7` dirty working tree for release commands
- `8` release failed (explicit or `conventional`): the tag could not be created or pushed, or no release tag was found in a shallow clone
- `9` `conventional` found no releasable changes

Helper functions use normal shell truthiness internally; do not expose their return codes as new top-level meanings without updating tests and docs.

## Editing Guidance

- Keep the implementation in one Bash file unless there is a strong reason to split it.
- Prefer small, explicit Bash over clever one-liners.
- Quote variables used in Git commands and string substitutions.
- Use `local`/`local -r` consistently inside functions.
- When changing version behavior, add or update Bats coverage near the related existing tests.
- Preserve `--help` and `--version` behavior outside a Git repository.
- Avoid changing release packaging (`publish`, `Dockerfile`) unless the version-baking flow is part of the task.
- When user-visible behavior changes, update `README.md`, the `usage()` help text, and, if the change affects it, the `test do` block of the Homebrew formula.

## Releasing

Releases of this tool are cut with the tool itself and published by CI.

1. From a clean, up-to-date `main`, run `./git-semver-release conventional --push` (or `patch`/`minor`/`major --push`). This pushes `main` and the new annotated tag. The tag message becomes the GitHub Release notes, so the default changelog annotation is usually what you want.
2. The Publish workflow (`.github/workflows/publish.yml`, running `./publish`) runs on every branch and tag push. It runs the Bats suite first, then:
   - For a branch push of an untagged commit, it publishes the image `ghcr.io/michalstutzmann/git-semver-release:X.Y.Z-CHANNEL.N.sha`.
   - For a branch push of a tagged commit, it publishes nothing and leaves that to the tag build.
   - For a tag push (detached `HEAD`), it publishes `:X.Y.Z` and `:latest`. It then creates the GitHub Release `vX.Y.Z`, with the version-baked script as its asset and the tag message as its notes.
3. Update the Homebrew tap by hand. In [`michalstutzmann/homebrew-git-semver-release`](https://github.com/michalstutzmann/homebrew-git-semver-release), point `url` in `Formula/git-semver-release.rb` at the new release asset and update `sha256`:

   ```bash
   curl -fsSL https://github.com/michalstutzmann/git-semver-release/releases/download/vX.Y.Z/git-semver-release | shasum -a 256
   ```

   If the release changed the exit codes or messages that the formula's `test do` block checks, update that too. Commit as `Bump git-semver-release to X.Y.Z`, push, then check with `brew upgrade git-semver-release && brew test git-semver-release`.
