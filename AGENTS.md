# CLAUDE.md

## Project Overview

`wt` is a git worktree manager with GitHub integration. It's a single-file Bash CLI tool (`bin/wt`, ~630 lines) that automates creating, listing, removing, and pruning git worktrees, with PR/CI status display via `gh`.

## Project Structure

```
bin/wt              # Main executable (all logic lives here)
functions/wt.zsh    # Zsh shell wrapper (auto-cd into new worktrees)
completions/_wt     # Zsh tab completion
release.sh          # Version tagging + Homebrew formula update
```

Config files live in `~/.config/wt/repos/*.conf` (sourced as shell variables).

## Tech Stack

Pure Bash (`set -e`). No build step, no package manager.

**Runtime dependencies:** `git`, `gh` (GitHub CLI), `jq`, `perl`, standard Unix tools.

## Code Conventions

- Command functions: `cmd_<name>` (e.g., `cmd_add`, `cmd_list`, `cmd_fork`)
- Helper functions: descriptive names or `_` prefix (e.g., `_symlink_shared`, `resolve_repo`)
- Always `local` for function variables
- Always quote variables: `"$var"`, not `$var`
- Errors to stderr: `echo "message" >&2`
- Minimal comments; code should be self-documenting
- `sed -i ''` (macOS-compatible in-place edit)
- Command dispatch via `case` statement at the bottom of the script

## Key Patterns

- **Config resolution:** by `--repo` flag, by current working directory, or fallback to single configured repo
- **Shared files:** symlinked (or copied with `--no-symlink`) from a shared directory into each worktree
- **VS Code workspace sync:** reads/writes `.code-workspace` JSONC files, uses `perl` for JSONC-to-JSON conversion
- **GitHub integration:** `gh pr list`, `gh pr checks`, `gh pr view` for status; all optional (works offline)

## Testing

Uses [BATS](https://bats-core.readthedocs.io/) (Bash Automated Testing System). Tests live in `test/`.

```bash
bats test/              # run all tests
bats test/config.bats   # run a specific test file
bats test/ --filter "strips trailing commas"  # run by name
```

Helper libraries (bats-assert, bats-support) are git submodules in `test/lib/`. After cloning, run `git submodule update --init`.

Each test gets an isolated environment with a fresh bare repo, config, and mock `gh` — no network access needed.

## Releasing

```bash
./release.sh <version>   # Tags, computes SHA, updates homebrew-tap repo
```

Distributed via `brew install francofrizzo/tap/wt`.
