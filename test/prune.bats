#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "prunes merged PRs with confirm y" {
  create_test_worktree "merged-prune"

  mock_gh 'case "$*" in
    *"pr list"*"--state merged"*) echo "[{\"headRefName\":\"merged-prune\",\"number\":50}]" ;;
    *) echo "[]" ;;
  esac'

  run bash -c "echo y | '$WT_BIN' prune"

  assert_success
  assert_output --partial "Removed"
  assert [ ! -d "$TEST_WORKTREES/merged-prune" ]
}

@test "prunes branches equal to default" {
  create_test_worktree "equal-prune"
  # Branch at same commit as main — will be detected as = main

  run bash -c "echo y | '$WT_BIN' prune"

  assert_success
  assert [ ! -d "$TEST_WORKTREES/equal-prune" ]
}

@test "skips dirty worktrees" {
  create_test_worktree "dirty-prune"
  dirty_worktree "dirty-prune"

  run_wt prune --dry-run

  assert_success
  assert_output --partial "Skipping"
  assert [ -d "$TEST_WORKTREES/dirty-prune" ]
}

@test "nothing to prune shows clean message" {
  create_test_worktree "unique-branch"
  add_commit_to_worktree "unique-branch" "unique commit"

  run_wt prune --dry-run

  assert_success
  assert_output --partial "No worktrees to clean up"
}

@test "abort on n keeps worktrees" {
  create_test_worktree "abort-prune"

  run bash -c "echo n | '$WT_BIN' prune"

  assert_success
  assert_output --partial "Aborted"
  assert [ -d "$TEST_WORKTREES/abort-prune" ]
}

@test "--dry-run shows list without deleting" {
  create_test_worktree "dryrun-prune"

  run_wt prune --dry-run

  assert_success
  assert_output --partial "Would remove"
  assert_output --partial "dryrun-prune"
  assert [ -d "$TEST_WORKTREES/dryrun-prune" ]
}
