-- New Trials need to be added in three places: 1. TWRTE.questIds near the top, 2. lookup in getTrialName(questId), 3. lookup in updateCooldownInfo()
-- New Coffers need to be added in two places: 1. TWRTE.lootIds near the top, 2. lookup in updateCooldownInfo()
-- Item IDs for coffers have been known to change.

--namespace
TrialsWeeklyResetTrackerExtended = {}
local TWRTE = TrialsWeeklyResetTrackerExtended

--constants
TWRTE.WEEK_IN_SECONDS = 604800
TWRTE.DAY_IN_SECONDS = 86400
TWRTE.HOUR_IN_SECONDS = 3600
TWRTE.MINUTE_IN_SECONDS = 60
TWRTE.MAX_DIFFERENCE = 5

--runtime data
TWRTE.characterId = GetCurrentCharacterId()
TWRTE.characterName = zo_strformat("<<1>>",GetRawUnitName("player"))
TWRTE.lastQuestId = nil
TWRTE.lastLootId = nil
TWRTE.questIds = {
  [5087] = "", -- Hel Ra Citadel, "Assaulting the Citadel"
  [5102] = "", -- Aetherian Archive, "The Mage's Tower"
  [5171] = "", -- Sanctum Ophidia, "The Oldest Ghost"
  [5352] = "", -- Maw of Lorkaj, "Into the Maw"
  [5894] = "", -- Halls of Fabrication, "Forging the Future"
  [6090] = "", -- Asylum Sanctorium, "Saint's Mercy"
  [6192] = "", -- Cloudrest, "Woe of the Welkynars"
  [6353] = ""  -- Sunspire, "The Return of Alkosh" (MD)
}
TWRTE.lootIds = {
      [87703] = "", --Warrior's Dulled Coffer
      [87708] = "", --Warrior's Honed Coffer
      [139665] = "", --Warrior's Dulled Coffer
      [139669] = "", --Warrior's Honed Coffer
      [87702] = "", --Mage's Ignorant Coffer
      [87707] = "", --Mage's Knowledgeable Coffer
      [139664] = "", --Mage's Ignorant Coffer
      [139668] = "", --Mage's Knowledgeable Coffer
      [81187] = "", --Serpent's Languid Coffer
      [81188] = "", --Serpent's Coiled Coffer
      [87705] = "", --Serpent's Languid Coffer
      [87706] = "", --Serpent's Coiled Coffer
      [139666] = "", --Serpent's Languid Coffer
      [139667] = "", --Serpent's Coiled Coffer
      [94089] = "", --Dro-m'Athra's Burnished Coffer
      [94090] = "", --Dro-m'Athra's Shining Coffer
      [139670] = "", --Dro-m'Athra's Burnished Coffer
      [139671] = "", --Dro-m'Athra's Shining Coffer
      [126130] = "", --Fabricant's Burnished Coffer
      [126131] = "", --Fabricant's Shining Coffer
      [139672] = "", --Fabricant's Burnished Coffer
      [139673] = "", --Fabricant's Shining Coffer
      [134585] = "", --Saint's Beatified Coffer
      [134586] = "", --Saint's Sanctified Coffer
      [139674] = "", --Saint's Beatified Coffer
      [139675] = "", --Saint's Sanctified Coffer
      [138711] = "", -- Welkynar's Grounded Coffer
      [138712] = "", -- Welkynar's Soaring Coffer
      [141738] = "", -- Welkynar's Grounded Coffer
      [141739] = "", -- Welkynar's Soaring Coffer
	  [151970] = "", -- Dragon God's Time-Worn Hoard
	  [151971] = "" -- Dragon God's Perfected Hoard
}

--saved data
TWRTE.data = nil

--turn a number representing seconds into a human readable string
--ex: 123456 == 1d 10h 17m 36s
local function secondsToCooldownString(seconds)
  local cooldownString, days, hours, minutes

  --get days, hours, and minutes
  days = zo_floor(seconds / TWRTE.DAY_IN_SECONDS)
  seconds = seconds % TWRTE.DAY_IN_SECONDS
  hours = zo_floor(seconds / TWRTE.HOUR_IN_SECONDS)
  seconds = seconds % TWRTE.HOUR_IN_SECONDS
  minutes = zo_floor(seconds / TWRTE.MINUTE_IN_SECONDS)
  seconds = seconds % TWRTE.MINUTE_IN_SECONDS

  cooldownString = ""

  --only add a part to the string if it is greater than 0
  if days > 0 then cooldownString = cooldownString..days.."d " end
  if hours > 0 then cooldownString = cooldownString..hours.."h " end
  if minutes > 0 then cooldownString = cooldownString..minutes.."m " end
  if seconds > 0 then cooldownString = cooldownString..seconds.."s" end

  return cooldownString
end

local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function getTrialName(questId)
  local lookup = {
    [5087] = "Hel Ra Citadel",
    [5102] = "Aetherian Archive",
    [5171] = "Sanctum Ophidia",
    [5352] = "Maw of Lorkaj",
    [5894] = "Halls of Fabrication",
    [6090] = "Asylum Sanctorium",
	[6192] = "Cloudrest",
	[6353] = "Sunspire"
  }

  return lookup[questId]
end

local function getCooldownInfo()
  local cooldownInfo = {}

  --for each character
  for characterId in pairs(TrialsWeeklyResetTrackerExtendedSavedVariables["characters"]) do
    cooldownInfo[TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][characterId]["name"]] = {}

    --for each quest saved to this character's cooldown data
    for questId, cooldownEnd in pairs(TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][characterId]["coffers"]) do
      local trialName = getTrialName(questId)
      local currentTime = GetTimeStamp()

      if cooldownEnd <= currentTime then
        cooldownInfo[TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][characterId]["name"]][trialName] = 0
      else
        cooldownInfo[TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][characterId]["name"]][trialName] = cooldownEnd - currentTime
      end
    end
  end

  return cooldownInfo
end

function TWRTE_displayCooldownInfoInChat()
  local cooldownInfo = getCooldownInfo()

  for characterName in pairs(cooldownInfo) do
    if tablelength(cooldownInfo[characterName]) > 0 then
      d(characterName)
    end

    for trialName in pairs(cooldownInfo[characterName]) do
      local timerEnd = cooldownInfo[characterName][trialName]

      if timerEnd <= 0 then
        d("- "..trialName..": available.")
      else
        d("- "..trialName..": "..secondsToCooldownString(timerEnd)..".")
      end
    end
  end
end
SLASH_COMMANDS["/twrte"] = TWRTE_displayCooldownInfoInChat

function TWRTE_toggleDebug()
  if TWRTE.data["debug"] then
    d("[TWRTE] Debug mode disabled.")
    TWRTE.data["debug"] = false
  else
    d("[TWRTE] Debug mode enabled.")
    TWRTE.data["debug"] = true
  end
end
SLASH_COMMANDS["/twrtedebug"] = TWRTE_toggleDebug

local function logEvent(event)
  if not TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["eventslog"]["config"]["enabled"] then return end

  for i=TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["eventslog"]["config"]["amount"]-1,1,-1
  do
    if TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["eventslog"]["logs"][i] then
      TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["eventslog"]["logs"][i+1] = TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["eventslog"]["logs"][i]
    end
  end

  TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["eventslog"]["logs"][1] = event
end

local function updateCooldownInfo()
  --questIds and their matching lootIds
  local lookup = {
    --Hel Ra Citadel, "Assaulting the Citadel"
    [5087] = {
      [87703] = "", --Warrior's Dulled Coffer
      [87708] = "", --Warrior's Honed Coffer
      [139665] = "", --Warrior's Dulled Coffer
      [139669] = "" --Warrior's Honed Coffer
    },
    --Aetherian Archive, "The Mage's Tower"
    [5102] = {
      [87702] = "", --Mage's Ignorant Coffer
      [87707] = "", --Mage's Knowledgeable Coffer
      [139664] = "", --Mage's Ignorant Coffer
      [139668] = "" --Mage's Knowledgeable Coffer
    },
    --Sanctum Ophidia, "The Oldest Ghost"
    [5171] = {
      [81187] = "", --Serpent's Languid Coffer
      [81188] = "", --Serpent's Coiled Coffer
      [87705] = "", --Serpent's Languid Coffer
      [87706] = "", --Serpent's Coiled Coffer
      [139666] = "", --Serpent's Languid Coffer
      [139667] = "" --Serpent's Coiled Coffer
    },
    --Maw of Lorkaj, "Into the Maw"
    [5352] = {
      [94089] = "", --Dro-m'Athra's Burnished Coffer
      [94090] = "", --Dro-m'Athra's Shining Coffer
      [139670] = "", --Dro-m'Athra's Burnished Coffer
      [139671] = "" --Dro-m'Athra's Shining Coffer
    },
    --Halls of Fabrication, "Forging the Future"
    [5894] = {
      [126130] = "", --Fabricant's Burnished Coffer
      [126131] = "", --Fabricant's Shining Coffer
      [139672] = "", --Fabricant's Burnished Coffer
      [139673] = "" --Fabricant's Shining Coffer
    },
    --Asylum Sanctorium, "Saint's Mercy"
    [6090] = {
      [134585] = "", --Saint's Beatified Coffer
      [134586] = "", --Saint's Sanctified Coffer
      [139674] = "", --Saint's Beatified Coffer
      [139675] = "" --Saint's Sanctified Coffer
    },
    -- Cloudrest, "Woe of the Welkynars"
    [6192] = {
      [138711] = "", -- Welkynar's Grounded Coffer
      [138712] = "", -- Welkynar's Soaring Coffer
      [141738] = "", -- Welkynar's Grounded Coffer
      [141739] = "" -- Welkynar's Soaring Coffer
    },
    -- Sunspire, "The Return of Alkosh"
	[6353] = {
	  [151970] = "", -- Dragon God's Time-Worn Hoard
	  [151971] = "" -- Dragon God's Perfected Hoard -- Guessed Item ID.
	}
  }

  --only continue if both quest and loot ids are initialized
  if not TWRTE.lastQuestId or not TWRTE.lastLootId then return end

  --only continue if we have matching information
  if not lookup[TWRTE.lastQuestId][TWRTE.lastLootId] then return end

  --get timestamps for comparison
  local lootTimestamp = tonumber(TWRTE.lootIds[TWRTE.lastLootId])
  local questTimestamp = tonumber(TWRTE.questIds[TWRTE.lastQuestId])

  --make sure they exist
  if not lootTimestamp or not questTimestamp then return end

  --calculate difference
  local difference = zo_abs(lootTimestamp - questTimestamp)

  --update cooldown info if difference is within acceptable margin
  if difference < TWRTE.MAX_DIFFERENCE then
    logEvent(GetTimeStamp()..": timer reset for quest "..TWRTE.lastQuestId.." (item "..TWRTE.lastLootId..")")

    --ensure there is a place to save cooldown
    TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["coffers"] = TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["coffers"] or {}

    --save the current time plus one week for the cooldown
    TrialsWeeklyResetTrackerExtendedSavedVariables["characters"][TWRTE.characterId]["coffers"][TWRTE.lastQuestId] = GetTimeStamp() + TWRTE.WEEK_IN_SECONDS

    --reset
    TWRTE.lootIds[TWRTE.lastLootId] = ""
    TWRTE.lastLootId = nil
    TWRTE.questIds[TWRTE.lastQuestId] = ""
    TWRTE.lastQuestId = nil
  end
end

--triggered when someone in the group loots something
local function lootReceived(eventCode, receivedBy, itemName, quantity, itemSound, lootType, receivedBySelf, isPickpocketLoot, questItemIconPath, itemId)
  --only continue if the event was triggered for the player
  if not receivedBySelf then return end

  if TWRTE.data["debug"] then
    d("[TWRTE] Looted "..itemName.." ("..itemId..") x"..quantity)
  end

  --if it is an item we're interested in
  if TWRTE.lootIds[itemId] then
    logEvent(GetTimeStamp()..": looted "..quantity.." "..itemName.." ("..itemId..")")

    --save timestamp and the itemId
    TWRTE.lootIds[itemId] = GetTimeStamp()
    TWRTE.lastLootId = itemId
  end

  --update the cooldown info
  updateCooldownInfo()
end
EVENT_MANAGER:RegisterForEvent("TWRTE_LOOT_RECEIVED", EVENT_LOOT_RECEIVED, lootReceived)

--triggered on quest complete or abandon
local function questRemoved(eventCode, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questId)
  --only continue if quest is complete
  if not isCompleted then return end

  local questName = GetCompletedQuestInfo(questId)

  if TWRTE.data["debug"] then
    d("[TWRTE] Completed quest "..questName.." ("..questId..")")
  end

  --if it is a quest we're interested in
  if TWRTE.questIds[questId] then
    logEvent(GetTimeStamp()..": completed quest "..questName.." ("..questId..")")

    --save timestamp and the questId
    TWRTE.questIds[questId] = GetTimeStamp()
    TWRTE.lastQuestId = questId
  end

  --this is probably unnecessary, but in the event the loot is received before the quest is "completed" we'll call here as well
  updateCooldownInfo()
end
EVENT_MANAGER:RegisterForEvent("TWRTE_QUEST_REMOVED", EVENT_QUEST_REMOVED, questRemoved)

local function migrateVersion1ToVersion2(data)
  for characterId in pairs(data["characters"]) do
    data["characters"][characterId]["lastCompletedQuest"] = {}
    data["characters"][characterId]["lastCompletedQuest"]["id"] = -1
    data["characters"][characterId]["lastCompletedQuest"]["name"] = ""
    data["characters"][characterId]["lastLootedItemId"] = -1
  end

  data["version"] = 2
end

local function migrateVersion2ToVersion3(data)
  for characterId in pairs(data["characters"]) do
    data["characters"][characterId]["lastCompletedQuest"] = nil
    data["characters"][characterId]["lastLootedItemId"]  = nil

    data["characters"][characterId]["eventslog"] = {}
    data["characters"][characterId]["eventslog"]["config"] = {}
    data["characters"][characterId]["eventslog"]["config"]["amount"] = 100
    data["characters"][characterId]["eventslog"]["config"]["enabled"] = true
    data["characters"][characterId]["eventslog"]["logs"] = {}
  end

  data["version"] = 3
end

local function migrateVersion3ToVersion4(data)
  for characterId in pairs(data["characters"]) do
    data["characters"][characterId]["coffers"] = {}

    for questId, lootTable in pairs(data["characters"][characterId]["quests"]) do
      local longestTimer = 0

      for lootId, cooldownEnd in pairs(lootTable) do
        if cooldownEnd > longestTimer then
          longestTimer = cooldownEnd
        end
      end

      data["characters"][characterId]["coffers"][questId] = longestTimer
    end

    data["characters"][characterId]["quests"] = nil
  end

  data["version"] = 4
end

local function migrateVersion4ToVersion5(data)
  data["debug"] = false

  data["version"] = 5
end

local function addonLoaded(eventCode, addonName)
  if addonName ~= "TrialsWeeklyResetTrackerExtended" then return end

  ZO_CreateStringId("SI_BINDING_NAME_TWRTE_DISPLAY_CHAT", "Display in chat")

  --setup saved variables
  TrialsWeeklyResetTrackerExtendedSavedVariables = TrialsWeeklyResetTrackerExtendedSavedVariables or {}
  TWRTE.data = TrialsWeeklyResetTrackerExtendedSavedVariables
  TWRTE.data["version"] = TWRTE.data["version"] or 5

  if TWRTE.data["version"] == 1 then
    migrateVersion1ToVersion2(TWRTE.data)
  end

  if TWRTE.data["version"] == 2 then
    migrateVersion2ToVersion3(TWRTE.data)
  end

  if TWRTE.data["version"] == 3 then
    migrateVersion3ToVersion4(TWRTE.data)
  end

  if TWRTE.data["version"] == 4 then
    migrateVersion4ToVersion5(TWRTE.data)
  end

  TWRTE.data["debug"] = TWRTE.data["debug"] or false
  TWRTE.data["characters"] = TWRTE.data["characters"] or {}
  TWRTE.data["characters"][TWRTE.characterId] = TWRTE.data["characters"][TWRTE.characterId] or {}
  TWRTE.data["characters"][TWRTE.characterId]["coffers"] = TWRTE.data["characters"][TWRTE.characterId]["coffers"] or {}
  TWRTE.data["characters"][TWRTE.characterId]["name"] = TWRTE.characterName
  TWRTE.data["characters"][TWRTE.characterId]["eventslog"] = TWRTE.data["characters"][TWRTE.characterId]["eventslog"] or {}
  TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"] = TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"] or {}
  TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"]["amount"] = TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"]["amount"] or 100
  TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"]["enabled"] = TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"]["enabled"] or true
  TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["logs"] = TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["logs"] or {}

  --remove extra logs
  if tablelength(TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["logs"]) > TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"]["amount"] then
    for i=tablelength(TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["logs"]),TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["config"]["amount"]+1,-1
    do
      TWRTE.data["characters"][TWRTE.characterId]["eventslog"]["logs"][i] = nil
    end
  end
end
EVENT_MANAGER:RegisterForEvent("TWRTE_ADDON_LOADED", EVENT_ADD_ON_LOADED, addonLoaded)