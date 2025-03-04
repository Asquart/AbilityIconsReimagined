--- @class (partial) AbilityIconsFramework
local AbilityIconsFramework = AbilityIconsFramework

local LAM2 = LibAddonMenu2

--- Initializes saved variables and configures their corresponding menus, using LibAddonMenu2 (if it exists).
function AbilityIconsFramework.InitializeSettings()
    AbilityIconsFramework.CONFIG = ZO_SavedVars:NewAccountWide("AbilityIconsFramework_SavedVariables", AbilityIconsFramework.SAVEDVARIABLES_VERSION, nil, AbilityIconsFramework.DEFAULT_ADDON_CONFIG)
    AbilityIconsFramework.CleanupAccountWideSettings(AbilityIconsFramework_SavedVariables, AbilityIconsFramework.DEFAULT_ADDON_CONFIG, nil)

    AbilityIconsFramework.GLOBALSETTINGS = ZO_SavedVars:NewAccountWide("AbilityIconsFramework_Globals", AbilityIconsFramework.SAVEDVARIABLES_VERSION, "global_settings",  AbilityIconsFramework.DEFAULT_SETTINGS)
    AbilityIconsFramework.CleanupAccountWideSettings(AbilityIconsFramework_Globals, AbilityIconsFramework.DEFAULT_SETTINGS, "global_settings")

    AbilityIconsFramework.CHARACTERSETTINGS = ZO_SavedVars:NewCharacterIdSettings("AbilityIconsFramework_Settings", AbilityIconsFramework.SAVEDVARIABLES_VERSION, "character_settings", AbilityIconsFramework.DEFAULT_SETTINGS)
    AbilityIconsFramework.CleanupCharacterIdSettings(AbilityIconsFramework_Settings, AbilityIconsFramework.DEFAULT_SETTINGS, "character_settings")

    if LAM2 == nil then return end

    local panelData = {
        type = "panel",
        name = "Ability Icons Framework",
        displayName = "|c66b2b2Ability|r |cffbf00Icons|r |c6C3BAAFramework|r",
        author = "|ce6202dKwiebe-Kwibus|r & Asquart",
        version = AbilityIconsFramework.version,
        slashCommand = "/aifgb",    -- (optional) will register a keybind to open to this panel
        registerForRefresh = true,   -- boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
        registerForDefaults = true   -- boolean (optional) (will set all options controls back to default values)
    }

    LAM2:RegisterAddonPanel("AbilityIconsFramework_Panel", panelData)

    local optionsData = {
        {
            type = "header",
            name = "Settings",
        },
        {
            type = "checkbox",
            name = "Use the same settings for all characters",
            getFunc = function()
                return AbilityIconsFramework.CONFIG.saveSettingsGlobally
            end,
            setFunc = AbilityIconsFramework.SetOptionGlobalIcons
        },
        {
            type = "checkbox",
            name = "Use Custom Scribed Ability Icons on ability bar",
            getFunc = function()
                return AbilityIconsFramework:GetSettings().showCustomScribeIcons
            end,
            setFunc = AbilityIconsFramework.SetOptionCustomIcons
        },
        {
            type = "checkbox",
            name = "Replace mismatched Base Ability Icons",
            getFunc = function()
                return AbilityIconsFramework:GetSettings().replaceMismatchedBaseIcons
            end,
            setFunc = AbilityIconsFramework.SetOptionMismatchedIcons
        }
    }

    -- Add mismatched icons options dynamically
-- Add mismatched icons options dynamically, sorted by class and skill tree
local mismatchedOptions = {}



 -- Group mismatched icons by main category, class, and skill tree
    local mainCategoryGroups = {}
    for iconName, data in pairs(AbilityIconsFramework.ICON_TO_SKILL_NAME) do
        local mainCategory = data.mainCategory
        local class = data.class
        local skillTree = data.skillTree

        if not mainCategoryGroups[mainCategory] then
            mainCategoryGroups[mainCategory] = {}
        end

        if not mainCategoryGroups[mainCategory][class] then
            mainCategoryGroups[mainCategory][class] = {}
        end

        if not mainCategoryGroups[mainCategory][class][skillTree] then
            mainCategoryGroups[mainCategory][class][skillTree] = {}
        end

        table.insert(mainCategoryGroups[mainCategory][class][skillTree], {
            position = data.position,
            option = {
                type = "checkbox",
                name = "Replace " .. data.skillName,
                getFunc = function()
                    return AbilityIconsFramework:GetSettings().mismatchedIcons[iconName]
                end,
                setFunc = function(value)
                    AbilityIconsFramework:GetSettings().mismatchedIcons[iconName] = value
                    AbilityIconsFramework.ReplaceMismatchedIcons()
                end,
            }
        })
    end

    -- Sort the main categories alphabetically
    local sortedMainCategories = {}
    for mainCategory, _ in pairs(mainCategoryGroups) do
        table.insert(sortedMainCategories, mainCategory)
    end
    table.sort(sortedMainCategories)

-- Add the sorted main categories to the main optionsData table
for _, mainCategory in ipairs(sortedMainCategories) do
    if mainCategory == "class" then
        -- Handle "class" main category directly without a dropdown
        for class, classData in pairs(mainCategoryGroups[mainCategory]) do
            -- Sort the skill trees within the class alphabetically
            local sortedSkillTrees = {}
            for skillTree, _ in pairs(classData) do
                table.insert(sortedSkillTrees, skillTree)
            end
            table.sort(sortedSkillTrees)

            -- Add the sorted skill trees under the class
            for _, skillTree in ipairs(sortedSkillTrees) do
                -- Sort the skills within the skill tree by position
                table.sort(mainCategoryGroups[mainCategory][class][skillTree], function(a, b)
                    return a.position < b.position
                end)

                -- Add a header for the class and skill tree
                table.insert(optionsData, {
                    type = "header",
                    name = class .. " - " .. skillTree,
                })

                -- Add the sorted skills under the skill tree
                for _, optionData in ipairs(mainCategoryGroups[mainCategory][class][skillTree]) do
                    table.insert(optionsData, optionData.option)
                end
            end
        end
    else
        -- Handle "non class" main category as a dropdown
        table.insert(optionsData, {
            type = "submenu",
            name = mainCategory,
            tooltip = "Options for " .. mainCategory,
            controls = {}
        })

        -- Sort the classes within the main category alphabetically
        local sortedClasses = {}
        for class, _ in pairs(mainCategoryGroups[mainCategory]) do
            table.insert(sortedClasses, class)
        end
        table.sort(sortedClasses)

        -- Add the sorted classes under the main category submenu
        for _, class in ipairs(sortedClasses) do
            -- Create a submenu for the class
            table.insert(optionsData[#optionsData].controls, {
                type = "submenu",
                name = class,
                tooltip = "Options for " .. class,
                controls = {}
            })

            -- Sort the skill trees within the class alphabetically
            local sortedSkillTrees = {}
            for skillTree, _ in pairs(mainCategoryGroups[mainCategory][class]) do
                table.insert(sortedSkillTrees, skillTree)
            end
            table.sort(sortedSkillTrees)

            -- Add the sorted skill trees under the class submenu
            for _, skillTree in ipairs(sortedSkillTrees) do
                -- Create a submenu for the skill tree
                table.insert(optionsData[#optionsData].controls[#optionsData[#optionsData].controls].controls, {
                    type = "submenu",
                    name = skillTree,
                    tooltip = "Options for " .. skillTree,
                    controls = {}
                })

                -- Sort the skills within the skill tree by position
                table.sort(mainCategoryGroups[mainCategory][class][skillTree], function(a, b)
                    return a.position < b.position
                end)

                -- Add the sorted skills under the skill tree submenu
                for _, optionData in ipairs(mainCategoryGroups[mainCategory][class][skillTree]) do
                    table.insert(optionsData[#optionsData].controls[#optionsData[#optionsData].controls].controls[#optionsData[#optionsData].controls[#optionsData[#optionsData].controls].controls].controls, optionData.option)
                end
            end
        end
    end
end

    LAM2:RegisterOptionControls("AbilityIconsFramework_Panel", optionsData)
end

--- Retrieves the saved settings, whether global or per character (and the default settings if nothing was previously saved).
function AbilityIconsFramework.GetSettings()
	if AbilityIconsFramework.CONFIG and AbilityIconsFramework.CONFIG.saveSettingsGlobally then
		return AbilityIconsFramework.GLOBALSETTINGS or AbilityIconsFramework.DEFAULT_SETTINGS
	else
        return AbilityIconsFramework.CHARACTERSETTINGS or AbilityIconsFramework.DEFAULT_SETTINGS
    end
end

--- Cleanup account-wide settings from previous versions.
--- @param savedVars table Contains the current account-wide saved variables.
--- @param defaultConfig table Contains the default account-wide saved variables.
--- @param namespace string? The sub-table (if any) in which the saved variables are stored.
-- Update the CleanupAccountWideSettings and CleanupCharacterIdSettings functions
function AbilityIconsFramework.CleanupAccountWideSettings(savedVars, defaultConfig, namespace)
    local currentConfig = savedVars["Default"][GetDisplayName()]["$AccountWide"]
    if namespace then
        currentConfig = currentConfig[namespace]
    end
    for key, _ in pairs(currentConfig) do
        if key ~= "version" and defaultConfig[key] == nil then
            currentConfig[key] = nil
        end
    end
    -- Cleanup mismatchedIcons table
    if currentConfig.mismatchedIcons then
        for iconName, _ in pairs(currentConfig.mismatchedIcons) do
            if defaultConfig.mismatchedIcons[iconName] == nil then
                currentConfig.mismatchedIcons[iconName] = nil
            end
        end
    end
end

function AbilityIconsFramework.CleanupCharacterIdSettings(savedVars, defaultConfig, namespace)
    local characterKey = GetCurrentCharacterId()
    local currentConfig = savedVars["Default"][GetDisplayName()][characterKey]
    if namespace then
        currentConfig = currentConfig[namespace]
    end
    for key, _ in pairs(currentConfig) do
        if key ~= "version" and defaultConfig[key] == nil then
            currentConfig[key] = nil
        end
    end
    -- Cleanup mismatchedIcons table
    if currentConfig.mismatchedIcons then
        for iconName, _ in pairs(currentConfig.mismatchedIcons) do
            if defaultConfig.mismatchedIcons[iconName] == nil then
                currentConfig.mismatchedIcons[iconName] = nil
            end
        end
    end
end

--- Set the setting for global (Account Wide) icons to on/off
--- @param value boolean
function AbilityIconsFramework.SetOptionGlobalIcons(value)
    local oldSettings = AbilityIconsFramework:GetSettings()
    AbilityIconsFramework.CONFIG.saveSettingsGlobally = value
    AbilityIconsFramework:GetSettings().showSkillStyleIcons = oldSettings.showSkillStyleIcons
    AbilityIconsFramework:GetSettings().showCustomScribeIcons = oldSettings.showCustomScribeIcons
    AbilityIconsFramework:GetSettings().replaceMismatchedBaseIcons = oldSettings.replaceMismatchedBaseIcons
end

--- Set the setting for skill style icons to on/off
--- @param value boolean
function AbilityIconsFramework.SetOptionSkillStyleIcons(value)
    AbilityIconsFramework:GetSettings().showSkillStyleIcons = value
    AbilityIconsFramework.OnCollectibleUpdated()
end

--- Set the setting for custom scribed icons to on/off
--- @param value boolean
function AbilityIconsFramework.SetOptionCustomIcons(value)
    AbilityIconsFramework:GetSettings().showCustomScribeIcons = value
    AbilityIconsFramework.OnCollectibleUpdated()
end

--- Set the setting for mismatched icons to on/off
--- @param value boolean
function AbilityIconsFramework.SetOptionMismatchedIcons(value)
    AbilityIconsFramework:GetSettings().replaceMismatchedBaseIcons = value
    AbilityIconsFramework.ReplaceMismatchedIcons()
end
