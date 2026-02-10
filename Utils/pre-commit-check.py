#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pre-commit validation for BetterFriendlist
Run: python Utils/pre-commit-check.py

Checks for common bug patterns before committing.
Also trims changelog files to keep only the 10 most recent versions.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ADDON_ROOT = Path(__file__).parent.parent
LUA_FILES = list(ADDON_ROOT.glob("**/*.lua"))
LOCALE_FILES = list((ADDON_ROOT / "Locales").glob("*.lua"))

# Changelog files
CHANGELOG_MD = ADDON_ROOT / "CHANGELOG.md"
CHANGELOG_LUA = ADDON_ROOT / "Modules" / "Changelog.lua"

# Number of versions to keep
MAX_VERSIONS = 10


class ChangelogCleaner:
    """Trims changelog files to keep only the N most recent versions."""
    
    # Regex pattern for version headers: ## [X.X.X] - YYYY-MM-DD or ## [DRAFT]
    VERSION_PATTERN = re.compile(r'^## \[([^\]]+)\]')
    
    def __init__(self, max_versions: int = MAX_VERSIONS):
        self.max_versions = max_versions
        self.cleaned_count = 0

    def _find_changelog_text_bounds(self, content: str) -> tuple[int, int] | tuple[None, None]:
        start_marker = 'local CHANGELOG_TEXT = [['
        end_marker = ']]'

        start_idx = content.find(start_marker)
        if start_idx == -1:
            return None, None

        text_start = start_idx + len(start_marker)

        search_start = text_start
        end_idx = -1
        while True:
            pos = content.find(end_marker, search_start)
            if pos == -1:
                break
            after = content[pos + 2:pos + 50] if pos + 50 < len(content) else content[pos + 2:]
            if '\n' in after and (
                'local function' in after
                or '-- Helper' in after
                or after.strip().startswith('--')
            ):
                end_idx = pos
                break
            search_start = pos + 2

        if end_idx == -1:
            return None, None

        return text_start, end_idx

    def sync_changelog_lua_from_md(self) -> tuple[bool, str]:
        """
        Replace Changelog.lua's CHANGELOG_TEXT with the contents of CHANGELOG.md.
        Returns (changed, message)
        """
        if not CHANGELOG_MD.exists():
            return False, "CHANGELOG.md not found"
        if not CHANGELOG_LUA.exists():
            return False, "Changelog.lua not found"

        md_content = CHANGELOG_MD.read_text(encoding='utf-8')
        md_content = md_content.rstrip('\n') + '\n'

        lua_content = CHANGELOG_LUA.read_text(encoding='utf-8')
        text_start, end_idx = self._find_changelog_text_bounds(lua_content)
        if text_start is None or end_idx is None:
            return False, "Could not find CHANGELOG_TEXT in Changelog.lua"

        current_text = lua_content[text_start:end_idx]
        if current_text == md_content:
            return False, "Changelog.lua already matches CHANGELOG.md"

        new_content = lua_content[:text_start] + md_content + lua_content[end_idx:]
        CHANGELOG_LUA.write_text(new_content, encoding='utf-8')
        self.cleaned_count += 1
        return True, "Changelog.lua synced from CHANGELOG.md"
    
    def trim_changelog_md(self) -> tuple[bool, str]:
        """
        Trim CHANGELOG.md to keep only max_versions.
        Returns (changed, message)
        """
        if not CHANGELOG_MD.exists():
            return False, "CHANGELOG.md not found"
        
        content = CHANGELOG_MD.read_text(encoding='utf-8')
        lines = content.split('\n')
        
        # Find all version header positions
        version_positions = []
        for i, line in enumerate(lines):
            if self.VERSION_PATTERN.match(line):
                version_match = self.VERSION_PATTERN.match(line)
                version_positions.append((i, version_match.group(1)))
        
        if len(version_positions) <= self.max_versions:
            return False, f"CHANGELOG.md has {len(version_positions)} versions (≤{self.max_versions}), no trimming needed"
        
        # Keep preamble + first N versions
        cutoff_idx = version_positions[self.max_versions][0]  # Line index where we cut
        
        trimmed_lines = lines[:cutoff_idx]
        
        # Remove trailing empty lines and add one final newline
        while trimmed_lines and trimmed_lines[-1].strip() == '':
            trimmed_lines.pop()
        
        # Add separator at end to indicate more history exists
        trimmed_lines.append('')
        trimmed_lines.append('---')
        trimmed_lines.append('')
        trimmed_lines.append(f'*Older versions archived. Full history available in git.*')
        trimmed_lines.append('')
        
        new_content = '\n'.join(trimmed_lines)
        CHANGELOG_MD.write_text(new_content, encoding='utf-8')
        
        removed_count = len(version_positions) - self.max_versions
        self.cleaned_count += 1
        return True, f"CHANGELOG.md trimmed: kept {self.max_versions} versions, removed {removed_count}"
    
    def trim_changelog_lua(self) -> tuple[bool, str]:
        """
        Trim Changelog.lua's CHANGELOG_TEXT to keep only max_versions.
        Returns (changed, message)
        """
        if not CHANGELOG_LUA.exists():
            return False, "Changelog.lua not found"
        
        content = CHANGELOG_LUA.read_text(encoding='utf-8')
        
        text_start, end_idx = self._find_changelog_text_bounds(content)
        if text_start is None or end_idx is None:
            return False, "Could not find CHANGELOG_TEXT in Changelog.lua"
        
        # Extract the changelog text
        changelog_text = content[text_start:end_idx]
        lines = changelog_text.split('\n')
        
        # Find all version header positions
        version_positions = []
        for i, line in enumerate(lines):
            if self.VERSION_PATTERN.match(line):
                version_match = self.VERSION_PATTERN.match(line)
                version_positions.append((i, version_match.group(1)))
        
        if len(version_positions) <= self.max_versions:
            return False, f"Changelog.lua has {len(version_positions)} versions (≤{self.max_versions}), no trimming needed"
        
        # Keep preamble + first N versions
        cutoff_idx = version_positions[self.max_versions][0]
        
        trimmed_lines = lines[:cutoff_idx]
        
        # Remove trailing empty lines
        while trimmed_lines and trimmed_lines[-1].strip() == '':
            trimmed_lines.pop()
        
        # Add separator at end
        trimmed_lines.append('')
        trimmed_lines.append('---')
        trimmed_lines.append('')
        trimmed_lines.append('*Older versions archived. Full history available in git.*')
        trimmed_lines.append('')
        
        new_changelog_text = '\n'.join(trimmed_lines)
        
        # Reconstruct the full file
        new_content = content[:text_start] + new_changelog_text + content[end_idx:]
        CHANGELOG_LUA.write_text(new_content, encoding='utf-8')
        
        removed_count = len(version_positions) - self.max_versions
        self.cleaned_count += 1
        return True, f"Changelog.lua trimmed: kept {self.max_versions} versions, removed {removed_count}"
    
    def run(self) -> list[str]:
        """Run cleanup on all changelog files. Returns list of messages."""
        messages = []
        staged_files = []

        changed_md, msg_md = self.trim_changelog_md()
        messages.append(f"{'[CLEANED]' if changed_md else '[OK]'} {msg_md}")
        if changed_md:
            staged_files.append(str(CHANGELOG_MD))

        synced_lua, msg_sync = self.sync_changelog_lua_from_md()
        messages.append(f"{'[SYNCED]' if synced_lua else '[OK]'} {msg_sync}")
        if synced_lua:
            staged_files.append(str(CHANGELOG_LUA))

        changed_lua, msg_lua = self.trim_changelog_lua()
        messages.append(f"{'[CLEANED]' if changed_lua else '[OK]'} {msg_lua}")
        if changed_lua:
            staged_files.append(str(CHANGELOG_LUA))

        # Auto-stage any files modified by the cleaner (fixes pre-commit hook ordering)
        if staged_files:
            unique_files = list(dict.fromkeys(staged_files))
            try:
                subprocess.run(
                    ['git', 'add'] + unique_files,
                    cwd=str(ADDON_ROOT),
                    check=True,
                    capture_output=True,
                )
                messages.append(f"[STAGED] Auto-staged {len(unique_files)} modified file(s)")
            except (subprocess.CalledProcessError, FileNotFoundError) as e:
                messages.append(f"[WARN] Could not auto-stage files: {e}")

        return messages


class BugChecker:
    def __init__(self):
        self.errors = []
        self.warnings = []
    
    def check_or_true_pattern(self, filepath: Path, content: str):
        """Lua 'or true' precedence bug detection"""
        pattern = r'(\w+\.?\w*)\s+or\s+true'
        for i, line in enumerate(content.split('\n'), 1):
            if re.search(pattern, line) and 'FIX' not in line.upper():
                self.errors.append(
                    f"[OR-TRUE BUG] {filepath.name}:{i}\n"
                    f"  -> {line.strip()}\n"
                    f"  Fix: Use 'if X == nil then X = true end' pattern"
                )
    
    def check_classic_guards(self, filepath: Path, content: str):
        """Check for missing Classic API guards"""
        retail_apis = ['C_Texture', 'Enum.TitleIconVersion', 'C_MythicPlus']
        for api in retail_apis:
            if api in content:
                # Check if guarded
                guard_pattern = rf'if\s+{api.split(".")[0]}\s+and'
                if not re.search(guard_pattern, content):
                    for i, line in enumerate(content.split('\n'), 1):
                        if api in line:
                            self.warnings.append(
                                f"[CLASSIC-GUARD] {filepath.name}:{i}\n"
                                f"  -> {api} used without Classic guard"
                            )
                            break
    
    def check_timer_cleanup(self, filepath: Path, content: str):
        """Check for timers without stored references"""
        for i, line in enumerate(content.split('\n'), 1):
            # Find C_Timer.NewTicker or NewTimer that aren't assigned to self.X
            if 'C_Timer.NewTicker(' in line or 'C_Timer.NewTimer(' in line:
                # Check if it's assigned to a variable (self.X = or local X =)
                if not re.search(r'(self\.\w+|local\s+\w+)\s*=\s*C_Timer', line):
                    self.warnings.append(
                        f"[TIMER-CLEANUP] {filepath.name}:{i}\n"
                        f"  -> Timer created without reference storage\n"
                        f"  -> {line.strip()}"
                    )

    def check_debug_prints(self, filepath: Path, content: str):
        """Warn on print() or DebugPrint() usage"""
        for i, line in enumerate(content.split('\n'), 1):
            stripped = line.strip()
            if stripped.startswith('--'):
                continue
            if re.search(r'\bprint\s*\(', line) or re.search(r'\bDebugPrint\s*\(', line) or 'BFL:DebugPrint(' in line:
                self.warnings.append(
                    f"[DEBUG-PRINT] {filepath.name}:{i}\n"
                    f"  -> Debug output detected (print/DebugPrint)\n"
                    f"  -> {stripped}"
                )
    
    def check_locale_completeness(self):
        """Verify all 11 locales have same keys"""
        expected_locales = {'enUS', 'deDE', 'esES', 'esMX', 'frFR', 
                           'itIT', 'ptBR', 'ruRU', 'koKR', 'zhCN', 'zhTW'}
        
        found_locales = set()
        for f in LOCALE_FILES:
            for locale in expected_locales:
                if locale in f.name:
                    found_locales.add(locale)
        
        missing = expected_locales - found_locales
        if missing:
            self.errors.append(
                f"[LOCALE-MISSING] Missing locale files: {missing}"
            )
    
    def run_all_checks(self):
        for lua_file in LUA_FILES:
            if 'Libs' in str(lua_file):
                continue  # Skip library files
            
            content = lua_file.read_text(encoding='utf-8', errors='ignore')
            self.check_or_true_pattern(lua_file, content)
            self.check_classic_guards(lua_file, content)
            self.check_timer_cleanup(lua_file, content)
            self.check_debug_prints(lua_file, content)
        
        self.check_locale_completeness()
        
        # Output results
        if self.errors:
            print("[ERROR] ERRORS (must fix):\n")
            for e in self.errors:
                print(f"  {e}\n")
        
        if self.warnings:
            print("[WARN] WARNINGS (review):\n")
            for w in self.warnings:
                print(f"  {w}\n")
        
        if not self.errors and not self.warnings:
            print("[OK] All checks passed!")
            return 0
        
        return 1 if self.errors else 0

if __name__ == "__main__":
    print("=" * 60)
    print("[CHECK] BetterFriendlist Pre-Commit Checker")
    print("=" * 60)
    
    # 1. Clean up changelog files
    print("\n[CHANGELOG] Cleaning changelog files...")
    cleaner = ChangelogCleaner(max_versions=MAX_VERSIONS)
    for msg in cleaner.run():
        print(f"  {msg}")
    
    # 2. Run bug checks
    print("\n[BUGS] Running bug pattern checks...")
    checker = BugChecker()
    sys.exit(checker.run_all_checks())
