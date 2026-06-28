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

- For normal handoff, PR readiness, or "ready for QA" checks, run `tools\BFL-ReadyForQA.ps1`; pass `-DeployClient retail` for ordinary runtime QA and `-DeployClient all` when cross-flavor loading, TOC/XML, compatibility code, settings runtime, or release packaging changed.
- For narrow tooling, ignore, package, or release metadata checks, `tools\BFL-PackageCheck.ps1` remains the focused package guard.
- Use `tools\BFL-PreCommitDelta.ps1` to compare current pre-commit warnings against the checked-in baseline. Update that baseline with `-UpdateBaseline` only when intentionally accepting or removing known warning signatures.
- For runtime, TOC, XML, locale, package, or deploy-tooling changes, deploy a fresh `CleanCopy` before handing back unless the user explicitly says not to deploy.
- Deploy to Retail for ordinary runtime changes. Deploy to all clients when TOC/XML, package metadata, compatibility code, or release packaging changes.
- Use `tools\BFL-ReviewCheck.ps1` for focused review diagnostics when the full ready-for-QA flow is too broad.
- Keep `.pkgmeta` aligned with ignored internal files so release packages do not include Codex, docs, tools, logs, backups, or workspace metadata.

## VSCode And Codex

- Open VSCode on the main repo or one active worktree for implementation. Use `BetterFriendlist.code-workspace` for overview across worktrees.
- Codex should run checks and deploy commands directly rather than asking the user to run a VSCode task.
- Use Plan or Goal mode for broad migrations, cross-flavor work, or any task where the definition of done needs to stay visible.
