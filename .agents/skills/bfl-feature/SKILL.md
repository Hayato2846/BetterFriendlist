---
name: bfl-feature
description: Plan, scope, implement, validate, and hand off BetterFriendlist feature work. Use when Codex is asked to add, change, prototype, migrate, or finish a BFL feature or bugfix, especially when the work may touch Lua/XML, settings, localization, Retail/Classic compatibility, SavedVariables, changelog entries, deployment, or a feature worktree.
---

# BFL Feature

## Overview

Use this skill to turn a BFL feature request into a focused implementation lane with explicit scope, cross-flavor checks, validation, and handoff notes.

Pair this skill with the project-level BetterFriendlist, WoW UI Retail, WoW UI Classic, and LibSettingsDesigner guidance when the task touches addon code, UI, settings, release metadata, or deployment.

## Start

1. Confirm the active checkout with `git rev-parse --show-toplevel` and `git status --short --branch`.
2. If the thread starts in the BFL hub, switch to the main repo or the intended feature worktree before editing.
3. Name the implementation lane: feature, bugfix, prototype, migration, review, or release-prep.
4. Identify the target flavor impact: Retail only, Classic only, all flavors, or unknown until API checks.
5. Decide whether to plan first. Use Plan or Goal mode for broad UI, compatibility, SavedVariables, localization, or cross-worktree work.

## Feature Brief

Before editing, summarize the feature in this compact shape:

- Goal: the user-visible behavior or symptom to change.
- Scope: files, modules, settings pages, commands, data, or integrations likely involved.
- Constraints: what must not change, privacy/combat/security limits, and beta/default behavior.
- Flavor risk: Retail, Classic progression, Classic Era, Anniversary, PTR, and capability checks needed.
- Validation: package check, pre-commit, deploy target, in-game command, SavedVariables profile, or screenshot review.
- Done when: observable completion criteria.

If the request is vague, ask the smallest useful clarification or state the working assumption before editing.

## Implementation

- Prefer existing modules, compatibility helpers, settings components, and localization patterns over new abstractions.
- Keep `BetterFriendlist.lua` and UI callback files thin. Put business logic in `Modules\`, shared helpers in `Utils\`, and static data in `Data\`.
- Add persistent settings through DB defaults and migrations when needed. Beta features default to disabled and must leave no side effects when off.
- Route user-facing text through localization and update all locale files in the same task.
- Check UI tasks against `docs/UI_CONVENTIONS.md`; use screenshots or a narrow visual assumption when layout, density, color, clipping, or state is material.
- Verify WoW API usage against local Retail and Classic UI sources before adding or changing calls.
- Use capability flags and BFL compatibility wrappers before raw flavor checks.
- Update `CHANGELOG.md` only for approved user-visible changes, under `[DRAFT]`.

## Validation

Choose the smallest validation set that matches risk:

- Tooling, ignore, packaging, or release metadata: run `tools\BFL-PackageCheck.ps1`.
- Runtime Lua/XML/locales/settings/package changes: run `tools\BFL-PackageCheck.ps1`, then deploy with `tools\BFL-Deploy.ps1 -Mode CleanCopy`.
- Cross-flavor loading, TOC/XML, compatibility, settings runtime, or packaging changes: deploy with `-Client all`.
- PR-ready work: run `tools\BFL-ReviewCheck.ps1`.
- Performance investigations: keep Perfy instrumentation separate and clean it with `tools\BFL-PerfyCleanup.ps1`; do not run `git restore .` as cleanup.
- Broad or risky changes: inspect `git diff --stat`, review changed files for common BFL bug traps, and run the filtered pre-commit check once.

Report any validation skipped or blocked with the exact command and reason.

## Handoff

End with:

- What changed.
- What was validated.
- What remains unvalidated and why.
- Worktree/branch status and whether the next action is continue, review, merge, archive, or needs decision.
