# Visual UI verification

Before visual Lua/XML or skin/theme edits, read the relevant sections of `docs/UI_CONVENTIONS.md`. If absent, check the same relative path in the main repo at `C:\Users\hofer\Documents\BFL\repos\BetterFriendlist`; if both are absent, report this and use available conventions.

Its `SettingsComponents.lua` guidance applies to legacy settings. Settings Center controls follow `libsettingsdesigner-bfl`; do not migrate them back to legacy controls when applying old UI examples.

Define the target state and geometry to inspect. Use supplied screenshots/references; if a low-risk request lacks them, state a narrow visual assumption and proceed. For ambiguous substantial redesigns, clarify the direction with a small annotated plan or throwaway mockup when useful.

## Required captures

1. Run `./tools/BFL-UISimCapture.ps1` from the active checkout before editing and after editing with the same fixture. Default: `/bfl preview friends_headers_i18n`. Select the changed surface with `-Profile`, e.g. `guild` or `friend_requests`.
2. Open and compare both runs' `normal.png` and `narrow.png`. Check clipping, overlap, anchoring, and readable text. Use `normal.log`/`narrow.log` for resolved geometry. Fix problems and recapture before handoff.
3. For unsupported surfaces, use a focused simulator scene or record why maintainer in-client capture is required. Give exact live-test steps; never automate the WoW client.

The prepared Windows Retail kit is in `references/wow-ui-sim-v0.1.40` under the BFL hub. Use `-SimulatorHome` for another location of that kit. Outputs default to `diagnostics/bfl-ui-tests` in the hub.

The runner restores template-declared left alignment of Modern card text only inside the simulator. Pass `-RawTextAlignment` when editing alignment so this cannot hide the result. Separate CJK placeholder glyphs, atlas differences, and simulator artifacts from in-game regressions.

## Relevant states

Review affected combinations of long names, `deDE`/CJK strings, empty/large lists, hover/selected/disabled/offline states, Blizzard/Dark/Custom/ElvUI themes, and Retail/Classic templates/scrolling. Document which client/state still needs live verification. A simulator screenshot does not establish in-game, taint, or controller correctness.
