
--[==============================================[
	trigger
]==============================================]--

function aura_env.trigger(event, ...)
	local msg = ...
	if not event or not msg then
		return
	end
	
	local msg_orig = msg
	
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
	
	local function send(msg)
		local ctime = GetTime()
		local dif = ctime - (aura_env.time or 0)
		if dif < 1 then
			return
		end
		aura_env.time = ctime
		if type(msg) == "string" then
			SendChatMessage(msg, channel)
		elseif type(msg) == "table" then
			for i, sub in ipairs(msg) do
				C_Timer.After((i - 1)*0.25, function()
					SendChatMessage(sub, channel)
				end)
			end
		end
	end
	
	local function check(func, msgl, ...)
		if not ... then
			return
		end
		local msg = msgl == ... and func() or func(...)
		if not msg then
			return
		end
		send(msg)
		return true
	end
	
	local ismyself = select(12, ...) == UnitGUID("player")
	
	if msg:lower():sub(1, 3) == "#my" and ismyself then
		msg = "!" .. msg:sub(4)
	end
	
	for name, info in pairs(aura_env.commands) do
		for _, match in ipairs(info.match) do
			if (aura_env.config[name] or info.bypass)
			and (not info.self or ismyself)
			and check(info.func, msg:lower(), msg:lower():match(match)) then
				break
			end
		end
	end
end

--[==============================================[
	declarations
]==============================================]--

local notecheck_matches = {
	-- SL -- SoD -- Kel'Thuzad
	"\nstartLine\n(.-)\nendLine\n";
	"\nstartLine\n(.-)\nendLine$";
	
	-- SL -- SoD -- Soulrender Dormazain
	"\nchainOrder\n(.-)\nend\n";
	"\nchainOrder\n(.-)\nend$";
	
	-- Generic
	"\nnotecheckstart\n(.-)\nnotecheckend";
}

local shardIDs = {
	[187073] = "unholy11"; -- Shard of Dyz (Rank 1)
	[187290] = "unholy12"; -- Shard of Dyz (Rank 2)
	[187299] = "unholy13"; -- Shard of Dyz (Rank 3)
	[187308] = "unholy14"; -- Shard of Dyz (Rank 4)
	[187318] = "unholy15"; -- Shard of Dyz (Rank 5)
	
	[187079] = "unholy21"; -- Shard of Zed (Rank 1)
	[187292] = "unholy22"; -- Shard of Zed (Rank 2)
	[187301] = "unholy23"; -- Shard of Zed (Rank 3)
	[187310] = "unholy24"; -- Shard of Zed (Rank 4)
	[187320] = "unholy25"; -- Shard of Zed (Rank 5)
	
	[187076] = "unholy31"; -- Shard of Oth (Rank 1)
	[187291] = "unholy32"; -- Shard of Oth (Rank 2)
	[187300] = "unholy33"; -- Shard of Oth (Rank 3)
	[187309] = "unholy34"; -- Shard of Oth (Rank 4)
	[187319] = "unholy35"; -- Shard of Oth (Rank 5)
	
	[187063] = "frost11"; -- Shard of Cor (Rank 1)
	[187287] = "frost12"; -- Shard of Cor (Rank 2)
	[187296] = "frost13"; -- Shard of Cor (Rank 3)
	[187305] = "frost14"; -- Shard of Cor (Rank 4)
	[187315] = "frost15"; -- Shard of Cor (Rank 5)
	
	[187071] = "frost21"; -- Shard of Tel (Rank 1)
	[187289] = "frost22"; -- Shard of Tel (Rank 2)
	[187298] = "frost23"; -- Shard of Tel (Rank 3)
	[187307] = "frost24"; -- Shard of Tel (Rank 4)
	[187317] = "frost25"; -- Shard of Tel (Rank 5)
	
	[187065] = "frost31"; -- Shard of Kyr (Rank 1)
	[187288] = "frost32"; -- Shard of Kyr (Rank 2)
	[187297] = "frost33"; -- Shard of Kyr (Rank 3)
	[187306] = "frost34"; -- Shard of Kyr (Rank 4)
	[187316] = "frost35"; -- Shard of Kyr (Rank 5)
	
	[187057] = "blood11"; -- Shard of Bek (Rank 1)
	[187284] = "blood12"; -- Shard of Bek (Rank 2)
	[187293] = "blood13"; -- Shard of Bek (Rank 3)
	[187302] = "blood14"; -- Shard of Bek (Rank 4)
	[187312] = "blood15"; -- Shard of Bek (Rank 5)
	
	[187059] = "blood21"; -- Shard of Jas (Rank 1)
	[187285] = "blood22"; -- Shard of Jas (Rank 2)
	[187294] = "blood23"; -- Shard of Jas (Rank 3)
	[187303] = "blood24"; -- Shard of Jas (Rank 4)
	[187313] = "blood25"; -- Shard of Jas (Rank 5)
	
	[187061] = "blood31"; -- Shard of Rev (Rank 1)
	[187286] = "blood32"; -- Shard of Rev (Rank 2)
	[187295] = "blood33"; -- Shard of Rev (Rank 3)
	[187304] = "blood34"; -- Shard of Rev (Rank 4)
	[187314] = "blood35"; -- Shard of Rev (Rank 5)
}

--[==============================================[
	functions
]==============================================]--

local function getRepText(factionID, overrideName)
	local
	name,
	description,
	standingID,
	barMin,
	barMax,
	barVal,
	atWarWith,
	canToggleAtWar,
	isHeader,
	isCollapsed,
	hasRep,
	isWatched,
	isChild,
	factionID,
	hasBonusRepGain,
	canBeLFGBonus
	= GetFactionInfoByID(factionID)
	if not name then
		return
	end
	
	local min = barVal - barMin
	local max = barMax - barMin
	
	local
	friendID,
	friendRep,
	friendMaxRep,
	friendName,
	friendText,
	friendTexture,
	friendTextLevel,
	friendThreshold,
	nextFriendThreshold
	= GetFriendshipReputation(factionID)
	
	local displayName
	local displayStanding
	
	if not friendID then
		displayName = name
		displayStanding = _G["FACTION_STANDING_LABEL" .. standingID] or standingID
	else
		displayName = friendName
		displayStanding = friendTextLevel
	end
	
	if overrideName then
		displayName = overrideName
	end
	
	local str = ""
	str = str .. displayName .. ": "
	str = str .. displayStanding
	if not (min == 0 and max == 0) then
		str = str .. " (" .. BreakUpLargeNumbers(min) .. " / " .. BreakUpLargeNumbers(max) .. ")"
	end
	return str
end

local function getShards()
	local shards = {}
	
	for itemID, name in pairs(shardIDs) do
		local c = GetItemCount(itemID, true)
		if c and c > 0 then
			shards[name] = true
		end
	end
	
	local function process(itemLink)
		if not itemLink then
			return
		end
		local link = itemLink:match("|Hitem:(.-)|h")
		if link then
			local _, _, gem1, gem2, gem3 = strsplit(":", link)
			local gems = {tonumber(gem1), tonumber(gem2), tonumber(gem3)}
			for _, itemID in ipairs(gems) do
				local name = shardIDs[itemID]
				if name then
					shards[name] = true
				end
			end
		end
	end
	
	for i = 1, 10 do
		local itemLink = GetInventoryItemLink("player", i)
		process(itemLink)
	end
	
	for j = 0, 4 do
		local n = GetContainerNumSlots(j)
		for i = 1, n do
			local itemLink = GetContainerItemLink(j, i)
			process(itemLink)
		end
	end
	
	return shards
end

local function getShardInfo(name)
	local shardType, shardIndex, shardRank = name:match("(%a+)(%d)(%d)")
	return shardType, tonumber(shardIndex), tonumber(shardRank)
end

--[==============================================[
	commands
]==============================================]--

aura_env.commands = {}

aura_env.commands.renown = {
	match = {
		"^!renown$";
	};
	func = function()
		local covID = C_Covenants.GetActiveCovenantID()
		if not covID then
			return
		end
		local covData = C_Covenants.GetCovenantData(covID)
		if not covData then
			return
		end
		local renown = C_CovenantSanctumUI.GetRenownLevel()
		if not renown then
			return
		end
		return "Renown: " .. tostring(renown) .. " (" .. tostring(covData.name) .. ")"
	end;
}

aura_env.commands.korthia = {
	match = {
		"^!korthia$";
	};
	func = function()
		return getRepText(2472--[[The Archivists' Codex]], "Korthia")
	end;
}

aura_env.commands.deathsadvance = {
	match = {
		"^!da$";
	};
	func = function()
		return getRepText(2470--[[Death's Advance]])
	end;
}

aura_env.commands.conduits = {
	match = {
		"^!conduits$";
	};
	func = function()
		--[[
		local missing = 0
		for conduitType = 0, 2 do
			local list = C_Soulbinds.GetConduitCollection(conduitType)
			for _, info in ipairs(list) do
				missing = missing + 9 - (info.conduitRank or 0)
			end
		end
		return "Missing: " .. missing .. " upgrades (cost: " .. BreakUpLargeNumbers(missing*3000) .. ")"
		--]]
		
		local specIndex = GetSpecialization()
		if not specIndex then
			return
		end
		
		local specName = select(2, GetSpecializationInfo(specIndex))
		
		local specMissing = 0
		local otherMissing = 0
		
		for conduitType = 0, 3 do
			local list = C_Soulbinds.GetConduitCollection(conduitType)
			for _, info in ipairs(list) do
				local missing = 11 - (info.conduitRank or 0)
				if not info.conduitSpecName or info.conduitSpecName == specName then
					specMissing = specMissing + missing
				else
					otherMissing = otherMissing + missing
				end
			end
		end
		
		local allMissing = specMissing + otherMissing
		
		-- return
		-- 	"[9.2] " ..
		-- 	specName .. ": "
		-- 	.. specMissing .. " (" .. BreakUpLargeNumbers(specMissing*3000) .. "), "
		-- 	.. "All: "
		-- 	.. allMissing .. " (" .. BreakUpLargeNumbers(allMissing*3000) .. ")"
		
		return
			"[9.2] " ..
			specName .. ": "
			.. specMissing
			.. ", "
			.. "All: "
			.. allMissing
	end;
}

aura_env.commands.shards = {
	match = {
		"^!shards$";
	};
	func = function()
		local shards = getShards()
		local ranks = {
			unholy = {0, 0, 0};
			frost = {0, 0, 0};
			blood = {0, 0, 0};
		}
		
		for name in pairs(shards) do
			local shardType, shardIndex, shardRank = getShardInfo(name)
			ranks[shardType][shardIndex] = shardRank
		end
		
		return
			"Unholy: " .. table.concat(ranks.unholy, " ") .. ", "
			.. "Frost: " .. table.concat(ranks.frost, " ") .. ", "
			.. "Blood: " .. table.concat(ranks.blood, " ")
	end;
}

aura_env.commands.tormentors = {
	match = {
		"^!tormentors$";
	};
	func = function()
		local done = C_QuestLog.IsQuestFlaggedCompleted(63854)
		if done then
			return "Tormentors: 1/1"
		else
			return "Tormentors: 0/1"
		end
	end;
}

aura_env.commands.embers = {
	match = {
		"^!embers$";
	};
	func = function()
		local shards = getShards()
		local total = 0
		local cost = {
			[1] = 0;
			[2] = 5;
			[3] = 5 + 15;
			[4] = 5 + 15 + 30;
			[5] = 5 + 15 + 30 + 50;
		}
		
		local info = C_CurrencyInfo.GetCurrencyInfo(1977--[[Stygian Ember]])
		if info and info.quantity then
			total = total + info.quantity
		end
		
		for name in pairs(shards) do
			local shardType, shardIndex, shardRank = getShardInfo(name)
			total = total + cost[shardRank]
		end
		
		local t1 = time {year = 2021, month = 7, day = 7, hour = 9}
		local t2 = GetServerTime()
		local weeks = math.ceil((t2 - t1)/86400/7)
		
		return string.format("Embers: %i total, %.2f per week", total, total/weeks)
	end;
}

-- aura_env.commands.notecheck = {
-- 	match = {
-- 		"^!notecheck (.+)$";
-- 		"^!notecheck$";
-- 	};
-- 	self = true;
-- 	func = function(msg)
-- 		if not _G.VExRT or not _G.VExRT.Note or not _G.VExRT.Note.Text1 then
-- 			return "ERROR: no ExRT note"
-- 		end
		
-- 		local note = _G.VExRT.Note.Text1
		
-- 		local result = {}
		
-- 		local in_note = {}
-- 		local in_raid = {}
		
-- 		-- local unformatted = {}
		
-- 		local t
		
-- 		for _, match in ipairs(notecheck_matches) do
-- 			local s1, s2, _ = note:find(match)
-- 			if s1 and s2 then
-- 				local section = note:sub(s1, s2)
-- 				note = note:sub(1, s1 - 1) .. note:sub(s2 + 1, -1)
-- 				-- for word in section:gmatch("%a+") do
-- 				-- 	unformatted[word] = true
-- 				-- end
-- 				for name in section:gmatch("|c........(.-)||r") do
-- 					name = name:gsub("[%p%s]", "") -- fix name formatting
-- 					in_note[name] = (in_note[name] or 0) + 1
-- 				end
-- 			end
-- 		end
		
-- 		if next(in_note) == nil then
-- 			return "ERROR: found no names in note"
-- 		end
		
-- 		-- scan raid
-- 		local grp_min = 1
-- 		local grp_max = 8
-- 		if msg then
-- 			-- grp_min, grp_max = msg:match("^%s*(%d+)%s*%-%s*(%d+)%s*$")
-- 			grp_min, grp_max = msg:gsub("%s", ""):match("(%d+)%-(%d+)")
-- 			grp_min = tonumber(grp_min)
-- 			grp_max = tonumber(grp_max)
-- 			if not grp_min or not (grp_min >= 1 and grp_min <= 8)
-- 			or not grp_max or not (grp_max >= 1 and grp_max <= 8)
-- 			or not (grp_min <= grp_max)
-- 			then
-- 				return "ERROR: invalid groups"
-- 			end
-- 		end
-- 		for i = 1, GetNumGroupMembers() do
-- 			local name, _, subgroup = GetRaidRosterInfo(i)
-- 			if name and subgroup then
-- 				local real = name:match("(.-)%-")
-- 				if real then
-- 					name = real
-- 				end
-- 				if subgroup >= grp_min and subgroup <= grp_max then
-- 					in_raid[name] = (in_raid[name] or 0) + 1
-- 				end
-- 			end
-- 		end
		
-- 		-- not in raid
-- 		t = {}
-- 		for name in pairs(in_note) do
-- 			if not in_raid[name] then
-- 				table.insert(t, name)
-- 			end
-- 		end
-- 		table.sort(t)
-- 		result[#result + 1] = "Not in raid: " .. table.concat(t, ", ")
		
-- 		-- not in note
-- 		t = {}
-- 		for name in pairs(in_raid) do
-- 			if not in_note[name] then
-- 				table.insert(t, name)
-- 			end
-- 		end
-- 		table.sort(t)
-- 		result[#result + 1] = "Not in note: " .. table.concat(t, ", ")
		
-- 		-- multiple hits
-- 		t = {}
-- 		for name, count in pairs(in_note) do
-- 			if count > 1 then
-- 				table.insert(t, name .. " (" .. count .. "x)")
-- 			end
-- 		end
-- 		if #t > 0 then
-- 			table.sort(t)
-- 			result[#result + 1] = "Listed multiple times: " .. table.concat(t, ", ")
-- 		end
		
-- 		-- unformatted
-- 		-- t = {}
-- 		-- for word in pairs(unformatted) do
-- 		-- 	if in_raid[word] then
-- 		-- 		table.insert(t, word)
-- 		-- 	end
-- 		-- end
-- 		-- if #t > 0 then
-- 		-- 	table.sort(t)
-- 		-- 	result[#result + 1] = "FORMATTING ERROR: " .. table.concat(t, ", ")
-- 		-- end
		
-- 		return result
-- 	end;
-- }

aura_env.commands.notecheck = {
	match = {
		"^!notecheck (.+)$";
		"^!notecheck$";
	};
	self = true;
	func = function(msg)
		if not msg then
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
			pattern = first .. "%s*(.-)\n%s*\n"
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
		
		-- unformatted
		-- t = {}
		-- for word in pairs(unformatted) do
		-- 	if in_raid[word] then
		-- 		table.insert(t, word)
		-- 	end
		-- end
		-- if #t > 0 then
		-- 	table.sort(t)
		-- 	result[#result + 1] = "FORMATTING ERROR: " .. table.concat(t, ", ")
		-- end
		
		return result
	end;
}

aura_env.commands.magetower = {
	match = {
		"^!magetower$";
	};
	func = function()
		local challenges = 0
		
		for i = 1, 7 do
			local done = select(3, GetAchievementCriteriaInfo(15310, i, true))
			if done then
				challenges = challenges + 1
			end
		end
		
		local classes = 0
		
		local t = {52769, 52764, 52761, 52766, 52765, 52758, 52767, 52762, 52768, 52763, 52760, 52759}
		for _, id in ipairs(t) do
			local done = select(3, GetAchievementCriteriaInfoByID(15308, id))
			if done then
				classes = classes + 1
			end
		end
		
		-- head mogs
		local mogIDs = {
			188534; -- Death Knight
			188542; -- Demon Hunter
			188550; -- Druid
			188558; -- Hunter
			188565; -- Mage
			188574; -- Monk
			188582; -- Paladin
			188589; -- Priest
			188598; -- Rogue
			188606; -- Shaman
			188613; -- Warlock
			188622; -- Warrior
		}
		
		local mogs = 0
		
		for _, id in ipairs(mogIDs) do
			if C_TransmogCollection.PlayerHasTransmog(id) then
				mogs = mogs + 1
			end
		end
		
		local bear_done = select(3, GetAchievementCriteriaInfo(15312, 1, true))
		
		if bear_done then
			mogs = mogs + 1
		end
		
		do
			return
				"Mage Tower:"
				.. " " .. challenges .. "/7"
				.. " (" .. mogs .. "/13 mogs, " .. classes .. "/12 classes)"
		end
		
		
		
		
		
		-- local bear_done = select(3, GetAchievementCriteriaInfo(15312, 1, true))
		
		return
			"Mage Tower: "
			.. challenges .. "/7 challenges"
			.. ", " .. classes .. "/12 classes"
			-- .. " bear=" .. tostring(bear_done)
	end;
}

aura_env.commands.flux = {
	match = {
		"^!flux$";
	};
	func = function()
		local total = 0
		
		local info = C_CurrencyInfo.GetCurrencyInfo(2009--[[Cosmic Flux]])
		if info and info.quantity then
			total = total + info.quantity
		end
		
		return string.format("Flux: %i", total)
	end;
}

aura_env.commands.rep = {
	match = {
		"^!rep (.+)$";
	};
	func = function(msg)
		local list = {}
		
		local index = 0
		while true do
			index = index + 1
			local name, _, _, _, _, _, _, _, _, _, _, _, _, id = GetFactionInfo(index)
			if not name then
				break
			end
			table.insert(list, {
				name = name;
				id = id;
			})
		end
		
		msg = msg:lower():gsub("[%p%s]", "")
		
		for _, info in ipairs(list) do
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
		
		local item = list[1]
		if item and item.correct > 0 then
			return getRepText(item.id)
		end
	end;
}
