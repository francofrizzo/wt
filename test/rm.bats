#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "remove existing worktree" {
  create_test_worktree "to-remove"
  assert [ -d "$TEST_WORKTREES/to-remove" ]

  run_wt rm to-remove

  assert_success
  assert [ ! -d "$TEST_WORKTREES/to-remove" ]
}

@test "remove with --force removes dirty worktree" {
  create_test_worktree "dirty-remove"
  dirty_worktree "dirty-remove"

  run_wt rm --force dirty-remove

  assert_success
  assert [ ! -d "$TEST_WORKTREES/dirty-remove" ]
}

@test "remove non-existent worktree exits non-zero" {
  run_wt rm nonexistent

  assert_failure
}

@test "branch cleanup attempted after removal" {
  create_test_worktree "cleanup-branch"

  run_wt rm cleanup-branch

  assert_success
  assert_output --partial "Removed"
  # Worktree directory must be gone
  assert [ ! -d "$TEST_WORKTREES/cleanup-branch" ]
}

@test "default branch not deleted even if worktree removed" {
  # Create a worktree for main
  git -C "$TEST_BARE" worktree add "$TEST_WORKTREES/main" main 2>/dev/null

  run_wt rm main

  assert_success
  # main branch must still exist
  git -C "$TEST_BARE" show-ref --verify --quiet "refs/heads/main"
}
