---function to check if the item can provide a given code.
---you can have it check and return true for multiple codes but for simplicity only the name is
---a valid code by default from the builder
---@param self LuaItem
---@param code string
---@return boolean
local function CanProvideCodeFunc(self, code)
    return code == self.Name
end

---function that gets triggered when left clicking a lua items as hosted item or in an itemgrid
---will do whatever you want it to
---@param self LuaItem
local function OnLeftClickFunc(self)
    -- your custom handling for clicks here
    -- return true
end

---function that gets triggered when right clicking a lua items as hosted item or in an itemgrid
---will do what ever you want it to
---@param self LuaItem
local function OnRightClickFunc(self)
    -- your custom handling for clicks here
    -- return true
end

---function that gets triggered when middle clicking a lua items as hosted item or in an itemgrid
---will dp whatever you want it to
---@param self LuaItem
local function OnMiddleClickFunc(self)
    -- your custom handling for clicks here
    -- return true
end

---function to check if, depending on the current state of the item, a certain code will be provided
---this can be much more complex but since we only use 1 code and this one should always be returned
---if you dont return a code here the item will be "disabled" in the maps/itemgrid
---and "enabled" if it provides the code
---@param self LuaItem
---@param code string
---@return integer
local function ProvidesCodeFunc(self, code)
    if CanProvideCodeFunc(self, code) then
		return 1
	end
    return 0
end

---save function triggered on closing poptracker to have a state to restore later on. specific to custom pseudo-cache LuaItems
---@param self LuaItem
---@return table
local function SaveManualLocationStorageFunc(self)
    return {
        -- save everything from ItemState in here separately
        MANUAL_LOCATIONS = self.ItemState.MANUAL_LOCATIONS,
        MANUAL_LOCATIONS_ORDER = self.ItemState.MANUAL_LOCATIONS_ORDER,
        Target = self.ItemState.Target,
        Name = self.Name,
        Icon = self.Icon
    }
end

---function triggered on loading the pack to restore the last saved state. specific to custom pseudo-cache LuaItems
---@param self LuaItem
---@param data table
local function LoadManualLocationStorageFunc(self, data)
    if data ~= nil and self.Name == data.Name then
        -- load everything from ItemState in here separately
        self.ItemState.MANUAL_LOCATIONS = data.MANUAL_LOCATIONS
        self.ItemState.MANUAL_LOCATIONS_ORDER = data.MANUAL_LOCATIONS_ORDER
        self.Icon = ImageReference:FromPackRelativePath(data.Icon)
    else
    end
end

-------
---there are more functions present by default that are unused in the example
--local function PropertyChangedFunc()
--    -- print("PropertyChangedFunc")
--end
--local function ItemState()
--end
--local function Name()
--end
--local function Icon ()--> ImageReference:FromPackRelativePath()
--end
--local function Type()
--end

------

---creates an empty pseudo cache item to store various states for up to 10 seeds to restroe when reconncting to those.
---mainly intended for manually marked off locations like shops or inspected locations OR for item states that have been
---manually set because they are hard to infer from game/server state
---@param name string
---@return LuaItem
function CreateLuaManualStorageItem(name)
    local self = ScriptHost:CreateLuaItem()
    -- self.Type = "custom"
    self.Name = name -- code
    self.Icon = ImageReference:FromPackRelativePath("/images/items/closed_Chest.png")
	---@type table<string, any>
    self.ItemState = {
		---@type table<string, table<string, integer>>
        MANUAL_LOCATIONS = {
            ["default"] = {}
        },
		---@type string[]
        MANUAL_LOCATIONS_ORDER = {}
        -- you can add many more custom stuff in here
    }
    self.PotentialCodes = {name}
    self.CanProvideCodeFunc = CanProvideCodeFunc
    self.OnLeftClickFunc = OnLeftClickFunc -- your_custom_leftclick_function_here
    self.OnRightClickFunc = OnRightClickFunc -- your_custom_rightclick_function_here
    self.OnMiddleClickFunc = OnMiddleClickFunc -- your_custom_middleclick_function_here
    self.ProvidesCodeFunc = ProvidesCodeFunc
    self.SaveFunc = SaveManualLocationStorageFunc
    self.LoadFunc = LoadManualLocationStorageFunc
    return self
end


function CreateOfflineGoalItem()
	local self = ScriptHost:CreateLuaItem()
	
	self.Name = "offline_goal"
	self.Icon = ImageReference:FromPackRelativePath("/images/settings/gear.png")
	self.ItemState = {
		goal = "unicron"
	}
	self.PotentialCodes = {"offline_goal"}
	
	local function UpdateDisplay(item)
		local label
		if item.ItemState.goal == "bosses" then
			label = "Bosses"
		else
			label = "Unicron"
		end
		item:SetOverlay("Goal: " .. label)
	end
	
	self.CanProvideCodeFunc = function(item, code)
		return code == item.Name
	end
	
	self.ProvidesCodeFunc = function(item, code)
		return 1
	end
	
	self.OnLeftClickFunc = function(item)
		--Offline settings should not override AP slot data
		if Archipelago and Archipelago.PlayerNumber > -1 then
			return
		end
		
		if item.ItemState.goal == "unicron" then
			item.ItemState.goal = "bosses"
		else
			item.ItemState.goal = "unicron"
		end
		local bosses_goal = Tracker:FindObjectForCode("bosses_goal")
		if bosses_goal then
			bosses_goal.Active = item.ItemState.goal == "bosses"
		end
		UpdateDisplay(item)
		UpdateBossesBeaten()
	end
	
	self.SaveFunc = function(item)
		return {goal = item.ItemState.goal}
	end
	self.LoadFunc = function(item, data)
		if data and data.goal then
			item.ItemState.goal = data.goal
		end
		UpdateDisplay(item)
		local bosses_goal = Tracker:FindObjectForCode("bosses_goal")
		if bosses_goal then
			bosses_goal.Active = item.ItemState.goal == "bosses"
		end
	end
	
	UpdateDisplay(self)
	
	return self
end



function CreateOfflineMiniconCountItem()
    local self = ScriptHost:CreateLuaItem()

    self.Name = "offline_minicon_count"
    self.Icon = ImageReference:FromPackRelativePath(
        "/images/settings/gear.png"
    )

    self.ItemState = {
        required = OFFLINE_REQUIRED_MINICONS or 30
    }

    self.PotentialCodes = {self.Name}
    self.CanProvideCodeFunc = CanProvideCodeFunc
    self.ProvidesCodeFunc = ProvidesCodeFunc

    local function UpdateDisplay(item)
        item:SetOverlay(
            "Mini-Cons: " ..
            tostring(item.ItemState.required)
        )
    end

    local function SetRequired(item, value)
        -- Keep the setting within the valid range.
        value = math.max(20, math.min(40, value))

        item.ItemState.required = value
        OFFLINE_REQUIRED_MINICONS = value

        UpdateDisplay(item)
        UpdateMiniconCounter()
    end

    self.OnLeftClickFunc = function(item)
        -- Do not override the AP goal settings.
        if Archipelago and Archipelago.PlayerNumber > -1 then
            return
        end

        SetRequired(item, item.ItemState.required + 1)
    end

    self.OnRightClickFunc = function(item)
        if Archipelago and Archipelago.PlayerNumber > -1 then
            return
        end

        SetRequired(item, item.ItemState.required - 1)
    end

    self.SaveFunc = function(item)
        return {
            required = item.ItemState.required
        }
    end

    self.LoadFunc = function(item, data)
        if data and data.required ~= nil then
            local value = tonumber(data.required)

            if value then
                item.ItemState.required =
                    math.max(20, math.min(40, value))
            end
        end

        OFFLINE_REQUIRED_MINICONS = item.ItemState.required

        UpdateDisplay(item)
        UpdateMiniconCounter()
    end

    UpdateDisplay(self)

    return self
end
