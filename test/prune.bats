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

@test "never prunes main worktree even when DEFAULT_BRANCH differs" {
  # Override DEFAULT_BRANCH to something other than main
  local config_dir="$XDG_CONFIG_HOME/wt/repos"
  cat > "$config_dir/test-repo.conf" <<EOF
BARE="$TEST_BARE"
WORKTREES="$TEST_WORKTREES"
REPO="test-owner/test-repo"
DEFAULT_BRANCH="develop"
EOF

  # Create a develop branch and a main worktree
  git -C "$TEST_BARE" branch develop main 2>/dev/null
  git -C "$TEST_BARE" fetch origin 2>/dev/null
  git -C "$TEST_BARE" worktree add "$TEST_WORKTREES/main" main 2>/dev/null

  run_wt prune --dry-run

  assert_success
  refute_output --partial "main"
  assert [ -d "$TEST_WORKTREES/main" ]
}

@test "--dry-run shows list without deleting" {
  create_test_worktree "dryrun-prune"

  run_wt prune --dry-run

  assert_success
  assert_output --partial "Would remove"
  assert_output --partial "dryrun-prune"
  assert [ -d "$TEST_WORKTREES/dryrun-prune" ]
}

@test "-i prompts per worktree and removes only y answers" {
  create_test_worktree "keep-me"
  create_test_worktree "remove-me"

  mock_gh 'case "$*" in
    *"pr list"*"--state merged"*) echo "[{\"headRefName\":\"keep-me\",\"number\":1},{\"headRefName\":\"remove-me\",\"number\":2}]" ;;
    *) echo "[]" ;;
  esac'

  run bash -c "printf 'n\ny\n' | '$WT_BIN' prune -i"

  assert_success
  assert [ -d "$TEST_WORKTREES/keep-me" ]
  assert [ ! -d "$TEST_WORKTREES/remove-me" ]
}

@test "-i with all n answers removes nothing" {
  create_test_worktree "merged-keep"

  mock_gh 'case "$*" in
    *"pr list"*"--state merged"*) echo "[{\"headRefName\":\"merged-keep\",\"number\":3}]" ;;
    *) echo "[]" ;;
  esac'

  run bash -c "echo n | '$WT_BIN' prune -i"

  assert_success
  assert_output --partial "Nothing removed"
  assert [ -d "$TEST_WORKTREES/merged-keep" ]
}

@test "--all lists active branches that prune would skip" {
  create_test_worktree "active-feat"
  add_commit_to_worktree "active-feat" "new work"

  run_wt prune --all --dry-run

  assert_success
  assert_output --partial "active-feat"
  assert_output --partial "active"
  assert [ -d "$TEST_WORKTREES/active-feat" ]
}

@test "--all without -i: single confirm removes all" {
  create_test_worktree "all-feat"
  add_commit_to_worktree "all-feat" "unmerged"

  run bash -c "echo y | '$WT_BIN' prune --all"

  assert_success
  assert [ ! -d "$TEST_WORKTREES/all-feat" ]
}

@test "--all -i force-removes dirty worktree on y" {
  create_test_worktree "dirty-all"
  add_commit_to_worktree "dirty-all" "unmerged"
  dirty_worktree "dirty-all"

  run bash -c "echo y | '$WT_BIN' prune --all -i"

  assert_success
  assert_output --partial "dirty"
  assert [ ! -d "$TEST_WORKTREES/dirty-all" ]
}

@test "--all never touches default branch worktree" {
  git -C "$TEST_BARE" worktree add "$TEST_WORKTREES/main" main 2>/dev/null
  create_test_worktree "other-feat"

  run_wt prune --all --dry-run

  assert_success
  refute_output --partial "(main)"
  assert_output --partial "other-feat"
}

@test "-a short flag works like --all" {
  create_test_worktree "short-flag"
  add_commit_to_worktree "short-flag" "unmerged"

  run_wt prune -a --dry-run

  assert_success
  assert_output --partial "short-flag"
}
