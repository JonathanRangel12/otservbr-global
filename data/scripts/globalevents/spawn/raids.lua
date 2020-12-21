local raids = {
	-- Weekly
	--Segunda-Feira
	[''] = {
		[''] = {raidName = 'RatsThais'},
	},

	--Terça-Feira
	[''] = {
		[''] = {raidName = 'Midnight Panther'}
	},

	--Quarta-Feira
	[''] = {
		[''] = {raidName = 'Draptor'}
	},

	--Quinta-Feira
	[''] = {
		[''] = {raidName = 'Undead Cavebear'}
	},

	--Sexta-feira
	[''] = {
		[''] = {raidName = 'Titanica'}
	},

	--Sábado
	[''] = {
		[''] = {raidName = 'Draptor'}
	},

	--Domingo
	[''] = {
		[''] = {raidName = 'Midnight Panther'},
		[''] = {raidName = 'Orc Backpack'}
	},

	-- By date (Day/Month)
	['31/10'] = {
		['16:00'] = {raidName = 'Halloween Hare'}
	}
}

local spawnRaids = GlobalEvent("spawn raids")
function spawnRaids.onThink(interval, lastExecution, thinkInterval)
	local day, date = os.date('%A'), getRealDate()

	local raidDays = {}
	if raids[day] then
		raidDays[#raidDays + 1] = raids[day]
	end
	if raids[date] then
		raidDays[#raidDays + 1] = raids[date]
	end
	if #raidDays == 0 then
		return true
	end

	for i = 1, #raidDays do
		local settings = raidDays[i][getRealTime()]
		if settings and not settings.alreadyExecuted then
			Game.startRaid(settings.raidName)
			settings.alreadyExecuted = true
		end
	end
	return true
end

spawnRaids:interval(6000000)
spawnRaids:register()
