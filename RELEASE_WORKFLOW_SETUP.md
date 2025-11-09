# GitHub Actions Release Workflow Setup Guide

This addon uses the BigWigs Packager with GitHub Actions to automate releases to CurseForge, WoWInterface, Wago, and GitHub.

## Initial Setup

### 1. Create GitHub Repository
If you haven't already:
```powershell
cd "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist"
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR-USERNAME/BetterFriendlist.git
git push -u origin main
```

### 2. Configure Project IDs

#### CurseForge Project ID
1. Create your addon project at https://www.curseforge.com/wow/addons
2. Find the project ID in the URL (e.g., `399282` from `https://www.curseforge.com/wow/addons/betterfriendlist`)
3. Update `BetterFriendlist.toc`: `## X-Curse-Project-ID: YOUR_ID`

#### WoWInterface ID
1. Upload your addon at https://www.wowinterface.com/
2. Find the ID in the URL (e.g., `25635` from `https://www.wowinterface.com/downloads/info25635-BetterFriendlist.html`)
3. Update `BetterFriendlist.toc`: `## X-WoWI-ID: YOUR_ID`

#### Wago Project ID
1. Create project at https://addons.wago.io/developers
2. Copy the project ID from the developer dashboard
3. Update `BetterFriendlist.toc`: `## X-Wago-ID: YOUR_ID`

### 3. Generate API Tokens

#### CurseForge API Token
1. Go to https://wow.curseforge.com/account/api-tokens
2. Generate a new token
3. Copy the token (you'll add it to GitHub secrets)

#### WoWInterface API Token
1. Go to https://www.wowinterface.com/downloads/filecpl.php?action=apitokens
2. Generate a new token
3. Copy the token

#### Wago API Token
1. Go to https://addons.wago.io/account/apikeys
2. Create a new API key
3. Copy the token

### 4. Configure GitHub Repository Settings

#### Set GitHub Token Permissions
1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Actions** → **General**
3. Scroll to "Workflow permissions"
4. Select "Read and write permissions"
5. Click "Save"

> **Important:** Without this step, you'll get "resource not accessible by integration" errors!

#### Add Repository Secrets
1. Go to: **Settings** → **Secrets and variables** → **Actions**
2. Click "New repository secret" and add each of these:
   - Name: `CF_API_KEY`, Value: Your CurseForge token
   - Name: `WOWI_API_TOKEN`, Value: Your WoWInterface token
   - Name: `WAGO_API_TOKEN`, Value: Your Wago token

> **Note:** `GITHUB_TOKEN` is automatically provided and doesn't need to be added manually.

## Creating a Release

Once everything is set up, creating a release is simple:

### Using Git Command Line
```powershell
# Make sure all changes are committed
git add .
git commit -m "Your changes"
git push

# Create and push a tag
git tag v1.0.0
git push origin v1.0.0
```

### Using VS Code
1. Make sure all changes are committed and pushed
2. Open the terminal in VS Code
3. Run:
   ```powershell
   git tag v1.0.0
   git push origin v1.0.0
   ```

### What Happens Next
1. GitHub Actions automatically detects the new tag
2. The packager creates a `.zip` file with your addon
3. The version in the TOC is automatically set to `v1.0.0`
4. The addon is uploaded to:
   - CurseForge (if CF_API_KEY is set)
   - WoWInterface (if WOWI_API_TOKEN is set)
   - Wago (if WAGO_API_TOKEN is set)
   - GitHub Releases (always)

### Check Workflow Status
1. Go to your repository on GitHub
2. Click the "Actions" tab
3. You'll see your workflow running
4. Click on it to see detailed logs

## Version Numbering

Use semantic versioning for tags:
- `v1.0.0` - Major release
- `v1.1.0` - New features
- `v1.1.1` - Bug fixes
- `v1.0.0-beta1` - Pre-release versions

## Troubleshooting

### "resource not accessible by integration" Error
- Make sure GitHub Actions has "Read and write permissions" (see Step 4 above)

### Workflow Not Triggering
- Make sure you committed the `.github/workflows/release.yml` file before creating the tag
- Try pushing another tag after the workflow file is committed

### Upload Fails for Specific Platform
- Verify the project ID in the TOC file is correct
- Check that the corresponding API token is set in GitHub secrets
- Review the workflow logs in the Actions tab for detailed error messages

## Files Created

- **BetterFriendlist.toc** - Updated with project IDs and `@project-version@` keyword
- **.pkgmeta** - Packager configuration (excludes documentation files)
- **.github/workflows/release.yml** - GitHub Actions workflow
- **.gitignore** - Excludes unnecessary files from repository

## Next Steps

1. Update the Author name in `BetterFriendlist.toc`
2. Add your project IDs to `BetterFriendlist.toc`
3. Set up GitHub repository and secrets
4. Create your first release with `git tag v1.0.0 && git push origin v1.0.0`

## References

- [BigWigs Packager Wiki](https://github.com/BigWigsMods/packager/wiki)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [WoW Addon Guide](https://warcraft.wiki.gg/wiki/Using_the_BigWigs_Packager_with_GitHub_Actions)
