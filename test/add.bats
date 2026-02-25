#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup

  # Mock gh to avoid real network calls during add (fetch is real but local)
  mock_gh 'echo "[]"'
}

@test "create new branch from default" {
  run_wt add new-feature

  assert_success

  # Worktree directory should exist
  assert [ -d "$TEST_WORKTREES/new-feature" ]

  # Branch should exist in bare repo
  git -C "$TEST_BARE" show-ref --verify --quiet "refs/heads/new-feature"
}

@test "create from custom base" {
  # Create a base branch with a unique commit
  create_test_worktree "base-branch"
  add_commit_to_worktree "base-branch" "base commit"
  local base_commit
  base_commit=$(git -C "$TEST_WORKTREES/base-branch" rev-parse HEAD)

  run_wt add from-base base-branch

  assert_success
  assert [ -d "$TEST_WORKTREES/from-base" ]

  # New branch should point to the base commit
  local new_commit
  new_commit=$(git -C "$TEST_WORKTREES/from-base" rev-parse HEAD)
  assert_equal "$new_commit" "$base_commit"
}

@test "existing worktree returns path idempotently" {
  create_test_worktree "already-exists"

  run_wt add already-exists

  assert_success
  # stdout should have the path
  assert_output --partial "$TEST_WORKTREES/already-exists"
}

@test "branch with slashes becomes hyphenated dir" {
  run_wt add feat/my-thing

  assert_success
  assert [ -d "$TEST_WORKTREES/feat-my-thing" ]
}

@test "shared files symlinked" {
  local shared="$BATS_TEST_TMPDIR/shared"
  mkdir -p "$shared"
  echo "env content" > "$shared/.env"
  echo "config content" > "$shared/config.local"

  # Update config to include SHARED
  cat > "$XDG_CONFIG_HOME/wt/repos/test-repo.conf" <<EOF
BARE="$TEST_BARE"
WORKTREES="$TEST_WORKTREES"
REPO="test-owner/test-repo"
DEFAULT_BRANCH="main"
SHARED="$shared"
EOF

  run_wt add with-shared

  assert_success
  assert [ -L "$TEST_WORKTREES/with-shared/.env" ]
  assert [ -L "$TEST_WORKTREES/with-shared/config.local" ]
}

@test "--no-symlink copies instead of symlinking" {
  local shared="$BATS_TEST_TMPDIR/shared"
  mkdir -p "$shared"
  echo "env content" > "$shared/.env"

  cat > "$XDG_CONFIG_HOME/wt/repos/test-repo.conf" <<EOF
BARE="$TEST_BARE"
WORKTREES="$TEST_WORKTREES"
REPO="test-owner/test-repo"
DEFAULT_BRANCH="main"
SHARED="$shared"
EOF

  run_wt add no-sym-test --no-symlink

  assert_success
  assert [ -f "$TEST_WORKTREES/no-sym-test/.env" ]
  # Should NOT be a symlink
  assert [ ! -L "$TEST_WORKTREES/no-sym-test/.env" ]
}

@test "stdout is path only, messages go to stderr" {
  run_wt add stdout-test

  assert_success
  # Last line of stdout should be just the path
  local last_line
  last_line=$(echo "$output" | tail -1)
  assert_equal "$last_line" "$TEST_WORKTREES/stdout-test"
}
