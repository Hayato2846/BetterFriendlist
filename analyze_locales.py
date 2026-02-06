import os
import re

locale_dir = r"c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist\Locales"
en_us_path = os.path.join(locale_dir, "enUS.lua")

def parse_lua_locale(file_path):
    keys = {}
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        # Regex to find L.KEY = "Value" or L["KEY"] = "Value"
        # Handling potentially multiline strings or escaped quotes is tricky with regex but 
        # for simple locale files it usually works.
        matches = re.findall(r'L\.([A-Z0-9_]+)\s*=\s*"(.*?)"', content, re.DOTALL)
        for key, value in matches:
            keys[key] = value
            
        matches_brackets = re.findall(r'L\["([A-Z0-9_]+)"\]\s*=\s*"(.*?)"', content, re.DOTALL)
        for key, value in matches_brackets:
            keys[key] = value

    return keys

en_keys = parse_lua_locale(en_us_path)
locales = ["deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW"]
# locales = ["deDE"] # Debug

print(f"Total English Keys: {len(en_keys)}")

total_issues = 0

for loc in locales:
    file_path = os.path.join(locale_dir, f"{loc}.lua")
    if not os.path.exists(file_path):
        print(f"Skipping {loc} (File not found)")
        continue
        
    loc_keys = parse_lua_locale(file_path)
    
    missing = []
    identical = []
    
    for key, en_val in en_keys.items():
        if key not in loc_keys:
            missing.append(key)
        elif loc_keys[key] == en_val:
            # Check if the value is something that SHOULD be identical (like a number or symbol)
            # But usually a sentence shouldn't be identical.
            # Filtering out very short strings might help reduce false positives if needed,
            # but user wants to find laziness.
            if len(en_val) > 2: # Ignore very short strings like "s" or "m"
                 identical.append(key)

    if missing or identical:
        print(f"\n--- {loc} ---")
        if missing:
            print(f"Missing Keys: {len(missing)}")
            for k in missing:
                print(f"  [MISSING] {k}")
        if identical:
            print(f"Identical to English (Potential Laziness): {len(identical)}")
            for k in identical:
                print(f"  [IDENTICAL] {k}: \"{en_keys[k]}\"")
        total_issues += len(missing) + len(identical)

if total_issues == 0:
    print("\nNo localization issues found!")
