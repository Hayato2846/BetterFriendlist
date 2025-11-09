# 🚀 GitHub Actions Release Setup - Schritt-für-Schritt Anleitung

## ✅ Status: Workflow-Dateien installiert!

Die folgenden Dateien wurden erstellt und nach GitHub gepusht:
- `.github/workflows/release.yml` - GitHub Actions Workflow
- `.pkgmeta` - BigWigs Packager Konfiguration
- `.gitignore` - Git Ignore Rules (aktualisiert)
- `CHANGELOG.md` - Automatisch eingebunden in Releases
- `RELEASE_NOTES_v1.0.md` - Detaillierte Release Notes

---

## 📋 Nächste Schritte (30 Min Setup)

### **Schritt 1: Projekte auf Plattformen erstellen** (15 Min)

#### 1A. CurseForge
1. Gehe zu: https://www.curseforge.com/wow/addons
2. Klicke **"Create New Project"**
3. Fülle aus:
   - **Project Name**: BetterFriendlist
   - **Game**: World of Warcraft
   - **Category**: AddOns
   - **Short Description**: "Complete replacement for WoW Friends frame with custom groups, raid management, Quick Join, and more!"
4. Nach Erstellung: Kopiere die **Project ID** aus der URL
   - Beispiel: `https://www.curseforge.com/wow/addons/betterfriendlist` → ID ist in der URL (oft 6-stellig)
   - Oder: Gehe zu **Project Settings** → siehst du die ID dort

#### 1B. WoWInterface
1. Gehe zu: https://www.wowinterface.com/
2. Klicke **"Control Panel"** (oben rechts)
3. Wähle **"Add-On Manager"** → **"Submit Add-on"**
4. Fülle aus:
   - **Add-on Name**: BetterFriendlist
   - **Category**: Miscellaneous oder Social & Communication
   - **Description**: Kopiere aus `RELEASE_NOTES_v1.0.md`
5. Nach Erstellung: Kopiere die **Add-on ID** aus der URL
   - Beispiel: `https://www.wowinterface.com/downloads/info12345-BetterFriendlist.html` → ID ist `12345`

#### 1C. Wago Addons
1. Gehe zu: https://addons.wago.io/
2. Login mit GitHub Account
3. Gehe zu **"Developers"** → **"Create Project"**
4. Fülle aus:
   - **Project Name**: BetterFriendlist
   - **Game**: World of Warcraft
   - **Description**: Kopiere aus README.md
5. Nach Erstellung: Kopiere die **Project ID** (im Developer Dashboard sichtbar)

---

### **Schritt 2: Project IDs in .toc eintragen** (2 Min)

Öffne `BetterFriendlist.toc` und ersetze die leeren IDs:

```toc
## X-Curse-Project-ID: DEINE_CURSEFORGE_ID
## X-WoWI-ID: DEINE_WOWINTERFACE_ID
## X-Wago-ID: DEINE_WAGO_ID
```

**Beispiel:**
```toc
## X-Curse-Project-ID: 399282
## X-WoWI-ID: 25635
## X-Wago-ID: abc123def
```

Speichern und committen:
```powershell
git add BetterFriendlist.toc
git commit -m "chore: Add platform project IDs"
git push origin main
```

---

### **Schritt 3: API Tokens generieren** (5 Min)

#### 3A. CurseForge API Token
1. Gehe zu: https://www.curseforge.com/account/api-tokens
2. Klicke **"Generate Token"**
3. **Name**: "BetterFriendlist GitHub Actions"
4. Kopiere den Token (wird nur einmal angezeigt!)

#### 3B. WoWInterface API Token
1. Gehe zu: https://www.wowinterface.com/downloads/filecpl.php?action=apitokens
2. Klicke **"Generate New Token"**
3. **Description**: "BetterFriendlist Releases"
4. Kopiere den Token

#### 3C. Wago API Token
1. Gehe zu: https://addons.wago.io/account/apikeys
2. Klicke **"Create New API Key"**
3. **Name**: "BetterFriendlist Releases"
4. **Permissions**: Wähle "Upload Releases"
5. Kopiere den Token

---

### **Schritt 4: GitHub Repository Konfiguration** (5 Min)

#### 4A. Workflow Permissions (WICHTIG!)
1. Gehe zu: https://github.com/Hayato2846/BetterFriendlist/settings/actions
2. Scrolle zu **"Workflow permissions"**
3. Wähle: ✅ **"Read and write permissions"**
4. Klicke **"Save"**

**⚠️ OHNE DIESEN SCHRITT**: "resource not accessible by integration" Fehler!

#### 4B. API Tokens als Secrets hinzufügen
1. Gehe zu: https://github.com/Hayato2846/BetterFriendlist/settings/secrets/actions
2. Klicke **"New repository secret"** (3× für die 3 Tokens):

**Secret 1:**
- **Name**: `CF_API_KEY`
- **Secret**: [CurseForge Token einfügen]

**Secret 2:**
- **Name**: `WOWI_API_TOKEN`
- **Secret**: [WoWInterface Token einfügen]

**Secret 3:**
- **Name**: `WAGO_API_TOKEN`
- **Secret**: [Wago Token einfügen]

**HINWEIS**: `GITHUB_TOKEN` wird automatisch bereitgestellt, nicht manuell hinzufügen!

---

### **Schritt 5: Ersten automatischen Release testen** (3 Min)

Jetzt ist alles fertig! Teste den Workflow:

```powershell
cd "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist"

# Tag v1.0 löschen (lokal und remote)
git tag -d v1.0
git push origin :refs/tags/v1.0

# Neu erstellen und pushen
git tag -a v1.0 -m "Version 1.0 - Initial Stable Release"
git push origin v1.0
```

**Was passiert:**
1. GitHub Actions erkennt den Tag `v1.0`
2. BigWigs Packager erstellt `.zip` Datei
3. Version in `.toc` wird automatisch auf `1.0` gesetzt
4. Upload zu CurseForge, WoWInterface, Wago, GitHub Releases

---

### **Schritt 6: Workflow Status prüfen** (2 Min)

1. Gehe zu: https://github.com/Hayato2846/BetterFriendlist/actions
2. Siehst du den Workflow **"Package and Release"** laufen?
3. Klicke drauf für Details und Logs
4. Nach ~2-3 Minuten: ✅ Grüner Haken = Erfolg!

**Releases prüfen:**
- CurseForge: https://www.curseforge.com/wow/addons/betterfriendlist/files
- WoWInterface: https://www.wowinterface.com/downloads/fileinfo.php?id=DEINE_ID
- Wago: https://addons.wago.io/addons/betterfriendlist
- GitHub: https://github.com/Hayato2846/BetterFriendlist/releases

---

## 🎉 Fertig! Zukünftige Releases

Für v1.1, v1.2, etc. nur noch:

```powershell
# Änderungen committen
git add .
git commit -m "feat: New feature"
git push

# Tag erstellen und pushen
git tag v1.1.0
git push origin v1.1.0
```

→ **Automatisch** auf allen Plattformen! 🚀

---

## 📦 Was wird gepackt?

**Enthalten im .zip:**
- Alle `.lua` Dateien
- Alle `.xml` Dateien
- `.toc` Datei (mit automatischer Version)
- `CHANGELOG.md` (als Changelog)

**NICHT enthalten** (via `.pkgmeta` excluded):
- Dokumentation (README, Release Notes, Roadmaps)
- Entwicklungs-Dateien (`.md` Notizen, `plans/`, `docs/`)
- Git-Dateien (`.git`, `.github`, `.gitignore`)
- Referenz-Dateien (`reference/`, `predecessor/`)

---

## 🐛 Troubleshooting

### Problem: "resource not accessible by integration"
**Lösung**: GitHub Actions Permissions auf "Read and write" setzen (Schritt 4A)

### Problem: Workflow wird nicht getriggert
**Lösung**: 
- Prüfe ob `.github/workflows/release.yml` committed und gepusht wurde
- Tag muss mit `v` beginnen (z.B. `v1.0`, nicht `1.0`)

### Problem: Upload zu Plattform schlägt fehl
**Lösung**:
- Prüfe Project ID in `.toc` (korrekt?)
- Prüfe API Token in GitHub Secrets (korrekt gesetzt?)
- Schaue in Workflow-Logs für genaue Fehlermeldung

### Problem: Version in .toc wird nicht ersetzt
**Lösung**:
- Stelle sicher, dass `.toc` `@project-version@` statt feste Version enthält
- BigWigs Packager ersetzt das automatisch beim Packaging

---

## 📚 Referenzen

- [BigWigs Packager Wiki](https://github.com/BigWigsMods/packager/wiki)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [WoW Addon Packaging Guide](https://warcraft.wiki.gg/wiki/Using_the_BigWigs_Packager_with_GitHub_Actions)

---

## ✅ Checkliste

- [ ] CurseForge Projekt erstellt + ID kopiert
- [ ] WoWInterface Projekt erstellt + ID kopiert
- [ ] Wago Projekt erstellt + ID kopiert
- [ ] Project IDs in `.toc` eingetragen
- [ ] CurseForge API Token generiert
- [ ] WoWInterface API Token generiert
- [ ] Wago API Token generiert
- [ ] GitHub Workflow Permissions auf "Read and write"
- [ ] 3 Secrets in GitHub Repository hinzugefügt
- [ ] Test-Release mit `v1.0` Tag durchgeführt
- [ ] Workflow erfolgreich gelaufen (grüner Haken)
- [ ] Addon auf allen Plattformen verfügbar

---

**Bei Fragen oder Problemen**: GitHub Issues → https://github.com/Hayato2846/BetterFriendlist/issues
