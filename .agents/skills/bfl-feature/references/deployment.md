# Deployment for runtime QA

For user-requested runtime implementations/fixes, deploy a fresh `CleanCopy` before handoff so the maintainer can test. Skip only if the user opts out or deployment is blocked; report the exact command and reason. Documentation and read-only reviews alone need no deployment.

Run in the active worktree and deploy its complete deployable state, rather than selecting changed files. All clients targeted by that operation receive the same source state. Normal deploy exclusions still apply.

```powershell
./tools/BFL-Deploy.ps1 -Mode CleanCopy -Client retail -Source .
./tools/BFL-Deploy.ps1 -Mode CleanCopy -Client forever -Source .
./tools/BFL-Deploy.ps1 -Mode CleanCopy -Client all -Source .
```

- Choose the affected client explicitly: Retail-only work uses `retail`; Classic-only work selects the affected Classic client(s).
- Forever work, including Forever friends displayed in Retail, also requires `forever`, targeting actual `_forever_\Interface\AddOns` BetterFriendlist and Menu Bridge folders in addition to other affected clients.
- Use `all` when shared TOC/XML, compatibility, settings runtime, loading, or packaging affects multiple flavors. Run source/package checks before deploying. `ReadyForQA -DeployClient` may satisfy the same deployment when it performs the required fresh copy for the final state; do not immediately repeat it.
- Existing non-linked, non-git AddOn folders are mirrored directly by `CleanCopy`. This is the normal path; do not convert them to links. Use `Link` only for explicitly requested link-based live development; use `Zip` for exact release-package testing.
- Allow sufficient command time. Program Files writes can require sandbox escalation. For locks/permissions failures, report the actual blocker; if a watcher holds the folder, reopen VSCode on the repo/worktree rather than the deployment folder. Do not ask the maintainer to run a VSCode task instead of executing authorized commands.
- Verify runtime files and `Modules/Changelog.lua` in targets. Markdown such as `CHANGELOG.md` is excluded. Keep release packages free of internal/workflow files; follow `.pkgmeta` exclusions.

For exact release ZIP installs use `tools/BFL-InstallRelease.ps1 -Client retail -Zip <absolute-release-zip>`. For migrations, release candidates, or old profiles, use `tools/BFL-SavedVariables.ps1` to back up/restore the affected SavedVariables as appropriate; preserve the user's data. Read the relevant `docs/DEPLOYMENT_TESTING.md` section when this workflow or command options are needed.

The maintainer performs live clicks, invites, friend requests, and whispers. Provide the real entry point, affected client/build, and relevant combat/chat-lockdown/beta state. Analyze supplied logs and distinguish simulated checks from live results.
