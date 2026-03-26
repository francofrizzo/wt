#!/usr/bin/env bats

setup() {
  load test_helper
  _common_setup
}

@test "creates settings.json with worktree directory" {
  run_wt claude-setup

  assert_success
  assert_output --partial "$TEST_WORKTREES"

  local settings="$HOME/.claude/settings.json"
  [ -f "$settings" ]
  run jq -r '.permissions.additionalDirectories[0]' "$settings"
  assert_output "$TEST_WORKTREES"
}

@test "preserves existing settings" {
  mkdir -p "$HOME/.claude"
  cat > "$HOME/.claude/settings.json" <<'EOF'
{
  "voiceEnabled": true,
  "promptSuggestionEnabled": false
}
EOF

  run_wt claude-setup
  assert_success

  local settings="$HOME/.claude/settings.json"
  run jq -r '.voiceEnabled' "$settings"
  assert_output "true"
  run jq -r '.promptSuggestionEnabled' "$settings"
  assert_output "false"
  run jq -r '.permissions.additionalDirectories[0]' "$settings"
  assert_output "$TEST_WORKTREES"
}

@test "idempotent — no duplicates on second run" {
  run_wt claude-setup
  assert_success
  run_wt claude-setup
  assert_success

  local settings="$HOME/.claude/settings.json"
  run jq '.permissions.additionalDirectories | length' "$settings"
  assert_output "1"
}

@test "multiple repos add multiple directories" {
  local config_dir="$XDG_CONFIG_HOME/wt/repos"
  local tmpdir
  tmpdir=$(cd "$BATS_TEST_TMPDIR" && pwd -P)
  local second_worktrees="$tmpdir/second-worktrees"
  mkdir -p "$second_worktrees"
  cat > "$config_dir/second-repo.conf" <<EOF
BARE="$tmpdir/second.git"
WORKTREES="$second_worktrees"
EOF

  run_wt claude-setup
  assert_success

  local settings="$HOME/.claude/settings.json"
  run jq '.permissions.additionalDirectories | length' "$settings"
  assert_output "2"
}

@test "no repos configured exits 1" {
  rm "$XDG_CONFIG_HOME/wt/repos/test-repo.conf"

  run_wt claude-setup
  assert_failure
  assert_output --partial "No repositories configured"
}
