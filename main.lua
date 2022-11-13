local dataStoreService = game:GetService("DataStoreService")
local players = game:GetService("Players")

local template = require(script.template)

local autoSaving = false
local profile = {}
profile.__index = profile
profile.dataStore = dataStoreService:GetDataStore("profiles")
profile.prefix = "profile"
profile.retries = 3
profile.active = {
	amount = 0, 
	profiles = {} :: {[Player]: profile}
}

local function standardLoad(self: profile): template | nil
	for _ = 0, self.retries do
		local success, result = pcall(self.dataStore.GetAsync, self.dataStore, self.key)
		if success then
			if result then
				return result
			else
				return template()
			end
		else
			warn(result)
		end
	end
	return false
end

function profile.new(player: Player, loader: ((profile) -> (template | nil))?)
	local self = setmetatable({}, profile)
	self.player = player
	self.key = ("%s_%d"):format(self.prefix, self.player.UserId)
	self.data = (loader) and loader(self) or standardLoad(self)
	if not self.data then
		self:destroy()
		return nil
	end
	self.shouldAutoSave = true
	profile.active.amount += 1
	profile.active.profiles[player] = self
	return self
end

--[[

    This function could improve. Could have the provided duration scale based on the amount of players and what is reasonable for the system
        to not go over it's rate limits.

]]

function profile.autoSave(duration: number, cooldown: number)
	if not autoSaving then
		autoSaving = true
		while autoSaving do
			for _, currentProfile: profile in pairs(profile.active.profiles) do
				if currentProfile.shouldAutoSave then
					task.spawn(currentProfile.save, currentProfile)
					task.wait(duration / profile.active.amount)
				end
			end
			task.wait(cooldown or 1)
		end
	end
	return {
		cancel = function()
			autoSaving = false
		end
	}
end

function profile.autoDisconnect()
	players.PlayerRemoving:Connect(function(player: Player)
		local selectedProfile = profile.active.profiles[player]
		if selectedProfile then
			selectedProfile:save()
			selectedProfile:destroy()
		end
	end)
end

type reconcileRecursiveMemory = {
	dataDimension: {},
	templateDimension: {}
}

function profile.reconcile(self: profile, _recursiveMemory: reconcileRecursiveMemory?)
	local dataDimension = (_recursiveMemory) and _recursiveMemory.dataDimension or self.data
	local templateDimension = (_recursiveMemory) and _recursiveMemory.templateDimension or template()
	for k, v in pairs(templateDimension) do
		if typeof(v) == "table" then
			if not dataDimension[k] then
				dataDimension[k] = {}
			end
			profile.reconcile(self, {
				dataDimension = dataDimension[k],
				templateDimension = v
			})
		elseif not dataDimension[k] then
			dataDimension[k] = v
		end
	end
end

function profile.save(self: profile)
	for _ = 0, self.retries do
		local success, result = pcall(self.dataStore.SetAsync, self.dataStore, self.key, self.data)
		if success then
			return
		else
			warn(result)
		end
	end
end

function profile.destroy(self: profile)
	if profile.active.profiles[self.player] then
		profile.active.amount -= 1
		profile.active.profiles[self.player] = nil
	end
	setmetatable(self, nil)
	table.clear(self)
end

type template = template.Type
type profile = typeof(profile.new(Instance.new("Player")))
export type Type = profile

return profile
