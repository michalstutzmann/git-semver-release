setup_file() {
  bats_require_minimum_version 1.5.0

  # Point Git to a test repo in `tmp` directory
  export GIT_DIR=tmp/.git
  export GIT_WORK_TREE=tmp
  export TEST_FILE=tmp/test
}

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  mkdir -p tmp
}

teardown() {
  rm -rf tmp
}

@test "Fail if Git repository is not initialized" {
  run --separate-stderr ./git-semver-release version
  assert_failure 1
  assert_stderr 'fatal: not a Git repository'
}

@test "Fail if Git repository is empty" {
  # Initialize Git repository
  initialize

  run --separate-stderr ./git-semver-release version
  assert_failure 2
  assert_stderr 'error: no commits yet'
}

@test "Detect dirty tree with untracked files" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create an untracked file
  printf 'untracked' > tmp/untracked

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.dirty$'
}

@test "Detect dirty tree with unstaged modifications" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Modify tracked file without staging
  printf 'modified' > "$TEST_FILE"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.dirty$'
}

@test "Detect dirty tree with staged but uncommitted changes" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Stage a change without committing
  printf 'staged' > "$TEST_FILE"
  git add test

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.dirty$'
}

@test "Fail release when tree is dirty" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create an untracked file
  printf 'untracked' > tmp/untracked

  run --separate-stderr ./git-semver-release patch 'Release'
  assert_failure 5
  assert_stderr 'error: uncommitted changes found'
}

@test "Calculate version for commit without previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^0\.0\.0-dev\.1\.[0-9a-f]{7}$'
}

@test "Create initial release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release 'Initial'
  assert_success

  run git tag --points-at HEAD
  assert_output --regexp '^v0\.0\.1$'
}

@test "Get version of the latest tag pointing to the same commit" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create second release tag
  tag "v0.0.1"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^0\.0\.1$'
}

@test "Create patch release without previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release patch 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.0\.1$'
}

@test "Create minor release without previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release minor 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.1\.0$'
}

@test "Create major release without previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  # Create release
  run ./git-semver-release major 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.0$'
}

@test "Create patch release with previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create second commit
  commit 'Second'

  run ./git-semver-release patch 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.0\.1$'
}

@test "Create minor release with previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create second commit
  commit 'Second'

  run ./git-semver-release minor 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.1\.0$'
}

@test "Create major release with previous release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create second commit
  commit 'Second'

  # Create release
  run ./git-semver-release major 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.0$'
}

@test "Calculate version of patch release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create second commit
  commit 'Second'
  # Create second release tag
  tag "v0.0.1"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^0\.0\.1$'
}

@test "Create conventional commit release without previous tag" {
  # Initialize Git repository
  initialize
  # Create conventional commit
  commit 'feat: initial feature'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.1\.0$'
}

@test "Create patch release with conventional commit" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create conventional commit
  commit 'fix: fix'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.0\.1$'
}

@test "Create minor release with conventional commit" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create conventional commit
  commit 'feat: feature'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.1\.0$'
}

@test "Create minor release with scoped conventional commit" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create scoped conventional commit
  commit 'feat(auth): add login'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.1\.0$'
}

@test "Create major release with conventional commit using bang" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create conventional commit
  commit 'feat!: feature'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.0$'
}

@test "Create major release with scoped conventional commit using bang" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create scoped conventional commit with bang
  commit 'refactor(api)!: redesign endpoints'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.0$'
}

@test "Create major release with conventional commit using footer" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create conventional commit
  commit $'feat: feature\n\nBREAKING CHANGE: breaking change'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.0$'
}

@test "Scan all commits since last tag: fix then feat bumps minor" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create multiple conventional commits
  commit 'fix: first fix'
  commit 'feat: new feature'
  commit 'fix: second fix'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v0\.1\.0$'
}

@test "Scan all commits since last tag: feat then breaking change bumps major" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v0.0.0"
  # Create multiple conventional commits
  commit 'feat: new feature'
  commit 'feat!: breaking feature'
  commit 'fix: small fix'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.0$'
}

@test "Expand version placeholder in tag message" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release patch 'Release $version'
  assert_success
  run git tag -n1 --points-at HEAD
  assert_output --regexp 'Release 0\.0\.1'
}

@test "Detect dirty tree with commits beyond tag" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create release tag
  tag "v1.0.0"
  # Create another commit
  commit 'Second'
  # Create an untracked file
  printf 'untracked' > tmp/untracked

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.dirty$'
}

@test "Scan all commits since last tag: earlier feat wins over latest fix" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create multiple conventional commits — feat is earlier, fix is latest
  commit 'feat: add search'
  commit 'fix: typo'

  run ./git-semver-release 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.1\.0$'
}

@test "Create config file" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release create-config-file
  assert_success
  run cat .git-semver-release.properties
  assert_output --partial 'dirty_indicator=dirty'
  assert_output --partial 'pre_release_format=dev$separator$commit_count$separator$commit_short_sha$separator$dirty_indicator'
  rm -f .git-semver-release.properties
}

@test "Use custom dirty indicator from config" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create custom config
  printf 'dirty_indicator=modified\n' > .git-semver-release.properties
  # Create an untracked file
  printf 'untracked' > tmp/untracked

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.modified$'
  rm -f .git-semver-release.properties
}

initialize() {
  git init
  git config user.name 'test'
  git config user.email 'test'
}

commit() {
  local name="$1"

  printf '%s' "$name" > "$TEST_FILE"
  git add .
  git commit -am "$name"
}

tag() {
  local name="$1"

  git tag --annotate "$name" --message "$name"
}
