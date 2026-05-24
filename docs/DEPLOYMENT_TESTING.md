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

Install a release ZIP for exact package testing:

```powershell
.\tools\BFL-InstallRelease.ps1 -Client retail -Zip C:\Users\hofer\Documents\BFL\releases\BetterFriendlist\BetterFriendlist-2.5.9.zip
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

1. Merge feature branches into `main`.
2. Create a release-candidate worktree from `main`.
3. Run `.\tools\BFL-PackageCheck.ps1`; it also verifies that tracked internal files are excluded by `.pkgmeta`.
4. Deploy the candidate with `CleanCopy` to Retail and the relevant Classic clients.
5. Test with clean and migrated SavedVariables profiles.
6. Update `CHANGELOG.md` and the `.toc` version when doing release work.
7. Push the tag; GitHub Actions packages and publishes the release.
8. Download/install the generated ZIP with `BFL-InstallRelease.ps1` and do one exact-package smoke test.

## Review Automation

Run the local review gate before opening or updating a PR:

```powershell
.\tools\BFL-ReviewCheck.ps1
```

The review check runs package validation, verifies TOC file references, checks changed locale
keys against `enUS`, scans changed Lua files for common bug patterns, and prints diff-based
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
