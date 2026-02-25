# wt - shell wrapper that cd's into new worktrees
#
# Source this file in your .zshrc:
#   source "$(brew --prefix)/share/wt/wt.zsh"
#
# Commands that produce a worktree path (add, bare branch names) will
# automatically cd into the created directory. All other commands pass
# through to the wt binary directly.

wt() {
  case "$1" in
    ""|-h|--help|-l|-r|list|ls|rm|remove|prune|clean|repos|init|__complete)
      command wt "$@"
      return
      ;;
    --repo)
      # --repo <name> <subcommand> ... — check the subcommand
      case "$3" in
        ""|-h|--help|-l|-r|list|ls|rm|remove|prune|clean|repos|init|__complete)
          command wt "$@"
          return
          ;;
      esac
      ;;
  esac

  local dir
  dir=$(command wt "$@") || return
  [ -d "$dir" ] && cd "$dir" || echo "$dir"
}
