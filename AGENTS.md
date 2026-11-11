# BetterFriendlist Agent Guide

## Workspace and scope

- Work in `C:\Users\hofer\Documents\BFL\repos\BetterFriendlist` or the intended worktree, never a deployment folder. Before coding/workflow changes run `git rev-parse --show-toplevel` and `git status --short --branch`.
- One branch/worktree per feature, issue, or parallel chat. For checkout setup, follow [worktree setup](.agents/skills/bfl-feature/references/worktree.md): check attachments, use Codex creation, confirm returned path/branch. Preserve requested names; issue names start `issue-NNN-` in the worktree and branch feature part. Keep `codex/*` local. Preserve unrelated changes and recheck overlapping diffs.
- GitHub writes require explicit instructions; issue/PR implementation alone does not authorize comments, reactions, metadata or state changes. Use the connector for current remote facts; read the issue/PR body, state and relevant discussion before planning its edits.
- The maintainer performs live WoW tests. Never use Computer Use, desktop automation or remote input for BFL, or request test contacts/account access. Prepare builds, exact live steps, and analyze supplied results.

## Implementation contracts

- Logic in `Modules/`, helpers in `Utils/`, data in `Data/`; keep UI wiring thin.
- No emojis in project files. Commits use `{type}: {description} ({context})` with existing BFL types.
- Assess Retail and every supported Classic flavor for user-visible fixes/features; resolve affected regressions in the same task. Forever is Mainline-family. Verify changed native API/event/template contracts against relevant local sources. Prefer `BFL.Is*`, `BFL.Has*`, `BFL.Compat` over raw version checks.
- Load `betterfriendlist` for runtime work, `bfl-feature` for implementation/releases/deployment, and `libsettingsdesigner-bfl` for Settings Center/library work only. Load relevant conditional references before their work, especially visual edits and changelog/releases.
- New strings and changed `enUS` values need real translations in all 10 non-English locales in the same change. Preserve printf placeholders, WoW markup, links and escaped newlines. Require `tools/BFL-LocalizationCheck.ps1 -Mode Changed -BaseRef <branch-base>`. Allowlist only justified exact locale/key or locale/value exceptions for product names, client keys or established UI terms; no substring/whole-locale exceptions.
- Keep Perfy instrumentation out of normal source; inspect cleanup with `tools/BFL-PerfyCleanup.ps1`, never `git restore .`.

## Validation

Run applicable checks directly. Reuse successful results only for the same relevant state, including checks inside QA wrappers; repeat after invalidating changes or to resolve failures. Never skip required checks to save tokens.

| Changed surface | Required validation |
| --- | --- |
| Docs/guidance/comments/narrow tooling text | `git status`, `git diff --stat`, smallest relevant check |
| Lua/XML/locales/settings; tooling behavior/ignore/package/release metadata | `tools/BFL-PackageCheck.ps1` |
| Code that can add warning signatures | `tools/BFL-PreCommitDelta.ps1`; baseline updates only when intentional |
| User-facing locale keys/values | Localization check above, in addition to runtime checks |
| Visual layout/themes/fonts/scrolling | Visual reference: before/after simulator captures and image review |
| Implemented runtime features/fixes for QA | Fresh `CleanCopy`; deployment reference defines clients/exceptions |
| PR readiness, explicit QA, release-near, broad/risky or substantial runtime handoff | `tools/BFL-ReadyForQA.ps1`; `-DeployClient retail`/`all` only when needed |

Use `tools/BFL-ReviewCheck.ps1` for focused diagnostics when full QA is unwarranted. Keep `.pkgmeta` excluding internal files (`.agents`, docs, tools, logs, backups, workspace metadata). Report blocked checks/deploys with exact command/reason; distinguish static/simulator evidence from live in-game, taint and controller results.

## Releases

- Keep upcoming notes under `[DRAFT]`; follow the changelog/release reference. No test/debug/recovery commands in public notes.
- Never create/push release tags with raw Git. Use `tools/BFL-CreateReleaseTag.ps1 -Version X.Y.Z`; `-Push` only for explicitly requested publication. Full localization, translation-freshness and Lua locale-switching smoke must pass before a tag exists; never bypass/weaken these gates or move them to CI.
- Corrections retain the authorized version; tag replacement or a different version needs explicit authorization. Follow the release reference and `docs/DEPLOYMENT_TESTING.md#release-candidate-flow`, including integration and per-destination verification.

## Context efficiency

- Start with specific symbols/scoped `rg` and bounded excerpts; expand to necessary callers/contracts. Avoid whole-file/log/locale/tool-catalog dumps when focused output suffices.
- Reuse current instructions/findings/checks; re-read after relevant edits, drift or lost context. Preserve unresolved risks across compaction. Load docs by task, not as a startup bundle.
- Batch independent reads/checks; summarize success and retain full failure diagnostics. Never truncate evidence needed for diagnosis.
- Small tasks need a short action/validation statement; broad work needs a concise plan. Create persistent Goals only on explicit request.
