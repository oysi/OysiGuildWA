
local MAJOR = "OysiGuildWA-1.0"
local MINOR = 23

--[==============================================[
	trigger
]==============================================]--

local commands = {}

local function get_command(msg, pattern)
	local name, args = msg:match(pattern)
	if not name then
		return
	end
	return commands[name:lower()], args
end

local last_time = 0

function aura_env.trigger(event, msg, _, _, _, _, _, _, _, _, _, _, guid)
	-- throttle
	local ctime = GetTime()
	if ctime - last_time < 1 then
		return
	end
	
	-- get channel
	local channel
	if (event == "CHAT_MSG_GUILD") and aura_env.config.enable_guild then
		channel = "GUILD"
	elseif (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") and aura_env.config.enable_raid then
		channel = "RAID"
	elseif (event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER") and aura_env.config.enable_party then
		channel = "PARTY"
	end
	if not channel then
		return
	end
	
	local is_my = false
	local is_self = guid == UnitGUID("player")
	
	-- get command
	local command, args = get_command(msg, "^!([%a%p]+) ?(.*)$");
	if (not command) then
		command, args = get_command(msg, "^[!#]my([%a%p]+) ?(.*)$");
		if (command) then
			is_my = true;
		else
			command, args = get_command(msg, "^[!#]" .. UnitName("player"):lower() .. "([%a%p]+) ?(.*)$");
			if (not command) then
				return;
			end
		end
	end
	if not aura_env.config[command.name] then
		return
	end
	if (command.self or is_my) and not is_self then
		return
	end
	
	command.msg = args
	command.msgl = args:lower()
	
	command.is_my = is_my
	command.is_self = is_self
	
	-- execute command
	local result = command:func()
	if not result then
		return
	end
	
	if type(result) == "string" then
		result = {result}
	end
	
	local output = {}
	for i = 1, #result do
		local val = result[i]
		if #val <= 255 then
			table.insert(output, val)
		else
			local s = 255 + 1 - (val:sub(1, 255):reverse():find(" ") or 1)
			table.insert(output, val:sub(1, s))
			table.insert(output, val:sub(s + 1))
		end
	end
	
	for i, sub in ipairs(output) do
		C_Timer.After((i - 1)*0.1, function()
			SendChatMessage(sub, channel)
		end)
	end
	
	last_time = ctime
end

--[==============================================[
	lib
]==============================================]--

local lib = {};

local function get_rep_text(factionID)
	-- major faction
	local info = C_MajorFactions.GetMajorFactionData(factionID);
	if (info and info.name) then
		if (not info.renownLevelThreshold) then
			return info.name .. ": Renown " .. info.renownLevel
		end
		local cur = info.renownReputationEarned;
		local max = info.renownLevelThreshold;
		return
			info.name .. ": Renown " .. info.renownLevel
			.. " (" .. BreakUpLargeNumbers(cur) .. " / " .. BreakUpLargeNumbers(max) .. ")";
	end
	
	-- friendship
	local info = C_GossipInfo.GetFriendshipReputation(factionID);
	if (info and info.name) then
		if (not info.nextThreshold) then
			return info.name .. ": " .. info.reaction
		end
		local cur = info.standing - info.reactionThreshold;
		local max = info.nextThreshold - info.reactionThreshold;
		return
			info.name .. ": " .. info.reaction
			.. " (" .. BreakUpLargeNumbers(cur) .. " / " .. BreakUpLargeNumbers(max) .. ")";
	end
	
	local name, _, standingID, bar_min, bar_max, bar_val = GetFactionInfoByID(factionID)
	if not name then
		return
	end
	
	local min = bar_val - bar_min
	local max = bar_max - bar_min
	
	local friendID, _, _, friendName, _, _, friendTextLevel = C_GossipInfo.GetFriendshipReputation(factionID)
	
	local disp_name = friendID and friendName or name
	local disp_standing = friendID and friendTextLevel or _G["FACTION_STANDING_LABEL" .. standingID] or standingID
	
	local str = ""
	str = str .. disp_name .. ": " .. disp_standing
	if not (min == 0 and max == 0) then
		str = str .. " (" .. BreakUpLargeNumbers(min) .. " / " .. BreakUpLargeNumbers(max) .. ")"
	end
	return str
end

function lib.tstr(t)
	if t < 60 then
		return string.format("%is", t)
	elseif t < 3600 then
		return string.format("%im %is", t/60, t%60)
	elseif t < 86400 then
		return string.format("%ih %im %is", t/3600, t/60%60, t%60)
	else
		return string.format("%id %ih %im %is", t/86400, t/3600%24, t/60%60, t%60)
	end
end

--[==============================================[
	commands
]==============================================]--

commands.rep = {
	func = function(self)
		local list = {}
		
		for i = 1, math.huge do
			local name, _, _, _, _, _, _, _, _, _, _, _, _, id = GetFactionInfo(i)
			if not name then
				break
			end
			table.insert(list, {
				name = name;
				id = id;
			})
		end
		
		local msg = self.msgl:gsub("[%p%s]", "")
		
		for _, info in pairs(list) do
			local name = info.name:lower():gsub("[%p%s]", "")
			local match = name:match(msg)
			info.correct = 0
			info.early = false
			if match then
				info.correct = #match / #name
				if name:sub(1, #match) == match then
					info.early = true
				end
			end
		end
		
		table.sort(list, function(a, b)
			if a.early ~= b.early then
				return a.early and not b.early
			elseif a.correct ~= b.correct then
				return a.correct > b.correct
			else
				return a.name < b.name
			end
		end)
		
		local info = list[1]
		if info and info.correct > 0 then
			return get_rep_text(info.id)
		end
	end;
}

local magetower_classes = {
	[01] = {"WARRIOR"    , "Warrior"     , 52769, 188622};
	[02] = {"PALADIN"    , "Paladin"     , 52764, 188582};
	[03] = {"HUNTER"     , "Hunter"      , 52761, 188558};
	[04] = {"ROGUE"      , "Rogue"       , 52766, 188598};
	[05] = {"PRIEST"     , "Priest"      , 52765, 188589};
	[06] = {"DEATHKNIGHT", "Death Knight", 52758, 188534};
	[07] = {"SHAMAN"     , "Shaman"      , 52767, 188606};
	[08] = {"MAGE"       , "Mage"        , 52762, 188565};
	[09] = {"WARLOCK"    , "Warlock"     , 52768, 188613};
	[10] = {"MONK"       , "Monk"        , 52763, 188574};
	[11] = {"DRUID"      , "Druid"       , 52760, 188550};
	[12] = {"DEMONHUNTER", "Demon Hunter", 52759, 188542};
}

commands.magetower = {
	func = function(self)
		local challenges = 0
		local achis = 0
		local mogs = 0
		
		local list = {}
		for i = 1, 7 do
			local name, _, done = GetAchievementCriteriaInfo(15310, i, true)
			if done then
				challenges = challenges + 1
			end
			table.insert(list, (done and "|cFF00FF00" or "|cFFFF0000") .. name)
		end
		if self.is_my then
			print("Challenges: " .. table.concat(list, "|r, "))
		end
		
		local bear_done = select(3, GetAchievementCriteriaInfo(15312, 1, true))
		if bear_done then
			mogs = mogs + 1
		end
		
		if self.is_my then
			print(
				"Bear: "
				.. (bear_done and "|cFF00FF00" or "|cFFFF0000")
				.. (bear_done and "done" or "not done")
			)
		end
		
		for _, info in ipairs(magetower_classes) do
			local achi = select(3, GetAchievementCriteriaInfoByID(15308, info[3]))
			if achi then
				achis = achis + 1
			end
			local mog = C_TransmogCollection.PlayerHasTransmog(info[4])
			if mog then
				mogs = mogs + 1
			end
			if self.is_my then
				print(
					(mog and "|cFF00FF00" or "|cFFFF0000") .. "mog "
					.. (achi and "|cFF00FF00" or "|cFFFF0000") .. "achi "
					.. RAID_CLASS_COLORS[info[1]]:WrapTextInColorCode(info[2])
				)
			end
		end
		
		return
			"Mage Tower:"
			.. " " .. challenges .. "/7"
			.. " (" .. mogs .. "/13 mogs, " .. achis .. "/12 classes)"
	end;
}

commands.notecheck = {
	self = true;
	func = function(self)
		local msg = self.msgl
		if not msg or msg == "" then
			return "ERROR: invalid input"
		end
		if not _G.VExRT or not _G.VExRT.Note or not _G.VExRT.Note.Text1 then
			return "ERROR: no ExRT note"
		end
		
		local note = _G.VExRT.Note.Text1
		
		local result = {}
		
		local in_note = {}
		local in_raid = {}
		
		-- parse msg
		local pattern
		local groupstr
		
		note = "\n\n" .. note .. "\n\n"
		
		msg = msg .. ";"
		
		local first, second = msg:match("^(.-);(.*);?$")
		
		if not first then
			return "ERROR: invalid input"
		end
		
		if first:sub(1, 2) == "p=" then
			pattern = first:sub(3):gsub("\\n", "\n")
		else
			pattern = first .. "(.-)\n%s*\n"
		end
		
		local t
		
		local count = 0
		
		for w in note:lower():gmatch(pattern) do
			count = count + 1
		end
		
		if count == 0 then
			return "ERROR: no match"
		elseif count >= 2 then
			return "ERROR: multiple matches, narrow the pattern"
		end
		
		local s1, s2, _ = note:lower():find(pattern)
		if s1 and s2 then
			local section = note:sub(s1, s2)
			note = note:sub(1, s1 - 1) .. note:sub(s2 + 1, -1)
			-- for word in section:gmatch("%a+") do
			-- 	unformatted[word] = true
			-- end
			for name in section:gmatch("|c........(.-)||r") do
				-- fix name formatting
				name = name:gsub("[%p%s]", "")
				-- name = name:sub(1, 1):upper() .. name:sub(2)
				in_note[name] = (in_note[name] or 0) + 1
			end
		end
		
		if next(in_note) == nil then
			return "ERROR: found no names in note"
		end
		
		-- scan raid
		local grp_min = 1
		local grp_max = 8
		if second ~= "" then
			-- grp_min, grp_max = msg:match("^%s*(%d+)%s*%-%s*(%d+)%s*$")
			grp_min, grp_max = second:gsub("%s", ""):match("(%d+)%-(%d+)")
			grp_min = tonumber(grp_min)
			grp_max = tonumber(grp_max)
			if not grp_min or not (grp_min >= 1 and grp_min <= 8)
			or not grp_max or not (grp_max >= 1 and grp_max <= 8)
			or not (grp_min <= grp_max)
			then
				return "ERROR: invalid groups"
			end
		end
		for i = 1, GetNumGroupMembers() do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if name and subgroup then
				local real = name:match("(.-)%-")
				if real then
					name = real
				end
				if subgroup >= grp_min and subgroup <= grp_max then
					in_raid[name] = (in_raid[name] or 0) + 1
				end
			end
		end
		
		-- not in raid
		t = {}
		for name in pairs(in_note) do
			if not in_raid[name] then
				table.insert(t, name)
			end
		end
		table.sort(t)
		result[#result + 1] = "Not in raid: " .. table.concat(t, ", ")
		
		-- not in note
		t = {}
		for name in pairs(in_raid) do
			if not in_note[name] then
				table.insert(t, name)
			end
		end
		table.sort(t)
		result[#result + 1] = "Not in note: " .. table.concat(t, ", ")
		
		-- multiple hits
		t = {}
		for name, count in pairs(in_note) do
			if count > 1 then
				table.insert(t, name .. " (" .. count .. "x)")
			end
		end
		if #t > 0 then
			table.sort(t)
			result[#result + 1] = "Listed multiple times: " .. table.concat(t, ", ")
		end
		
		return result
	end;
}

commands.guids = {
	self = true;
	func = function(self)
		local guids = {}
		
		local function add(unit)
			local name = UnitName(unit)
			local guid = UnitGUID(unit)
			if name and guid then
				guids[name] = guid
			end
		end
		
		add("player")
		
		if UnitInRaid("player") then
			for i = 1, 40 do
				add("raid" .. i)
			end
		elseif UnitInParty("player") then
			for i = 1, 5 do
				add("party" .. i)
			end
		end
		
		local list = {}
		
		for name, guid in pairs(guids) do
			list[#list + 1] = {name, guid}
		end
		
		table.sort(list, function(a, b) return a[2] < b[2] end)
		
		local disp = {}
		
		for i, v in ipairs(list) do
			disp[#disp + 1] = v[1]
		end
		
		return table.concat(disp, ", ")
	end;
}

commands.quest = {
	func = function(self)
		local quest = self.msg:match("|Hquest(.-)|h");
		local total = self.msg:match("|c........|Hquest.-|h.-|h|r");
		if (quest and total) then
			local _, questID = strsplit(":", quest);
			questID = tonumber(questID);
			if (questID) then
				local title = C_QuestLog.GetTitleForQuestID(questID);
				if (C_QuestLog.IsQuestFlaggedCompleted(questID)) then
					return "Done " .. total;
				elseif (C_QuestLog.IsOnQuest(questID)) then
					return "In Progress " .. total;
				else
					return "Not Done " .. total;
				end
			end
		end
	end,
}

-- commands.keys = {
-- 	func = function(self)
-- 		local cmapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID();
-- 		local level = C_MythicPlus.GetOwnedKeystoneLevel();
		
-- 		if (not (cmapID and level and level > 1)) then
-- 			return "[no keystone]";
-- 		end
		
-- 		local name = C_ChallengeMode.GetMapUIInfo(cmapID);
-- 		if (not name) then
-- 			name = "cmapID:" .. cmapID .. "";
-- 		end
		
-- 		return "+" .. level .. " [" .. name .. "]";
-- 	end,
-- }

-- commands.vault = {
-- 	self = true,
-- 	func = function(self)
-- 		local hist = C_MythicPlus.GetRunHistory(false, true);
		
-- 		table.sort(hist, function(a, b)
-- 			if (a.level ~= b.level) then
-- 				return a.level > b.level;
-- 			else
-- 				return a.mapChallengeModeID < b.mapChallengeModeID;
-- 			end
-- 		end);
		
-- 		local function get_best(n)
-- 			local info = {level = math.huge};
-- 			if (n <= #hist) then
-- 				for i = 1, n do
-- 					local level = hist[i].level;
-- 					if (level < info.level) then
-- 						info.level = level;
-- 					end
-- 				end
-- 			else
-- 				info.level = 0;
-- 			end
-- 			info.vault = C_MythicPlus.GetRewardLevelFromKeystoneLevel(info.level);
-- 			return info;
-- 		end
		
-- 		local list = {
-- 			get_best(1),
-- 			get_best(4),
-- 			get_best(8),
-- 		};
		
-- 		for i, v in ipairs(list) do
-- 			list[i] = "(+" .. v.level .. ")";
-- 		end
		
-- 		return table.concat(list, " ");
-- 	end,
-- };

commands.vault = {
	self = true,
	func = function(self)
		local list = {};
		
		local activities = C_WeeklyRewards.GetActivities();
		for i, v in ipairs(activities) do
			if (v.type == Enum.WeeklyRewardChestThresholdType.MythicPlus) then
				list[v.index] = "(+" .. v.level .. ")";
			end
		end
		
		return table.concat(list, " ");
	end,
};

commands.reward = {
	self = true,
	func = function(self)
		local a, b = self.msgl:match("%+?(%-?%d+)%s*%-%s*%+?(%-?%d+)");
		if (not a) then
			a, b = self.msgl:match("%+?(%-?%d+)%s*to%s*%+?(%-?%d+)");
		end
		if (not a) then
			a = self.msgl:match("%+?(%-?%d+)");
		end
		
		a = tonumber(a);
		b = tonumber(b) or a;
		
		if (not a) then
			return;
		end
		
		local list = {};
		
		local vault_done = {};
		local chest_done = {};
		
		local step = b >= a and 1 or -1;
		
		for level = a, b, step do
			local vault, chest = C_MythicPlus.GetRewardLevelForDifficultyLevel(level);
			if ((vault ~= 0 and chest ~= 0) and (not vault_done[vault] or not chest_done[chest])) then
				vault_done[vault] = true;
				chest_done[chest] = true;
				
				table.insert(list, {
					level = level;
					vault = vault;
					chest = chest;
				});
			end
		end
		
		for i, v in ipairs(list) do
			list[i] = "+" .. v.level .. " = " .. v.chest .. " (" .. v.vault .. ")";
		end
		
		return list;
	end,
};

--?--BELOW IS FLUFF--?--BELOW IS FLUFF--?--BELOW IS FLUFF--?--
--?--BELOW IS FLUFF--?--BELOW IS FLUFF--?--BELOW IS FLUFF--?--
--?--BELOW IS FLUFF--?--BELOW IS FLUFF--?--BELOW IS FLUFF--?--

-- commands.whelp = {
-- 	func = function(self)
-- 		local ids = {
-- 			[2148] = "st",
-- 			[2149] = "aoe",
-- 			[2150] = "heal",
-- 			[2151] = "heal",
-- 			[2152] = "crit",
-- 			[2153] = "haste",
-- 		};
		
-- 		local total = 0;
		
-- 		local buffs = {}
-- 		for id, name in pairs(ids) do
-- 			local info = C_CurrencyInfo.GetCurrencyInfo(id);
-- 			buffs[name] = (buffs[name] or 0) + info.quantity;
-- 		end
		
-- 		local result = {};
-- 		for name, count in pairs(buffs) do
-- 			if (count > 0) then
-- 				total = total + count;
-- 				table.insert(result, count .. " " .. name);
-- 			end
-- 		end
		
-- 		return "(" .. total .. "/6) " .. table.concat(result, ", ");
-- 	end,
-- };

commands.whelp = {
	func = function(self)
		local ids = {
			{id = 2148, name = "st"     },
			{id = 2149, name = "aoe"    },
			{id = 2152, name = "crit"   },
			{id = 2153, name = "haste"  },
			{id = 2151, name = "stheal" },
			{id = 2150, name = "aoeheal"},
		};
		
		local total = 0;
		local result = {};
		
		for _, data in ipairs(ids) do
			local info = C_CurrencyInfo.GetCurrencyInfo(data.id);
			if (info.quantity > 0) then
				total = total + info.quantity;
				table.insert(result, info.quantity .. " " .. data.name);
			end
		end
		
		return "(" .. total .. "/6) " .. table.concat(result, ", ");
	end,
};

commands.soup = {
	self = true,
	func = function(self)
		-- time {year = 2022, month = 12, day = 8, hour = 19, min = 0, sec = 0}
		-- 1670522400
		local dif = 1670522400 - GetServerTime();
		
		local sec_until = dif%(60*60*3.5);
		local sec_since = 60*60*3.5 - sec_until;
		
		local sec_end = 15*60 - sec_since;
		if (sec_end > 0) then
			return "Soup ends in " .. lib.tstr(sec_end);
		end
		
		local sec_start = sec_until;
		if (sec_start > 0) then
			return "Soup starts in " .. lib.tstr(sec_start);
		end
		
		return "something went wrong";
	end,
}

commands.siege = {
	self = true,
	func = function(self)
		-- time {year = 2022, month = 12, day = 8, hour = 19, min = 0, sec = 0}
		-- 1670522400
		local dif = 1670522400 - GetServerTime();
		
		local sec_until = dif%(60*60*2);
		local sec_since = 60*60*2 - sec_until;
		
		return "Siege started " .. lib.tstr(sec_since) .. " ago, next siege in " .. lib.tstr(sec_until);
	end,
}

commands.soupsiege = {
	self = true,
	func = function(self)
		return {
			commands.soup.func(self),
			commands.siege.func(self),
		}
	end,
};

commands.siegesoup = {
	self = true,
	func = function(self)
		return {
			commands.siege.func(self),
			commands.soup.func(self),
		}
	end,
};

commands.malware = {
	func = function(self)
		return "v" .. MINOR;
	end,
}

commands.rarehp = {
	func = function(self)
		local unitID = "target";
		local cid = UnitClassification(unitID);
		if (UnitIsQuestBoss(unitID)) then
			cid = "questboss";
		end
		if (cid == "worldboss" or cid == "rareelite" or cid == "rare" or cid == "questboss") then
			local t = (UnitHealth(unitID) or 0) / (UnitHealthMax(unitID) or 1);
			return math.ceil(t*100) .. "% [" .. cid .. "] " .. UnitName(unitID);
		end
	end,
}

commands.renownpenis = {
	func = function(self)
		local ids = C_MajorFactions.GetMajorFactionIDs();
		if (not ids) then
			return;
		end
		local size = 0;
		for _, id in ipairs(ids) do
			local info = C_MajorFactions.GetMajorFactionData(id);
			if (info and info.isUnlocked) then
				size = size + info.renownLevel;
			end
		end
		return "8" .. ("="):rep(1 + size*0.25) .. "D";
	end,
}

--?--BELOW IS DRAGONFLIGHT--?--BELOW IS DRAGONFLIGHT--?--BELOW IS DRAGONFLIGHT--?--
--?--BELOW IS DRAGONFLIGHT--?--BELOW IS DRAGONFLIGHT--?--BELOW IS DRAGONFLIGHT--?--
--?--BELOW IS DRAGONFLIGHT--?--BELOW IS DRAGONFLIGHT--?--BELOW IS DRAGONFLIGHT--?--

commands.hunts = {
	func = function(self)
		local info = C_MajorFactions.GetMajorFactionData(2503--[[Maruuk Centaur]]);
		if (not info) then
			return;
		end
		
			-- ripped from https://wago.io/rcYyjlfq6/1 pls dont sue
			local goal = 25
			
			local factionInfo = C_MajorFactions.GetMajorFactionData(2503)
			local renownLevel = factionInfo.renownLevel
			local earnedAtThisLevel = factionInfo.renownReputationEarned
			
			local totalEarned = (renownLevel * 2500) + earnedAtThisLevel 
			local totalGoal = 2500 * goal
			
			local bags = GetItemCount(200516, true)
			local trophies = GetItemCount(200093, true)
			local totalTrophies = (bags * 4) + trophies
			local reputationInBags = totalTrophies * (550/20)
			local totalEarnedWithBags = totalEarned + reputationInBags
			
			local totalTodo = totalGoal - totalEarnedWithBags    
			local repPerHunt = 15*6 + ((550/20) * 4)
			
			local numHuntsLeft = totalTodo / repPerHunt
			
			-- 	return ("Renown %s - %s/2500\nWith bags: %s - %s/2500\nHunts to do to get to %s: %s"):format(
			-- 		renownLevel,
			-- 		earnedAtThisLevel,
			-- 		math.floor(totalEarnedWithBags / 2500),
			-- 		totalEarnedWithBags % 2500,
			-- 		goal,
			-- 		math.ceil(numHuntsLeft)
			-- 	)
		
		return "Missing: " .. math.ceil(math.max(numHuntsLeft, 0)) .. " hunts";
	end,
}

commands.renown = {
	func = function(self)
		local ids = C_MajorFactions.GetMajorFactionIDs();
		if (not ids) then
			return;
		end
		local data = {}
		for _, id in ipairs(ids) do
			local info = C_MajorFactions.GetMajorFactionData(id);
			if (info and info.isUnlocked) then
				table.insert(data, info);
			end
		end
		local order = {
			[2507] = 1,
			[2503] = 2,
			[2511] = 3,
			[2510] = 4,
		};
		table.sort(data, function(a, b)
			return (order[a.factionID] or a.factionID) < (order[b.factionID] or b.factionID);
		end);
		local total = 0
		local result = {}
		for _, info in ipairs(data) do
			total = total + info.renownLevel;
			table.insert(result, info.renownLevel);
		end
		return "Renown: " .. table.concat(result, ", ");
	end,
}

--?--BELOW IS SHADOWLANDS--?--BELOW IS SHADOWLANDS--?--BELOW IS SHADOWLANDS--?--
--?--BELOW IS SHADOWLANDS--?--BELOW IS SHADOWLANDS--?--BELOW IS SHADOWLANDS--?--
--?--BELOW IS SHADOWLANDS--?--BELOW IS SHADOWLANDS--?--BELOW IS SHADOWLANDS--?--

--!--BELOW IS DEPRECATED--!--BELOW IS DEPRECATED--!--BELOW IS DEPRECATED--!--
--!--BELOW IS DEPRECATED--!--BELOW IS DEPRECATED--!--BELOW IS DEPRECATED--!--
--!--BELOW IS DEPRECATED--!--BELOW IS DEPRECATED--!--BELOW IS DEPRECATED--!--

-- preprocess
for name, command in pairs(commands) do
	command.name = name
end
