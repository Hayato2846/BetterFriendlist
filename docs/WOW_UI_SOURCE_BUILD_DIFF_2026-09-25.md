# WoW UI Source Build Diff — PTR2 12.1.5.69952 and Classic 5.5.4.69934

Status: analysis complete; BFL-relevant compatibility work is already present in `v2.9.1`
Date: 2026-09-25
BFL base: `main` at `cd0c0ebe4f90`
Implementation branch: `v2.9.1`
Worktree: `C:\Users\hofer\Documents\BFL\worktrees\BetterFriendlist\v2.9.1`

## Scope and result

The 2026-09-25 source refresh had already advanced three repositories before this follow-up audit:

1. Retail PTR2 from `12.1.5.69848` to `12.1.5.69952`.
2. WoW Forever from `1.60.1.69913` to `1.60.1.70009`.
3. Classic progression from `5.5.4.69585` to `5.5.4.69934`.

The Forever delta was assessed separately. This document covers the two additional build changes. A fresh `git pull --ff-only` on all eight configured UI-source repositories found no newer remote commit after the earlier refresh.

The PTR2 build contains two BFL-relevant changes:

- Texture mutation can now be denied through `Enum.ForbiddenAspect.SetTexture`; BFL already uses a fail-closed compatibility wrapper for foreign and third-party textures.
- Blizzard added secure `UnitFrameUtil` delegates for PvP indicators, group-role icons, and arena-opponent presentation; BFL already uses the new PvP-indicator delegate in its raid rows.

Classic progression is a version-only build: its complete diff is the single line change in `version.txt`. It introduces no API, XML, Lua, TOC, event, template, or mixin change for BFL.

## Audited source state

| Flavor | Branch | Current build | Current HEAD | Change in previous refresh |
| --- | --- | --- | --- | --- |
| Retail live | `live` | `12.1.0.69933` | `09b9db7948ab` | No change in that refresh. |
| Retail PTR | `ptr` | `12.1.0.69587` | `a89e9d0ceb7f` | No change in that refresh. |
| Retail PTR2 | `ptr2` | `12.1.5.69952` | `5c9363cc1b4e` | **New build; audited here.** |
| WoW Forever | `forever` | `1.60.1.70009` | `bd2470aed543` | New build; already assessed separately. |
| Classic progression | `classic` | `5.5.4.69934` | `cde55d0033e8` | **New build; audited here.** |
| Classic PTR | `classic_ptr` | `5.5.4.67849` | `ea6f4ee4ce0d` | No change. |
| Classic Era | `classic_era` | `1.15.9.69722` | `33e177d9bf38` | No change. |
| Classic Anniversary | `classic_anniversary` | `2.5.6.69795` | `1463c686270b` | No change. |

Authoritative local roots:

- PTR2: `C:\Users\hofer\Documents\BFL\references\wow-ui-source-ptr2`
- Classic progression: `C:\Users\hofer\Documents\BFL\references\wow-ui-source-classic`

## Exact comparison ranges

### Retail PTR2

- Old: `f663342f08a6e06060b0d77628abf4e503907e67` — `12.1.5.69848`
- New: `5c9363cc1b4e80b98963e3fcc87ab460fa911a94` — `12.1.5.69952`
- Commit count: 1
- Diff: 25 files, 630 insertions, 300 deletions
- Source command: `git diff f663342f08a6e06060b0d77628abf4e503907e67..5c9363cc1b4e80b98963e3fcc87ab460fa911a94`

### Classic progression

- Old: `ecadf9d3326fa87828cacca7f13c0ab5f41840a6` — `5.5.4.69585`
- New: `cde55d0033e89b246381385b2f063cd6c6047ef8` — `5.5.4.69934`
- Commit count: 1
- Diff: `version.txt` only, one insertion and one deletion
- Source command: `git diff ecadf9d3326fa87828cacca7f13c0ab5f41840a6..cde55d0033e89b246381385b2f063cd6c6047ef8`

## BFL impact decisions

Priorities use the same scale as the existing UI-source impact manifest:

- **P0:** loading, data-loss, error, or taint risk.
- **P1:** visible compatibility defect or high-value feature.
- **P2:** useful feature with narrower context or PTR uncertainty.
- **P3:** observe or adopt only with measured benefit.
- **No action:** no BFL-owned surface or no behavioral value.

| ID | Priority | Source change | BFL impact and decision | Current status |
| --- | --- | --- | --- | --- |
| `COMP-FORBIDDEN-TEXTURE` | P1 compatibility | `ForbiddenAspect` adds `SetTexture` and `QueryRotation`; `ClearSVG`, `SetSVG`, and `SetColorTexture` now check `SetTexture`, while `GetRotation` checks `QueryRotation`. Existing enum values above bit 1024 move upward. | BFL recolors some textures owned by Blizzard or another addon in Broker and skin integrations. A forbidden write can therefore raise an error. The correct strategy is symbolic lookup plus `HasAnyForbiddenAspects`, not hard-coded enum values. BFL-owned textures are not expected to carry these restrictions. | **Implemented.** `BFL.TrySetColorTexture()` resolves `Enum.ForbiddenAspect.SetTexture` dynamically, fails closed on forbidden, secret, or failing queries, contains setter errors, and preserves older-client behavior. Broker, AddOnSkins, ElvUI, and EllesmereUI foreign-texture writes use it. Contract tests cover allowed, forbidden, secret, error, and legacy paths. |
| `COMP-RAID-PVP-DELEGATE` | P1 compatibility and feature | The new shared `UnitFrameUtil.lua` exposes `UpdateUnitPvPIndicator()` and `GetUnitPvPIndicatorDisplayInfo()` through secure delegates. Blizzard explicitly documents the updater as safe for addons. | BFL owns raid/party rows and can now show faction/PvP/prestige indicators without inspecting secret identity state in addon Lua. Directly consuming the display-info table would still expose secret-bearing values to tainted code, so the updater delegate is the safer integration. | **Implemented.** BFL raid rows capability-check and `pcall` `UnitFrameUtil.UpdateUnitPvPIndicator`, request mercenary-aware faction display, normalize compact icon size, and clear stale icons if the API is absent or fails. Older clients keep the hidden-indicator fallback. |
| `FEAT-SECRET-SAFE-ROLE-ICON` | P2 opportunity | `UnitFrameUtil.UpdateUnitFrameRoleIcon()` and `GetUnitRoleIconDisplayInfo()` provide secret-safe role presentation. Blizzard moved its compact-unit-frame role logic to the updater. | BFL currently derives combat roles itself for its roster model, counts, and custom rows. Replacing only the icon branch would not make the complete BFL raid model secret-safe, because roster construction and role summaries still consume role values. | **Follow-up candidate, not required by this build.** If BFL must remain visible in identity-restricted PvP contexts, migrate the complete role-data path together and use the updater delegate for row textures. Do not consume secret display-info values in Lua conditionals. |
| `COMP-ARENA-SPEC-SECRETS` | No action | `GetArenaOpponentSpec()` is now documented with secret returns and secret-safe arguments. `UnitFrameUtil` adds secure arena spec/name/role/color updaters and Blizzard migrates CompactArenaFrame to them. | BFL has no arena-opponent-frame implementation and no `GetArenaOpponentSpec` call site. | No code change. Reuse Blizzard's updater delegates if an arena surface is ever added. |
| `COMP-RAID-MARKER-LOCKDOWN` | No action | `IsRaidMarkerActive()` becomes secret during chat-messaging lockdown. | BFL does not call `IsRaidMarkerActive`. Existing raid-target operations use separate APIs and are unaffected by this documentation change. | No code change. Any future marker-state UI must reject or delegate secret state instead of branching on it. |
| `FEAT-AURA-CARRY-OVER` | No action | New `C_UnitAuras.GetRefreshCarryOverDuration()` directly returns the predicted duration carried into a refreshed aura. AuraContainer and CooldownViewer migrate from subtracting base duration from extended duration. | BFL owns no aura container, pandemic alert, or cooldown-viewer calculation. | No code change. This API is preferable to the old two-call calculation if BFL ever gains an aura-duration feature. |
| `FEAT-ADVENTURE-MAP-COUNTS` | No action | `C_AdventureMap` gains `GetNumMapInsets`, `GetNumQuestOffers`, and `GetNumZoneChoices`. | No friend, social, roster, raid-management, or settings use case exists in BFL. | No code change. |
| `FEAT-COOLDOWN-LINKED-SPELL` | No action | `Enum.CooldownSetSpellFlags.SelectHighestLevelLinkedSpell` is added; CooldownViewer improves linked-item validation and indexes override/tooltip spell names for filtering. | BFL neither embeds nor searches CooldownViewer data. | No code change. |
| `COMP-CLASSIC-69934` | No action | Classic progression advances from build 69585 to 69934 with only `version.txt` changed. | There is no runtime source delta to adapt to and no new feature to expose. | No code change; retain the existing Classic capability fallbacks. |

## PTR2 API and implementation diff disposition

This section accounts for every changed source family in build 69952.

### Generated API documentation

| Source | Change | BFL disposition |
| --- | --- | --- |
| `AdventureMapDocumentation.lua` | Adds three count queries for insets, offers, and zone choices. | No BFL surface. |
| `CooldownViewerConstantsDocumentation.lua` | Adds `SelectHighestLevelLinkedSpell = 4`. | No BFL surface. |
| `ForbiddenAspectConstantsDocumentation.lua` | Adds `SetTexture = 2048` and `QueryRotation = 4096`; shifts `QueryAnimationProgress` and `AddAnimations`. | Relevant; symbolic, fail-closed texture guard already implemented. BFL does not query rotation or animation state. |
| `PvpInfoDocumentation.lua` | Documents secret `GetArenaOpponentSpec(index)`. | No BFL call site. |
| `RaidMarkersDocumentation.lua` | Marks `IsRaidMarkerActive()` secret in chat-messaging lockdown. | No BFL call site. |
| `SimpleTextureBaseAPIDocumentation.lua` | Adds forbidden-aspect checks to SVG mutation, color-texture mutation, and rotation query. | `SetColorTexture` relevant on foreign textures; implemented. BFL has no SVG/rotation call site. |
| `TutorialDocumentation.lua` | Adds reserved account tutorial enum value 51. | No BFL surface. |
| `UnitAuraDocumentation.lua` | Adds secret-aware `GetRefreshCarryOverDuration`. | No BFL aura surface. |

### Blizzard UI implementation

| Source family | Change | BFL disposition |
| --- | --- | --- |
| `Blizzard_UnitFrame/Shared/UnitFrameUtil.lua` | Moves the prior mainline helper into Shared and expands it with secure PvP, group-role, and arena display delegates. | PvP updater adopted. Role updater is a future whole-path migration candidate. Arena delegates are unrelated. |
| `CompactUnitFrame.lua` | Replaces direct role-icon branching with `UnitFrameUtil.UpdateUnitFrameRoleIcon`. | Confirms the intended secret-safe usage pattern; no direct BFL hook dependency. |
| `CompactArenaFrame.lua` | Replaces direct arena spec/name/role/color processing with secure delegates. | No BFL arena surface. |
| UnitFrame TOCs and `ui-code-list.txt` | Load the shared helper in both mainline and classic-style UnitFrame packages; EnvironmentCleanup adds a UnitFrame dependency. | BFL uses runtime capability discovery and does not depend on a source path or numeric client version. |
| `Blizzard_AuraContainerUtil.lua` | Uses the new direct carry-over-duration API. | No BFL aura surface. |
| `Blizzard_CooldownViewer` | Uses carry-over duration, tightens item cooldown matching, and indexes override spell names. | No BFL CooldownViewer integration. |
| `Blizzard_HousingBlueprint` | Improves notice/error presentation and fixes an `errorText` typo. | No BFL housing surface. |
| `Blizzard_AutoQuestPopUpTracker` | Masks item icons in auto-quest popups. | No BFL objective-tracker surface. |
| `EventScheduler.lua` | Deduplicates scheduled events by `eventKey`. | No BFL event-scheduler surface. |

## Compatibility conclusions

1. Build 69952 does not require a TOC/interface-number change beyond the existing 12.1.5 declaration.
2. No API consumed by BFL was removed or had its argument list changed.
3. The only newly enforced BFL risk is mutation of a foreign texture carrying `SetTexture`; the current compatibility helper covers the relevant integration paths.
4. The secure UnitFrame delegates are additive. BFL's PvP-indicator integration gains visible functionality while retaining a clean fallback.
5. No direct dependency is taken on `UnitFrameUtil` load order: every use is discovered at runtime.
6. Classic build 69934 is behaviorally identical to 69585 according to the complete source diff.

## Verification and follow-up

Completed during the `v2.9.1` implementation and this audit:

- Full source refresh of all configured Retail and Classic UI repositories with `git pull --ff-only`.
- Reflog reconstruction of the previous refresh's actual build transitions.
- Complete file and API diff for PTR2 `69848..69952`.
- Complete Classic diff for `69585..69934`.
- BFL call-site audit for texture mutation, raid/PvP indicators, role icons, raid markers, arena specs, Adventure Map, UnitAuras, and CooldownViewer.
- Existing automated contracts for forbidden texture mutation and the secret-safe raid PvP updater.
- Existing Ready-for-QA, package, localization, Lua syntax, and warning-delta checks for the encompassing `v2.9.1` implementation.

Recommended runtime acceptance on a 12.1.5 client:

1. Open BFL raid/party rows in normal PvE and confirm faction/PvP/prestige indicators update without Lua errors.
2. Exercise Broker, ElvUI, EllesmereUI, and AddOnSkins integrations to confirm forbidden foreign textures are skipped cleanly.
3. Enter an identity-restricted PvP context and observe whether BFL's broader role model needs the optional whole-path secure-role migration described above.

No additional Classic in-game behavior test is required specifically for build 69934 because the build contains no UI-source change beyond `version.txt`; the normal cross-flavor release smoke remains applicable.
