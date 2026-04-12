# Git SemVer Release

A single Bash script that versions your project from Git tags using [Semantic Versioning](https://semver.org/). No plugins, no runtime dependencies beyond Git and Bash — works in any CI system or locally.

- **`version`** — calculates the current pre-release version without creating any tags
- **`major` / `minor` / `patch`** — creates an annotated Git tag with the bumped version
- **(default)** — creates a tag with the bump type determined from [Conventional Commits](https://www.conventionalcommits.org/)

## Quick Start

```shell
# Install
curl https://raw.githubusercontent.com/michalstutzmann/git-semver-release/refs/heads/main/git-semver-release \
  --output ~/.local/bin/git-semver-release && chmod +x ~/.local/bin/git-semver-release

# Get current pre-release version
git-semver-release version        # e.g. 0.0.1-dev.3.abcdef0

# Create a release tag
git-semver-release patch           # creates v0.0.1
```

> Make sure `~/.local/bin` is in your `PATH`.

## Prerequisites

- [Git 2.4+](https://git-scm.com/) — required for `git tag --points-at`
- [Bash 4+](https://www.gnu.org/software/bash/)

## Commands

### `version` — Calculate Pre-Release Version

```shell
git-semver-release version
```

Returns the current version **without creating a tag**. If HEAD is on a release tag, it returns that version exactly. Otherwise, it increments PATCH and appends pre-release metadata in the SemVer format `MAJOR.MINOR.PATCH-PRE_RELEASE`.

| Latest release tag | Commits since release | Short SHA | Uncommitted changes | Output |
|-|-|-|-|-|
| *(none)* | 1 | `abcdef0` | no | `0.0.1-dev.1.abcdef0` |
| `v0.0.0` | 0 | `abcdef0` | no | `0.0.0` |
| `v0.0.0` | 1 | `abcdef1` | no | `0.0.1-dev.1.abcdef1` |
| `v0.0.1` | 1 | `abcdef1` | yes | `0.0.2-dev.1.abcdef1.dirty` |

### `major` / `minor` / `patch` — Create Release Tag

```shell
git-semver-release (major|minor|patch) [MESSAGE]
```

Creates an annotated Git tag `vMAJOR.MINOR.PATCH`. Fails if there are uncommitted changes.

The optional `MESSAGE` becomes the tag annotation. Use `$version` as a placeholder for the calculated version number (e.g. `"Release $version"`).

**Patch** bumps the third number:

| Latest release tag | Created tag |
|-|-|
| *(none)* | `v0.0.1` |
| `v0.0.0` | `v0.0.1` |
| `v0.0.1` | `v0.0.2` |
| `v0.1.0` | `v0.1.1` |

**Major and minor** bump their respective number and reset the lower ones to zero:

| Latest release tag | `major` | `minor` |
|-|-|-|
| `v0.0.1` | `v1.0.0` | `v0.1.0` |
| `v1.2.3` | `v2.0.0` | `v1.3.0` |

### *(default)* — Release Using Conventional Commits

```shell
git-semver-release [MESSAGE]
```

When called without `major`, `minor`, or `patch`, the bump type is determined from the latest commit message following [Conventional Commits](https://www.conventionalcommits.org/). Optional scopes (e.g. `feat(auth):`) are supported.

| Commit message pattern | Bump type | Example |
|-|-|-|
| Contains `!:` (breaking change indicator) | **major** | `feat!: remove v1 API` |
| Contains `BREAKING CHANGE:` in the message body | **major** | `feat: new API\nBREAKING CHANGE: removed v1` |
| Starts with `feat:` or `feat(<scope>):` | **minor** | `feat(auth): add OAuth login` |
| Everything else | **patch** | `fix: null pointer on empty input` |

| Latest release tag | Latest commit message | Created tag |
|-|-|-|
| *(none)* | `fix: typo` | `v0.0.1` |
| `v0.0.1` | `feat: add search` | `v0.1.0` |
| `v0.0.1` | `feat(api): add search` | `v0.1.0` |
| `v0.1.0` | `feat!: redesign API` | `v1.0.0` |
| `v0.1.0` | `refactor(api)!: remove deprecated endpoints` | `v1.0.0` |
| `v1.0.0` | `feat: add filter\nBREAKING CHANGE: changed response format` | `v2.0.0` |

### `create-config-file` — Generate Default Configuration

```shell
git-semver-release create-config-file
```

Creates `.git-semver-release.properties` in the current directory with default values.

## Configuration

The pre-release format is customizable via `.git-semver-release.properties`:

```properties
dirty_indicator=dirty
pre_release_format=dev$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
build_format=
```

### Variables

| Variable | Replaced with |
|-|-|
| `$separator` | `.` (dot, hardcoded) |
| `$commit_count` | Number of commits since the last release tag |
| `$commit_short_sha` | 7-character SHA of the latest commit |
| `$dirty_indicator` | Value of `dirty_indicator` if there are uncommitted changes, empty otherwise |
| `$branch` | Current Git branch name |

### Example: Branch-Based Pre-Release

```properties
dirty_indicator=dirty
pre_release_format=$branch$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
build_format=
```

This produces versions like `0.0.1-feature-login.3.abcdef0` instead of `0.0.1-dev.3.abcdef0`.

## Exit Codes

| Code | Meaning |
|-|-|
| 0 | Success |
| 1 | Not a Git repository |
| 2 | No commits in the repository |
| 3 | Failed to create config file |
| 4 | Failed to calculate version |
| 5 | Uncommitted changes (release commands only) |
| 6 | Failed to create release tag (explicit bump) |
| 7 | Failed to create release tag (conventional commits) |

## GitHub Action

### Inputs

| Input | Description | Required | Default |
|-|-|-|-|
| `command` | `version`, `major`, `minor`, `patch`, or `''` for conventional commits | no | `version` |
| `message` | Tag annotation (supports `$version` placeholder) | no | |

### Outputs

| Output | Description |
|-|-|
| `version` | The calculated or released version string |

> **Important:** Use `fetch-depth: 0` on `actions/checkout` so the tool can access all tags and commit history.

### Examples

Get current development version:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
- uses: michalstutzmann/git-semver-release@v1
  id: semver
  with:
    command: version
- run: echo "${{ steps.semver.outputs.version }}"
```

Create a release tag using conventional commits:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
- uses: michalstutzmann/git-semver-release@v1
  id: semver
  with:
    command: ''
    message: 'Release $version'
```

Create a release tag with explicit bump type:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
- uses: michalstutzmann/git-semver-release@v1
  id: semver
  with:
    command: patch
    message: 'Release $version'
```

## CI Examples

### Maven (CI-Friendly)

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
- uses: michalstutzmann/git-semver-release@v1
  id: semver
  with:
    command: version
- run: docker build --push --tag "myregistry/myimage:${{ steps.semver.outputs.version }}" .
```

## Development

### Prerequisites

- [Bats 1.5.0+](https://bats-core.readthedocs.io/en/stable/)
- [Nectos Act](https://nektosact.com/) (for local GitHub Action testing)
- [GitHub CLI](https://cli.github.com/)

### Run Tests

```shell
bats test/test.bats
```

### Run GitHub Action Locally

```shell
act push -s GITHUB_TOKEN="$(gh auth token)"
```

> Make sure `DOCKER_HOST` points to the Docker socket, e.g. on macOS with Colima: `DOCKER_HOST=unix:///Users/<USER>/.colima/default/docker.sock`

> On macOS use `--container-architecture linux/arm64`.
