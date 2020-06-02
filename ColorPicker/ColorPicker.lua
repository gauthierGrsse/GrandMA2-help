-- ColorPicker v5 - Florian ANAYA - 2020
-- https://github.com/FlorianANAYA/GrandMA2-help
-- This plugin will create a color picker in a layout view for several
-- groups of fixtures. It uses the Appearance of the macros to display
-- colors, so there is no need to mess with images.
-- The groups are defined by the user below.
-- The plugin will create master macros that change the color of all fixtures.
-- It also supports layers, so that the user can have several masters.
-- It uses executors (defined by the user) and macros. The first available
-- continuous range of macros is automatically selected.
-- It is possible to include fixtures that only have a color wheel, GrandMA
-- will pick the one that looks the more like the one asked
-- Note: any line that starts with -- is a comment and is not used by the plugin.
-- Don't forget that, if the plugin doesn't work and shows no message at all,
-- you might have made a typo in the config, you'll find more info in the
-- system monitor.
-- Tested GrandMA2 version: 3.7

-----------------------
-- Start of settings --
-----------------------

-- List of group IDs that will be used in the color picker.
-- Group IDs must be separated by commas ( , ). It is possible to use group
-- names instead of IDs, don't forget to include quotes (ie. {1, 2, "Mac Vipers", 8} )
-- Sub groups can be created, they will have separate masters (ie. {1,2,{3,4,5}} )
local groups = { 1,2,5,6 }

-- ID of first executor to use (There will be as many executors used as
-- there are groups declared above)
-- If one of the executors already exists, the program will not execute.
-- It must include the exec page, the format is X.XXX (ie. 1.101, 5.001 or 7.015)
local execId = 1.101

-- The ID of the layout to be used.
-- If a layout already exists at this ID, it will be used anyway
-- without affecting other elements already present, but the macros
-- may overlap those other elements.
local layoutId = 1

-- The fade time between colors (in seconds)
local fadeTime = 1

-- This is the list of colors that will be used in the color picker.
-- they can be changed and deleted. New colors can be added.
-- They are defined by RGB or swatchbook entry (gel). A list of all gels
-- can be found in the color picker.
--  If a swatchbook color is defined, it will be used instead of RGB value.
-- Nevertheless, RGB values must be present for the macro color appearance.
-- RGB colors are defined as percent. Swatchbook colors can be defined by
-- name (ie. "MA colors"."White") or by number (ie. 1.1), they must be enclosed
-- by 'quotes' like this: '"lee"."primary red"' or '8.106'.
-- Names can be anything you like and can contain spaces,
-- but must be present and there cannot be duplicate.
-- White and other colors cannot be defined, but they will be used anyway.
-- GrandMA2 will translate the RGB values you provide to whatever is
-- available in the fixture (RGBW, RGBWA+UV, or anything that is available).
local colors =
{
  {['name'] = 'White CTO', ['red'] = 100, ['green'] = 100, ['blue'] = 70, ["swatchbook"] = '"Lee"."full CT orange"'},
  {['name'] = 'White CTB', ['red'] = 100, ['green'] = 100, ['blue'] = 100, ["swatchbook"] = '8.120'},
  {['name'] = 'Red', ['red'] = 100, ['green'] = 0, ['blue'] = 0},
  {['name'] = 'Orange', ['red'] = 100, ['green'] = 50, ['blue'] = 0,},
  {['name'] = 'Yellow', ['red'] = 100, ['green'] = 100, ['blue'] = 0,},
  {['name'] = 'Lime', ['red'] = 50, ['green'] = 100, ['blue'] = 0,},
  {['name'] = 'Green', ['red'] = 0, ['green'] = 100, ['blue'] = 0,},
  {['name'] = 'Light green', ['red'] = 0, ['green'] = 100, ['blue'] = 50},
  {['name'] = 'Lavender', ['red'] = 0, ['green'] = 50, ['blue'] = 100},
  {['name'] = 'Cyan', ['red'] = 0, ['green'] = 100, ['blue'] = 100},
  {['name'] = 'Blue', ['red'] = 0, ['green'] = 0, ['blue'] = 100},
  {['name'] = 'Violet', ['red'] = 50, ['green'] = 0, ['blue'] = 100},
  {['name'] = 'Magenta', ['red'] = 100, ['green'] = 0, ['blue'] = 100},
  {['name'] = 'Pink', ['red'] = 100, ['green'] = 0, ['blue'] = 50},
}

-- Layout settings
local startX = 0
local startY = 0
local offsetX = 1
local offsetY = 1.1

--------------------------------
-- End of settings            --
-- Don't touch anything below --
--------------------------------

-- The first macro ID used
local firstMacroId = 1
-- The current macro being used (also the current macro being searched empty)
local currentMacroId = 1
-- The ID of the last macro that is going to be used
local lastMacroId = 1
-- The total number of macros that need to be created
local nbNeededMacros = 0

-- ¨Page of the execs (all execs will be on this page)
local execPage = 0
-- The total number of execs needed
local nbNeededExecs = 0
-- The ID of the first exec to be used
local firstExecId = 0
-- The current exec being used by the plugin
local currentExecId = firstExecId
-- Defines the last exec ID used
local lastExecId = 0

-- Position of the current element in the layout
local x = startX
local y = startY

-- number of colors in the color picker
local nbColors = #colors
-- The handle of the progress bar
local progressBarHandle = 0
-- Becomes true at the end of the script, to avoid the user to execute the
-- plugin twice without a reset of the variables
local alreadyExecuted = false
-- Predeclaration of functions
local addQuotes, createMacroRowAll, treatGroup, treatGroupOrArray, countNeededMacroNbInGroup, findFirstAvailableMacro, verifyFreeExecs, verifyColors, verifyGroup, createGels, createLayout, verifyLayout

-- If the argument is a string, this functions add quotes
-- at the beginning and end of the string if it doesn't already have them.
-- If the argument is anything else, the function just uses tostring on it
addQuotes = function(str)
  if (type(str) == "string") then
    if (string.sub(str, 1, 1) ~= '"') then
      str = '"' .. str
    end
    local length = string.len(str)
    if (string.sub(str, length, length) ~= '"') then
      str = str .. '"'
    end
  else
    str = tostring(str)
  end
  return str
end

-- Creates a row of master macros 
createMacroRowAll = function()
  x = startX + offsetX
  y = y + offsetY
  for colorIndex, colorValues in pairs(colors) do 
    gma.cmd('Store Macro 1.' .. tostring(currentMacroId) .. ' "' .. "All " .. colorValues["name"] .. '"')
    gma.cmd('Appearance Macro 1.' .. tostring(currentMacroId) .. ' /r=' .. tostring(colorValues["red"]) .. ' /g=' .. tostring(colorValues["green"]) .. ' /b=' .. tostring(colorValues["blue"]))
    gma.cmd('Assign Macro 1.' .. tostring(currentMacroId) .. ' Layout ' .. tostring(layoutId) .. ' /x=' .. tostring(x) .. ' /y=' .. tostring(y))
    x = x + offsetX
    currentMacroId = currentMacroId + 1
    gma.gui.progress.set(progressBarHandle, currentMacroId - firstMacroId)
    gma.sleep(0.05)
  end 
end

treatGroup  = function(groupPoolId)
  local groupFirstMacroId = currentMacroId -- ID of the first macro of this row
  local lastMacroId = currentMacroId + nbColors -1 -- ID of the last macro of this row
  gma.cmd("ClearAll")
  gma.cmd("Group " .. addQuotes(groupPoolId))
  x = startX
  y = y + offsetY
  gma.cmd('Assign Group ' .. addQuotes(groupPoolId) .. ' Layout ' .. tostring(layoutId) .. ' /x=' .. tostring(x) .. ' /y=' .. tostring(y))
  
  local cueNb = 1
  -- We iterate over all the colors of the list, for every one of them,
  -- We set the color in the programmer and store it in the cue in the sequence
  -- We assign the command to the cue to change the Appearance of macros
  -- We create the macro that will trigger the cue
  for colorId, colorValues in ipairs(colors) do
    gma.cmd('At gel ' .. colorValues["swatchbook"])
    gma.cmd('Store Cue ' .. tostring(cueNb) .. ' Executor ' .. tostring(execPage) .. '.' .. tostring(currentExecId))
    gma.cmd('Label Cue ' .. tostring(cueNb) .. ' Executor ' .. tostring(execPage) .. '.' .. tostring(currentExecId) .. ' "' ..colorValues["name"] .. '"')
    gma.cmd('Assign Cue ' .. tostring(cueNb) .. ' Executor ' .. tostring(execPage) .. '.' .. tostring(currentExecId) .. ' /fade=' .. tostring(fadeTime) .. ' /CMD="Label Macro 1.' .. tostring(groupFirstMacroId) .. ' Thru 1.' .. tostring(lastMacroId) .. ' _ ; Label Macro 1.' .. tostring(currentMacroId) .. ' VVVVVVVVVVVV"')
    gma.cmd('Store Macro 1.' .. tostring(currentMacroId))
    gma.cmd('Label Macro 1.' .. tostring(currentMacroId) .. ' "_"')
    gma.cmd('Store Macro 1.' .. tostring(currentMacroId) .. '.1')
    gma.cmd('Assign Macro 1.' .. tostring(currentMacroId) .. '.1 /cmd="Goto Cue ' .. tostring(cueNb) .. ' Executor ' .. tostring(execPage) .. '.' .. tostring(currentExecId))
    gma.cmd('Appearance Macro 1.' .. tostring(currentMacroId) .. ' /r=' .. tostring(colorValues["red"]) .. ' /g=' .. tostring(colorValues["green"]) .. ' /b=' .. tostring(colorValues["blue"]))
    x = x + offsetX
    gma.cmd('Assign Macro 1.' .. tostring(currentMacroId) .. ' Layout ' .. tostring(layoutId) .. ' /x=' .. tostring(x) .. ' /y=' .. tostring(y))
    cueNb = cueNb + 1
    currentMacroId = currentMacroId + 1
    gma.gui.progress.set(progressBarHandle, currentMacroId - firstMacroId)
    gma.sleep(0.05)
  end
  gma.cmd('Label Executor ' .. tostring(execPage) .. '.' .. tostring(currentExecId) .. ' "Colors ' .. gma.show.getobj.label(gma.show.getobj.handle("Group ".. tostring(groupPoolId))) .. '"')
  currentExecId = currentExecId + 1
end

-- Recursive function that treats a group ID or an array of group ID
treatGroupOrArray = function(groupNbOrArray)
  if (type(groupNbOrArray) == "table") then
    local macroIdOfAllRow = currentMacroId -- We store the ID of the first master macro, before the global variable "currentMacroId" is changed by the function
    local macroIdsOfGroups = {} -- table that will hold all the first macro number of the picker of the lines of this group
    createMacroRowAll() -- We create the master macros
    for index,groupPoolId in ipairs(groupNbOrArray) do
      macroIdsOfGroups[index] = currentMacroId -- We add the ID of this macro to our macro list 
      treatGroupOrArray(groupPoolId)
    end
    -- We fill the master macro lines
    for colorIndex,colorValues in ipairs(colors) do
      -- The command should only contain a + sign if necessary
      local cmd = "Macro "
      local first = true
      for macroIndex, macroId in ipairs(macroIdsOfGroups) do
        if (not first) then
          cmd = cmd .. " + "
        end
        cmd = cmd .. tostring(macroId + colorIndex -1)
        first = false
      end
      gma.cmd('Store Macro 1.' .. tostring(macroIdOfAllRow + colorIndex - 1) .. '.1')
      gma.cmd('Assign Macro 1.' .. tostring(macroIdOfAllRow + colorIndex - 1) .. '.1 /cmd="' .. cmd .. '"')
    end
  else
    -- if the paramter is not a table, we treat it as a group
    treatGroup(groupNbOrArray)
  end
end

-- Recursive function that counts the total number of macros needed for a table
-- of group ID using the amount of colors per group.
countNeededMacroNbInGroup = function(groupNbOrArray)
  nbNeededMacros = nbNeededMacros + nbColors -- we add the number of colors
  if (type(groupNbOrArray) == "table") then
    for groupIndex, value in ipairs(groupNbOrArray) do
      countNeededMacroNbInGroup(value)
    end 
  else
    nbNeededExecs = nbNeededExecs + 1
  end
  lastExecId = firstExecId + nbNeededExecs - 1
end

-- Count the number of total needed macros and finds the first available
-- macro ID that has a suffisant following free space.
-- Also verifies that the maximum macro ID has not been reached.
findFirstAvailableMacro = function()
  -- Count the number of needed macros
  countNeededMacroNbInGroup (groups)
  local empty = false
  while (not empty) do
    empty = true
    for testedMacroNb=currentMacroId,currentMacroId+nbNeededMacros-1,1 do
      local handle = gma.show.getobj.handle("Macro "..tostring(testedMacroNb))
      empty = handle == nil
      if (not empty) then
        currentMacroId = testedMacroNb + 1
        break
      end
    end 
  end
  firstMacroId = currentMacroId
  lastMacroId = firstMacroId + nbNeededMacros-1
  -- We check that we have not reached the maximum macro ID.
  -- I tested and found that 10000 is the maximum, but this value may
  -- evolve in the future or between different installation, so we test
  -- by storing the last macro and verifying that it exists.
  gma.cmd("Store Macro 1." .. tostring(lastMacroId))
  local macroHandle = gma.show.getobj.handle("Macro 1." .. tostring(lastMacroId))
  gma.cmd("Delete Macro 1." .. tostring(lastMacroId))
  if (macroHandle == nil) then
    gma.gui.msgbox("Not enough macros available", "The maximum number of macros has been reached.\nThere are not enough available macros to create the Color Picker.")
    return false
  end
  return true
end

-- Verifys if there is a suffisent number of unsuned execs
-- counting from the one specified by the user
verifyFreeExecs = function()
  local allFree = true
  for execNb=firstExecId,firstExecId+nbNeededExecs-1,1 do
    local execHandle = gma.show.getobj.handle("Executor " .. tostring(execPage) .. '.' .. tostring(execNb))
    if (execHandle == nil) then
      gma.feedback("Executor " .. tostring(execPage) .. '.' .. tostring(execNb) .. " is not used.")
    else
      gma.feedback("Executor " .. tostring(execPage) .. '.' .. tostring(execNb) .. " is used")
      allFree = false
    end
  end
  return allFree
end

-- verifies that all colors provided have RGB and that swatchbooks
-- colors provided exist
verifyColors = function()
  for colorIndex,colorValues in ipairs(colors) do
    if (type(colorValues) ~= "table") then
      gma.gui.msgbox("Incorrect values", "Your color definition is incorrect, please check")
      return false
    end
    if (type(colorValues["name"]) ~= "string") then
      gma.gui.msgbox("Missing value", "All colors must have a name. \nColor n°" .. tostring(colorIndex) .. " doesn't have a (proper) name")
      return false
    end
    for colorIndex = 1,#colors-1,1 do
      for secondColorIndex = colorIndex+1,#colors,1 do
        if (colors[colorIndex]["name"] == colors[secondColorIndex]["name"]) then
          gma.gui.msgbox("Invalid color name", "There cannot be two colors with the same name (' " .. colors[colorIndex]["name"] .. " ')")
          return false
        end
      end
    end
    if (type(colorValues["red"]) ~= "number" or type(colorValues["green"]) ~= "number" or type(colorValues["blue"]) ~= "number") then
      gma.gui.msgbox("Missing value", "All colors must have RGB values (even if you are using a swatchbook value).\nColor ' " .. colorValues["name"] .. " ' is missing red, green or blue.")
      return false
    end
    if (type(colorValues["swatchbook"]) ~= "nil") then
      if (type(colorValues["swatchbook"]) ~= "string") then
        gma.gui.msgbox("Incorrect value", "The gel of the color ' " .. colorValues["name"] .. " ' is not correct.\nCheck that you correctly insterted 'quotes'")
        return false
      end
      if (gma.show.getobj.handle('gel ' .. colorValues["swatchbook"]) == nil) then
        gma.gui.msgbox("Unknown gel", "The gel ' " .. colorValues["swatchbook"] .. " ' is unknown in color ' " .. colorValues["name"] .. " '")
        return false
      end
    end
  end
  return true
end

verifyGroup = function(groupOrArray)
  if (type(groupOrArray) == "table") then
    for groupindex,groupId in pairs(groupOrArray) do
      if (not verifyGroup(groupId)) then
        return false
      end
    end
  else
    local handle = gma.show.getobj.handle("group " .. addQuotes(groupOrArray))
    if (handle == nil) then
      gma.gui.msgbox("Unknown group", "One of the specified group doesn't exists.\nThe group ' " .. tostring(groupOrArray) .. " ' coulnd't be found. Please check.")
      return false
    end
  end
  return true
end

verifyLayout = function()
  if (type(layoutId) ~= "number") then
    gma.gui.msgbox("Invalid layout ID", "The specified layout ID is not correct, please edit the plugin to change the specified value")
    return false
  end
  if (layoutId <= 0) then
    gma.gui.msgbox("Invalid layout ID", "The specified layout ID is not correct, please edit the plugin to change the specified value")
    return false
  end
  local layoutHandle = gma.show.getobj.handle("Layout " .. tostring(layoutId))
  if (layoutHandle == nil) then
    -- We check that we have not reached the maximum layout ID.
    -- I tested and found that 10000 is the maximum, but this value may
    -- evolve in the future or between different installation, so we test
    -- by storing the provided layout and verifying that it exists.
    gma.cmd("Store Layout " .. tostring(layoutId))
    layoutHandle = gma.show.getobj.handle("Layout " .. tostring(layoutId))
    gma.cmd("Delete Layout " .. tostring(layoutId))
    if (layoutHandle == nil) then
      gma.gui.msgbox("Invalid layout ID", "The provided layout ID is too high")
      return false
    end
  end
  return true
end

createGels = function()
  gma.cmd('Delete Gel "ColorPicker"')
  gma.cmd('Store Gel "ColorPicker"')
  for colorIndex,colorValues in ipairs(colors) do
    if (type(colorValues["swatchbook"]) == "nil") then
      gma.cmd('Store Gel "ColorPicker"."' .. colorValues["name"] .. '"')
      gma.cmd('Assign Gel "ColorPicker"."' .. colorValues["name"] .. '" /color="' .. colorValues['red'] .. ' ' .. colorValues['green'] .. ' ' .. colorValues['blue'] .. '"')
      colorValues["swatchbook"] = '"ColorPicker"."' .. colorValues["name"] .. '"'
    end
  end
end

-- Creates and names the layout if it doesn't already exists
createLayout = function()
  local layout = gma.show.getobj.handle("Layout " .. tostring(layoutId))
  if (layout == nil) then
    gma.cmd('Store layout ' .. tostring(layoutId))
    gma.cmd('Label layout ' .. tostring(layoutId) .. '"Color Picker"')
  end
end


-- Execution of the program when the user clicks on the plugin
return function()
  -- We check that the plugin has not already been executed without a reload
  if (alreadyExecuted) then
    gma.feedback("Plugin exited: Script already executed")
    gma.gui.msgbox("Operation canceled", "The script has already been executed.\nIf you want to create a second color picker, please reload the plugin (edit the plugin and hit 'reload')")
    return
  end
  
  -- We initialize variables (in case the plugin is executed twice in a row)
  firstMacroId = 1
  currentMacroId = 1
  lastMacroId = 1
  nbNeededMacros = 0
  nbNeededExecs = 0
  x = startX
  y = startY
  
  -- We find the specified exec page and exec ID and verify they are correct
  execPage = math.floor(execId)
  firstExecId = math.tointeger(tostring((execId - execPage) * 1000))
  if (execPage <= 0 or firstExecId <= 0) then
    gma.gui.msgbox("Incorrect exec", "The specified executor " .. tostring(execId) .. " is invalid.\nIt must include the exec page, in the format X.XXX (ie. 1.101, 5.001, 10.015).")
    gma.feedback("Plugin exited: Incorrect first executor")
    return
  end
  currentExecId = firstExecId
  
  -- We search the first available macros
  progressBarHandle = gma.gui.progress.start("Creating Color Picker")
  gma.gui.progress.settext(progressBarHandle, "Searching for available macros")
  if (not findFirstAvailableMacro()) then
    gma.feedback("Plugin exited: Not enough available macros")
    gma.gui.progress.stop(progressBarHandle)
    return
  end
  gma.feedback("nbNeededMacros=" .. tostring(nbNeededMacros) .. ", nbNeededExecs=" .. tostring(nbNeededExecs))
  
  -- We verify colors
  gma.gui.progress.settext(progressBarHandle, "Verifying colors")
  if (not verifyColors()) then
    gma.feedback("Plugin exited: Incorrect colors")
    gma.gui.progress.stop(progressBarHandle)
    return
  end
  
  -- We verify groups
  gma.gui.progress.settext(progressBarHandle, "Verifying groups")
  if (not verifyGroup(groups)) then
    gma.feedback("Plugin exited: Incorrect groups")
    gma.gui.progress.stop(progressBarHandle)
    return
  end
  
  -- We verifiy the layout definition
  gma.gui.progress.settext(progressBarHandle, "Verifying layout")
  if (not verifyLayout()) then
    gma.feedback("Plugin exited: Incorrect layout")
    gma.gui.progress.stop(progressBarHandle)
    return
  end
  
  -- We verifiy that needed execs are available
  gma.gui.progress.settext(progressBarHandle, "Verifying execs")
  if (not verifyFreeExecs()) then
    gma.feedback("Plugin exited: Not enough free executors")
    gma.gui.progress.stop(progressBarHandle)
    gma.gui.msgbox("Error: Not enough free executors", "The plugin is configured to use executors " .. tostring(execPage) .. "." .. tostring(firstExecId) .. " Thru " .. tostring(execPage) .. "." .. tostring(lastExecId) .. " but they are currently in use.\nPlease delete them or change the config of the plugin so that it uses other executors.")
    return
  end
  gma.gui.progress.stop(progressBarHandle)
  
  if (not gma.gui.confirm("Color Picker", "The Color Picker is about to be created on:\n- Layout " .. tostring(layoutId) ..  "\n- Executors " .. tostring(execPage) .. "." .. tostring(firstExecId) .. " Thru " .. tostring(execPage) .. "." .. tostring(lastExecId) .. "\n- Macros " .. tostring(firstMacroId) .. " Thru " .. tostring(lastMacroId) .. "\nIf this is not correct, please edit the plugin to change those values.")) then
    gma.feedback("Plugin exited: Operation aborted by the user")
    gma.gui.msgbox("Operation canceled", "The creation of the color picker has been aborted.")
    return
  end
    
  gma.cmd("BlindEdit on")
  createLayout()
  progressBarHandle = gma.gui.progress.start("Creating Color Picker")
  gma.gui.progress.setrange(progressBarHandle, 0, nbNeededMacros)
  gma.gui.progress.settext(progressBarHandle, "Creating macros: ")
  createGels()
  treatGroupOrArray(groups)
  gma.cmd("ClearAll")
  gma.gui.progress.settext(progressBarHandle, "Finishing up")
  gma.cmd("BlindEdit Off")
  gma.cmd('Delete Gel "ColorPicker"')
  gma.gui.progress.stop(progressBarHandle)
  alreadyExecuted = true
  gma.gui.msgbox("Operation complete", "The Color Picker has been created on layout " .. tostring(layoutId))
end


