# wt

Git worktree manager with GitHub integration. Shows CI status, PR review state, and cleans up merged worktrees automatically.

## Features

- **Create worktrees** from a bare repo with one command
- **List worktrees** with last commit, PR number, CI pass/fail, and review status
- **Prune** worktrees whose PRs have been merged
- **Multi-repo** support via simple config files
- **VS Code workspace** sync (optional) — auto-adds/removes worktrees
- **Shared files** — copy common untracked files into new worktrees
- **Zsh integration** — cd wrapper and tab completion

## Install

### Homebrew

```bash
brew install francofrizzo/tap/wt
```

### Manual

```bash
git clone https://github.com/francofrizzo/wt.git
ln -s "$PWD/wt/bin/wt" /usr/local/bin/wt
```

### Dependencies

- [git](https://git-scm.com/)
- [gh](https://cli.github.com/) — GitHub CLI (for PR/CI status)
- [jq](https://jqlang.github.io/jq/) — JSON processor

## Setup

Configure a repository:

```bash
wt init myproject --bare ~/code/myproject.git
```

This creates `~/.config/wt/repos/myproject.conf`. The GitHub repo slug is auto-detected from the remote URL.

### Full init options

```bash
wt init myproject \
  --bare ~/code/myproject.git \
  --worktrees ~/code/myproject-worktrees \
  --repo owner/myproject \
  --workspace ~/myproject.code-workspace \
  --shared ~/code/myproject-worktrees/.shared \
  --default-branch main
```

| Option | Description | Default |
|---|---|---|
| `--bare` | Path to bare repo | **required** |
| `--worktrees` | Directory for worktrees | `<bare-parent>/<name>-worktrees` |
| `--repo` | GitHub `owner/repo` slug | auto-detected from remote |
| `--workspace` | VS Code `.code-workspace` file | none |
| `--shared` | Directory copied into new worktrees | none |
| `--default-branch` | Default branch name | `main` |

### Config format

Each repo is a sourceable shell file at `~/.config/wt/repos/<name>.conf`:

```bash
BARE="/Users/you/code/myproject.git"
WORKTREES="/Users/you/code/myproject-worktrees"
REPO="owner/myproject"
```

## Usage

### Create a worktree

```bash
wt my-feature              # new branch off origin/main
wt my-feature origin/dev   # new branch off origin/dev
wt add my-feature          # explicit add subcommand
```

If the branch exists locally or on the remote, it checks it out. Otherwise, it creates a new branch from the base ref.

The worktree path is printed to stdout, so you can use it in scripts:

```bash
cd $(wt my-feature)
```

### List worktrees

```bash
wt list
```

Output shows each worktree with:
- Branch name and directory
- Last commit (relative time + message)
- PR number with CI status (pass/fail/running) and review state (approved/changes/pending)
- Merged PRs shown dimmed

### Remove a worktree

```bash
wt rm my-feature
```

### Prune merged worktrees

```bash
wt prune
```

Finds all worktrees whose PRs have been merged on GitHub and removes them (with confirmation).

### List configured repos

```bash
wt repos
```

### Target a specific repo

```bash
wt --repo myproject list
```

By default, `wt` auto-detects the repo based on your current directory. The `--repo` flag is only needed when you're outside any configured worktree path.

## Zsh integration

Add to your `~/.zshrc`:

```bash
source "$(brew --prefix)/share/wt/wt.zsh"
```

This gives you:

- **Auto-cd**: `wt my-feature` creates the worktree and `cd`s into it
- **Tab completion**: subcommands, branch names, worktree names, `--repo` names

## How it works

`wt` operates on [bare git repositories](https://git-scm.com/docs/git-worktree). Instead of cloning a repo normally, you clone it bare and create worktrees for each branch you work on. This lets you have multiple branches checked out simultaneously without stashing or switching.

```
~/code/
  myproject.git/              # bare repo (no working tree)
  myproject-worktrees/
    main/                     # worktree for main
    feature-auth/             # worktree for feature-auth
    fix-login-bug/            # worktree for fix-login-bug
```

## Releasing a new version

Run the release script:

```bash
./release.sh 0.2.0
```

This tags the release, computes the tarball SHA, updates the Homebrew formula, and pushes everything. Users then run `brew upgrade wt`.
