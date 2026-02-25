#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "init with local file:// URL" {
  # Create a source repo to clone from
  local src="$BATS_TEST_TMPDIR/source-repo.git"
  git clone --bare "$TEST_BARE" "$src" 2>/dev/null
  git -C "$src" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null

  local init_dir="$BATS_TEST_TMPDIR/init-test"
  mkdir -p "$init_dir"
  cd "$init_dir"

  run_wt init "file://$src" --default-branch main

  assert_success

  # Config should be created
  assert [ -f "$XDG_CONFIG_HOME/wt/repos/source-repo.conf" ]

  # Bare repo should exist
  local bare_path="$init_dir/source-repo.git"
  assert [ -d "$bare_path" ]

  # Worktrees dir should exist
  assert [ -d "$init_dir/source-repo-worktrees" ]
}

@test "init with --bare explicit" {
  local my_bare="$BATS_TEST_TMPDIR/explicit.git"
  git clone --bare "$TEST_BARE" "$my_bare" 2>/dev/null

  run_wt init myproject --bare "$my_bare" --default-branch main

  assert_success
  assert [ -f "$XDG_CONFIG_HOME/wt/repos/myproject.conf" ]

  # Config should have correct BARE path
  run grep "^BARE=" "$XDG_CONFIG_HOME/wt/repos/myproject.conf"
  assert_output --partial "$my_bare"
}

@test "init from inside a worktree (auto-detect)" {
  create_test_worktree "detect-test"
  cd "$(cd "$TEST_WORKTREES/detect-test" && pwd -P)"

  # Remove existing config so init creates a fresh one
  rm -f "$XDG_CONFIG_HOME/wt/repos/test-repo.conf"

  run_wt init --name detected-repo --default-branch main

  assert_success
  assert [ -f "$XDG_CONFIG_HOME/wt/repos/detected-repo.conf" ]
}

@test "init with all optional flags" {
  local my_bare="$BATS_TEST_TMPDIR/flagtest.git"
  git clone --bare "$TEST_BARE" "$my_bare" 2>/dev/null

  local ws_file="$BATS_TEST_TMPDIR/my.code-workspace"
  echo '{"folders":[]}' > "$ws_file"

  local shared_dir="$BATS_TEST_TMPDIR/shared"
  mkdir -p "$shared_dir"

  local wt_dir="$BATS_TEST_TMPDIR/custom-worktrees"

  run_wt init flagtest --bare "$my_bare" \
    --worktrees "$wt_dir" \
    --workspace "$ws_file" \
    --shared "$shared_dir" \
    --default-branch develop

  assert_success

  local conf="$XDG_CONFIG_HOME/wt/repos/flagtest.conf"
  assert [ -f "$conf" ]

  run grep "WORKSPACE=" "$conf"
  assert_output --partial "$ws_file"

  run grep "SHARED=" "$conf"
  assert_output --partial "$shared_dir"

  run grep "DEFAULT_BRANCH=" "$conf"
  assert_output --partial "develop"
}

@test "init outside worktree without --bare exits 1" {
  cd "$BATS_TEST_TMPDIR"

  # Not inside any git repo, no --bare flag
  run_wt init

  assert_failure
  assert_output --partial "Not inside a git worktree"
}
