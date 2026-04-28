# Git SemVer Release

Version your project from Git tags with a single Bash script. No language-specific release framework, no plugins, no runtime dependencies beyond [Git 2.13+](https://git-scm.com/) and [Bash 4+](https://www.gnu.org/software/bash/).

Use it as a local CLI, a [Docker image](#docker), a [GitHub Action](#github-action), or a [GitLab CI job](#gitlab-ci).

## Quickstart

Install it:

```shell
brew tap michalstutzmann/git-semver-release
brew install git-semver-release
```

or:

```shell
curl -fsSL https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/git-semver-release \
  --output ~/.local/bin/git-semver-release && chmod +x ~/.local/bin/git-semver-release
```

Then run:

```shell
git-semver-release version
# 0.0.1-alpha.3.abcdef0

git-semver-release conventional --dry-run
# Would release 0.1.0

git-semver-release patch --dry-run
# Would release 0.0.2
```

## Why Git SemVer Release

- Single-file Bash tool that works across polyglot repos.
- Derives versions directly from Git tags and history.
- Works locally, in Docker builds, in GitHub Actions, and in GitLab CI.
- Supports both explicit bump commands and [Conventional Commits](https://www.conventionalcommits.org/).
- Generates pre-release versions from branch and commit metadata without extra services.

## Common Workflows

### Calculate the current version

```shell
git-semver-release version
git-semver-release
```

Example output:

- `0.0.0-alpha.1.abcdef0` for a repo with commits but no release tags yet
- `0.0.1-alpha.3.abcdef0` for commits after `v0.0.0`
- `0.0.2-alpha.3.abcdef0.dirty` when the working tree is dirty
- `1.2.3` when `HEAD` is exactly on tag `v1.2.3`

### Create a release manually

```shell
git-semver-release patch
git-semver-release minor
git-semver-release major
```

These commands create an annotated Git tag and fail if the working tree is dirty.

### Create a release from Conventional Commits

```shell
git-semver-release conventional
```

Commit messages since the last release determine the bump:

- `fix:` or `perf:` -> patch
- `feat:` -> minor
- `feat!:` or `BREAKING CHANGE:` -> major

### Publish the tag immediately

```shell
git-semver-release conventional --push
git-semver-release minor --channel beta --push
```

## Why Use This Instead Of Heavier Release Tooling

Use `git-semver-release` if you want:

- Git-based version calculation without bringing in a Node, Ruby, or JVM release framework.
- A version string you can reuse anywhere: Docker tags, Maven revisions, Gradle properties, SBT, shell scripts, custom deploy steps.
- A small tool that is easy to audit, vendor, and debug.

Use something else if you need:

- Automated GitHub Releases or release notes publishing.
- Registry publishing orchestration across npm, PyPI, Maven Central, and similar ecosystems.
- Full changelog management beyond annotated Git tags.

Quick comparison:

| Tool | Best for | Tradeoff |
|-|-|-|
| `git-semver-release` | Small Git-based versioning and tagging in polyglot repos, with Docker, GitHub Actions, and GitLab CI integrations | You handle downstream release publishing yourself |
| `semantic-release` | Full automated releases to package registries and hosting platforms | Requires a larger Node-based release setup |
| `release-please` | PR-driven release automation and release notes on GitHub | More opinionated around GitHub workflows and release PRs |
| `git describe` | Raw Git-derived identifiers for builds and debugging | Not a SemVer release workflow and does not create release tags |

## Installation

### Homebrew

```shell
brew tap michalstutzmann/git-semver-release
brew install git-semver-release
```

### Manual

```shell
curl -fsSL https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/git-semver-release \
  --output ~/.local/bin/git-semver-release && chmod +x ~/.local/bin/git-semver-release
```

Make sure `~/.local/bin` is in your `PATH`.

### Docker

A prebuilt image is published to GitHub Container Registry: [`ghcr.io/michalstutzmann/git-semver-release`](https://github.com/michalstutzmann/git-semver-release/pkgs/container/git-semver-release). Tags include `latest`, `edge` (built from `main`), and one per release (`X.Y.Z`, `X.Y`, `X`).

```shell
docker run --rm -v "$PWD:/home" ghcr.io/michalstutzmann/git-semver-release version
```

Mount the working tree to `/home` (the image's `WORKDIR`). The default command is `version`, so you can also run:

```shell
docker run --rm -v "$PWD:/home" ghcr.io/michalstutzmann/git-semver-release
```

Pass any other command and flags after the image name:

```shell
docker run --rm -v "$PWD:/home" ghcr.io/michalstutzmann/git-semver-release conventional --dry-run
```

To push tags created inside the container, mount your Git credentials and pass `--push` as you would locally.

## Command Reference

### `version`

```shell
git-semver-release version
```

Returns the current version without creating a tag. If `HEAD` is on a release tag, it returns that version exactly. Otherwise, it returns the next patch pre-release version.

| Latest release tag | Commits since release | Short SHA | Uncommitted changes | Output |
|-|-|-|-|-|
| *(none)* | 1 | `abcdef0` | no | `0.0.0-alpha.1.abcdef0` |
| `v0.0.0` | 0 | `abcdef0` | no | `0.0.0` |
| `v0.0.0` | 1 | `abcdef1` | no | `0.0.1-alpha.1.abcdef1` |
| `v0.0.1` | 1 | `abcdef1` | yes | `0.0.2-alpha.1.abcdef1.dirty` |

### `major`, `minor`, `patch`

```shell
git-semver-release (major|minor|patch) [--channel CHANNEL] [--push] [--dry-run] [MESSAGE]
```

Creates an annotated tag `vMAJOR.MINOR.PATCH`. By default, the tag message is `Release $version` plus a changelog of commit subjects since the previous release.

```text
Release 1.2.0

Changes:
- Add search endpoint
- Fix null pointer on empty input
- Update dependencies
```

If you pass `MESSAGE`, it replaces the default annotation entirely. Use `$version` as a placeholder, for example `"Release $version"`.

`--channel` creates a pre-release tag such as `v1.0.0-beta`. `--push` pushes the created tag to `origin`. `--dry-run` prints what would be released without tagging or pushing.

| Latest release tag | `patch` | `minor` | `major` |
|-|-|-|-|
| *(none)* | `v0.0.1` | `v0.1.0` | `v1.0.0` |
| `v0.0.1` | `v0.0.2` | `v0.1.0` | `v1.0.0` |
| `v1.2.3` | `v1.2.4` | `v1.3.0` | `v2.0.0` |

### `conventional`

```shell
git-semver-release conventional [--channel CHANNEL] [--push] [--dry-run] [MESSAGE]
```

Determines the bump type from commit messages since the last release using [Conventional Commits](https://www.conventionalcommits.org/). The highest bump wins: major > minor > patch. If no releasable commits are found, the command exits with code `7`.

| Commit message pattern | Bump type | Example |
|-|-|-|
| Contains `!:` | major | `feat!: remove v1 API` |
| Contains `BREAKING CHANGE:` in the body | major | `feat: new API` with a breaking-change footer |
| Starts with `feat:` or `feat(scope):` | minor | `feat(auth): add OAuth login` |
| Starts with `fix:` or `perf:` | patch | `fix: null pointer on empty input` |
| Everything else | skipped | `docs: update readme` |

When multiple commits are present, the highest bump type wins:

| Latest release tag | Commits since release | Created tag |
|-|-|-|
| *(none)* | `fix: typo` | `v0.0.1` |
| `v0.0.1` | `feat: add search` | `v0.1.0` |
| `v0.0.1` | `feat(api): add search` | `v0.1.0` |
| `v0.1.0` | `feat!: redesign API` | `v1.0.0` |
| `v0.1.0` | `refactor(api)!: remove deprecated endpoints` | `v1.0.0` |
| `v1.0.0` | `fix: typo` then `feat: add search` then `fix: bug` | `v1.1.0` |
| `v1.0.0` | `feat: add search` then `feat!: new API` then `fix: bug` | `v2.0.0` |
| `v1.0.0` | `chore: update deps` then `docs: update readme` | *(skipped)* |

### `release-tag`

```shell
git-semver-release release-tag
```

Prints the tag at `HEAD` (e.g. `v1.2.3`) when it points to a release. Exits with code `1` otherwise.

### `create-config-file`

```shell
git-semver-release create-config-file
```

Creates `.git-semver-release.properties` in the current directory with default values.

## GitHub Action

Start with a copy-paste workflow:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    fetch-tags: true
    ref: ${{ github.ref }}
- uses: michalstutzmann/git-semver-release@v1
  id: git-semver-release
- run: echo "${{ steps.git-semver-release.outputs.version }}"
```

Release from Conventional Commits:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    fetch-tags: true
    ref: ${{ github.ref }}
- uses: michalstutzmann/git-semver-release@v1
  with:
    command: conventional
    push: true
```

Inputs:

| Input | Description | Default |
|-|-|-|
| `command` | `version`, `major`, `minor`, `patch`, or `conventional` | `version` |
| `push` | Push the created tag to `origin` | `false` |
| `channel` | Pre-release channel such as `alpha`, `beta`, `rc` | |
| `message` | Tag annotation message, supports `$version` | |

Outputs:

| Output | Description |
|-|-|
| `version` | The calculated version |

Important: use `fetch-depth: 0`, `fetch-tags: true`, and `ref: ${{ github.ref }}` on `actions/checkout` so the tool can see tags and full history.

The action also adds `git-semver-release` to `PATH`, so you can call it directly in later steps:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    fetch-tags: true
    ref: ${{ github.ref }}
- uses: michalstutzmann/git-semver-release@v1
- run: echo "$(git-semver-release version)"
```

## GitLab CI

Two integration options are available depending on your setup.

### Option 1: `include: remote`

Use the hosted GitLab template directly from GitHub:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'
```

The included template downloads the latest script and exposes a hidden job named `.git-semver-release`.

Calculate the current version:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'

semver:
  extends: .git-semver-release
```

Create a release using Conventional Commits:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'

release:
  extends: .git-semver-release
  variables:
    GSR_COMMAND: "conventional"
    GSR_PUSH: "true"
```

Use the calculated version in a downstream job:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'

semver:
  extends: .git-semver-release

deploy:
  stage: deploy
  needs: [semver]
  script:
    - echo "Deploying version $VERSION"
```

Variables:

| Variable | Description | Default |
|-|-|-|
| `GSR_COMMAND` | `version`, `major`, `minor`, `patch`, or `conventional` | `version` |
| `GSR_PUSH` | Push the created tag to `origin` | `false` |
| `GSR_CHANNEL` | Pre-release channel such as `alpha`, `beta`, `rc` | |
| `GSR_MESSAGE` | Tag annotation message, supports `$version` | |
| `GSR_SCRIPT_URL` | Script download URL | GitHub raw URL |

### Option 2: GitLab CI/CD Component

If your environment prefers GitLab components, mirror this repo to GitLab and include the component:

```yaml
include:
  - component: gitlab.com/<namespace>/git-semver-release/git-semver-release@main
    inputs:
      command: conventional
      push: true
```

Use the version in a downstream job:

```yaml
include:
  - component: gitlab.com/<namespace>/git-semver-release/git-semver-release@main

stages:
  - test
  - deploy

deploy:
  stage: deploy
  needs: [git-semver-release]
  script:
    - echo "Deploying version $VERSION"
```

Inputs:

| Input | Type | Description | Default |
|-|-|-|-|
| `stage` | `string` | Pipeline stage for the job | `test` |
| `version` | `string` | Version of the `git-semver-release` Docker image to use | `latest` |
| `command` | `string` | `version`, `major`, `minor`, `patch`, or `conventional` | `version` |
| `push` | `boolean` | Push the created tag to `origin` | `false` |
| `channel` | `string` | Pre-release channel such as `alpha`, `beta`, `rc` | |
| `message` | `string` | Tag annotation message, supports `$version` | |

Outputs:

The calculated version is exported as `$VERSION` via a [dotenv artifact](https://docs.gitlab.com/ee/ci/variables/#pass-an-environment-variable-to-another-job), so downstream jobs can reuse it directly.

Important: both GitLab options set `GIT_DEPTH: 0` and `GIT_STRATEGY: clone` so tags and history are available.

## Configuration

Customize behavior with `.git-semver-release.properties`:

```properties
channel=alpha
dirty_indicator=dirty
pre_release_format=$channel$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
tag_prefix=v
```

| Property | Default | Description |
|-|-|-|
| `channel` | `alpha` | Default pre-release channel |
| `dirty_indicator` | `dirty` | Added when the working tree has uncommitted changes |
| `pre_release_format` | `$channel$separator...` | Template for pre-release identifiers |
| `tag_prefix` | `v` | Prefix for Git tags |

Variables available in `pre_release_format`:

| Variable | Replaced with |
|-|-|
| `$channel` | Value of `channel` |
| `$separator` | `.` |
| `$commit_count` | Number of commits since the last release tag |
| `$commit_short_sha` | Abbreviated SHA of the latest commit |
| `$dirty_indicator` | `dirty_indicator` when the tree is dirty, otherwise empty |
| `$branch` | Current branch with non-alphanumeric characters normalized to `-` |

Example branch-based pre-release:

```properties
dirty_indicator=dirty
pre_release_format=$branch$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
```

This produces versions like `0.0.1-feature-login.3.abcdef0`.

## CI Examples

### Maven

```shell
mvn --define="revision=$(git-semver-release version)" deploy
```

### Gradle

```shell
gradle -Pversion="$(git-semver-release version)" publish
```

### SBT

```shell
sbt "set version := \"$(git-semver-release version)\"" publish
```

### Docker

```shell
docker build --push --tag "myregistry/myimage:$(git-semver-release version)" .
```

### GitHub Actions + Docker

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    fetch-tags: true
    ref: ${{ github.ref }}
- uses: michalstutzmann/git-semver-release@v1
- run: docker build --push --tag "myregistry/myimage:$(git-semver-release version)" .
```

## Exit Codes

| Code | Description |
|-|-|
| 0 | Success |
| 1 | Not a Git repository |
| 2 | No commits yet |
| 3 | Failed to create config file |
| 4 | Failed to calculate version |
| 5 | Uncommitted changes found |
| 6 | Failed to create release tag |
| 7 | No releasable changes found |

## Development

Prerequisites:

- [Bats 1.5.0+](https://bats-core.readthedocs.io/en/stable/)
- [Nectos Act](https://nektosact.com/) for local GitHub Action testing
- [GitHub CLI](https://cli.github.com/)

Run tests:

```shell
bats test/test.bats
```

Run the GitHub Action workflow locally:

```shell
act push -s GITHUB_TOKEN="$(gh auth token)"
```

On macOS with Colima, make sure `DOCKER_HOST` points to the Docker socket, for example `DOCKER_HOST=unix:///Users/<USER>/.colima/default/docker.sock`.

On macOS, use `--container-architecture linux/arm64`.
