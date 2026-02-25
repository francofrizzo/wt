#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "--repo flag selects config" {
  WT_REPO="test-repo"
  resolve_repo

  assert_equal "$BARE" "$TEST_BARE"
  assert_equal "$WORKTREES" "$TEST_WORKTREES"
  assert_equal "$REPO" "test-owner/test-repo"
}

@test "nonexistent --repo exits 1" {
  WT_REPO="nonexistent"
  run resolve_repo

  assert_failure
  assert_output --partial "Unknown repo: nonexistent"
}

@test "CWD inside worktree resolves correct config" {
  create_test_worktree "feature-a"
  cd "$TEST_WORKTREES/feature-a"

  WT_REPO=""
  BARE="" WORKTREES="" REPO="" DEFAULT_BRANCH=""
  resolve_repo

  assert_equal "$BARE" "$TEST_BARE"
  assert_equal "$WORKTREES" "$TEST_WORKTREES"
}

@test "single config fallback when CWD matches nothing" {
  cd "$BATS_TEST_TMPDIR"

  WT_REPO=""
  BARE="" WORKTREES="" REPO="" DEFAULT_BRANCH=""
  resolve_repo

  assert_equal "$BARE" "$TEST_BARE"
}

@test "multiple configs with no CWD match exits 1" {
  # Add a second config
  cat > "$XDG_CONFIG_HOME/wt/repos/other-repo.conf" <<EOF
BARE="/tmp/other.git"
WORKTREES="/tmp/other-worktrees"
REPO="other/repo"
DEFAULT_BRANCH="main"
EOF

  cd "$BATS_TEST_TMPDIR"

  WT_REPO=""
  BARE="" WORKTREES="" REPO="" DEFAULT_BRANCH=""
  run resolve_repo

  assert_failure
  assert_output --partial "Could not determine repo"
  assert_output --partial "test-repo"
  assert_output --partial "other-repo"
}
