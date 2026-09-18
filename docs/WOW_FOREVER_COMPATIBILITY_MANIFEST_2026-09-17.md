# WoW Forever Compatibility Manifest

Status: implementation and automated validation complete; Forever client QA pending
Date: 2026-09-17
BFL base: `main` at `a42602b`
Implementation branch: `codex/wow-forever`
Worktree: `C:\Users\hofer\Documents\BFL\worktrees\BetterFriendlist\wow-forever`

## Executive decision

WoW Forever must be treated as a game type in the Mainline code family, not as
Classic. Its `1.60.1` version string is not a valid family discriminator.

The compatibility contract is therefore:

1. Determine the code family from `WOW_PROJECT_ID` and
   `WOW_PROJECT_MAINLINE`, never from the numeric interface version alone.
2. Determine optional behavior from API, enum, addon, template, and game-rule
   capabilities.
3. Keep expansion labels such as `IsTWW` and `IsMidnight` separate from API
   family and feature support.
4. Do not hard-code `camelot`. Blizzard uses that game-type name in the current
   source routing, but has explicitly described it as temporary. The audited
   public API exposes `C_GameRules.IsStandard()` but no durable
   `IsForever()`/`IsCamelot()` identity function. BFL does not need a positive
   Forever identity to be compatible.

This is a required architectural correction. With the current logic,
`tocVersion < 20000` makes Forever look like Classic Era and prevents several
Mainline features from loading.

## Audited source baselines

| Flavor | Branch | Build | HEAD | Role in this audit |
| --- | --- | --- | --- | --- |
| WoW Forever | `forever` | `1.60.1.69893` | `4d5d706b8e01` | Target game type and authoritative delta. |
| Retail PTR2 | `ptr2` | `12.1.5.69848` | `f663342f08a6` | Mainline 12.1.5 comparison baseline. |
| Retail live | `live` | `12.1.0.69587` | `8ea15b61e45c` | Current live regression baseline. |
| Retail PTR | `ptr` | `12.1.0.69587` | `a89e9d0ceb7f` | Secondary Mainline regression baseline. |

The Wednesday source-update automation now includes `forever` alongside
`live`, `ptr`, `ptr2`, and all configured Classic branches. The local Forever
clone is clean and tracks `origin/forever`.

## API and UI findings

### Mainline family evidence

- Forever's `Blizzard_FriendsFrame.toc` declares
  `AllowLoadGameType: mainline`.
- The same TOC selects shared `[Family]` files and replaces only selected files
  with `[Game]` variants for the current `camelot` game type.
- `Blizzard_ProjectConstants` still defines `WOW_PROJECT_MAINLINE = 1` and
  `WOW_PROJECT_CLASSIC = 2`; Mainline BNet code defaults `WOW_PROJECT_ID` to
  `WOW_PROJECT_MAINLINE`.
- The modern disarmament/secrets model is present. BFL already detects
  `issecretvalue` by capability, which is the correct foundation for Forever.

### Surface comparison

A static inventory found 169 `C_*` namespace/method pairs referenced by BFL.
No method that is documented on PTR2 and used by BFL is absent from the Forever
generated API documentation. Eleven referenced helpers are undocumented on
both baselines, so they are existing guarded/legacy cases rather than a Forever
regression.

The generated `FriendList`, `SocialQueue`, `RecruitAFriend`,
`SocialRestrictions`, `Club`, and `PartyInfo` API surfaces used by BFL are
materially aligned between Forever and PTR2. The relevant differences are:

| Surface | Forever delta | BFL impact |
| --- | --- | --- |
| Recent Allies | Search input uses `interactionCategoryFilters` with `Enum.RecentAlliesInteractionCategoryFilter`; PTR2 uses `interests` with `Enum.RecentAlliesFriendTag`. Forever adds `IsInteractionCategoryFilterSupportedForCurrentGameType()`. | Required schema adapter. The current BFL payload would be wrong on Forever. |
| Battle.net friend tags | Adds `C_BattleNet.IsFriendTagSupportedForCurrentGameType()`. | Required per-tag filtering before display, search, or mutation. |
| Game rules | Forever exposes dynamic rules including disabled friends, Who, raid groups, Quick Join, and guilds; `GAME_RULES_CHANGED` is synchronous. | Required central rule wrapper and live navigation refresh. |
| Native FriendsFrame | Forever has three tabs (Friends, Raid, Quick Join), removes the native Who tab/mixins, and routes `ShowWhoPanel()` to the LFG frame. | BFL must not assume Standard's four-tab topology or native Who ownership. |
| Friend dropdown data | Forever supplies `ownerFrame` in chat-origin context data. | Preserve the owner frame through BFL menu/context adapters. |
| Shared panel skin | Forever has game-specific side-tab and NineSlice offsets. | Visual QA is required for Modern and Legacy navigation/skins. |
| Guild info | Adds preferred-play-settings getters, setter, request, and update event. | Optional product opportunity, not needed for first-load compatibility. |

## Required implementation backlog

| ID | Priority | Required work | Acceptance criteria |
| --- | --- | --- | --- |
| `WF-COMP-FAMILY` | P0 | Introduce an explicit Mainline-family flag based on `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE`. Make every Classic subtype conditional on not being Mainline. Either redefine the existing `IsRetail` compatibility flag as Mainline-family or migrate its callers to a new clearly named flag. Leave `IsTWW`/`IsMidnight` as content-version labels only. | Simulated `1.60.1` plus `WOW_PROJECT_MAINLINE` is Mainline and never Classic/Classic Era. Existing Era, Anniversary, and progression fixtures remain Classic. |
| `WF-COMP-TOC` | P0 | Add the Forever interface number to both addon TOCs. The expected value derived from `1.60.1` is `16001`; confirm it from the fourth `GetBuildInfo()` return in the client or authoritative release metadata before finalizing. Do not remove existing values. | BFL and the Menu Bridge load without the out-of-date opt-in on the Forever client. |
| `WF-COMP-CAPABILITIES` | P0 | Replace version-threshold feature gates with capability checks where Forever has Midnight APIs under a low version. At minimum audit `HasModernScrollBox`, `HasRecentAllies`, `HasEditMode`, Social UI, guild, Quick Join, RAF, raid, menu, dropdown, and settings gates. | Forever enables every available modern surface; missing/disabled APIs fail closed without errors. Retail and Classic behavior is unchanged. |
| `WF-COMP-RECENT` | P0 | Add a dual Recent Allies search adapter. Prefer `RecentAlliesInteractionCategoryFilter` plus `interactionCategoryFilters` when present; filter every category through `IsInteractionCategoryFilterSupportedForCurrentGameType()`. Retain the PTR2 `RecentAlliesFriendTag` plus `interests` path as fallback. | Search and each offered category work on Forever and PTR2. Unsupported values are neither shown nor sent. Status-only and empty-filter searches remain valid. |
| `WF-COMP-GAMERULES` | P0 | Add one protected `IsGameRuleActive` helper and use it for `IngameFriendsListDisabled`, `IngameWhoListDisabled`, `DisableRaidGroups`, `DisableQuickJoin`, and `GuildsDisabled` where their surfaces exist. Subscribe safely to `GAME_RULES_CHANGED` and rebuild section capabilities/navigation. | Disabled systems cannot be opened through BFL, rule changes update the visible UI without `/reload`, and missing rules/APIs preserve current behavior. |
| `WF-COMP-SECRETS` | P0 | Keep all Forever code on the Midnight-safe interaction path. Audit new routing, menus, searches, whispers, invites, and raid actions for secret-value tests before comparison/conversion and for secure-call boundaries. Do not add a version-based escape hatch. | No secret-value comparison, coercion, or protected-action errors in the Forever smoke matrix. Existing secret-path tests pass. |
| `WF-COMP-FRIENDTAGS` | P1 | When available, call `IsFriendTagSupportedForCurrentGameType()` for every native tag. Exclude unsupported tags from definitions, chips, search, and `SetFriendTags()` payloads. Preserve the existing behavior when the capability is absent. | Menus and mutations contain only supported native tags; custom BFL tags continue to work. |
| `WF-COMP-WHO` | P1 | Decouple BFL's Who surface from Standard FriendsFrame indices and mixins. Honor `IngameWhoListDisabled`. Decide at runtime whether BFL's owned Who implementation is available without relying on Blizzard's removed Forever WhoFrame. Route Forever's `/who` and `ShowWhoPanel()` entry points into BFL while BFL owns the Friends UI. | BFL navigation has no missing-mixin/global errors. Who is reachable only when supported and allowed; `/who` opens BFL's Who tab without also opening `LFGWhoListFrame`, while the native Group Finder remains available from its own UI. |
| `WF-COMP-MENUS` | P1 | Preserve `ownerFrame` when adapting Blizzard/chat friend context data and re-run menu ownership/anchor tests under the disarmament model. | Chat- and BFL-origin menus anchor, close, and dispatch correctly without taint. |
| `WF-COMP-TOOLS` | P1 | Add a `forever` client target to `BFL-Paths.ps1`, deployment/install/SavedVariables parameter validation, Ready-for-QA deployment coverage, and deployment documentation once the install-folder name is known. Keep UI source paths separate from WoW deployment targets. | `CleanCopy`, install, SavedVariables lookup, and Ready-for-QA accept the Forever target and resolve only the intended client directory. |
| `WF-COMP-SKINS` | P1 | Verify both BFL navigation modes, side-tab icons, NineSlice edges, simple mode, ElvUI integration, scaling, and narrow/dense layouts against the Forever game-specific shared panel templates. Use capability/layout fixes only where a visible defect exists. | No clipped, offset, doubled, or mis-anchored tab/window art across the supported UI modes. |
| `WF-COMP-STANDARD-ONLY` | P1 | Audit Mainline gates whose feature may still be Standard-only, especially `HouseListProxy` and addon-load assumptions. Gate them on the concrete addon/API or game rule rather than the Mainline family alone. | A missing Standard-only Blizzard addon never produces load retries, errors, or dead UI on Forever. |

## Implementation disposition

| ID | Outcome |
| --- | --- |
| `WF-COMP-FAMILY` | Implemented. `BFL.IsMainline` is resolved from `WOW_PROJECT_ID`; all Classic subtype flags require a non-Mainline family. `BFL.IsRetail` remains a compatibility alias for Mainline. The fallback recognizes the reserved `16001` Forever interface without classifying it as Era. |
| `WF-COMP-TOC` | Implemented in BetterFriendlist and the Menu Bridge with `16001`. A live fourth-return `GetBuildInfo()` confirmation remains part of first-client QA because no Forever installation is currently present. |
| `WF-COMP-CAPABILITIES` | Implemented. Recent Allies, ScrollBox, Social UI, menus, dropdowns, Edit Mode, guild, RAF, Quick Join, raid, and settings retain concrete API/rule checks while existing `IsRetail` callers inherit the Mainline-family correction. |
| `WF-COMP-RECENT` | Implemented with a dual schema resolver. Forever emits only `interactionCategoryFilters`; Standard emits only `interests`; unsupported categories and secret/error results fail closed. |
| `WF-COMP-GAMERULES` | Implemented through the protected central wrapper and `GAME_RULES_CHANGED` refresh. Disabled friends, Who, raid, Quick Join, and guild surfaces cannot be selected or redirected through BFL. |
| `WF-COMP-SECRETS` | Implemented for the new paths. Game-rule results, system-status results, category support, tag support, searches, addon checks, and guild preference reads are protected and reject secret results before inspection. Full taint/protected-action verification remains an in-client smoke item. |
| `WF-COMP-FRIENDTAGS` | Implemented. Native definitions, chips/search mappings, stored handoff data, desired state, and `SetFriendTags` payloads contain only supported game-type tags. Custom tags are unchanged. |
| `WF-COMP-WHO` | Implemented as a BFL-owned capability. It requires the concrete Who API, honors `IngameWhoListDisabled`, and routes Forever's `/who` plus `ShowWhoPanel()` entry point to BFL's Who tab. During the resulting BFL-owned query, Forever's `LFGWhoListFrame` listener is temporarily suspended so its `WHO_LIST_UPDATE` handler cannot open `LFGParentFrame`; the listener is restored after the result or timeout. The Who list shows a loading spinner until `WHO_LIST_UPDATE`; its empty-result message is reserved for completed empty responses. Opening BFL's Search Builder imports the current query's name, guild, zone, class, race, and level filters—including Forever's automatic zone/range—and preserves unmodeled free-form terms without sending another request. The native Group Finder remains accessible through its own UI, and no removed Blizzard Who mixin is required. |
| `WF-COMP-MENUS` | Implemented in the core context wrapper, MenuSystem, and Menu Bridge safe context. The originating `ownerFrame` is retained for both BFL- and chat-origin adapters. |
| `WF-COMP-TOOLS` | Implemented. `classic_beta` maps to the current Forever Beta folder `_classic_beta_`; `forever` remains mapped to the future standalone `_forever_` target. Both are supported by CleanCopy/install/SavedVariables/Ready-for-QA tooling, and `all` safely skips absent targets. |
| `WF-COMP-SKINS` | Implemented at the compatibility layer. Modern side tabs compose BFL count placement with the active game-type `GetIconAnchorOffsetsForTabArt()` result rather than replacing Forever's template offset. Visual verification of Modern, Legacy, Simple, ElvUI, scale, and density combinations remains in-client QA. No source-backed NineSlice defect requiring an override was found. |
| `WF-COMP-STANDARD-ONLY` | Implemented. `HouseListProxy` now requires the concrete `Blizzard_HouseList` addon capability before registering load/combat hooks; Mainline family alone is insufficient. |

Feature-opportunity decisions:

- `WF-FEAT-RECENT-CATEGORIES`: shipped through the supported-category adapter and Blizzard labels.
- `WF-FEAT-GUILD-PREFERENCES`: evaluated and explicitly not exposed as a user-facing control because BFL has no clear friend-list workflow for mutating it. A guarded read-only snapshot and update-event version are available for future diagnostics/workflows.
- `WF-FEAT-DIAGNOSTICS`: shipped as `BFL:GetCompatibilityDiagnostics()` without exposing the temporary internal game-type label.
- `WF-FEAT-OWNED-WHO`: shipped behind the concrete Who API and game rule; BFL owns `/who` while active, and Blizzard's Group Finder remains separately accessible through its own UI.

## Feature opportunities

These are not launch blockers and should remain capability-gated:

| ID | Priority | Opportunity | Guardrail |
| --- | --- | --- | --- |
| `WF-FEAT-RECENT-CATEGORIES` | P1 | Present Forever's six native Recent Allies interaction categories: Professions, PvP, Raiding, Dungeons, Delves, and Questing. | Use Blizzard labels when available and expose only values approved by the game-type support API. Do not map unsupported role/roleplay tags by numeric coincidence. |
| `WF-FEAT-GUILD-PREFERENCES` | P2 | Evaluate preferred-play-settings as guild roster/search metadata or filtering. | Ship only with a clear user workflow; observe the update event and keep the feature absent when the API is missing. |
| `WF-FEAT-DIAGNOSTICS` | P2 | Extend BFL diagnostics to report project family, TOC version, Standard/non-Standard state, active relevant game rules, and capability outcomes. | Do not expose the temporary `camelot` label as a permanent product name. |
| `WF-FEAT-OWNED-WHO` | P2 | BFL may provide a richer in-window Who experience than Forever's native LFG routing when the API and game rule allow it. | Treat this as a BFL-owned feature, not restoration of removed Blizzard frames; validate expected product behavior with maintainers in client. |

## Explicit no-action findings

- BFL has no `AuraContainer`, `AuraButton`, `UnitAura`, or `C_UnitAuras` call
  site. The 12.1 aura-container/button migration therefore requires no current
  code change. Any future aura surface must start on the 12.1 model.
- Forever-only SD/HD, Hardcore, Self-Found, and experience-preset game-rule
  APIs have no BFL social/roster use case.
- `C_BattleNet.AreHighResTexturesInstalled()` does not replace a BFL texture
  capability check.
- `C_EditMode.GetEditModeDefaultLayout()` is not needed for compatibility with
  BFL's current settings/UI ownership.

## Validation matrix

Static and automated gates:

1. Add family-classification tests for Mainline `1.60.1`, Retail 12.x, Classic
   Era 1.15.x, Anniversary 2.5.x, and progression 5.5.x.
2. Add dual-schema Recent Allies tests, including missing enums, unsupported
   categories, API errors, and status-only searches.
3. Add friend-tag support-filter and mutation-payload tests.
4. Add game-rule on/off/error tests plus a `GAME_RULES_CHANGED` navigation
   refresh test.
5. Run `tools\BFL-PackageCheck.ps1` and
   `tools\BFL-PreCommitDelta.ps1` for runtime changes. Run the changed-locale
   contract if implementation changes any user-facing string.
6. Run `tools\BFL-ReadyForQA.ps1` after the substantial cross-flavor runtime
   implementation, with a clean Forever deployment once the client target is
   configured.

Required in-client smoke coverage:

- clean login and reload without out-of-date opt-in;
- Friends, requests, Recent Allies, Quick Join, RAF, guild, raid, and Who
  availability under each applicable game rule;
- add/remove/search native and custom friend tags;
- whisper, invite, note, favorite, context-menu, and raid actions under secrets;
- native `/who` and BFL Who routing;
- Modern, Legacy, Simple Mode, scaling/density, and supported skin integrations;
- at least one Retail, Classic Era, Anniversary, and progression regression
  smoke after the family-classification change.

## Validation result (2026-09-17)

- Lua syntax validation passed for all changed runtime and test files.
- `BFL-PackageCheck.ps1` passed, including companion-addon metadata.
- `BFL-PreCommitDelta.ps1` passed with 0 new and 0 resolved warning signatures
  after the intentional line-number baseline refresh.
- `BFL-ReviewCheck.ps1 -BaseRef main` passed with 0 failures and 0 warnings;
  the changed-locale contract checked all 11 locales with 0 failures.
- `BFL-ReadyForQA.ps1 -DeployClient all -BaseRef main` passed.
- Fresh CleanCopy content, including the Menu Bridge, was deployed to Retail,
  PTR, XPTR, Beta, the installed Forever Beta (`_classic_beta_`), Classic
  progression, Classic PTR, Classic Era, and Anniversary. Source/deployment
  hashes were spot-checked for the compatibility core, Recent Allies adapter,
  and Menu Bridge TOC.
- The future standalone Forever deployment target resolves to
  `C:\Program Files (x86)\World of Warcraft\_forever_` and is safely skipped
  while that client is absent. The installed Forever Beta resolves through
  `classic_beta` to `_classic_beta_` and receives normal CleanCopy deployments.
  A live `GetBuildInfo()` interface confirmation and the visual/taint smoke
  matrix remain open in-client QA items rather than code or tooling blockers.

## Definition of done

Forever support is complete only when every P0/P1 compatibility item above is
implemented or explicitly retired with source evidence, both TOCs accept the
confirmed interface, static gates pass, a fresh Forever deployment loads, and
the in-client smoke matrix has no Lua errors, taint/protected-action failures,
or disabled-system escape paths.
