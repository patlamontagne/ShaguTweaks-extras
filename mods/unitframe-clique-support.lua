local _G = ShaguTweaks.GetGlobalEnv()
local T = ShaguTweaks.T

local module = ShaguTweaks:register({
  title = T["Clique Support for Unit Frames"],
  description = T["Add Clique support for player and target unit frames to enable spell casting on click."],
  expansions = { ["vanilla"] = true, ["tbc"] = false },
  category = T["Clique Support"],
  maintainer = "@patlamontagne (GitHub)",
  enabled = true,
  config = {
    ["clique.player"] = true,
    ["clique.target"] = true,
    ["clique.targettarget"] = true,
    ["clique.raid"] = true,
  }
})

-- Helper function to add Clique support to a frame
local function AddCliqueSupport(frame, unitstr)
  if not frame or not unitstr then return end
  
  -- Set the unit property for Clique compatibility
  frame.unit = unitstr
  
  -- Register for all mouse buttons that Clique might use
  frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp', 'Button4Up', 'Button5Up')
  
  -- Store the original OnClick script if it exists
  local originalOnClick = frame:GetScript("OnClick")
  
  -- Create new OnClick handler that integrates with Clique
  frame:SetScript("OnClick", function()
    local button = arg1
    
    -- FIRST: Let Clique handle the click if it's available and has bindings
    if Clique and Clique.OnClick then
      -- Call Clique's OnClick handler first
      local handled = Clique:OnClick(button, unitstr)
      if handled then
        -- Clique handled the click, so we're done
        return
      end
    end
    
    -- If Clique didn't handle it, call the original OnClick if it exists
    if originalOnClick then
      originalOnClick()
    end
  end)
  
  -- Register with Clique if it's available
  if Clique and Clique.RegisterFrame then
    Clique:RegisterFrame(frame)
  end
end

-- Function to register frames with Clique after they're created
local function RegisterFramesWithClique()
  -- Player Frame
  if PlayerFrame and module.config["clique.player"] then
    AddCliqueSupport(PlayerFrame, "player")
  end
  
  -- Target Frame
  if TargetFrame and module.config["clique.target"] then
    AddCliqueSupport(TargetFrame, "target")
  end
  
  -- Target of Target Frame (if it exists)
  if TargetofTargetFrame and module.config["clique.targettarget"] then
    AddCliqueSupport(TargetofTargetFrame, "targettarget")
  end

end

module.enable = function(self)
  -- Wait for frames to be created, then add Clique support
  local frameWatcher = CreateFrame("Frame")
  frameWatcher:SetScript("OnUpdate", function()
    -- Check if the main unit frames exist
    if PlayerFrame and TargetFrame then
      RegisterFramesWithClique()
      this:SetScript("OnUpdate", nil) -- Stop checking once frames are found
    end
  end)
  
  -- Also register when Clique loads
  local cliqueWatcher = CreateFrame("Frame")
  cliqueWatcher:RegisterEvent("ADDON_LOADED")
  cliqueWatcher:SetScript("OnEvent", function()
    if arg1 == "Clique" then
      -- Small delay to ensure frames are ready
      local delayFrame = CreateFrame("Frame")
      delayFrame:SetScript("OnUpdate", function()
        RegisterFramesWithClique()
        this:SetScript("OnUpdate", nil)
      end)
    end
  end)
  
  -- Check if Clique is already loaded
  if Clique then
    local delayFrame = CreateFrame("Frame")
    delayFrame:SetScript("OnUpdate", function()
      RegisterFramesWithClique()
      this:SetScript("OnUpdate", nil)
    end)
  end
end

-- Global Clique registration function for raid frames
local function RegisterRaidFramesWithClique()
  if not module.config["clique.raid"] then return end
  
  local raid = ShaguTweaksRaidFrame
  if Clique and raid and raid.cluster and raid.cluster.frames then
    for id = 1, 40 do
      local frame = raid.cluster.frames[id]
      if frame and Clique.RegisterFrame then
        Clique:RegisterFrame(frame)
      end
    end
  end
end

-- Global Clique watcher for raid frames
local raidCliqueWatcher = CreateFrame("Frame")
raidCliqueWatcher:RegisterEvent("ADDON_LOADED")
raidCliqueWatcher:SetScript("OnEvent", function()
  if arg1 == "Clique" then
    RegisterRaidFramesWithClique()
  end
end)

-- Also check if Clique is already loaded for raid frames
if Clique then
  RegisterRaidFramesWithClique()
end
