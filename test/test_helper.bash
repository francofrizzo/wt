#!/bin/bash

# Shared test infrastructure for wt BATS tests.
#
# Every test gets:
#   - Isolated $HOME and $XDG_CONFIG_HOME in $BATS_TEST_TMPDIR
#   - A fresh bare git repo ($TEST_BARE) with one initial commit on main
#   - A worktrees directory ($TEST_WORKTREES)
#   - A pre-written config at ~/.config/wt/repos/test-repo.conf
#   - A mock gh on $PATH (returns [] by default)
#   - run_wt helper that calls bin/wt
#   - bin/wt sourced (Phase 3 guard) for direct function testing

_common_setup() {
  load 'lib/bats-support/load'
  load 'lib/bats-assert/load'

  WT_BIN="$BATS_TEST_DIRNAME/../bin/wt"

  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_CONFIG_HOME="$HOME/.config"
  mkdir -p "$HOME"

  # Git needs user config to commit
  git config --global user.email "test@test.com"
  git config --global user.name "Test User"
  git config --global init.defaultBranch main

  # Resolve to canonical path (macOS /var -> /private/var)
  local tmpdir
  tmpdir=$(cd "$BATS_TEST_TMPDIR" && pwd -P)
  TEST_BARE="$tmpdir/test-repo.git"
  TEST_WORKTREES="$tmpdir/test-repo-worktrees"
  mkdir -p "$TEST_WORKTREES"

  # Create a bare repo with one commit on main
  git init --bare "$TEST_BARE" 2>/dev/null
  local tmp_clone="$BATS_TEST_TMPDIR/_init_clone"
  git clone "$TEST_BARE" "$tmp_clone" 2>/dev/null
  git -C "$tmp_clone" checkout -b main 2>/dev/null
  echo "init" > "$tmp_clone/README.md"
  git -C "$tmp_clone" add . 2>/dev/null
  git -C "$tmp_clone" commit -m "initial commit" 2>/dev/null
  git -C "$tmp_clone" push origin main 2>/dev/null
  rm -rf "$tmp_clone"

  # Set up origin remote pointing to itself (for local fetch operations)
  git -C "$TEST_BARE" remote add origin "$TEST_BARE" 2>/dev/null || true
  git -C "$TEST_BARE" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null
  git -C "$TEST_BARE" fetch origin 2>/dev/null
  # Set HEAD to main so git branch -d can check merge status
  git -C "$TEST_BARE" symbolic-ref HEAD refs/heads/main

  # Write config
  local config_dir="$XDG_CONFIG_HOME/wt/repos"
  mkdir -p "$config_dir"
  cat > "$config_dir/test-repo.conf" <<EOF
BARE="$TEST_BARE"
WORKTREES="$TEST_WORKTREES"
REPO="test-owner/test-repo"
DEFAULT_BRANCH="main"
EOF

  # Mock gh on PATH (default: return [])
  local mock_bin="$BATS_TEST_TMPDIR/mock_bin"
  mkdir -p "$mock_bin"
  cat > "$mock_bin/gh" <<'MOCKGH'
#!/bin/bash
# Default mock: return empty JSON array
echo "[]"
MOCKGH
  chmod +x "$mock_bin/gh"
  export PATH="$mock_bin:$PATH"

  # Source wt for direct function testing (Phase 3 guard prevents main() from running)
  source "$WT_BIN"
}

# Override the mock gh with custom behavior.
# Usage: mock_gh 'case "$*" in *"pr list"*) echo "[...]" ;; *) echo "[]" ;; esac'
mock_gh() {
  local mock_bin="$BATS_TEST_TMPDIR/mock_bin"
  cat > "$mock_bin/gh" <<MOCKGH
#!/bin/bash
$1
MOCKGH
  chmod +x "$mock_bin/gh"
}

# Run the wt binary (not sourced — triggers main()).
run_wt() {
  run "$WT_BIN" "$@"
}

# Create a worktree in the test bare repo.
# Usage: create_test_worktree <branch> [base]
create_test_worktree() {
  local branch="$1"
  local base="${2:-main}"
  local dir="${branch//\//-}"
  git -C "$TEST_BARE" worktree add --no-track -b "$branch" "$TEST_WORKTREES/$dir" "$base" 2>/dev/null
}

# Add a commit to a worktree.
# Usage: add_commit_to_worktree <branch> [message]
add_commit_to_worktree() {
  local branch="$1"
  local msg="${2:-test commit}"
  local dir="${branch//\//-}"
  echo "$msg" >> "$TEST_WORKTREES/$dir/file.txt"
  git -C "$TEST_WORKTREES/$dir" add . 2>/dev/null
  git -C "$TEST_WORKTREES/$dir" commit -m "$msg" 2>/dev/null
}

# Make a worktree dirty (modified tracked file).
dirty_worktree() {
  local branch="$1"
  local dir="${branch//\//-}"
  echo "dirty" >> "$TEST_WORKTREES/$dir/README.md"
}

# Make a worktree have untracked files.
untracked_in_worktree() {
  local branch="$1"
  local dir="${branch//\//-}"
  echo "untracked" > "$TEST_WORKTREES/$dir/untracked_file.txt"
}
