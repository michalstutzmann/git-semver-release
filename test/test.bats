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
  # Modify tracked file without staging
  printf 'modified' > "$TEST_FILE"

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
  assert_output --regexp '^0\.0\.0-alpha\.1\.[0-9a-f]{7}$'
}

@test "Create initial conventional release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'fix: initial fix'

  run ./git-semver-release conventional 'Initial'
  assert_success
  assert_output '0.0.1'

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
  assert_output '0.0.1'
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

@test "Create patch release when HEAD is at the latest tag" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.2.3"

  run ./git-semver-release patch 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --partial 'v1.2.4'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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

  run ./git-semver-release conventional 'Release'
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
  # Modify tracked file without staging
  printf 'modified' > "$TEST_FILE"

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

  run ./git-semver-release conventional 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.1\.0$'
}

@test "Auto-bump patch with fix commit beyond tag" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create a fix commit
  commit 'fix: typo'

  run ./git-semver-release conventional 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.1$'
}

@test "Auto-bump patch with perf commit beyond tag" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create a perf commit
  commit 'perf: optimize query'

  run ./git-semver-release conventional 'Release'
  assert_success
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.1$'
}

@test "Push tag and branch commits to remote with --push flag" {
  # Initialize bare remote repository
  env -u GIT_DIR -u GIT_WORK_TREE git init --bare tmp/remote
  # Initialize Git repository
  initialize
  git remote add origin "$PWD/tmp/remote"
  # Create initial commit
  commit 'fix: initial fix'

  run --separate-stderr ./git-semver-release patch --push
  assert_success
  assert_output '0.0.1'

  # Verify tag was pushed to remote
  run env -u GIT_DIR -u GIT_WORK_TREE git -C tmp/remote tag
  assert_output 'v0.0.1'

  # Verify branch commits were pushed to remote
  run env -u GIT_DIR -u GIT_WORK_TREE git -C tmp/remote rev-parse "$(git rev-parse HEAD)"
  assert_success
}

@test "Skip release when all commits are non-releasable" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create non-releasable commits
  commit 'chore: update deps'
  commit 'docs: update readme'

  run --separate-stderr ./git-semver-release conventional
  assert_failure 7
  assert_stderr 'error: no releasable changes found'
}

@test "Skip release for non-conventional commits" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create a non-conventional commit
  commit 'update something'

  run --separate-stderr ./git-semver-release conventional
  assert_failure 7
  assert_stderr 'error: no releasable changes found'
}

@test "No patch bump when HEAD is at the latest tag" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create release tag
  tag "v1.0.0"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^1\.0\.0$'
}

@test "release-tag prints tag when HEAD is on a release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create release tag
  tag "v1.2.3"

  run ./git-semver-release release-tag
  assert_success
  assert_output 'v1.2.3'
}

@test "release-tag prints tag when HEAD is on a release with dirty tree" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create release tag
  tag "v1.2.3"
  # Dirty the working tree
  printf 'modified' > "$TEST_FILE"

  run ./git-semver-release release-tag
  assert_success
  assert_output 'v1.2.3'
}

@test "release-tag prints empty string when HEAD is not on a release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create release tag
  tag "v1.2.3"
  # Move HEAD past the release
  commit 'Second'

  run ./git-semver-release release-tag
  assert_success
  assert_output ''
}

@test "release-tag ignores pre-release tags at HEAD" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create pre-release tag only (no stable release at HEAD)
  tag "v1.2.3-alpha.1"

  run ./git-semver-release release-tag
  assert_success
  assert_output ''
}

@test "Non-conventional bang message does not trigger major bump" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create a non-conventional commit with bang
  commit 'this is not conventional!: something'

  run --separate-stderr ./git-semver-release conventional
  assert_failure 7
  assert_stderr 'error: no releasable changes found'
}

@test "Message starting with feat prefix but not a conventional commit does not trigger minor bump" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create a commit that starts with 'feat' but is not a conventional commit
  commit 'featuring: new stuff'

  run --separate-stderr ./git-semver-release conventional
  assert_failure 7
  assert_stderr 'error: no releasable changes found'
}

@test "Dry run does not create tag for explicit release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run --separate-stderr ./git-semver-release patch --dry-run
  assert_success
  assert_stderr 'Would release 0.0.1'

  # Verify no tag was created
  run git tag
  assert_output ''
}

@test "Dry run does not create tag for conventional release" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create conventional commit
  commit 'feat: new feature'

  run --separate-stderr ./git-semver-release conventional --dry-run
  assert_success
  assert_stderr 'Would release 1.1.0'

  # Verify no new tag was created
  run git tag
  assert_output 'v1.0.0'
}

@test "Dry run does not push tag" {
  # Initialize bare remote repository
  env -u GIT_DIR -u GIT_WORK_TREE git init --bare tmp/remote
  # Initialize Git repository
  initialize
  git remote add origin "$PWD/tmp/remote"
  # Create initial commit
  commit 'fix: initial fix'

  run --separate-stderr ./git-semver-release patch --push --dry-run
  assert_success
  assert_stderr 'Would release 0.0.1'

  # Verify no tag was pushed to remote
  run env -u GIT_DIR -u GIT_WORK_TREE git -C tmp/remote tag
  assert_output ''
}

@test "Use custom tag prefix from config" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create custom config with empty prefix
  printf 'tag_prefix=\n' > .git-semver-release.properties
  # Create release tag without prefix
  tag "1.0.0"
  # Create another commit
  commit 'fix: bug fix'

  run ./git-semver-release conventional
  assert_success
  assert_output '1.0.1'
  run git tag --points-at HEAD
  assert_output --regexp '^1\.0\.1$'
  rm -f .git-semver-release.properties
}

@test "Use custom dirty indicator from config" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create custom config
  printf 'dirty_indicator=modified\n' > .git-semver-release.properties
  # Modify tracked file without staging
  printf 'modified' > "$TEST_FILE"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.modified$'
  rm -f .git-semver-release.properties
}

@test "Pre-release tag does not affect stable version calculation" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create another commit
  commit 'Second'
  # Create pre-release tag
  tag "v1.0.1-alpha"
  # Create another commit
  commit 'Third'

  run ./git-semver-release patch
  assert_success
  assert_output '1.0.1'
  run git tag --points-at HEAD
  assert_output --regexp '^v1\.0\.1$'
}

@test "Pre-release tag does not affect version command" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create initial release tag
  tag "v1.0.0"
  # Create another commit
  commit 'Second'
  # Create pre-release tag
  tag "v1.0.1-alpha"
  # Create another commit
  commit 'Third'

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^1\.0\.1-alpha\.2\.[0-9a-f]{7}$'
}

@test "Default command without arguments behaves like version" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release
  assert_success
  assert_output --regexp '^0\.0\.0-alpha\.1\.[0-9a-f]{7}$'
}

@test "--help prints usage and exits 0" {
  run ./git-semver-release --help
  assert_success
  assert_output --partial 'usage: git-semver-release'
}

@test "-h prints usage and exits 0" {
  run ./git-semver-release -h
  assert_success
  assert_output --partial 'usage: git-semver-release'
}

@test "Push tag with --push flag for conventional release" {
  # Initialize bare remote repository
  env -u GIT_DIR -u GIT_WORK_TREE git init --bare tmp/remote
  # Initialize Git repository
  initialize
  git remote add origin "$PWD/tmp/remote"
  # Create conventional commit
  commit 'feat: initial feature'

  run --separate-stderr ./git-semver-release conventional --push
  assert_success
  assert_output '0.1.0'

  # Verify tag was pushed to remote
  run env -u GIT_DIR -u GIT_WORK_TREE git -C tmp/remote tag
  assert_output 'v0.1.0'

  # Verify branch commits were pushed to remote
  run env -u GIT_DIR -u GIT_WORK_TREE git -C tmp/remote rev-parse "$(git rev-parse HEAD)"
  assert_success
}

@test "Use custom pre_release_format with branch variable from config" {
  # Initialize Git repository
  initialize
  # Use a non-default branch name
  git checkout -b feature/login 2>/dev/null
  # Custom format using $branch
  printf 'pre_release_format=$branch$separator$commit_count$separator$commit_short_sha\n' > .git-semver-release.properties
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^0\.0\.0-feature-login\.1\.[0-9a-f]{7}$'
  rm -f .git-semver-release.properties
}

@test "Use custom channel from config" {
  # Initialize Git repository
  initialize
  # Set channel in config
  printf 'channel=beta\n' > .git-semver-release.properties
  # Create initial commit
  commit 'Initial'

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^0\.0\.0-beta\.1\.[0-9a-f]{7}$'
  rm -f .git-semver-release.properties
}

@test "Calculate version at release tag with dirty tree" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create release tag
  tag "v1.2.3"
  # Dirty the working tree
  printf 'modified' > "$TEST_FILE"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '\.dirty$'
}

@test "Fail with explicit error when describe output is unrecognized" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create a tag that matches the describe glob but fails the semver regex
  tag "v1.2.3.4"

  run --separate-stderr ./git-semver-release version
  assert_failure 4
  assert_stderr --partial 'unrecognized git describe output'
}

@test "Non-semver tag does not interfere with version calculation" {
  # Initialize Git repository
  initialize
  # Create initial commit
  commit 'Initial'
  # Create a non-semver tag (would have been picked up by the loose glob)
  tag "v1.2"

  run ./git-semver-release version
  assert_success
  assert_output --regexp '^0\.0\.0-alpha\.1\.[0-9a-f]{7}$'
}

@test "Auto-generated tag message includes changelog of commits since last release" {
  # Initialize Git repository
  initialize
  # Create initial commit and release
  commit 'Initial'
  tag "v0.0.0"
  # Create commits to be included in the changelog
  commit 'fix: null pointer'
  commit 'feat: add search'

  run ./git-semver-release patch
  assert_success

  run git tag -l --format='%(contents)' v0.0.1
  assert_output --partial 'Release 0.0.1'
  assert_output --partial '- feat: add search'
  assert_output --partial '- fix: null pointer'
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
