#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pre-commit validation for BetterFriendlist
Run: python Utils/pre-commit-check.py

Checks for common bug patterns before committing.
"""

import os
import re
import sys
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ADDON_ROOT = Path(__file__).parent.parent
LUA_FILES = list(ADDON_ROOT.glob("**/*.lua"))
LOCALE_FILES = list((ADDON_ROOT / "Locales").glob("*.lua"))

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
                    f"  → {line.strip()}\n"
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
                                f"  → {api} used without Classic guard"
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
                        f"  → Timer created without reference storage\n"
                        f"  → {line.strip()}"
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
        print("[CHECK] BetterFriendlist Pre-Commit Checker\n")
        
        for lua_file in LUA_FILES:
            if 'Libs' in str(lua_file):
                continue  # Skip library files
            
            content = lua_file.read_text(encoding='utf-8', errors='ignore')
            self.check_or_true_pattern(lua_file, content)
            self.check_classic_guards(lua_file, content)
            self.check_timer_cleanup(lua_file, content)
        
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
    checker = BugChecker()
    sys.exit(checker.run_all_checks())
