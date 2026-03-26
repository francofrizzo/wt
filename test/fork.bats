#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "fork from clean worktree" {
  create_test_worktree "source-branch"
  add_commit_to_worktree "source-branch" "source commit"
  local source_commit
  source_commit=$(git -C "$TEST_WORKTREES/source-branch" rev-parse HEAD)

  cd "$TEST_WORKTREES/source-branch"
  run_wt fork forked-branch

  assert_success
  assert [ -d "$TEST_WORKTREES/forked-branch" ]

  # New branch should be at same commit
  local fork_commit
  fork_commit=$(git -C "$TEST_WORKTREES/forked-branch" rev-parse HEAD)
  assert_equal "$fork_commit" "$source_commit"
}

@test "fork with dirty state transfers changes" {
  create_test_worktree "dirty-source"
  dirty_worktree "dirty-source"

  cd "$TEST_WORKTREES/dirty-source"
  run_wt fork dirty-fork

  assert_success
  assert [ -d "$TEST_WORKTREES/dirty-fork" ]

  # Source should be clean after fork
  local source_status
  source_status=$(git -C "$TEST_WORKTREES/dirty-source" status --porcelain)
  assert_equal "$source_status" ""

  # New worktree should have the changes
  local fork_status
  fork_status=$(git -C "$TEST_WORKTREES/dirty-fork" status --porcelain)
  assert [ -n "$fork_status" ]
}

@test "fork with untracked files transfers them" {
  create_test_worktree "untracked-source"
  untracked_in_worktree "untracked-source"

  cd "$TEST_WORKTREES/untracked-source"
  run_wt fork untracked-fork

  assert_success

  # Untracked file should be in new worktree
  assert [ -f "$TEST_WORKTREES/untracked-fork/untracked_file.txt" ]

  # Source should be clean
  local source_untracked
  source_untracked=$(git -C "$TEST_WORKTREES/untracked-source" ls-files --others --exclude-standard)
  assert_equal "$source_untracked" ""
}

@test "fork --keep preserves changes in both worktrees" {
  create_test_worktree "keep-source"
  dirty_worktree "keep-source"

  cd "$TEST_WORKTREES/keep-source"
  run_wt fork keep-fork --keep

  assert_success
  assert [ -d "$TEST_WORKTREES/keep-fork" ]

  # Source should still have changes
  local source_status
  source_status=$(git -C "$TEST_WORKTREES/keep-source" status --porcelain)
  assert [ -n "$source_status" ]

  # New worktree should also have the changes
  local fork_status
  fork_status=$(git -C "$TEST_WORKTREES/keep-fork" status --porcelain)
  assert [ -n "$fork_status" ]
}

@test "fork --keep with untracked files preserves them in both" {
  create_test_worktree "keep-untracked"
  untracked_in_worktree "keep-untracked"

  cd "$TEST_WORKTREES/keep-untracked"
  run_wt fork keep-untracked-fork --keep

  assert_success

  # Untracked file should be in both worktrees
  assert [ -f "$TEST_WORKTREES/keep-untracked/untracked_file.txt" ]
  assert [ -f "$TEST_WORKTREES/keep-untracked-fork/untracked_file.txt" ]
}

@test "fork preserves relative path in output" {
  create_test_worktree "path-source"
  mkdir -p "$TEST_WORKTREES/path-source/subdir/nested"

  cd "$(cd "$TEST_WORKTREES/path-source/subdir/nested" && pwd -P)"
  run_wt fork path-fork

  assert_success
  assert_output --partial "path-fork/subdir/nested"
}

@test "fork outside worktree exits 1" {
  cd "$BATS_TEST_TMPDIR"

  run_wt fork should-fail

  assert_failure
  assert_output --partial "not inside a worktree"
}
