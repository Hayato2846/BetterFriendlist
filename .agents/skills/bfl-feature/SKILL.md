---
name: bfl-feature
description: Plan, scope, implement, validate, and hand off BetterFriendlist feature work. Use when Codex is asked to add, change, prototype, migrate, or finish a BFL feature or bugfix, especially when the work may touch Lua/XML, settings, localization or locale keys, Retail/Classic compatibility, SavedVariables, changelog entries, release tagging, deployment, or a feature worktree.
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

## GitHub Issue Safety

- Treat requests to inspect, fix, address, or implement a GitHub issue as authorization for read-only issue inspection and local code work only.
- Never post a comment or reply to an issue unless the user separately and explicitly asks for that exact GitHub write action.
- Never close, reopen, or otherwise change an issue's state unless the user separately and explicitly asks for that exact state change.
- Do not infer permission to comment or close from phrases such as "fix directly", from a successful implementation, validation, deployment, commit, merge, push, or release.
- Keep issue comments, reactions, labels, assignees, milestones, title/body edits, and state changes untouched by default. Report the recommended GitHub follow-up to the user instead.

## Implementation

- Prefer existing modules, compatibility helpers, settings components, and localization patterns over new abstractions.
- Keep `BetterFriendlist.lua` and UI callback files thin. Put business logic in `Modules\`, shared helpers in `Utils\`, and static data in `Data\`.
- Add persistent settings through DB defaults and migrations when needed. Beta features default to disabled and must leave no side effects when off.
- Route user-facing text through localization and write genuine translations for all 10 non-English locales in the same task. Never insert English placeholders, TODO translations, or copied fallback text.
- Treat changed `enUS` values like new localization work: review and update the same key in every translated locale while preserving printf placeholders, WoW markup, links, and escaped newlines.
- Do not hand off locale-affecting work until `tools\BFL-LocalizationCheck.ps1 -Mode Changed -BaseRef <branch-base>` passes. Add allowlist entries only for intrinsically untranslated product names, client key labels, or established locale-specific UI terms. Scope them to an exact locale/key or exact locale/value match, justify them, and never allow substrings or an entire locale.
- Check UI tasks against `docs/UI_CONVENTIONS.md`; use screenshots or a narrow visual assumption when layout, density, color, clipping, or state is material.
- Verify WoW API usage against local Retail and Classic UI sources before adding or changing calls.
- Use capability flags and BFL compatibility wrappers before raw flavor checks.
- Update `CHANGELOG.md` only for approved user-visible changes, under `[DRAFT]`.

## Changelog Style

- Read the latest two or three published entries in `CHANGELOG.md` before writing. Keep the existing English style. For a larger update, open with one short sentence about the biggest changes. Group entries by WoW version where that helps players find what's relevant, then use the existing Added, Improved, Fixed, or Compatibility headings as needed.
- Start each bullet with the feature or UI label in bold, followed by a hyphen and one or two plain sentences. Write for someone who plays WoW and has never seen BFL's code. Say what they can do now, what went wrong before, or where to find the new option. Use the words players see in-game, such as Who, right-click menu, BattleTag, or Raid tab.
- Keep it conversational and matter-of-fact. Skip marketing language, filler, and claims about speed or reliability without evidence. Leave out API names, interface numbers, internal rendering details, and fixes to regressions that only existed in the current draft. Mention defaults, level requirements, client differences, and privacy behavior when they affect what a player sees or does.
- For example, write “**Recently Added** - Long-time friends no longer show up as newly added after a reconnect.” Explain a restricted API in terms of the visible effect, such as “You can still open the guild list when the game temporarily hides extra details like professions.”
- Keep upcoming notes under `[DRAFT]` until release promotion. Preserve published entries and run `tools/BFL-PackageCheck.ps1` to sync the embedded changelog used in game.

## Secret Values, Secret Context, and Taint

For every runtime change, review the changed path and its immediate callers for three distinct risks: access to Secret Values, restrictions on the execution context, and taint reaching protected Blizzard code. For a pure addon-owned path with no such boundary, a brief diff review is enough. Apply the checks below when a path crosses into Blizzard APIs, native widgets, hooks, or callbacks.

1. **Trace the data and the call path.** Identify the Blizzard API, event, or widget that produces the value, the callback context it runs in, and the first operation that consumes it. Follow the value through shared helpers, deferred callbacks, and caches. Read the generated API documentation and the native caller in the local UI source for the affected client and build. Check return secrecy and context-dependent restrictions (such as `SecretInChatMessagingLockdown`) separately from `SecretArguments`, API availability, combat lockdown, and restrictions on protected actions.
2. **Guard before consuming.** Reuse `BFL:IsSecret` for individual values. For API tables, also check the applicable table restrictions, such as `issecrettable` when the table or its contents can be secret. Check the container before indexing or iteration, and check individual fields before branching, comparing, converting, formatting, using them as keys, or passing them to APIs that require readable arguments. A successful `pcall` and `type(result) == "table"` can still leave a secret table. Guard before logging or storing values in caches or SavedVariables.
3. **Keep the feature usable under restrictions.** Use readable base data if optional enrichment is unavailable. Keep restricted data out of fallback results and avoid caching a restricted read as an authoritative empty response. Check that the feature recovers when the restriction lifts. For example, `C_Club.GetClubMembers` can return a secret table during chat lockdown. Skip club enrichment before `ipairs` and keep the base guild roster available.
4. **Keep taint out of Blizzard's protected path.** Trace hook and callback order through the protected action, including clicks and panel transitions. Avoid replacing Blizzard methods, mutating Blizzard-owned tables or secure attributes, or changing the layout or visibility of protected frames from addon code unless the documented path supports it in that context. Prefer addon-owned UI and supported observation hooks. A secure hook does not make the addon callback secure, and deferring the callback does not make the data readable or the action permitted. Defer a blocked action only if the documented restriction can lift and the original action is still valid when retried.
5. **Match verification to the boundary.** Test the normal path, the restricted return or action, and recovery. Use a targeted regression test when static review cannot catch the failure, such as a mock that throws on iteration or indexing of a secret table. For hooks, protected actions, or suspected taint, reproduce through the real entry point on the affected client and inspect the taint log, including the first addon frame in the blocked path. For context-sensitive behavior, use the relevant state such as combat or chat lockdown. Report the client/build and distinguish source review and mocks from live results. If live verification is unavailable, name the exact path and context still untested.

## Validation

Choose the smallest validation set that matches risk:

- Light: docs, guidance, comments, or narrow tooling text changes usually need only `git status`, `git diff --stat`, and the smallest relevant focused check.
- Package/tooling: run `tools\BFL-PackageCheck.ps1` when ignore rules, package metadata, release tooling, or deploy tooling changed.
- Runtime: run `tools\BFL-PackageCheck.ps1` for Lua/XML/locales/settings/package changes.
- Test-ready deployment: for every user-requested runtime implementation or bugfix, deploy a fresh `CleanCopy` before handoff. The maintainer expects a deployed state for testing without a separate deploy request. Select the affected client explicitly, for example `tools\BFL-Deploy.ps1 -Mode CleanCopy -Client retail -Source .` for Retail-only work.
- Cross-flavor runtime: deploy the affected Classic client explicitly, or use `-Client all` when TOC/XML, compatibility, settings runtime, shared loading, or packaging behavior affects multiple flavors.
- Deployment exceptions: skip the required deploy only when the user explicitly opts out or deployment is blocked; report the exact command and reason.
- Warning delta: run `tools\BFL-PreCommitDelta.ps1` when code changes could introduce new pre-commit warning signatures. Use `tools\BFL-PreCommitDelta.ps1 -UpdateBaseline` only when intentionally accepting a changed warning baseline.
- Full QA: run `tools\BFL-ReadyForQA.ps1` only for PR readiness, explicit "ready for QA", release-near work, broad/risky changes, or final handoff after substantial runtime work.
- Focused review diagnostics: run `tools\BFL-ReviewCheck.ps1` when `ReadyForQA` is too broad.
- Localization: run `tools\BFL-LocalizationCheck.ps1 -Mode Changed -BaseRef <branch-base>` whenever user-facing keys or values changed. A failure means the feature remains incomplete; do not replace missing translations with English to make the check pass.
- Performance investigations: keep Perfy instrumentation separate and clean it with `tools\BFL-PerfyCleanup.ps1`; do not run `git restore .` as cleanup.
- Broad or risky changes: inspect `git diff --stat`, review changed files for common BFL bug traps, and run only the checks needed for the changed surface.

Report any validation skipped or blocked with the exact command and reason.

## Release Tags

- Never create or push `v*` tags with raw git commands.
- Use `tools\BFL-CreateReleaseTag.ps1 -Version X.Y.Z`; pass `-Push` only after the user explicitly requests publication.
- Keep localization validation local and before tag creation. Do not move the tag gate into `.github/workflows/release.yml` or bypass its full, freshness, or Lua locale-switching runtime checks.

## Handoff

End with:

- What changed.
- What was validated.
- What remains unvalidated and why.
- Worktree/branch status and whether the next action is continue, review, merge, archive, or needs decision.
