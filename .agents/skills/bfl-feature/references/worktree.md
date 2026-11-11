# Worktree setup

- Main repository: `C:\Users\hofer\Documents\BFL\repos\BetterFriendlist`. Preferred worktree root: `C:\Users\hofer\Documents\BFL\worktrees\BetterFriendlist`, configurable in Codex Settings > Worktrees. Use the actual workspace returned by Codex.
- Check `list_artifacts` and reuse a suitable active chat attachment. Otherwise use `create_worktree` with the repository, intended base ref, and descriptive task name. Start-in-Worktree mode or Hand off > Worktree are app alternatives. If tools are unavailable, wait for the app flow before editing.
- Wait for pending operations with `get_worktree_creation_status`. If registration fails but a workspace is returned, retry `attach_worktree` at that path. Confirm attachment before edits.
- Verify `git rev-parse --show-toplevel` and `git status --short --branch` in the returned workspace. If detached, `git switch -c <intended-branch>` there. Resolve branches already checked out elsewhere before proceeding.
- Preserve the user's branch name or existing BFL convention, e.g. `feat/contact-memory`; use `codex/` otherwise. Issue names begin `issue-NNN-` in the worktree and feature part of the branch, e.g. `fix/issue-89-elvui-skin-disabled`.
- Keep one branch/worktree per feature, issue, or parallel chat. Preserve unrelated dirty changes; refresh status/diff before overlapping edits. Use absolute paths for patches when the tool cwd differs from the target. Confirm the expected diff in the intended checkout after an edit batch; if missing, stop and locate the affected files.
- Run `tools/BFL-Worktree.ps1 -Action Workspace` from the main repository after branch setup to refresh `BetterFriendlist.code-workspace`. Use `-Action List` for Git worktrees. Reserve `-Action Create` for standalone worktrees outside the chat workflow.
- Open VSCode on the repository or one active worktree; use the generated workspace for overview. Treat WoW `Interface\AddOns\BetterFriendlist` folders as deployment targets only.
