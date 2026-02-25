#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "lists all worktrees" {
  create_test_worktree "branch-a"
  create_test_worktree "branch-b"

  run_wt list

  assert_success
  assert_output --partial "branch-a"
  assert_output --partial "branch-b"
}

@test "shows last commit message" {
  create_test_worktree "commit-test"
  add_commit_to_worktree "commit-test" "my unique commit message"

  run_wt list

  assert_success
  assert_output --partial "my unique commit message"
}

@test "shows open PR with number" {
  create_test_worktree "pr-branch"
  add_commit_to_worktree "pr-branch" "pr commit"

  mock_gh 'case "$*" in
    *"pr list"*"--state open"*) echo "[{\"headRefName\":\"pr-branch\",\"number\":42,\"reviewDecision\":\"\"}]" ;;
    *"pr list"*"--state merged"*) echo "[]" ;;
    *"check-runs"*) echo "{\"check_runs\":[]}" ;;
    *) echo "[]" ;;
  esac'

  run_wt list

  assert_success
  assert_output --partial "PR #42"
}

@test "shows merged PR" {
  create_test_worktree "merged-branch"

  mock_gh 'case "$*" in
    *"pr list"*"--state open"*) echo "[]" ;;
    *"pr list"*"--state merged"*) echo "[{\"headRefName\":\"merged-branch\",\"number\":99,\"mergedAt\":\"2025-01-15T10:00:00Z\"}]" ;;
    *) echo "[]" ;;
  esac'

  run_wt list

  assert_success
  assert_output --partial "merged"
  assert_output --partial "PR #99"
}

@test "shows CI pass/fail/running" {
  create_test_worktree "ci-branch"
  add_commit_to_worktree "ci-branch" "ci commit"

  mock_gh 'case "$*" in
    *"pr list"*"--state open"*) echo "[{\"headRefName\":\"ci-branch\",\"number\":10,\"reviewDecision\":\"\"}]" ;;
    *"pr list"*"--state merged"*) echo "[]" ;;
    *"check-runs"*) echo "failure" ;;
    *) echo "[]" ;;
  esac'

  run_wt list

  assert_success
  assert_output --partial "fail"
}

@test "shows dirty worktree" {
  create_test_worktree "dirty-list"
  dirty_worktree "dirty-list"

  run_wt list

  assert_success
  assert_output --partial "changed"
}

@test "shows no unique commits indicator" {
  create_test_worktree "equal-branch"
  # Branch is at same commit as main — no unique commits

  run_wt list

  assert_success
  assert_output --partial "no unique commits"
}
