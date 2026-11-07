-- Retail -> WoW Forever REALM RULESET probe (Normal / PvP / RP / RP-PvP).
-- Paste this WHOLE file into a new LuaWorkbench script in Retail, then use
-- Play / F5 / Ctrl+Enter. Run manually after Battle.net friends have loaded.
-- Leave startup/login/event automation disabled. No BetterFriendlist required.
-- Output: local chat only, plus the same report as a LuaWorkbench return value.
-- No friends/settings mutations, addon messages, invites, hooks, or saved data.
-- Names, BattleTags, GUIDs and account IDs are never printed. Realm text is
-- printed; full richPresence and its zone segment are not. Only a recognized
-- CAMWOW realm suffix or structured Forever ruleset segment is shown.
-- Rerun after restrictions lift; an absent/restricted snapshot is not proof
-- that Retail never receives the field. This tests current API observations.
-- Sources reviewed: live 12.1.5.70688 / forever 1.60.1.70707, 2026-11-06.
-- BattleNetDocumentation.lua: BNetGameAccountInfo has no documented ruleset
-- field. Project 18 comes from Forever Camelot/ProjectConstants.lua.
-- Retail build 70783 user observation: "Forever - Normal - Ashenvale".
-- Native Lua passes richPresence through; its builder/localized contract is
-- not in the source clone. Accept only known labels, with spaced ASCII hyphen
-- or U+00B7 middle-dot separators. Other localized labels remain UNKNOWN.

do
    -- Optional: paste an F number from a previous report to probe only that
    -- Battle.net list index. Indices may change when the friends list changes.
    local TARGET_FRIEND_INDEX = nil
    local MAX_FRIENDS = 1000
    local MAX_ACCOUNTS_PER_FRIEND = 20
    local MAX_SAMPLES = 3
    local MAX_LINES = 80
    local FOREVER_PROJECT_ID = 18

    local lines = {}
    local function emit(message)
        if #lines >= MAX_LINES then return end
        lines[#lines + 1] = "[ForeverRulesetProbe] " .. message
        pcall(function()
            if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(lines[#lines]) end
        end)
    end
    local function finish()
        return table.concat(lines, "\n")
    end

    -- Reject secrecy before type checks, comparisons, indexing or formatting.
    -- The checker results themselves are documented ordinary booleans.
    local function readable(value)
        if type(issecretvalue) ~= "function" then return "guard-unavailable" end
        local ok, secret = pcall(issecretvalue, value)
        if not ok then return "guard-error" end
        if secret ~= false then return "secret-value" end
        if type(canaccessvalue) == "function" then
            local accessOK, access = pcall(canaccessvalue, value)
            if not accessOK or access ~= true then return "inaccessible-value" end
        end
        if type(value) == "table" then
            if type(issecrettable) ~= "function" then return "table-guard-unavailable" end
            local tableOK, tableSecret = pcall(issecrettable, value)
            if not tableOK then return "table-guard-error" end
            if tableSecret ~= false then return "secret-table" end
            if type(canaccesstable) == "function" then
                local accessOK, access = pcall(canaccesstable, value)
                if not accessOK or access ~= true then return "inaccessible-table" end
            end
        end
        return "ok"
    end

    local function field(container, key)
        local state = readable(container)
        if state ~= "ok" then return nil, "container:" .. state end
        if type(container) ~= "table" then return nil, "container:not-table" end
        local ok, value = pcall(function() return container[key] end)
        if not ok then return nil, "read-error" end
        state = readable(value)
        if state ~= "ok" then return nil, state end
        if value == nil then return nil, "absent" end
        return value, "ok"
    end

    local function call(fn, ...)
        local state = readable(fn)
        if state ~= "ok" then return nil, state end
        if type(fn) ~= "function" then return nil, "API-unavailable" end
        local ok, value = pcall(fn, ...)
        -- Never output exception text: it may contain private or secret data.
        if not ok then return nil, "call-error" end
        state = readable(value)
        if state ~= "ok" then return nil, state end
        if value == nil then return nil, "absent" end
        return value, "ok"
    end

    local function integer(value, state, minimum)
        return state == "ok" and type(value) == "number"
            and value >= minimum and value < math.huge and value % 1 == 0
    end

    local function text(value, state)
        if state ~= "ok" then return "<" .. state .. ">" end
        if type(value) == "string" then
            -- Escape WoW markup; keep one bounded, readable output line.
            local clipped = value:sub(1, 100):gsub("[%c]", " "):gsub("|", "||")
            return '"' .. clipped .. (#value > 100 and '..."' or '"')
        end
        if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
        return "<" .. type(value) .. ">"
    end

    local function capability(fn, lookupState)
        if lookupState and lookupState ~= "ok" and lookupState ~= "absent" then return "lookup:" .. lookupState end
        local state = readable(fn)
        if state ~= "ok" then return state end
        return type(fn) == "function" and "available" or "unavailable"
    end

    emit("v2; realm ruleset only; anonymous F/G indices; realm text visible.")
    if type(issecretvalue) ~= "function" or type(issecrettable) ~= "function" then
        emit("STOP: secret value/table guards unavailable; no friend data inspected.")
        return finish()
    end

    local getSelected, getSelectedState = field(C_BattleNet, "GetFriendAccountInfo")
    local getCount, getCountState = field(C_BattleNet, "GetFriendNumGameAccounts")
    local getGame, getGameState = field(C_BattleNet, "GetFriendGameAccountInfo")
    local getByID, getByIDState = field(C_BattleNet, "GetGameAccountInfoByID")
    local getChatLockdown = field(C_ChatInfo, "InChatMessagingLockdown")
    emit("APIs: BNGetNumFriends=" .. capability(BNGetNumFriends)
        .. "; GetFriendNumGameAccounts=" .. capability(getCount, getCountState)
        .. "; GetFriendGameAccountInfo=" .. capability(getGame, getGameState))
    emit("APIs: GetFriendAccountInfo=" .. capability(getSelected, getSelectedState)
        .. "; GetGameAccountInfoByID=" .. capability(getByID, getByIDState)
        .. "; canaccessvalue=" .. capability(canaccessvalue)
        .. "; canaccesstable=" .. capability(canaccesstable))

    local buildOK, version, build, _, interface = pcall(function() return GetBuildInfo() end)
    if buildOK then
        emit("Client=" .. text(version, readable(version)) .. "; build=" .. text(build, readable(build))
            .. "; interface=" .. text(interface, readable(interface))
            .. "; WOW_PROJECT_ID=" .. text(WOW_PROJECT_ID, readable(WOW_PROJECT_ID)))
    else
        emit("Client build query=<call-error>")
    end
    local combat, combatState = call(InCombatLockdown)
    local chatLockdown, chatState = call(getChatLockdown)
    emit("Context: combat=" .. text(combat, combatState)
        .. "; chatMessagingLockdown=" .. text(chatLockdown, chatState))
    local camelot = WOW_PROJECT_CAMELOT
    emit("Forever detection: BNetGameAccountInfo.wowProjectID=18; local WOW_PROJECT_CAMELOT="
        .. text(camelot, readable(camelot)) .. "; not inferred from the Retail player's realm.")
    emit("E=C_BattleNet.GetFriendGameAccountInfo(F,G); S=C_BattleNet.GetFriendAccountInfo(F).gameAccountInfo;")
    emit("I=C_BattleNet.GetGameAccountInfoByID(E/S.gameAccountID); IDs are passed only when readable, never printed.")
    emit("<absent>=nil; <secret/inaccessible...>=unreadable; <call/read-error>=failed, not absent.")

    local labels = { PVE = "Normal", PVP = "PvP", RP = "RP", RPPVP = "RP-PvP" }
    local function tokenFromRealm(value)
        if type(value) ~= "string" then return nil end
        if #value > 512 then return nil, "oversize" end
        local upper = value:upper()
        local normalized = upper:match("^CAMWOW[A-Z]+%d+REALM%d+([A-Z]+)$")
        if normalized and labels[normalized] then return normalized end
        upper = upper:gsub("RP%-PVP", " RPPVP "):gsub("RP%s+PVP", " RPPVP ")
        local found
        for _, token in ipairs({ "RPPVP", "PVP", "PVE", "RP", "NORMAL" }) do
            if upper:find("%f[%w_]" .. token .. "%f[^%w_]") then
                local canonical = token == "NORMAL" and "PVE" or token
                if found and found ~= canonical then return nil, "conflicting-tokens" end
                found = canonical
            end
        end
        return found
    end

    local function presenceRealm(value)
        if type(value) ~= "string" or #value > 2048 then return nil end
        local start, _, suffix = value:upper():find(" %- (CAMWOW.+)$")
        if suffix and (suffix:match("^CAMWOW%s+[A-Z]+%d+%s+REALM%s+%d+%s+")
            or suffix:match("^CAMWOW[A-Z]+%d+REALM%d+")) then
            return value:sub(start + 3)
        end
    end

    local function presenceRuleset(value)
        -- Caller has already rejected secret/inaccessible values. The zone is
        -- required for the observed three-part shape, but is never inspected
        -- for ruleset words or printed. Do not parse arbitrary PvP/Normal text.
        if type(value) ~= "string" or #value > 2048 or value:find("[%c|]") then return nil end
        local separators = { { "%-", "ASCII-hyphen" }, { "\194\183", "middle-dot" } }
        local presenceLabels = { NORMAL = "PVE", PVP = "PVP", RP = "RP", ["RP-PVP"] = "RPPVP" }
        local upper = value:upper()
        for _, first in ipairs(separators) do
            for _, second in ipairs(separators) do
                local label, zone = upper:match("^%s*FOREVER%s+" .. first[1]
                    .. "%s+(.-)%s+" .. second[1] .. "%s+(.+)%s*$")
                if label and zone then
                    label = label:match("^%s*(.-)%s*$")
                    zone = zone:match("^%s*(.-)%s*$")
                    local extraSeparator = false
                    for _, separator in ipairs(separators) do
                        if zone:find("%s+" .. separator[1] .. "%s+") then extraSeparator = true end
                    end
                    if zone ~= "" and not extraSeparator and presenceLabels[label] then
                        return presenceLabels[label], first[2] == second[2] and first[2] or "mixed-hyphen/middle-dot"
                    end
                end
            end
        end
    end

    local function isOnlineForever(info)
        local client, clientState = field(info, "clientProgram")
        if clientState ~= "ok" then return nil, ".clientProgram:" .. clientState end
        if type(client) ~= "string" then return nil, ".clientProgram:wrong-type" end
        if client ~= "WoW" then return false end
        local online, onlineState = field(info, "isOnline")
        if onlineState ~= "ok" then return nil, ".isOnline:" .. onlineState end
        if type(online) ~= "boolean" then return nil, ".isOnline:wrong-type" end
        if not online then return false end
        local project, projectState = field(info, "wowProjectID")
        if projectState ~= "ok" then return nil, ".wowProjectID:" .. projectState end
        if type(project) ~= "number" then return nil, ".wowProjectID:wrong-type" end
        return project == FOREVER_PROJECT_ID
    end

    local inferred, conflicts = 0, 0
    local function show(info, state, path)
        emit(path .. ": snapshot=" .. state)
        if state ~= "ok" then return end
        local project, projectState = field(info, "wowProjectID")
        local client, clientState = field(info, "clientProgram")
        local online, onlineState = field(info, "isOnline")
        emit("  .clientProgram=" .. text(client, clientState) .. "; .wowProjectID="
            .. text(project, projectState) .. "; .isOnline=" .. text(online, onlineState))
        local realm, realmState = field(info, "realmName")
        local display, displayState = field(info, "realmDisplayName")
        local presence, presenceState = field(info, "richPresence")
        emit("  .realmName=" .. text(realm, realmState) .. "; .realmDisplayName=" .. text(display, displayState))
        local suffix = presenceState == "ok" and presenceRealm(presence) or nil
        local structuredToken, separatorKind
        if presenceState == "ok" then structuredToken, separatorKind = presenceRuleset(presence) end
        local presenceDescription = text(nil, presenceState)
        if presenceState == "ok" then
            presenceDescription = type(presence) == "string" and ("readable-string(" .. #presence .. " bytes)")
                or ("<" .. type(presence) .. ">")
        end
        emit("  .richPresence=" .. presenceDescription .. "; CAMWOW realm suffix=" .. text(suffix, suffix and "ok" or "absent")
            .. "; Forever ruleset segment=" .. (structuredToken and (labels[structuredToken] .. " (" .. separatorKind .. "; zone omitted)") or "<unrecognized>"))
        local token, source, conflict
        for _, candidate in ipairs({
            { realm, realmState, ".realmName" },
            { display, displayState, ".realmDisplayName" },
            { suffix, suffix and "ok" or "absent", ".richPresence[CAMWOW realm suffix]" },
        }) do
            if candidate[2] == "ok" then
                local nextToken, issue = tokenFromRealm(candidate[1])
                if issue == "conflicting-tokens" or (token and nextToken and token ~= nextToken) then conflict = true end
                if nextToken and not token then token, source = nextToken, candidate[3] end
            end
        end
        if structuredToken then
            if token and token ~= structuredToken then conflict = true end
            if not token then token, source = structuredToken, ".richPresence[Forever ruleset segment]" end
        end
        if conflict then
            conflicts = conflicts + 1
            emit("  RESULT=CONFLICT; ruleset text sources disagree; do not infer a ruleset.")
        elseif token and isOnlineForever(info) == true then
            inferred = inferred + 1
            emit("  RESULT=inferred " .. labels[token] .. " from " .. path .. source .. "; text evidence, not a dedicated API enum.")
        else
            emit("  RESULT=UNKNOWN; no unambiguous readable ruleset text for a confirmed online Forever account.")
        end
        local extra = {}
        for _, key in ipairs({ "ruleset", "rulesetID", "realmRuleset", "realmRulesetID", "realmType", "realmTypeID" }) do
            local value, valueState = field(info, key)
            extra[#extra + 1] = key .. "=" .. text(value, valueState)
        end
        emit("  Undocumented candidate fields (unmapped): " .. table.concat(extra, "; "))
    end

    local friends, friendsState = call(BNGetNumFriends)
    if not integer(friends, friendsState, 0) then
        emit("STOP: BNGetNumFriends=" .. text(friends, friendsState) .. "; no safe friend count.")
        return finish()
    end
    if TARGET_FRIEND_INDEX ~= nil and not integer(TARGET_FRIEND_INDEX, "ok", 1) then
        emit("STOP: TARGET_FRIEND_INDEX must be nil or a positive whole number.")
        return finish()
    end
    local first, last = 1, math.min(friends, MAX_FRIENDS)
    if TARGET_FRIEND_INDEX then first, last = TARGET_FRIEND_INDEX, math.min(TARGET_FRIEND_INDEX, friends) end
    emit("Scan: friend indices " .. first .. ".." .. last .. " of " .. friends .. "; max " .. MAX_SAMPLES .. " detailed E/S/I samples.")

    local samples, enumerated, fallback, unreadable, limited = 0, 0, 0, 0, 0
    local issues, issueOrder = {}, {}
    local function noteIssue(state)
        if not issues[state] then issueOrder[#issueOrder + 1] = state end
        issues[state] = (issues[state] or 0) + 1
    end
    local function sample(info, state, friendIndex, gameIndex, origin)
        if samples >= MAX_SAMPLES then return end
        samples = samples + 1
        local path = origin .. "(F" .. friendIndex .. (gameIndex and (",G" .. gameIndex) or "") .. ")"
        show(info, state, path)
        if origin == "E" then
            local selected, selectedState = call(getSelected, friendIndex)
            if selectedState == "ok" then selected, selectedState = field(selected, "gameAccountInfo") end
            local id, idState = field(info, "gameAccountID")
            local selectedID, selectedIDState = field(selected, "gameAccountID")
            if integer(id, idState, 1) and integer(selectedID, selectedIDState, 1) then
                emit("S(F" .. friendIndex .. ") relation to E: " .. (id == selectedID and "same gameAccountID." or "different gameAccountID."))
            end
            -- Selected may be a different game/account. Say so without names.
            if selectedState == "ok" and isOnlineForever(selected) ~= true then
                emit("S(F" .. friendIndex .. "): not confirmed online Forever; selected account can differ from E.")
            else
                show(selected, selectedState, "S(F" .. friendIndex .. ")")
            end
        end
        local id, idState = field(info, "gameAccountID")
        if integer(id, idState, 1) then
            local direct, directState = call(getByID, id)
            show(direct, directState, "I(" .. path .. ")")
        else
            emit("I(" .. path .. "): skipped; .gameAccountID=" .. (idState == "ok" and "invalid-ID" or idState))
        end
    end

    for friendIndex = first, last do
        local count, countState = call(getCount, friendIndex)
        if integer(count, countState, 0) and capability(getGame) == "available" then
            if count > MAX_ACCOUNTS_PER_FRIEND then limited = limited + 1 end
            for gameIndex = 1, math.min(count, MAX_ACCOUNTS_PER_FRIEND) do
                local info, state = call(getGame, friendIndex, gameIndex)
                local forever, reason
                if state == "ok" then forever, reason = isOnlineForever(info) else reason = state end
                if forever == true then
                    enumerated = enumerated + 1
                    sample(info, state, friendIndex, gameIndex, "E")
                elseif state ~= "ok" or forever == nil then
                    unreadable = unreadable + 1
                    noteIssue("E:" .. reason)
                end
            end
        else
            unreadable = unreadable + 1
            noteIssue("count:" .. (countState == "ok" and "invalid-count-or-game-API-unavailable" or countState))
            -- Read-only fallback when enumeration is unavailable/restricted.
            local selected, state = call(getSelected, friendIndex)
            if state == "ok" then selected, state = field(selected, "gameAccountInfo") end
            if state == "ok" and isOnlineForever(selected) == true then
                fallback = fallback + 1
                sample(selected, state, friendIndex, nil, "S")
            elseif state ~= "ok" then
                noteIssue("S:" .. state)
            end
        end
    end

    emit("SUMMARY: online Forever E accounts=" .. enumerated .. "; S fallbacks=" .. fallback
        .. "; unavailable/restricted/absent scan reads=" .. unreadable .. "; detailed samples=" .. samples .. ".")
    emit("Detailed snapshots with inferred token=" .. inferred .. "; conflicts=" .. conflicts
        .. "; source snapshots may describe the same account.")
    local issueParts = {}
    for _, state in ipairs(issueOrder) do issueParts[#issueParts + 1] = state .. "=" .. issues[state] end
    emit("Scan issue breakdown: " .. (#issueParts > 0 and table.concat(issueParts, "; ") or "none") .. ".")
    if enumerated + fallback == 0 then
        emit("No confirmed online Forever account observed. Have a known Forever friend log in, wait for the roster, then rerun.")
    end
    if friends > MAX_FRIENDS or limited > 0 then
        emit("Scan capped: friends=" .. MAX_FRIENDS .. "; accounts/friend=" .. MAX_ACCOUNTS_PER_FRIEND .. ". Use TARGET_FRIEND_INDEX for a missed friend.")
    end
    emit("Next: copy this report; verify a sampled friend's actual realm ruleset. UNKNOWN/restricted results are inconclusive; rerun out of combat/chat lockdown.")
    return finish()
end
