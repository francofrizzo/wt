#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "cd to existing worktree prints correct path" {
  create_test_worktree "cd-target"

  run_wt cd cd-target

  assert_success
  assert_output "$TEST_WORKTREES/cd-target"
}

@test "cd to nonexistent worktree exits 1" {
  run_wt cd no-such-branch

  assert_failure
  assert_output --partial "Worktree not found"
}

@test "cd with slashes in branch name resolves to hyphenated dir" {
  create_test_worktree "feat/slash-test"

  run_wt cd feat/slash-test

  assert_success
  assert_output "$TEST_WORKTREES/feat-slash-test"
}
