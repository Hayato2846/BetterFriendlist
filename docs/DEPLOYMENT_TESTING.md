# BetterFriendlist Deployment and Testing

This repository is the development workspace. The WoW `Interface\AddOns\BetterFriendlist`
folders are deployment targets only.

## Layout

Recommended local layout:

```text
C:\Users\hofer\Documents\BFL\
  repos\BetterFriendlist\
  worktrees\BetterFriendlist\
  deploy\
    retail\BetterFriendlist\
    classic\BetterFriendlist\
    classic_era\BetterFriendlist\
    classic_ptr\BetterFriendlist\
    anniversary\BetterFriendlist\
    ptr\BetterFriendlist\
    xptr\BetterFriendlist\
    beta\BetterFriendlist\
    classic_beta\BetterFriendlist\
    forever\BetterFriendlist\
  releases\BetterFriendlist\
  savedvariables\BetterFriendlist\
```

Each WoW client uses either a managed `Interface\AddOns\BetterFriendlist` folder or a link
to the matching deployment slot. Existing non-linked client folders are normal on Windows
because WoW, VSCode, antivirus, or file watchers can keep the AddOn directory locked.

## Worktrees

Use one branch and one worktree for each feature, bugfix, or parallel Codex chat. When the
work is driven by a GitHub issue, include the issue number in both names with an
`issue-NNN-` prefix, for example:

```powershell
.\tools\BFL-Worktree.ps1 -Action Create -Name issue-89-elvui-skin-disabled -Branch fix/issue-89-elvui-skin-disabled
```

For non-issue work, use a concise feature name such as `quickfilter-sorter-tab`.

## Offline UI captures

Run the capture script from the checkout you want to inspect. It uses the prepared
Retail simulator kit under `references/wow-ui-sim-v0.1.40` in the BFL hub and reads
installed game assets while WoW is closed.

```powershell
.\tools\BFL-UISimCapture.ps1
.\tools\BFL-UISimCapture.ps1 -Scenario nickname_hint
```

The default capture renders the friend list at normal and narrow widths. The
nickname scenario renders four states, from `modern-collapsed` and
`modern-expanded` through `legacy-collapsed` and `legacy-expanded`. Add
`-Variant modern-expanded` to capture just that state. Add `-Fade` to capture
the hint halfway through its fade-out. Each run writes PNGs and
frame logs under `diagnostics/bfl-ui-tests`. Use the same scenario before and
after a change to compare screenshots and geometry. The Retail simulator uses
Retail artwork for both interface styles.

## Native friend menu

Run this check on Retail, Forever, Classic progression, Classic Era, and Anniversary. Include both interface styles on clients that offer them.

Client selection and API availability are checked separately. The native
route requires Blizzard's link handler, mouse routing and menu extension
APIs. The client test below checks whether the route keeps Whisper taint-free.

- Right-click directly on a friend row and choose Whisper in Blizzard's menu.
- Check that BFL's groups, nickname, tags, private note, known characters and
  account controls appear for eligible friends. Check that standard friend
  actions and Menu Bridge entries appear once.
- On Forever, with a friend on another ruleset, check that Invite or Request to
  Join shows the ruleset restriction. For a friend with multiple accounts,
  verify that only the blocked character is disabled in the account submenu.
- Left-click a row, then move the pointer away. The selection should stay
  highlighted after the tooltip disappears. A second click clears it.
  Check that dragging a row still works.
- Enable Click to Whisper with Single Click and check that one click opens
  the Blizzard edit box. In Double Click mode, check that the first click
  selects and a quick second click opens the edit box once. A late second
  click or moving to another row should start a new sequence.
- In Legacy, select a friend and click Send Message. Select a different
  friend and verify the next click targets the new selection. Deselecting
  should disable the button.
- In the Friends Broker tooltip, left-click a friend, then right-click and
  choose Whisper. Check both a Battle.net friend and a character friend.
  Check that Alt- and Shift-click still run their broker actions and that
  collapsing and reopening a group routes clicks to the current row.
- In Who, click a result to select it, then repeat with a quick double-click
  to open a whisper. Verify that changing the double-click action to Invite
  still invites. Check Ctrl-click column search, Alt-click in the Search
  Builder, and Whisper from the right-click menu.
- In the guild window, right-click an online guild member and choose Whisper.
  In Guild Broker, test a left-click and Whisper from the right-click menu.
  Verify the recipient after selecting a different member, including one on
  another realm if available. Check that Alt-click and Shift-click retain
  their broker actions.
- In Recent Allies, choose Whisper from a character's right-click menu.
- Check that the Blizzard chat field opens and inspect the taint log. Opening
  the field is sufficient for this test. No message needs to be sent.
- On Forever and Retail, enter combat with Click to Whisper set to Single Click.
  Test a Battle.net and character friend, including after scrolling to new rows.
  Repeat with Double-click and verify that the first click selects the row.
  Repeat with Streamer Mode active. Check that changing rows or pressing the
  chat-link modifier cancels the pending second click.
- In the same combat, test Send Message in Legacy, left-click in both brokers,
  and double-click in Who. Repeat with Streamer Mode enabled and verify the
  recipient each time. Check that broker Alt- and Shift-click and Who's
  Invite option still take their own paths.
- With Streamer Mode active, test both double-click and right-click followed
  by Whisper on a Who result. Open the Guild Broker's right-click menu and
  choose Whisper. Check the recipient and inspect the taint log.
- With Streamer Mode active, test the BattleTag, Nickname, and Note formats on
  the menu title. For a Real ID friend without a nickname or note, verify the
  short BattleTag appears in both the native and BFL fallback menus. Check the
  character-name fallback on a character friend. Choose Whisper and confirm
  the chat edit box still targets that friend. Inspect the taint log for both steps.
- While chat lockdown is active, test native right-click and Whisper on a
  character and a Battle.net friend. Check whether the client opens the menu
  and chat edit box, and inspect the taint log.
- When a link cannot be built, check that right-click opens the BFL menu and
  that group actions are available. With the Menu Bridge
  enabled, supported third-party actions should appear once.
- With Total RP 3 enabled and its profile action allowed, disable the Menu
  Bridge companion and reload. Verify that the profile action appears once.
  Re-enable the companion to verify captured third-party actions in BFL-owned
  menus such as Who and Recent Allies.

The offline smoke test checks that the row's hyperlink layer passes
right-clicks to Blizzard's native handler and delegates other supported row
interactions to BFL. In the client, choose Whisper from the resulting menu and
inspect the taint log for the right-click and Whisper path.

## Native raid member menu

- Join a raid and open BFL's Raid tab. Right-click two members in different
  groups before opening Blizzard's Raid tab. Verify that the native raid
  management menu targets the clicked member.
- Try an available raid management action. Repeat after a roster or subgroup
  change and in both BFL layouts on clients that offer them.
- Enter combat while hovering a member and verify the old click target is
  cleared. Check the native menu again after combat.

## Native friend search

- In Retail and Forever, start in BFL and type the name of an offline Title Friend.
  Check that the BFL field stays visible before focusing, while typing, and
  after clearing it. Try a BFL nickname, note and tag as well.
- Enter combat with both windows closed, then open BFL for the first time
  and look up a friend whose name matches only through Blizzard's search.
  Repeat with Social UI already loaded and with it still unloaded, and in
  Modern and Legacy. Also enter combat while the native field is active.
- Open Blizzard Social UI while the native field is embedded in BFL.
  Verify the native field and list return to Blizzard and BFL's local
  search remains usable. Close Blizzard Social UI and reopen BFL in combat.
- Clear the search with its X, apply a BFL Quick Filter, then switch to
  Recent Allies and back. Repeat in both BFL interface styles and Simple Mode.
- Verify that both lists keep their own search field visible and editable.
  In a context that restricts friend results, verify the local search remains
  usable and previous native matches disappear. Check the taint log and
  `ADDON_ACTION_BLOCKED` for the search and layout paths.

## Modes

- `CleanCopy`: mirrors a repo or worktree into the active client AddOn folder when that folder already exists as a normal non-git directory. If the client path is missing or already linked, it uses the deployment slot/link layout.
- `Link`: links a WoW client directly to a repo, worktree, or deployment slot for live development.
- `Zip`: installs a release ZIP into a deployment slot for user-equivalent testing.

Prefer `CleanCopy` for normal QA because it deploys a filtered runtime copy without internal
repo, docs, or tooling files. Use `Link` only when fast edit/reload iteration matters or when
you explicitly want to convert the client folder to a link after closing programs that hold
the folder open.

For existing non-linked client AddOn folders, direct mirroring is the expected `CleanCopy`
path, not a warning fallback. The deploy script refuses direct mirroring into links, unexpected
paths, or repository roots.

## Codex Workflow

Codex should run the needed scripts directly instead of asking the user to trigger VSCode
tasks. After changing addon runtime files, package metadata, or deployment tooling, Codex
should run the relevant checks and deploy a fresh `CleanCopy` before handing the turn back.

Default target is Retail:

```powershell
.\tools\BFL-Deploy.ps1 -Mode CleanCopy -Client retail -Source .
```

Use `-Client all` when the change affects cross-flavor loading, TOC/XML structure,
compatibility code, or release packaging.

The WoW Forever beta currently uses the `classic_beta` client key, which resolves to
the Blizzard installation folder `_classic_beta_`. The `forever` key remains available
for a future standalone `_forever_` installation.

The `forever` target resolves to the conventional `_forever_` WoW client folder. If that
client is not installed yet, `-Client all` reports it as skipped without affecting the
detected Retail, PTR, Beta, or Classic clients.

## CleanCopy Troubleshooting

`BFL-Deploy.ps1` uses `robocopy` for `CleanCopy` mirrors. Keep robocopy retries bounded:
the script passes `/R:1 /W:1` by default so access, permission, or lock failures surface
within seconds. Do not remove those options; robocopy's default retry behavior can make a
simple `Access denied` look like a long-running deploy.

If a direct client deploy appears to hang after this line:

```text
Mirroring CleanCopy directly to existing client AddOn folder: C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist
```

the first suspect is the client AddOn destination, not package generation. Common causes are:

- Missing elevation for `C:\Program Files (x86)\World of Warcraft`.
- WoW, WowUp, antivirus, VSCode, or another watcher holding files in `Interface\AddOns\BetterFriendlist`.
- A previous timed-out PowerShell/robocopy deploy process still running.

The useful diagnostic is the robocopy error line, for example
`FEHLER 5 (0x00000005) Zugriff verweigert` or `Access denied`. When that happens, rerun the
official deploy command with elevated permissions. If elevated deploy still fails, close WoW,
WowUp, and other watchers for the target client, then retry. After any timeout, verify the
client copy instead of assuming it succeeded; compare hashes for the changed runtime files or
check the target `LastWriteTime`.

## Common Commands

Deploy the current checkout to Retail:

```powershell
.\tools\BFL-Deploy.ps1 -Mode CleanCopy -Client retail -Source .
```

Deploy the current checkout to every detected client:

```powershell
.\tools\BFL-Deploy.ps1 -Mode CleanCopy -Client all -Source .
```

Deploy specifically to WoW Forever:

```powershell
.\tools\BFL-Deploy.ps1 -Mode CleanCopy -Client forever -Source .
```

Install a release ZIP for exact package testing:

```powershell
.\tools\BFL-InstallRelease.ps1 -Client retail -Zip C:\Users\hofer\Documents\BFL\releases\BetterFriendlist\BetterFriendlist-2.6.0.zip
```

Create a feature worktree:

```powershell
.\tools\BFL-Worktree.ps1 -Action Create -Name contact-memory -Branch feat/contact-memory
```

Back up Retail SavedVariables:

```powershell
.\tools\BFL-SavedVariables.ps1 -Action Backup -Client retail -ProfileName before-contact-memory
```

## Release Candidate Flow

1. Identify the authorized version and the refs to publish. Merge the intended changes into
   `main` locally. Keep `codex/*` branches local.
2. Create a release-candidate worktree from `main`.
3. Update both TOC versions and date the version entry in `CHANGELOG.md`. Run
   `.\tools\BFL-PackageCheck.ps1` to sync `Modules/Changelog.lua` and verify package exclusions.
4. **Review the exact public copy.** Read the entire version entry through its last line and
   compare it with the in-game entry. Inspect every slash command, including text carried forward
   from the draft. Remove test, debug, diagnostic, and internal recovery commands. Describe the
   player-visible result and leave storage and implementation details in technical documentation.
   Review the entry as it will appear on download sites and Discord.
5. Deploy the candidate with `CleanCopy` to Retail and the relevant Classic clients. Test with
   clean and migrated SavedVariables profiles.
6. Commit the reviewed candidate and run
   `.\tools\BFL-CreateReleaseTag.ps1 -Version X.Y.Z -ValidateOnly`. The gate checks locale
   coverage, English leakage, placeholder and markup parity, translation freshness, runtime
   locale switching, and package readiness.
7. Publish the agreed `main` commit with `git push origin refs/heads/main:refs/heads/main`.
   Confirm that `origin/main` points at the reviewed commit. Use
   `.\tools\BFL-CreateReleaseTag.ps1 -Version X.Y.Z -Push` only for the authorized version.
8. Check the release run against the tag and commit. Verify the version and embedded changelog
   in the published ZIP, check the upload result for each download site, and check the Discord
   step separately. Use `BFL-InstallRelease.ps1` for an exact-package smoke test.

### Correcting a published release

- Establish whether the correction affects the package, public release text, Discord, or several
  of them. Keep the requested version. Get explicit authorization before publishing a different
  version or replacing a published tag.
- For an authorized same-version rebuild, fix and review the release entry on `main`, keep both
  TOC versions, and rerun the release checks. Compare the existing annotated tag object from
  `git rev-parse refs/tags/vX.Y.Z` with
  `git ls-remote --refs origin refs/tags/vX.Y.Z`. Use the tag object's SHA, which is the
  unpeeled ref. After pushing the corrected `main`, run the guarded replacement.

  ```powershell
  .\tools\BFL-CreateReleaseTag.ps1 -Version X.Y.Z -ReplaceTagObject <existing-tag-object-sha> -Push
  ```

  If the ref changed or the release gate fails, stop and recheck the target. Verify the updated
  tag, published ZIP, and each upload separately.
- A tag replacement skips the automatic Discord announcement. To fix the existing message, open
  **Actions → Package and Release → Run workflow** on `main`, enter `release_tag` and
  `discord_message_link`, then verify the edit in the job log. This mode updates one existing
  webhook message using the changelog from the named tag. It skips packaging and requires the
  full entry to fit in one Discord message. For a release split across multiple messages, plan
  the edits for the affected posts before changing any of them.
- If an unintended tag starts a run, check its status and cancel it while possible. Record which
  destinations already received files or messages. GitHub refs, the GitHub release, download sites,
  and Discord are separate destinations. Verify cleanup at each affected destination before
  reporting it complete.

### Lessons from 3.1.0

- A broad push published a local `codex/*` branch. Release pushes now use an explicit destination
  for `main` and the release helper for the authorized tag.
- The final changelog bullet exposed an internal command and a storage detail. The pre-tag review
  now covers the full public entry, including its final line and any commands inherited from drafts.
- The correction first went out under a new version. That run reached download sites and
  Discord before it could be canceled. The approved correction replaced `v3.1.0` and the existing
  Discord announcement was edited in a separate manual run.
  [Unintended release run](https://github.com/Hayato2846/BetterFriendlist/actions/runs/42845500061) ·
  [Same-tag rebuild](https://github.com/Hayato2846/BetterFriendlist/actions/runs/42846120617) ·
  [Discord edit](https://github.com/Hayato2846/BetterFriendlist/actions/runs/42847559252)

## Review Automation

Run the local review gate before opening or updating a PR:

```powershell
.\tools\BFL-ReviewCheck.ps1
```

The review check runs package validation, verifies TOC file references, enforces genuine and
current translations for changed `enUS` keys, scans changed Lua files for common bug patterns, and prints diff-based
review risk buckets. On pull requests, GitHub Actions runs the same script and writes the
summary to the job output.

Use the risk buckets as a review guide, not as a substitute for in-game QA. Anything touching
TOC/XML, compatibility helpers, secure buttons, context menus, tooltips, SavedVariables, or
locale files still needs the matching Retail/Classic review path.

## VSCode

Open VSCode on `C:\Users\hofer\Documents\BFL\repos\BetterFriendlist` or a specific worktree.
Do not use the WoW `Interface\AddOns\BetterFriendlist` path as the main editing workspace
after migration; that path is a deployment target and may be replaced by scripts.
The `.vscode` folder is intentionally ignored by Git and excluded from release packaging.
`tools\BFL-Worktree.ps1 -Action Create` copies the local `.vscode` folder from the source
repo into each new worktree by default; pass `-SkipVSCodeCopy` when a worktree should start
without local editor settings.

For a persistent Source Control view across reboots, open the generated
`BetterFriendlist.code-workspace` from the main repo. It lists the main checkout and all
current worktrees as real VSCode workspace folders, which is more reliable than depending
only on repository auto-detection. Regenerate it after manual worktree changes with:

```powershell
.\tools\BFL-Worktree.ps1 -Action Workspace
```

To migrate convenience folders from an older workspace, import it once and exclude broad
parent folders that would nest the repo and worktree roots:

```powershell
.\tools\BFL-Worktree.ps1 -Action Workspace -ImportWorkspacePath C:\Users\hofer\Documents\BetterFriendlist.code-workspace -ExcludeImportedFolderName BFL
```

Recommended daily setup:

- Prefer VSCode Insiders on this machine; it currently has the newer WoW API, Lua, GitLens,
  Todo Tree, StyLua, Error Lens, spell checker, and Codex/ChatGPT extensions installed.
- Use Project Manager entries for the main repo and active feature worktrees so each Codex
  chat or feature starts in the correct checkout.
- Treat editor diagnostics as the first pass only. WoW Lua LS, Ketho WoW API, LuaLS, and
  Error Lens help catch missing globals, nil/arity issues, and flavor-only APIs, but API
  decisions still need the local Retail and Classic `wow-ui-source` clones.
- For normal hand-test loops, run the VSCode task `QA: Package + Deploy Retail`. Use
  `QA: Package + Deploy All` when TOC/XML, package metadata, compatibility code, or release
  packaging could affect multiple flavors.
- Use the VSCode task `Review Check` before opening or refreshing a pull request.
- Keep XML auto-close/rename support available, but do not format WoW XML on save.
- Use GitLens and GitHub Actions after pushing branches to review history and CI without
  leaving the editor.
- Use Todo Tree for intentional short-lived tags such as `TODO`, `FIXME`, `PERF`, `TAINT`,
  `MIGRATION`, or `REVIEW`; do not use source comments as a long-term backlog.
- Keep StyLua as a manual formatting tool until the project adopts a checked-in formatter
  configuration, to avoid broad formatting churn.
