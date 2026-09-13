# WoW UI Source Impact Manifest — 12.1.5 implementation

Status: implemented; static Ready-for-QA, CleanCopy deployment, and maintainer in-game QA passed
Date: 2026-09-13
BFL base: `main` at `b9f53ce`
Implementation branch: `codex/12-1-5-feat-compat-modern-pos`
Worktree: `C:\Users\hofer\Documents\BFL\worktrees\BetterFriendlist\12-1-5-feat-compat-modern-pos`

## Scope and decision rule

This manifest records the implementation decision for every BFL-relevant item found in the refreshed Retail and Classic UI sources and in the unofficial 12.1.5 PTR 1 addon-author notes. Compatibility and feature value have equal weight. A 12.1.5-only API is accepted only behind a runtime capability check and a safe older-client fallback; a version-number branch is not considered sufficient.

Priorities:

- **P0:** loading, data-loss, error, or taint risk.
- **P1:** visible compatibility defect or high-value feature.
- **P2:** useful feature with narrower context or PTR uncertainty.
- **P3:** observe or adopt only with measured benefit.
- **No action:** no BFL-owned surface, or migration would not change user-visible behavior, safety, or measured cost.

## Audited source baselines

| Flavor | Branch | Build | HEAD | Result |
| --- | --- | --- | --- | --- |
| Retail live | `live` | `12.1.0.69587` | `8ea15b61e45c` | LFG assignment parity applies now. |
| Retail PTR | `ptr` | `12.1.0.69587` | `a89e9d0ceb7f` | Relevant social surfaces match live. |
| Retail PTR2 | `ptr2` | `12.1.5.69594` | `49b69918fcdc` | Source for the gated 12.1.5 features. |
| Classic progression | `classic` | `5.5.4.69585` | `ecadf9d3326f` | No BFL-specific delta. |
| Classic PTR | `classic_ptr` | `5.5.4.67849` | `ea6f4ee4ce0d` | No new remote change. |
| Classic Era | `classic_era` | `1.15.9.69722` | `33e177d9bf38` | New LFG browse nil guard has no BFL-owned call site. |
| Classic Anniversary | `classic_anniversary` | `2.5.6.69795` | `1463c686270b` | New LFG browse nil guard has no BFL-owned call site. |

The generated API documentation and Blizzard call sites in these local Gethe clones are the authoritative implementation reference. PTR behavior can still change before release.

## Implemented BFL work

| ID | Type / priority | Decision and implementation | Older-client behavior | Remaining acceptance |
| --- | --- | --- | --- | --- |
| `COMP-RAID-LFG` | Compatibility, P1 | Implemented. `BFL.Compat.ShouldDisplayMainTankAndAssist()` wraps `C_LFGInfo.IsInMatchmadeRaidWithoutRoleRequirements()`. Main Tank/Main Assist icons and their tooltip hitboxes are suppressed when Blizzard reports the restricted matchmade-raid context. `LFG_UPDATE` goes through BFL's safe event registration and the coalesced refresh. Leader/Assistant rank and combat-role visuals are unchanged. | Missing API, invalid event, secret return, or API error fails open to the previous icon behavior. All Classic flavors therefore retain their current presentation. | In-game checks in a normal raid and a role-free matchmade raid. |
| `COMP-TOC-1215` | Compatibility, P1 | Implemented. `120105` is the leading interface value; all previous Retail and Classic values remain declared. | No older interface target was removed. | Load on build `12.1.5.69594` without the out-of-date opt-in. |
| `FEAT-INTL-SEARCH` | Feature, P1 | Implemented. `BFL.IntlCompat` provides guarded `Contains`, primary-strength equality, case folding, and tertiary sort keys. Local BFL friend/filter fields and the Recent Allies fallback use the helper. Sort keys are prepared once during list construction and are not generated inside `table.sort`. Native `C_BattleNet.SearchFriends` and `C_RecentAllies.SearchRecentAllies` remain authoritative. Contact IDs and SavedVariables keys are untouched. | Missing, partial, secret, empty, or failing native results use BFL's existing `StripAccents():lower()` behavior. | PTR locale smoke matrix (`deDE`, `frFR`, `ruRU`, `koKR`, `zhCN`, `zhTW`) and a large-list performance comparison. |
| `PERF-SIGNAL-MAP` | Performance, P3 | Implemented narrowly for the raid/LFG burst coalescer. `BFL.TimerCompat.CreateKeyedDebouncer()` uses `C_Timer.NewTimedSignalMap()` when available; rescheduling the same numeric key replaces its deadline. This avoids a broad timer migration while proving the API on a real hot path. | A generation-based `C_Timer.After` fallback ignores superseded callbacks. If no timer exists, the callback executes immediately. | Compare refresh counts on PTR; expand to other modules only if profiling shows a benefit. |
| `COMP-STORY-RAID` | Compatibility, P1 | Implemented. The Legacy and Modern Raid tabs follow Blizzard's `DifficultyUtil.InStoryRaid()` state, including disabled visuals and Blizzard's restriction reason. | Classic and clients without the API keep the Raid tab available. | Maintainer in-game QA passed. |
| `FEAT-MASTER-LOOTER` | Feature, P1 | Implemented. Raid members use Blizzard's roster flag, party members use the guarded loot-method mapping, and the original Blizzard Master Looter texture is supported by Classic plus both Retail raid layouts. | Clients or groups without a Master Looter flag simply keep the icon hidden. | Maintainer in-game QA passed. |

## Unofficial 12.1.5 PTR 1 notes: complete disposition

| PTR change | BFL impact | Decision / required work |
| --- | --- | --- |
| `CustomAuraButton` Pandemic Enter/Active/Leave animations and the new forbidden aspects | BFL owns no `CustomAuraButton`, AuraContainer, or Pandemic animation path. | **No action.** Adding an aura feature would be a new product area unrelated to friend/raid management. Re-audit only if BFL later renders aura buttons. |
| `TimedSignalMap` and `CreateTimedSignalCallbackMap` | Direct fit for burst event coalescing. | **Implemented** through a BFL-owned keyed debouncer with fallback. BFL does not depend on the convenience wrapper. |
| `CreateFrameWithOptions` | Existing BFL factories and XML already express parents, templates, IDs, and initial visibility. | **No migration.** The API adds no user-visible capability here and is PTR-only. New isolated 12.1.5-only frames may use it later behind a capability check. |
| `roundLayoutToNearestPixel`, `SetRoundLayoutToNearestPixel`, recursive `PixelUtil` helper | BFL has no reported fractional-layout defect tied to these APIs; its one pixel-size calculation is not equivalent to recursive layout rounding. | **No blanket migration.** Validate a specific blurry or drifting surface first, then enable it capability-safely for that subtree. |
| Native `math.*`, `string.*`, and `table.*` utility functions with aliases | Existing names remain aliased and BFL has no breakage from the move to native code. | **No compatibility edit.** Prefer existing project helpers for cross-flavor code; adopt a new native-only name only with a guard and measurable simplification. |
| Removed `Blizzard_Deprecated*` addons | Repository audit found no BFL TOC dependency, load call, or symbol reference to any removed addon. | **No action.** Package validation remains the regression gate. |
| `C_Weather` | No friend, social, roster, queue, or raid-management use case. | **No action.** Weather UI would be unrelated feature scope. |
| `C_Intl` | High-value Unicode search and collation opportunity across supported locales. | **Implemented** locally and capability-gated. Secret values are rejected before comparison, conversion, or native API access; locale and performance smoke tests remain. |
| Localized aura spell-ID tooltip line | BFL does not add or recolor that tooltip line. | **No action.** |
| `Enum.TooltipDataLineType.UnitCriteriaProgress` for Mythic+ enemy forces | BFL does not parse or transform Mythic+ tooltip lines. | **No action.** |
| Macro `#showtooltip` ping fix | BFL does not own action-bar macro pings. | **No action.** |
| Long-duration aura duration-object rendering fix | BFL owns no aura-duration object. | **No action.** |
| `EnumerateFrames` performance fix | BFL gains the client fix transparently and does not need an API change. | **No action.** Do not expand enumeration usage without profiling. |
| Direct `Hide()` panel/Game Menu fix | BFL's own window routing is not a Blizzard panel regression workaround. | **No action.** Retain existing panel APIs and verify normal close/reopen behavior in smoke QA. |

## Other refreshed-source findings

| API or source family | Disposition |
| --- | --- |
| 12.1 SocialUI, Battle.net friend tags, server search, Recent Allies, Title Friends, Friends restrictions, and SocialUI routing | Already covered by BFL capability helpers and current implementations; regression QA only. |
| Optional `UnitCanAssist` arguments, VoiceChat TTS secret annotation, aura/nameplate/private-aura work | No BFL call site; no action. |
| `UnitIsPlayerControlledOrGroupMember()` | Observe. It currently replaces no faulty or complicated BFL guard. |
| `C_PvP.IsTrainingGroundsArena/BG`, `C_UnitAuras.GetAuraCasterGUID`, `C_AuraContainerUtil.*`, `C_ActionBar.IsMacroActionWithShowTooltip` | No BFL-owned feature surface; no action. |
| Classic progression, PTR, Era, and Anniversary deltas | No changed API, event, template, or mixin consumed by BFL; no code change. Shared capability fallbacks are the required compatibility behavior. |

## Verification contract

Static and automated gates:

1. Lua/XML/package validation via `tools\BFL-PackageCheck.ps1`.
2. New warning-signature comparison via `tools\BFL-PreCommitDelta.ps1`.
3. Locale completeness/freshness via `tools\BFL-LocalizationCheck.ps1 -Mode Changed -BaseRef main`.
4. Focused runtime contract tests for missing/native/error API paths, keyed rescheduling, LFG assignment visibility, and assignment-icon/tooltips.
5. Fresh deployment for runtime QA on Retail. Classic source-level compatibility is enforced by the fallbacks and should receive at least one client smoke test before release.

Result through 2026-09-13: all executable static gates passed. `BFL-PackageCheck`, `BFL-PreCommitDelta`, `BFL-ReviewCheck`, the changed-locale contract, and direct `luac -p` checks reported no failure. The warning baseline remains at 748 known signatures; it was refreshed only for source-line relocation, with zero warnings added or removed. Fresh `CleanCopy` deployments completed for every locally installed Retail and Classic target. The maintainer subsequently reported successful in-game QA; command output from that client session is not retained in this repository.

Maintainer acceptance reported complete:

- Load without out-of-date opt-in on 12.1.5.
- Search and sort representative Latin, Cyrillic, Korean, Simplified Chinese, and Traditional Chinese names and labels.
- Compare large-list refresh cost with 12.1.0.
- Exercise normal raid and role-free matchmade raid assignment visibility.
- Verify the Story Mode Raid-tab restriction and disabled-state tooltip in Modern/Legacy.
- Verify Master Looter presentation in supported raid layouts.

## Release decision

The code is release-ready because every new runtime symbol is discovered dynamically and has the current Retail/Classic behavior as fallback. PTR API names or semantics must be rechecked against future source updates before later publications.
