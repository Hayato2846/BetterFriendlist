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

## VSCode

Open VSCode on `C:\Users\hofer\Documents\BFL\repos\BetterFriendlist` or a specific worktree.
Do not use the WoW `Interface\AddOns\BetterFriendlist` path as the main editing workspace
after migration; that path is a deployment target and may be replaced by scripts.
