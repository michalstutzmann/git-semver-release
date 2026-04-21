# Git SemVer Release

A single Bash script that versions your project from Git tags using [Semantic Versioning](https://semver.org/). No plugins, no runtime dependencies beyond Git and Bash — works in any CI system or locally.

- **`version`** — calculates the current pre-release version without creating any tags
- **`major` / `minor` / `patch`** — creates an annotated Git tag with the bumped version
- **`conventional`** — creates a tag with the bump type determined from [Conventional Commits](https://www.conventionalcommits.org/)

## Installation

### Homebrew

```shell
brew tap michalstutzmann/git-semver-release
brew install git-semver-release
```

### Manual

```shell
curl https://raw.githubusercontent.com/michalstutzmann/git-semver-release/refs/heads/main/git-semver-release \
  --output ~/.local/bin/git-semver-release && chmod +x ~/.local/bin/git-semver-release
```

> Make sure `~/.local/bin` is in your `PATH`.

## Usage

### Current Version

```shell
git-semver-release version    # E.g. 0.0.1-alpha.3.abcdef0
```

or just:

```shell
git-semver-release            # E.g. 0.0.1-alpha.3.abcdef0
```

### Manual Bump

```shell
git-semver-release patch      # Creates v0.0.1 tag
git-semver-release minor      # Creates v0.1.0 tag
git-semver-release major      # Creates v1.0.0 tag
```

### Conventional Commits

```shell
git-semver-release conventional  # Creates v0.0.1 tag for fix:/perf: commits
git-semver-release conventional  # Creates v0.1.0 tag for feat: commits
git-semver-release conventional  # Creates v1.0.0 tag for breaking changes (!: or BREAKING CHANGE:)
```

## Prerequisites

- [Git 2.13+](https://git-scm.com/) — required for `git describe --exclude`
- [Bash 4+](https://www.gnu.org/software/bash/)

## Commands

### `version` — Calculate Pre-Release Version

```shell
git-semver-release version
```

Returns the current version **without creating a tag**. If HEAD is on a release tag, it returns that version exactly. Otherwise, it appends pre-release metadata in the SemVer format `MAJOR.MINOR.PATCH-PRE_RELEASE`.

| Latest release tag | Commits since release | Short SHA | Uncommitted changes | Output |
|-|-|-|-|-|
| *(none)* | 1 | `abcdef0` | no | `0.0.0-alpha.1.abcdef0` |
| `v0.0.0` | 0 | `abcdef0` | no | `0.0.0` |
| `v0.0.0` | 1 | `abcdef1` | no | `0.0.1-alpha.1.abcdef1` |
| `v0.0.1` | 1 | `abcdef1` | yes | `0.0.2-alpha.1.abcdef1.dirty` |

### `major` / `minor` / `patch` — Create Release Tag

```shell
git-semver-release (major|minor|patch) [--channel CHANNEL] [--push] [--dry-run] [MESSAGE]
```

Creates an annotated Git tag `vMAJOR.MINOR.PATCH`. Fails if there are uncommitted changes.

The optional `MESSAGE` becomes the tag annotation. Use `$version` as a placeholder for the calculated version number (e.g. `"Release $version"`).

Pass `--channel` to create a pre-release tag (e.g. `v1.0.0-alpha`, `v1.0.0-beta`, `v1.0.0-rc`). Pass `--push` to push the created tag to the `origin` remote. Pass `--dry-run` to preview the release without creating a tag or pushing.

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

### `conventional` — Release Using Conventional Commits

```shell
git-semver-release conventional [--channel CHANNEL] [--push] [--dry-run] [MESSAGE]
```

The bump type is determined from **all commit messages since the last release** following [Conventional Commits](https://www.conventionalcommits.org/). The highest bump type wins (major > minor > patch). Optional scopes (e.g. `feat(auth):`) are supported. If no commits match a releasable type, the release is skipped with exit code 7.

| Commit message pattern | Bump type | Example |
|-|-|-|
| Contains `!:` (breaking change indicator) | **major** | `feat!: remove v1 API` |
| Contains `BREAKING CHANGE:` in the message body | **major** | `feat: new API\nBREAKING CHANGE: removed v1` |
| Starts with `feat:` or `feat(<scope>):` | **minor** | `feat(auth): add OAuth login` |
| Starts with `fix:` / `perf:` (with optional scope) | **patch** | `fix: null pointer on empty input` |
| Everything else (`chore:`, `docs:`, non-conventional, etc.) | **skip** | `chore: update deps` |

| Latest release tag | Commits since release | Created tag |
|-|-|-|
| *(none)* | `fix: typo` | `v0.0.1` |
| `v0.0.1` | `feat: add search` | `v0.1.0` |
| `v0.0.1` | `feat(api): add search` | `v0.1.0` |
| `v0.1.0` | `feat!: redesign API` | `v1.0.0` |
| `v0.1.0` | `refactor(api)!: remove deprecated endpoints` | `v1.0.0` |
| `v1.0.0` | `feat: add filter\nBREAKING CHANGE: changed response format` | `v2.0.0` |
| `v1.0.0` | `fix: typo` → `feat: add search` → `fix: bug` | `v1.1.0` |
| `v1.0.0` | `feat: add search` → `feat!: new API` → `fix: bug` | `v2.0.0` |
| `v1.0.0` | `chore: update deps` → `docs: update readme` | *(skipped)* |

### `create-config-file` — Generate Default Configuration

```shell
git-semver-release create-config-file
```

Creates `.git-semver-release.properties` in the current directory with default values.

## Configuration

Customizable via `.git-semver-release.properties`:

```properties
channel=alpha
dirty_indicator=dirty
pre_release_format=$channel$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
tag_prefix=v
```

| Property | Default | Description |
|-|-|-|
| `channel` | `alpha` | Pre-release channel identifier (e.g. `alpha`, `beta`, `rc`) |
| `dirty_indicator` | `dirty` | Appended to pre-release versions when the working tree has uncommitted changes |
| `pre_release_format` | `$channel$separator…` | Template for pre-release identifiers (see variables below) |
| `tag_prefix` | `v` | Prefix for Git tags (e.g. `v` produces `v1.0.0`, empty produces `1.0.0`) |

### Variables

| Variable | Replaced with |
|-|-|
| `$channel` | Value of `channel` property |
| `$separator` | `.` (dot, hardcoded) |
| `$commit_count` | Number of commits since the last release tag |
| `$commit_short_sha` | Abbreviated SHA of the latest commit |
| `$dirty_indicator` | Value of `dirty_indicator` if there are uncommitted changes, empty otherwise |
| `$branch` | Current Git branch name (characters outside `[0-9A-Za-z-]` are replaced with `-`) |

### Example: Branch-Based Pre-Release

```properties
dirty_indicator=dirty
pre_release_format=$branch$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
```

This produces versions like `0.0.1-feature-login.3.abcdef0` instead of `0.0.1-alpha.3.abcdef0`.

## GitHub Action

### Inputs

| Input | Description | Default |
|-|-|-|
| `command` | Command to run: `version`, `major`, `minor`, `patch`, or `conventional` (conventional commits) | `version` |
| `push` | Push the created tag to the origin remote | `false` |
| `channel` | Create a pre-release tag with the given channel (e.g. `alpha`, `beta`, `rc`) | |
| `message` | Annotation message for the tag (supports `$version` placeholder) | |

### Outputs

| Output | Description |
|-|-|
| `version` | The calculated version |

> **Important:** Use `fetch-depth: 0`, `fetch-tags: true` and `ref: ${{ github.ref }}` on `actions/checkout` so the tool can access all tags and commit history.

### Examples

#### Get the current pre-release version

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

#### Create a release using conventional commits

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

#### Create a minor release with a channel

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    fetch-tags: true
    ref: ${{ github.ref }}
- uses: michalstutzmann/git-semver-release@v1
  with:
    command: minor
    channel: beta
    push: true
```

The action adds `git-semver-release` to `PATH`, so it can be called directly in subsequent steps:

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

Two integration options are available depending on your GitLab setup.

### Option 1: `include: remote`

Works directly from GitHub — no mirroring required:

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'
```

The included `gitlab-ci.yml` provides a hidden job `.git-semver-release` that you can extend in your pipeline.

#### Variables

| Variable | Description | Default |
|-|-|-|
| `GSR_COMMAND` | Command to run: `version`, `major`, `minor`, `patch`, or `conventional` (conventional commits) | `version` |
| `GSR_PUSH` | Push the created tag to the origin remote | `false` |
| `GSR_CHANNEL` | Create a pre-release tag with the given channel (e.g. `alpha`, `beta`, `rc`) | |
| `GSR_MESSAGE` | Annotation message for the tag (supports `$version` placeholder) | |

#### Examples

##### Get the current pre-release version

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'

semver:
  extends: .git-semver-release
```

##### Create a release using conventional commits

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'

release:
  extends: .git-semver-release
  variables:
    GSR_COMMAND: "conventional"
    GSR_PUSH: "true"
```

##### Create a minor release with a channel

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/michalstutzmann/git-semver-release/main/gitlab-ci.yml'

release:
  extends: .git-semver-release
  variables:
    GSR_COMMAND: "minor"
    GSR_CHANNEL: "beta"
    GSR_PUSH: "true"
```

##### Use the version in a downstream job

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

### Option 2: GitLab CI/CD Component

For environments where `include: remote` is restricted (e.g. corporate firewalls), the repo can be [mirrored to GitLab](https://docs.gitlab.com/ee/user/project/repository/mirror/) and used as a [CI/CD Component](https://docs.gitlab.com/ee/ci/components/) with typed inputs and validation.

#### Inputs

| Input | Type | Description | Default |
|-|-|-|-|
| `stage` | `string` | Pipeline stage for the job | `test` |
| `command` | `string` | Command to run: `version`, `major`, `minor`, `patch`, or `conventional` (conventional commits) | `version` |
| `push` | `boolean` | Push the created tag to the origin remote | `false` |
| `channel` | `string` | Create a pre-release tag with the given channel (e.g. `alpha`, `beta`, `rc`) | |
| `message` | `string` | Annotation message for the tag (supports `$version` placeholder) | |
| `script_url` | `string` | URL to download the git-semver-release script from | *(GitHub raw URL)* |

#### Examples

##### Get the current pre-release version

```yaml
include:
  - component: gitlab.com/<namespace>/git-semver-release/git-semver-release@main
```

##### Create a release using conventional commits

```yaml
include:
  - component: gitlab.com/<namespace>/git-semver-release/git-semver-release@main
    inputs:
      command: conventional
      push: true
```

##### Create a minor release with a channel

```yaml
include:
  - component: gitlab.com/<namespace>/git-semver-release/git-semver-release@main
    inputs:
      command: minor
      channel: beta
      push: true
```

##### Use the version in a downstream job

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

### Outputs

The calculated version is exported as `$VERSION` via a [dotenv artifact](https://docs.gitlab.com/ee/ci/variables/#pass-an-environment-variable-to-another-job), making it available to all downstream jobs.

> **Important:** Both options set `GIT_DEPTH: 0` and `GIT_STRATEGY: clone` so the tool can access all tags and commit history.

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
| 7 | No releasable changes found (conventional commits) |

## Development

### Prerequisites

- [Bats 1.5.0+](https://bats-core.readthedocs.io/en/stable/)
- [Nectos Act](https://nektosact.com/) (for local GitHub Action testing)
- [GitHub CLI](https://cli.github.com/)

### Run Tests

```shell
bats test/test.bats
```

### Run GitHub Action Workflow Locally

```shell
act push -s GITHUB_TOKEN="$(gh auth token)"
```

> Make sure `DOCKER_HOST` points to the Docker socket, e.g. on macOS with Colima: `DOCKER_HOST=unix:///Users/<USER>/.colima/default/docker.sock`

> On macOS use `--container-architecture linux/arm64`.
