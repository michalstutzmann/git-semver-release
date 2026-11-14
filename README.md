# Git SemVer Release

Version your project from Git tags with a single Bash script. No language-specific release framework, no plugins, no runtime dependencies beyond [Git 2.13+](https://git-scm.com/) and [Bash 4+](https://www.gnu.org/software/bash/).

Use it as a local CLI, in CI, or as a [Docker image](#docker).

It is useful when you want one small command that can:

- Print a SemVer-compatible build version from the current Git state.
- Create annotated release tags with explicit `major`, `minor`, or `patch` bumps.
- Infer release bumps from Conventional Commit messages.
- Produce branch/commit-based pre-release versions for CI without editing package files.

It does not publish packages, create GitHub Releases, or manage language-specific changelogs. It leaves those steps to your existing CI/deployment pipeline.

## Quickstart

Install it with Homebrew (see [Installation](#installation) for a manual download or Docker):

```shell
brew install michalstutzmann/git-semver-release/git-semver-release
```

Then run (assuming the latest release is `v0.1.0` and three commits have been added since, the highest being a `feat:`):

```shell
git-semver-release version
# 0.1.1-main.3.abcdef0       # next-patch pre-release identifier (channel = branch name)

git-semver-release conventional --dry-run
# Would release 0.2.0        # feat: in the new commits triggers a minor bump

git-semver-release patch --dry-run
# Would release 0.1.1        # explicit patch is always one increment from v0.1.0
```

For a brand-new repository with commits but no release tags yet, `git-semver-release version` starts from `0.1.0` and prints a pre-release such as `0.1.0-main.1.abcdef0`.

To version builds or cut releases in a pipeline, see [CI Usage](#ci-usage).

## Why Git SemVer Release

Use `git-semver-release` if you want:

- Git-based version calculation without a Node, Ruby, or JVM release framework, and without a project manifest such as `package.json`, `pom.xml`, `pyproject.toml`, or `build.gradle`.
- A version string you can reuse anywhere: Docker tags, Maven revisions, Gradle properties, SBT, shell scripts, custom deploy steps.
- Release tags to remain the source of truth instead of committed version-file bumps.
- A choice between explicit bump commands and [Conventional Commits](https://www.conventionalcommits.org/).
- A small single-file tool that is easy to audit, vendor, and debug. Version calculation is built on `git describe`; release tagging and changelog generation are layered on top.

Use something else if you need:

- Automated GitHub Releases or release notes publishing.
- Registry publishing orchestration across npm, PyPI, Maven Central, and similar ecosystems.
- Full changelog management beyond annotated Git tags.
- Automatic updates to project files such as `package.json`, `pom.xml`, or `pyproject.toml`.

Quick comparison:

| Tool | Best for | Tradeoff |
|-|-|-|
| `git-semver-release` | Small Git-based versioning and tagging in polyglot repos, with a Docker image | You handle downstream release publishing yourself |
| `semantic-release` | Full automated releases to package registries and hosting platforms | Requires a larger Node-based release setup |
| `release-please` | PR-driven release automation and release notes on GitHub | More opinionated around GitHub workflows and release PRs |
| `bump2version` / `bump-my-version` | Updating version strings inside project files | File edits become part of the release workflow |
| `git describe` | Raw Git-derived identifiers for builds and debugging | Not a SemVer release workflow and does not create release tags |

## Common Workflows

### Calculate the current version

```shell
git-semver-release version
```

Example output:

- `0.1.0-main.1.abcdef0` for a repo with commits but no release tags yet (channel defaults to the branch name, here `main`)
- `0.1.1-main.3.abcdef0` for three commits after `v0.1.0`
- `0.1.1-main.3.abcdef0.dirty` for the same commits plus uncommitted changes
- `1.2.3` when `HEAD` is exactly on tag `v1.2.3` and the working tree is clean

### Create a release manually

```shell
git-semver-release patch
git-semver-release minor
git-semver-release major
```

These commands create an annotated Git tag, print the released version, and fail if the working tree is dirty.

### Create a release from Conventional Commits

```shell
git-semver-release conventional
```

Commit messages since the last release determine the bump:

- `fix:` or `perf:` -> patch
- `feat:` -> minor
- A Conventional Commit type with `!:` (e.g. `feat!:`, `refactor!:`) or a `BREAKING CHANGE:` footer -> major

### Publish the tag immediately

```shell
git-semver-release conventional --push
git-semver-release minor --push
```

### Release from CI

See [CI Usage](#ci-usage) for the checkout settings CI needs and a complete GitHub Actions release job.

## Installation

### Homebrew

```shell
brew install michalstutzmann/git-semver-release/git-semver-release
```

The formula depends on Homebrew's Bash, so it also works on macOS, where `/bin/bash` is too old.

### Manual

```shell
curl -fsSL https://github.com/michalstutzmann/git-semver-release/releases/latest/download/git-semver-release \
  --create-dirs --output ~/.local/bin/git-semver-release && chmod +x ~/.local/bin/git-semver-release
```

Make sure `~/.local/bin` is in your `PATH`. To pin a version, replace `latest/download` with `download/vX.Y.Z`.

The script needs Bash 4+ and Git 2.13+. macOS ships Bash 3.2 as `/bin/bash`; install a newer Bash (for example `brew install bash`) and make sure it comes first in your `PATH`. Under an older Bash the script stops with exit code `1`.

### Docker

A multi-architecture (`linux/amd64`, `linux/arm64`) image is published to GitHub Container Registry: [`ghcr.io/michalstutzmann/git-semver-release`](https://github.com/michalstutzmann/git-semver-release/pkgs/container/git-semver-release). Tags:

- `:latest` and `:X.Y.Z` for each release. Pin `:X.Y.Z` in CI for reproducible results.
- `:X.Y.Z-CHANNEL.N.sha` (e.g. `:0.1.1-main.5.abcdef0`) for builds of branch commits between releases.

Run it from the repository root and mount the working tree at `/home`, the image's `WORKDIR`:

```shell
docker run --rm -v "$PWD:/home" ghcr.io/michalstutzmann/git-semver-release version
```

The default command is `version`, so you can also run:

```shell
docker run --rm -v "$PWD:/home" ghcr.io/michalstutzmann/git-semver-release
```

Pass any other command and flags after the image name:

```shell
docker run --rm -v "$PWD:/home" ghcr.io/michalstutzmann/git-semver-release conventional --dry-run
```

Annotated release tags need a Git identity, which the container does not have, so pass one through the environment. On Linux, also run as your own user so the new tag is not owned by `root`:

```shell
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e GIT_COMMITTER_NAME="$(git config user.name)" \
  -e GIT_COMMITTER_EMAIL="$(git config user.email)" \
  -v "$PWD:/home" \
  ghcr.io/michalstutzmann/git-semver-release conventional
```

The image has no SSH client, so `--push` only works there with HTTPS remotes whose credentials are available inside the container. It is usually simpler to push from the host afterwards:

```shell
git push origin HEAD --follow-tags
```

## Command Reference

```shell
git-semver-release [command] [options] [MESSAGE]
```

Without a command, `version` runs. An unknown command or option, a `--channel` without a value, or an extra argument (such as an unquoted multi-word `MESSAGE`) fails with exit code `3` instead of being ignored.

### `version`

```shell
git-semver-release version [--channel CHANNEL]
```

Prints the current version without creating a tag.

- If `HEAD` is on a release tag and the working tree is clean, it prints that version exactly.
- Otherwise (commits since the release, or uncommitted changes), it prints the next patch pre-release version.
- With no prior release, the initial pre-release is `0.1.0-CHANNEL.N.sha`, per the SemVer recommendation that initial development starts at `0.1.0`.

The pre-release channel defaults to the current branch name, normalized for SemVer (`feature/login` becomes `feature-login`); override it with `--channel` or the [`channel` property](#configuration). On a detached `HEAD`, which is common in CI, the branch name is `HEAD`, so [pass the channel explicitly](#set-the-channel-on-a-detached-head).

Release tags may be annotated or lightweight (e.g. created with plain `git tag v1.2.3`); both count for every command. Pre-release tags such as `v1.2.3-rc.1` and build-metadata tags such as `v1.2.3+build.7` never count as releases.

The examples below assume the branch is `main`.

| Latest release tag | Commits since release | Short SHA | Uncommitted changes | Output |
|-|-|-|-|-|
| *(none)* | 1 | `abcdef0` | no | `0.1.0-main.1.abcdef0` |
| `v0.1.0` | 0 | `abcdef0` | no | `0.1.0` |
| `v0.1.0` | 1 | `abcdef1` | no | `0.1.1-main.1.abcdef1` |
| `v0.1.1` | 0 | `abcdef1` | yes | `0.1.2-main.dirty` |
| `v0.1.1` | 1 | `abcdef1` | yes | `0.1.2-main.1.abcdef1.dirty` |

If no release tag is found and the clone is shallow, `version` also prints a warning on stderr, because the release tags may just be missing from the clone. See [CI Usage](#fetch-the-full-history-and-tags).

### `major`, `minor`, `patch`

```shell
git-semver-release (major|minor|patch) [--push] [--dry-run] [MESSAGE]
```

Creates an annotated tag `vMAJOR.MINOR.PATCH` and prints the released version (without the tag prefix) on stdout, so you can capture it:

```shell
new_version="$(git-semver-release patch)"
```

By default, the tag message is `Release $version` plus a changelog of commit subjects since the previous release:

```text
Release 1.2.0

Changes:
- Add search endpoint
- Fix null pointer on empty input
- Update dependencies
```

If you pass `MESSAGE`, it replaces the default annotation entirely. `$version` in it expands to the released version. Use single quotes so your shell does not expand `$version` first:

```shell
git-semver-release patch 'Release $version'
```

- `--push` pushes the current branch and the created tag to `origin`. If the push fails, the tag already exists locally: push it with `git push origin vX.Y.Z` rather than releasing again.
- `--dry-run` prints `Would release X.Y.Z` on stderr (nothing on stdout) without tagging or pushing.
- `--channel` is accepted for symmetry with `version` but has no effect here: explicit bumps always produce a plain `vMAJOR.MINOR.PATCH` tag.

The command fails with exit code `7` on a dirty working tree, and with `8` if the tag cannot be created (for example, it already exists or Git has no user identity for the annotation) or cannot be pushed.

| Latest release tag | `patch` | `minor` | `major` |
|-|-|-|-|
| *(none)* | `v0.1.0` | `v0.1.0` | `v1.0.0` |
| `v0.1.0` | `v0.1.1` | `v0.2.0` | `v1.0.0` |
| `v1.2.3` | `v1.2.4` | `v1.3.0` | `v2.0.0` |

With no prior release, both `patch` and `minor` finalize the initial pre-release `0.1.0-CHANNEL.N.sha` into `v0.1.0` (per the SemVer recommendation that initial development starts at `0.1.0`). Only `major` jumps past it to `v1.0.0`.

### `conventional`

```shell
git-semver-release conventional [--push] [--dry-run] [MESSAGE]
```

Determines the bump type from commit messages since the last release (or the whole history if there is none) using [Conventional Commits](https://www.conventionalcommits.org/), then releases exactly like the explicit commands above, with the same options, output, and failures.

If no releasable commits are found, it creates no tag and exits with code `9`. That code is reserved for "nothing to release", so CI can treat it as success while still failing on real errors:

```shell
git-semver-release conventional --push || [ $? -eq 9 ]
```

| Commit message pattern | Bump type | Example |
|-|-|-|
| Subject starts with `type!:` or `type(scope)!:` | major | `feat!: remove v1 API`, `refactor(api)!: drop endpoint` |
| `BREAKING CHANGE:` or `BREAKING-CHANGE:` anywhere in the message, usually as a footer | major | `feat: new API` with footer `BREAKING CHANGE: v1 removed` |
| Subject starts with `feat:` or `feat(scope):` | minor | `feat(auth): add OAuth login` |
| Subject starts with `fix:`, `perf:`, `fix(scope):`, or `perf(scope):` | patch | `fix: null pointer on empty input` |
| Everything else | skipped | `docs: update readme`, `Fix: typo`, `fix:typo` |

`feat`, `fix`, and `perf` must be lowercase, and the colon must be followed by a space and a description.

When multiple commits are present, the highest bump type wins (major > minor > patch):

| Latest release tag | Commits since release | Created tag |
|-|-|-|
| *(none)* | `fix: typo` | `v0.1.0` |
| `v0.0.1` | `feat: add search` | `v0.1.0` |
| `v0.0.1` | `feat(api): add search` | `v0.1.0` |
| `v0.1.0` | `feat!: redesign API` | `v1.0.0` |
| `v0.1.0` | `refactor(api)!: remove deprecated endpoints` | `v1.0.0` |
| `v1.0.0` | `fix: typo` then `feat: add search` then `fix: bug` | `v1.1.0` |
| `v1.0.0` | `feat: add search` then `feat!: new API` then `fix: bug` | `v2.0.0` |
| `v1.0.0` | `chore: update deps` then `docs: update readme` | *(none, exit code `9`)* |

### `release-tag`

```shell
git-semver-release release-tag
```

Prints the stable release tag at `HEAD` (e.g. `v1.2.3`) when `HEAD` is on a release and the working tree is clean, or an empty line otherwise. A dirty working tree is not the release, which matches `version` reporting a dirty pre-release there. Pre-release and build-metadata tags are ignored. The command exits with `0` either way.

Use it in CI to tell release builds from other builds, for example to also tag an image as `latest`:

```shell
version="$(git-semver-release version)"
docker build --tag "myregistry/myimage:$version" .
if [ -n "$(git-semver-release release-tag)" ]; then
  docker tag "myregistry/myimage:$version" myregistry/myimage:latest
fi
```

### Global flags

```shell
git-semver-release --version
git-semver-release --help    # also -h
```

`--version` prints the installed `git-semver-release` version. Source checkouts print `dev`; released artifacts have the version baked in at publish time. Both flags work outside a Git repository.

## Configuration

Customize behavior with a `.git-semver-release.properties` file. It is read from the current working directory, so run the command from the directory that contains it, usually the repository root.

The format is intentionally simple: one `key=value` pair per line, with no spaces around `=`. Blank lines and lines starting with `#` are ignored. Values are used verbatim: there is no quoting, escaping, inline comments, or multi-line values.

```properties
# These are the defaults, except channel, which defaults to the current branch name
channel=beta
dirty_indicator=dirty
pre_release_format=$channel$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
tag_prefix=v
```

| Property | Default | Description |
|-|-|-|
| `channel` | *current branch name* | Pre-release channel. `--channel` overrides it per invocation. |
| `dirty_indicator` | `dirty` | Added when the working tree has uncommitted changes. An empty value falls back to `dirty`; to drop the indicator, remove `$dirty_indicator` from `pre_release_format`. |
| `pre_release_format` | `$channel$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator` | Template for pre-release identifiers |
| `tag_prefix` | `v` | Prefix for release tags. Set it to an empty value (`tag_prefix=`) for tags like `1.2.3`. |

Variables available in `pre_release_format`:

| Variable | Replaced with |
|-|-|
| `$channel` | `--channel`, else the `channel` property, else the current branch name, with characters other than letters, digits, and `-` replaced by `-` |
| `$separator` | `.` |
| `$commit_count` | Number of commits since the last release tag (all commits if there is none); empty for a dirty checkout sitting on the release tag |
| `$commit_short_sha` | Abbreviated SHA of `HEAD`; empty for a dirty checkout sitting on the release tag |
| `$dirty_indicator` | Value of `dirty_indicator` when the tree is dirty, otherwise empty |
| `$branch` | Current branch name, normalized like `$channel`. Unlike `$channel`, it ignores `--channel` and the `channel` property. Kept for backwards compatibility. |

After the template is rendered, repeated dots are collapsed and leading/trailing dots are trimmed. That keeps custom formats valid when optional fields such as `$dirty_indicator` are empty.

Example that keeps the branch name visible while using a fixed channel:

```properties
channel=beta
pre_release_format=$channel$separator$branch$separator$commit_count
```

On branch `feature/login`, three commits after `v0.1.0`, this produces `0.1.1-beta.feature-login.3`.

## CI Usage

### Fetch the full history and tags

Versions are calculated from release tags in the history. Many CI systems clone shallowly by default (GitHub Actions fetches a single commit), which hides earlier releases, so versioning would silently restart at `0.1.0`.

When no release tag is found in a shallow clone, `version` prints a warning and release commands refuse to run (exit code `8`). Fetch everything instead:

- GitHub Actions: `fetch-depth: 0` on `actions/checkout`
- GitLab CI: `GIT_DEPTH: "0"`
- Elsewhere: `git fetch --unshallow --tags`

Make sure tags are fetched too: with full history but no tags there is nothing to detect, and versioning starts over at `0.1.0`.

### Set the channel on a detached HEAD

CI often checks out a detached `HEAD` (tag builds, GitHub pull requests, every GitLab CI job). The branch name is then `HEAD`, giving versions like `1.0.1-HEAD.3.abcdef0`. Pass the branch explicitly:

- GitHub Actions: `git-semver-release version --channel "${GITHUB_HEAD_REF:-$GITHUB_REF_NAME}"`
- GitLab CI: `git-semver-release version --channel "$CI_COMMIT_REF_NAME"`

A clean checkout of a release tag prints the plain version regardless of the channel.

### Give release jobs an identity and push access

Release tags are annotated, so Git needs a name and email: set `user.name` and `user.email`, or `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL`. `--push` also needs permission to push to `origin`.

### GitHub Actions release job

```yaml
name: Release
on:
  push:
    branches: [main]
permissions:
  contents: write # lets --push push the tag with GITHUB_TOKEN
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0 # full history and tags
      - name: Install git-semver-release
        run: |
          curl -fsSL https://github.com/michalstutzmann/git-semver-release/releases/latest/download/git-semver-release \
            --create-dirs --output "$HOME/.local/bin/git-semver-release"
          chmod +x "$HOME/.local/bin/git-semver-release"
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"
      - name: Release
        run: |
          git config user.name 'github-actions[bot]'
          git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
          # Exit code 9 means no releasable commits since the last release
          git-semver-release conventional --push || [ $? -eq 9 ]
```

Tags pushed with the default `GITHUB_TOKEN` do not trigger other workflows. If the tag push should start your publish workflow, give `actions/checkout` a personal access token or GitHub App token through its `token` input, or publish in the same job.

### Build tools

Pass the version to your build without editing project files.

Maven:

```shell
mvn --define="revision=$(git-semver-release version)" deploy
```

Gradle:

```shell
gradle -Pversion="$(git-semver-release version)" publish
```

SBT:

```shell
sbt "set version := \"$(git-semver-release version)\"" publish
```

Docker:

```shell
docker build --push --tag "myregistry/myimage:$(git-semver-release version)" .
```

## Exit Codes

| Code | Description |
|-|-|
| 0 | Success |
| 1 | Bash is older than 4 |
| 2 | Git is not installed |
| 3 | Invalid command line: unknown command or option, missing `--channel` value, or extra argument |
| 4 | Not a Git repository |
| 5 | No commits yet |
| 6 | Failed to calculate version |
| 7 | Uncommitted changes found (release commands only) |
| 8 | Release failed: the tag could not be created or pushed, or no release tag was found in a shallow clone |
| 9 | `conventional` found no releasable changes |
