---
name: bfl-feature
description: Implement and hand off BetterFriendlist features and fixes, or prepare BFL releases and client deployments. Includes visual verification when the UI changes.
---

# BFL Feature

Follow the active checkout's `AGENTS.md` for workspace, authorization, localization, cross-flavor, validation, and release gates. Do not duplicate its checklist or reload it if already in context.

Before editing, identify the intended behavior, affected surface/flavors, and validation. A short paragraph is sufficient for a narrow fix; use a concise plan when dependencies or completion criteria need tracking. Resolve routine choices from the code and session; ask only for missing information that changes the result. Do not create a persistent Goal unless requested.

Load `betterfriendlist` for runtime implementation. Load WoW-source skills for changed native contracts and `libsettingsdesigner-bfl` for Settings Center work, as routed there; do not load every companion for every task.

## Conditional procedures

Read the matching reference before performing its work; skip unrelated references.

| Task | Required reference |
| --- | --- |
| Create/attach/name a worktree or resolve its setup | [Worktree setup](references/worktree.md) |
| Change visual layout, templates, textures, fonts, colors, scrolling, strata, skins/themes | [Visual UI](references/visual-ui.md) and the relevant `docs/UI_CONVENTIONS.md` sections, before editing |
| Change BFL settings windows/editors, including legacy Settings and Friend Tag Editor | [Settings window principles](references/settings-windows.md), in addition to the visual procedure |
| Edit public changelog/release notes, promote a version, tag/publish/correct a release | [Changelog and release](references/changelog-release.md) |
| Deploy runtime implementation/fixes for QA, install a release ZIP, or test SavedVariables migrations | [Deployment](references/deployment.md) |

For approved user-visible implementations, update `CHANGELOG.md` under `[DRAFT]` using the changelog reference. Keep runtime code and user-visible behavior changes within the authorized scope.

## Validation and handoff

Apply the `AGENTS.md` validation matrix to the final change. Reuse a successful check already run for that same relevant state, including checks inside QA wrappers. Additional skills add surface-specific checks, not duplicate runs. Inspect failures and fix causes; expand validation when risk, new edits, or failures justify it.

For user-requested runtime implementations/fixes, prepare a fresh `CleanCopy` for testing before handoff using the deployment reference, unless the user opts out or deployment is blocked. No deployment for documentation or read-only review alone.

Finish concisely with changed behavior, validation results, remaining live-test gaps or blockers, and the worktree/branch when needed for the next action. Never present simulator/mocks as proof of live taint safety.
