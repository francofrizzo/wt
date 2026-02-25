#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
  export WORKSPACE="$BATS_TEST_TMPDIR/test.code-workspace"
}

@test "strips trailing commas" {
  cat > "$WORKSPACE" <<'EOF'
{
  "folders": [
    {"path": "/first"},
    {"path": "/second"},
  ],
}
EOF

  run workspace_read
  assert_success
  # Output should be valid JSON
  echo "$output" | jq . >/dev/null 2>&1
  assert_equal $? 0
}

@test "strips // line comments" {
  cat > "$WORKSPACE" <<'EOF'
{
  // This is a comment
  "folders": [
    {"path": "/first"} // inline comment
  ]
}
EOF

  run workspace_read
  assert_success
  echo "$output" | jq . >/dev/null 2>&1
  assert_equal $? 0
}

@test "strips /* */ block comments" {
  cat > "$WORKSPACE" <<'EOF'
{
  /* This is a
     block comment */
  "folders": [
    {"path": "/first"}
  ]
}
EOF

  run workspace_read
  assert_success
  echo "$output" | jq . >/dev/null 2>&1
  assert_equal $? 0
}

@test "workspace_add adds folder entry" {
  cat > "$WORKSPACE" <<'EOF'
{
  "folders": [
    {"path": "/existing"}
  ]
}
EOF

  workspace_add "/new/worktree"

  local count
  count=$(jq '.folders | length' "$WORKSPACE")
  assert_equal "$count" "2"

  local first_path
  first_path=$(jq -r '.folders[0].path' "$WORKSPACE")
  assert_equal "$first_path" "/new/worktree"
}

@test "workspace_remove removes folder entry" {
  cat > "$WORKSPACE" <<'EOF'
{
  "folders": [
    {"path": "/keep"},
    {"path": "/remove-me"}
  ]
}
EOF

  workspace_remove "/remove-me"

  local count
  count=$(jq '.folders | length' "$WORKSPACE")
  assert_equal "$count" "1"

  local remaining
  remaining=$(jq -r '.folders[0].path' "$WORKSPACE")
  assert_equal "$remaining" "/keep"
}

@test "no-op when WORKSPACE unset" {
  unset WORKSPACE

  run workspace_add "/some/path"
  assert_success
  assert_output ""

  run workspace_remove "/some/path"
  assert_success
  assert_output ""
}
