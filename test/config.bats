#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "valid config parsed — all 6 keys set correctly" {
  local conf="$BATS_TEST_TMPDIR/full.conf"
  cat > "$conf" <<'EOF'
BARE="/path/to/bare"
WORKTREES="/path/to/worktrees"
REPO="owner/repo"
WORKSPACE="/path/to/workspace.code-workspace"
SHARED="/path/to/shared"
DEFAULT_BRANCH="develop"
EOF

  # Clear any existing values
  BARE="" WORKTREES="" REPO="" WORKSPACE="" SHARED="" DEFAULT_BRANCH=""
  _load_config "$conf"

  assert_equal "$BARE" "/path/to/bare"
  assert_equal "$WORKTREES" "/path/to/worktrees"
  assert_equal "$REPO" "owner/repo"
  assert_equal "$WORKSPACE" "/path/to/workspace.code-workspace"
  assert_equal "$SHARED" "/path/to/shared"
  assert_equal "$DEFAULT_BRANCH" "develop"
}

@test "comments ignored" {
  local conf="$BATS_TEST_TMPDIR/comments.conf"
  cat > "$conf" <<'EOF'
# This is a comment
BARE="/path/to/bare"
  # Indented comment
WORKTREES="/path/to/worktrees"
EOF

  BARE="" WORKTREES=""
  _load_config "$conf"

  assert_equal "$BARE" "/path/to/bare"
  assert_equal "$WORKTREES" "/path/to/worktrees"
}

@test "empty lines ignored" {
  local conf="$BATS_TEST_TMPDIR/empty.conf"
  cat > "$conf" <<'EOF'

BARE="/path/to/bare"

WORKTREES="/path/to/worktrees"

EOF

  BARE="" WORKTREES=""
  _load_config "$conf"

  assert_equal "$BARE" "/path/to/bare"
  assert_equal "$WORKTREES" "/path/to/worktrees"
}

@test "malformed lines ignored — injection attempts skipped" {
  local conf="$BATS_TEST_TMPDIR/malformed.conf"
  cat > "$conf" <<'EOF'
rm -rf /
$(echo pwned)
just bare words
BARE="/safe/path"
EOF

  BARE=""
  _load_config "$conf"

  assert_equal "$BARE" "/safe/path"
}

@test "unknown keys ignored" {
  local conf="$BATS_TEST_TMPDIR/unknown.conf"
  cat > "$conf" <<'EOF'
BARE="/path/to/bare"
UNKNOWN="should be ignored"
EVIL_KEY="nope"
EOF

  BARE="" UNKNOWN=""
  _load_config "$conf"

  assert_equal "$BARE" "/path/to/bare"
  assert_equal "${UNKNOWN:-}" ""
}

@test "unquoted values work" {
  local conf="$BATS_TEST_TMPDIR/unquoted.conf"
  cat > "$conf" <<'EOF'
BARE=/path/to/bare
WORKTREES=/path/to/worktrees
EOF

  BARE="" WORKTREES=""
  _load_config "$conf"

  assert_equal "$BARE" "/path/to/bare"
  assert_equal "$WORKTREES" "/path/to/worktrees"
}

@test "values with spaces (quoted) parsed correctly" {
  local conf="$BATS_TEST_TMPDIR/spaces.conf"
  cat > "$conf" <<'EOF'
BARE="/path with spaces/bare"
WORKTREES="/another path/worktrees"
EOF

  BARE="" WORKTREES=""
  _load_config "$conf"

  assert_equal "$BARE" "/path with spaces/bare"
  assert_equal "$WORKTREES" "/another path/worktrees"
}
