# Profile
An ultra-lightweight datastore wrapper for the Roblox game engine.

This module is designed to handle the basic neccessities for managing and utilizing datastores, while also offering a wide range of customizability. It's this virtue which allows for great power, even with it's lightweight nature. This will be greater explained as the tutorial continues.

---
### Creating a new profile

It's very simple to create a new profile:

```lua
local profile = Profile.new(player)
```

You can optionally pass a custom load function which will replace the default loader.

*this is just an example of how you would create a custom loader function. It does not follow the standard practices of loading data to keep it short and simple.*

If you wish to view the default loader function, check the source code for a function named `standardLoader`.

```lua
local profile = Profile.new(player, function(key: string)
   local dataStore = profile.dataStore
   dataStore:GetAsync(key)
end
```

`key: string` -> A string used to identify the specific user in question's data. It is a concatenation of `"profile.prefix".."_"..player.UserId`

### Setting up your data template

This module expects that there is a direct submodule located within the main module titled "template". It's contents should look like:

```lua
local function createTemplate()
    return {
        test = 5
    }
end

type template = typeof(createTemplate())
export type Type = template

return createTemplate
```

This might be a weird idiom, but it's the way I like to structure the templates because it offers better type support. If you are confused by `export type Type = template` it's really just for syntax purposes as I like to be able to import a type from a module as `type = module.Type`. If this is still confusing to you, just don't worry about it it's really not that important.

### Class-level values
This module offers a wide variety of customizability. At the class level, you can modify the following values:

`dataStore: DataStore` -> The data store object. Is equal to dataStoreService:GetDataStore("profiles") by default

`prefix: string` -> The prefix used to format an individual profiles `.key`

`retries: number` -> The amount of times the module will re-attempt a failed process before cancellation. `Default = 3`

`active: {amount: number, profiles: {[Player]: profile}}` -> keeps track of active profiles.

### Object-level values

`player: Player` -> The player corresponding to the profile

`key: string` -> A concatenation of `"profile.prefix".."_"..player.UserId`

`data: template` -> The data which was loaded from the dataStore

`shouldAutoSave: boolean` -> Signifies if this specific profile should be included in the autosaving process

### Class-level functions

`profile.new(player: Player, loader: ((DataStore, string) -> (template))?)` -> Creates a new profile and loads the player's data.

`profile.autoSave(duration: number, cooldown: number)` -> Begins the auto save process which will save all profiles loaded on the server within `duration` and will pause for `cooldown` until continuing the next itteration

*To be more clear, this means if you set the duration to `120` and there are 16 profiles loaded on the server, it will save someones profile every 7.5 seconds*

`profile.autoDisconnect()` -> Will automatically destroy the profile when the player leaves.

### Object-level methods

`profile:reconcile()` -> makes sure the players data is up to date with the current template

`profile:save()` -> saves the players data

`profile:destroy()` -> saves the players data, and cleans up to be garbage collected. Also turns the object into an empty table so it can no longer be used.

### Advanced example

```lua
local players = game:GetService("Players")

local Profile = require(script.profile)
Profile.autoDisconnect()
Profile.autoSave(120, 10)
--Profile.dataStore = dataStoreService:GetDataStore("someOtherDataStore")
-- technically you can change this before you initialize any of the profiles
-- if you must have a unique data store name
profile.prefix = "someOtherPrefix" --> defaults to "profile" meaning all keys will be "profile_<userId>" -- but in this case all the keys would now be "someOtherPrefix_<userId>"
profile.retries = 5 --> default is 3

local function playerAdded(player: Player)
  local profile = Profile.new(player)
  profile.reconcile()
  print(profile.data)
end
```

players.PlayerAdded:Connect(playerAdded)
