# Git SemVer Release

A command-line tool for creating Git tag-based releases using Semantic Versioning (SemVer).

The tool creates Git tags for releases in the format "vMAJOR.MINOR.PATCH" and calculates current version for pre-releases in the SemVer format "MAJOR.MINOR.PATCH-PRE_RELEASE+BUILD". 
For releases the MAJOR, MINOR or PATCH part is incremented before creating the tag.
For pre-releases the PATCH part is incremented and additional information placed in the PRE-RELEASE and BUILD parts.
The additional information is fully customizable with a configuration file .git-semver-release.properties:

```
dirty_indicator=dirty
pre_release_format=dev$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator
build_format=
```

Available variables for `pre_release_format` and `build_format`:

| Variable | Description |
|---|---|
| `$separator` | Replaced with `.` (dot) |
| `$commit_count` | Number of commits since the last release |
| `$commit_short_sha` | Short SHA of the latest commit |
| `$dirty_indicator` | Replaced with the value of `dirty_indicator` if there are uncommitted changes |
| `$branch` | Current Git branch name |

You can generate a default configuration file with:

```shell
git-semver-release create-config-file
```

## Prerequisites

* [Git 2.4+](https://git-scm.com/) - `git tag --points-at` support
* [Bash 4+](https://www.gnu.org/software/bash/)

## Installation

Download the tool to ~/.local/bin:

```shell
curl https://raw.githubusercontent.com/michalstutzmann/git-semver-release/refs/heads/main/git-semver-release --output ~/.local/bin/git-semver-release
chmod +x ~/.local/bin/git-semver-release
```

> Make sure ~/.local/bin is in your PATH.

## Usage

Get current development version:

```shell
git-semver-release version
```

Examples (with default configuration):

| Latest release tag | Latest commit short SHA | # of commits since last release | Modified tracked files and/or staged changes | `git-semver-release version` output |
|--------------------|-------------------------|---------------------------------|----------------------------------------------|-------------------------------------|
| -                  | abcdef0                 | 0                               | no                                           | 0.0.0-dev.1.abcdef0                 |
| v0.0.0             | abcdef0                 | 0                               | no                                           | 0.0.0                               |
| v0.0.0             | abcdef1                 | 1                               | no                                           | 0.0.1-dev.1.abcdef1                 |
| v0.0.1             | abcdef1                 | 1                               | yes                                          | 0.0.2-dev.1.abcdef1.dirty           |

Create release tag:

```shell
git-semver-release (major|minor|patch) [MESSAGE]
```

The MESSAGE can contain `$version` which will be replaced with the calculated version number.

Examples (patch with default configuration):

| Latest release tag | Uncommitted changes | `git-semver-release patch` release tag |
|--------------------|---------------------|----------------------------------------|
| -                  | no                  | v0.0.1                                 |
| -                  | yes                 | -  (error: uncommitted changes)        |
| v0.0.0             | no                  | v0.0.1                                 |
| v0.0.1             | no                  | v0.0.2                                 |
| v0.1.0             | no                  | v0.1.1                                 |

Examples (major/minor):

| Latest release tag | `git-semver-release major` | `git-semver-release minor` |
|--------------------|----------------------------|----------------------------|
| v0.0.1             | v1.0.0                     | v0.1.0                     |
| v1.2.3             | v2.0.0                     | v1.3.0                     |

Create release tag using conventional commits (default when no subcommand is given):

```shell
git-semver-release [MESSAGE]
```

When called without `major`, `minor`, or `patch`, the tool determines the version bump type from the latest commit message using [Conventional Commits](https://www.conventionalcommits.org/):

- **major**: commit message contains `!:` (breaking change indicator) or `BREAKING CHANGE:` in the body
- **minor**: commit message starts with `feat:`
- **patch**: all other commit messages

Examples (conventional):

| Latest release tag | Latest commit message matches regex  | `git-semver-release` release tag |
|--------------------|--------------------------------------|----------------------------------|
| -                  | `^[a-z]+: .+$`                      | v0.0.1                           |
| v0.0.1             | `^feat: .+$`                        | v0.1.0                           |
| v0.1.0             | `^feat!: .+$`                       | v1.0.0                           |
| v1.0.0             | `^feat: .+\nBREAKING CHANGE: .+$`   | v2.0.0                           |

## Use Cases

### Setting Version for Publishing in CI Pipeline

#### Maven CI-Friendly

```shell
mvn --define="revision=$(git-semver-release version)" deploy
```

#### Gradle

```shell
gradle -Pversion="$(git-semver-release version)" publish
```

#### SBT

```shell
sbt "set version := \"$(git-semver-release version)\"" publish
```

#### Docker

```shell
docker build --push --tag "myregistry/myimage:$(git-semver-release version)" .
```

## Development

### Testing

#### Prerequisites

* [Bats 1.5.0+](https://bats-core.readthedocs.io/en/stable/)
* [Nectos Act](https://nektosact.com/)
* [GitHub CLI](https://cli.github.com/)

#### Local

```shell
bats test/test.bats
```

#### Local GitHub Action

```shell
act push -s GITHUB_TOKEN="$(gh auth token)"
```

> Make sure `DOCKER_HOST` environment variable points to the Docker socket, e.g.: using Colima on Mac OS DOCKER_HOST=unix:///Users/<USER>/.colima/default/docker.sock

> On Mac OS use `--container-architecture linux/arm64`.
