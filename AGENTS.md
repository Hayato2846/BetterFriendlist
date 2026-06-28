# BetterFriendlist Agent Guide

## Workspace

- Work from `C:\Users\hofer\Documents\BFL\repos\BetterFriendlist` or one feature worktree under `C:\Users\hofer\Documents\BFL\worktrees\BetterFriendlist`.
- Treat WoW `Interface\AddOns\BetterFriendlist` folders as deployment targets only.
- At the start of coding or workflow changes, run `git rev-parse --show-toplevel` and `git status --short --branch`.
- If a thread starts in `C:\Users\hofer\Documents\BFL`, switch into the main repo or the intended worktree before reading, patching, validating, or deploying.

## Feature Flow

- Use one branch and one worktree per feature, issue, or parallel Codex thread.
- Prefer names that describe the top-level goal. For GitHub issues, prefix both branch and worktree with `issue-NNN-`.
- Avoid overlapping edits to the same file regions from multiple threads. If overlap is possible, refresh `git status` and inspect the diff before patching.
- Use `tools\BFL-Worktree.ps1` for worktree creation, listing, and workspace regeneration.

## Implementation Rules

- Keep runtime logic in `Modules\`, shared helpers in `Utils\`, static data in `Data\`, and UI wiring thin.
- Check Retail and Classic impact for every user-visible feature or bugfix. Prefer existing `BFL.Is*`, `BFL.Has*`, and `BFL.Compat` helpers over raw flavor checks.
- Put new user-facing strings through localization and update all locale files in the same change.
- Do not leave Perfy instrumentation in normal source. Use `tools\BFL-PerfyCleanup.ps1` to inspect cleanup candidates instead of running `git restore .`.

## Validation

- Match validation to risk. For docs, guidance, comments, or narrow tooling text changes, use `git status`, `git diff --stat`, and only the smallest relevant script.
- For narrow tooling, ignore, package, or release metadata checks, run `tools\BFL-PackageCheck.ps1`.
- For runtime Lua/XML/locales/settings changes, run `tools\BFL-PackageCheck.ps1`; deploy a fresh `CleanCopy` only when runtime QA is needed or requested.
- Use `tools\BFL-PreCommitDelta.ps1` when code changes could introduce new pre-commit warning signatures. Update the baseline with `-UpdateBaseline` only when intentionally accepting or removing known warning signatures.
- Use `tools\BFL-ReadyForQA.ps1` only for PR readiness, explicit "ready for QA", release-near work, broad/risky changes, or final handoff after substantial runtime work. Pass `-DeployClient retail` or `-DeployClient all` only when deploy validation is actually needed.
- Use `tools\BFL-ReviewCheck.ps1` for focused review diagnostics when `ReadyForQA` is too broad.
- Keep `.pkgmeta` aligned with ignored internal files so release packages do not include Codex, docs, tools, logs, backups, or workspace metadata.

## VSCode And Codex

- Open VSCode on the main repo or one active worktree for implementation. Use `BetterFriendlist.code-workspace` for overview across worktrees.
- Codex should run checks and deploy commands directly rather than asking the user to run a VSCode task.
- Use Plan or Goal mode for broad migrations, cross-flavor work, or any task where the definition of done needs to stay visible.
- Optimize for low process overhead: avoid repeated broad scans, full QA wrappers, manual/documentation lookups, or long status narration when the task is small and local.
