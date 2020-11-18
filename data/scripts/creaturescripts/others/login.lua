function Player.sendTibiaTime(self, hours, minutes)
	-- TODO: Migrate to protocolgame.cpp
	local msg = NetworkMessage()
	msg:addByte(0xEF)
	msg:addByte(hours)
	msg:addByte(minutes)
	msg:sendToPlayer(self)
	msg:delete()
	return true
end

local function onMovementRemoveProtection(cid, oldPos, time)
	local player = Player(cid)
	if not player then
		return true
	end

	local playerPos = player:getPosition()
	if (playerPos.x ~= oldPos.x or playerPos.y ~= oldPos.y or playerPos.z ~= oldPos.z) or player:getTarget() then
		player:setStorageValue(Storage.combatProtectionStorage, 0)
		return true
	end

	addEvent(onMovementRemoveProtection, 1000, cid, oldPos, time - 1)
end

local playerLogin = CreatureEvent("PlayerLogin")
function playerLogin.onLogin(player)
	local vocationSet = {
		[1] = { -- Sorcerer
				set = {{2190, 1}, {2643, 1}, {2649, 1}, {8820, 1}, {2175, 1}, {8819, 1}, {18559, 1}}
		},
		[2] = { -- Druid
				set = {{2182, 1}, {2643, 1}, {2649, 1}, {8820, 1}, {2175, 1}, {8819, 1}, {18559, 1}}
		},
		[3] = { -- Paladin
				set = {{2512, 1}, {2643, 1}, {2461, 1}, {2660, 1}, {8923, 1}, {2389, 3}, {18559, 1}}
		},
		[4] = { -- Knight
				set = {{8602, 1}, {2643, 1}, {2478, 1}, {2460, 1}, {2465, 1}, {2509, 1}, {18559, 1}}
		}
	}

	local items = {
		{7620, 5},
		{8704, 5},
		{2120, 1},
		{2674, 5},
		{2148, 3}
	}

	if player:getLastLoginSaved() == 0 then
		local vocation = player:getVocation():getId()
		local targetVocation = vocationSet[vocation]

		local backpack = player:addItem(1988)
		if backpack then
			for i = 1, #items do
				backpack:addItem(items[i][1], items[i][2])
			end
		end

		if targetVocation then
			for i = 1, #targetVocation.set do
				player:addItem(targetVocation.set[i][1], targetVocation.set[i][2])
			end
		end

		local town = player:getTown()
		if town and town:getId() == TOWNS_LIST.ROOKGAARD then
			player:addItem(2461, 1, true, 1, CONST_SLOT_HEAD)
			player:addItem(2650, 1, true, 1, CONST_SLOT_ARMOR)
			player:addItem(2512, 1, true, 1, CONST_SLOT_RIGHT)
			player:addItem(2379, 1, true, 1, CONST_SLOT_LEFT)
			player:addItem(2649, 1, true, 1, CONST_SLOT_LEGS)
			player:addItem(2643, 1, true, 1, CONST_SLOT_FEET)
			player:addItem(2050, 1, true, 1, CONST_SLOT_AMMO)
		end

	else
		player:sendTextMessage(MESSAGE_STATUS_DEFAULT, string.format("Your last visit in ".. SERVER_NAME ..": %s.", os.date("%d. %b %Y %X", player:getLastLoginSaved())))
	end

	local playerId = player:getId()
	DailyReward.init(playerId)

	player:loadSpecialStorage()

	if player:getGroup():getId() >= 4 then
		player:setGhostMode(true)
	end
	-- Boosted creature
	player:sendTextMessage(MESSAGE_LOOT, "Today's boosted creature: " .. BoostedCreature.name .. " \
	Boosted creatures yield more experience points, carry more loot than usual and respawn at a faster rate.")
	
	-- Bestiary tracker
	player:refreshBestiaryTracker()
		
	-- Stamina
	nextUseStaminaTime[playerId] = 1

	-- EXP Stamina
	nextUseXpStamina[playerId] = 1

	-- Prey Small Window
	for slot = CONST_PREY_SLOT_FIRST, CONST_PREY_SLOT_THIRD do
		player:sendPreyData(slot)
	end

	-- New prey
	nextPreyTime[playerId] = {
		[CONST_PREY_SLOT_FIRST] = 1,
		[CONST_PREY_SLOT_SECOND] = 1,
		[CONST_PREY_SLOT_THIRD] = 1
	}

	if (player:getAccountType() == ACCOUNT_TYPE_TUTOR) then
	local msg = [[:: Tutor Rules
		1 *> 3 Warnings you lose the job.
		2 *> Without parallel conversations with players in Help, if the player starts offending, you simply mute it.
		3 *> Be educated with the players in Help and especially in the Private, try to help as much as possible.
		4 *> Always be on time, if you do not have a justification you will be removed from the staff.
		5 *> Help is only allowed to ask questions related to tibia.
		6 *> It is not allowed to divulge time up or to help in quest.
		7 *> You are not allowed to sell items in the Help.
		8 *> If the player encounters a bug, ask to go to the website to send a ticket and explain in detail.
		9 *> Always keep the Tutors Chat open. (required).
		10 *> You have finished your schedule, you have no tutor online, you communicate with some CM in-game
		or ts and stay in the help until someone logs in, if you can.
		11 *> Always keep a good Portuguese in the Help, we want tutors who support, not that they speak a satanic ritual.
		12 *> If you see a tutor doing something that violates the rules, take a print and send it to your superiors. "
		- Commands -
		Mute Player: /mute nick, 90 (90 seconds)
		Unmute Player: /unmute nick.
		- Commands -]]
		player:popupFYI(msg)
	end

	-- Open channels
	if table.contains({TOWNS_LIST.DAWNPORT, TOWNS_LIST.DAWNPORT_TUTORIAL}, player:getTown():getId())then
		player:openChannel(3) -- World chat
	else
		player:openChannel(3) -- World chat
		player:openChannel(5) -- Advertsing main
	end

	-- Rewards
	local rewards = #player:getRewardList()
	if(rewards > 0) then
		player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("You have %d %s in your reward chest.",
		rewards, rewards > 1 and "rewards" or "reward"))
	end

	-- Update player id
	local stats = player:inBossFight()
	if stats then
		stats.playerId = player:getId()
	end

	if player:getStorageValue(Storage.combatProtectionStorage) < 1 then
		player:setStorageValue(Storage.combatProtectionStorage, 1)
		onMovementRemoveProtection(playerId, player:getPosition(), 10)
	end
	-- Set Client XP Gain Rate
	local baseExp = 100
	if Game.getStorageValue(GlobalStorage.XpDisplayMode) > 0 then
		baseExp = getRateFromTable(experienceStages, player:getLevel(), configManager.getNumber(configKeys.RATE_EXP))
	end

	local staminaMinutes = player:getStamina()
	local doubleExp = false --Can change to true if you have double exp on the server
	local staminaBonus = (staminaMinutes > 2400) and 150 or ((staminaMinutes < 840) and 50 or 100)
	if doubleExp then
		baseExp = baseExp * 2
	end
	player:setStaminaXpBoost(staminaBonus)
	player:setBaseXpGain(baseExp)

	local worldTime = getWorldTime()
	local hours = math.floor(worldTime / 60)
	local minutes = worldTime % 60
	player:sendTibiaTime(hours, minutes)

	if player:getStorageValue(Storage.isTraining) == 1 then --Reset exercise weapon storage
		player:setStorageValue(Storage.isTraining,0)
	end
	return true
end
playerLogin:register()
