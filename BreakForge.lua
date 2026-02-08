local ADDON_NAME, ns = ...

-- ============================================================================
-- 1. BÖLÜM: ALTYAPI
-- ============================================================================

local addon = ns
addon.dbDefault = {
    BreakForge = {
        Enabled = true, Hidden = false, Mute = false, 
        Width = 300, Height = 30, IconZoom = 0.1, X = 0, Y = -150,
        
        -- Party Ayarları
        PartyEnabled = true, 
        PartyWidth = 220, 
        PartyHeight = 30, 
        PartyIconSize = 30, 
        PartySpacing = 5,
        PartyX = -250, PartyY = 0,
        
        -- Görsel Ayarlar
        Texture = "2. Smooth", 
        Font = "Friz Quadrata", 
        FontSize = 12, 
        FontOutline = "OUTLINE", -- [YENİ]
        BackgroundAlpha = 0.8, 
        BorderSize = 1, 
        BorderPosition = "OUTSIDE",
        
        -- Renkler
        ColorCooldown = "FF0000", ColorReady = "FF7700",
        NotInterruptibleColor = "808080", InterruptedColor = "00FF00",
        
        CooldownHide = false, NotInterruptibleHide = false, SoundMedia = "RaidWarning"
    }
}
addon.db = addon.dbDefault 
addon.characterClass = select(2, UnitClass("player"))

addon.Utilities = {
    HexToRGB = function(self, hex)
        if not hex then return 1,1,1,1 end
        local r, g, b = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
        return tonumber(r, 16)/255, tonumber(g, 16)/255, tonumber(b, 16)/255, 1
    end
}

local eventFrame = CreateFrame("Frame"); local eventRegistry = {}
eventFrame:SetScript("OnEvent", function(self, event, ...) if eventRegistry[event] then for _, func in ipairs(eventRegistry[event]) do func(event, ...) end end end)
addon.eventsHandler = { Register = function(self, func, event, unit) if not eventRegistry[event] then eventRegistry[event] = {}; if unit then eventFrame:RegisterUnitEvent(event, "target", "focus") else eventFrame:RegisterEvent(event) end end table.insert(eventRegistry[event], func) end }

local LibStub = { GetLocale = function() return { ["Interrupted"] = "KESILDI" } end }
local function SetAlphaFromBoolean(self, condition, trueAlpha, falseAlpha)
    local success, _ = pcall(function() if condition then self:SetAlpha(trueAlpha or 1) else self:SetAlpha(falseAlpha or 0) end end)
    if not success then self:SetAlpha(falseAlpha or 0) end
end
local function AddMixin(frame) if not frame.SetAlphaFromBoolean then frame.SetAlphaFromBoolean = SetAlphaFromBoolean end end

local function CreateDurationObject(s, e)
    local obj = {}
    obj.GetTotalDuration = function() return (e - s) / 1000 end
    obj.GetRemainingDuration = function() local t = (e - (GetTime()*1000))/1000; return (t<0) and 0 or t end
    obj.GetElapsedDuration = function() local t = ((GetTime()*1000) - s)/1000; return (t<0) and 0 or t end
    return obj
end
if not _G.UnitCastingDuration then _G.UnitCastingDuration = function(u) local _,_,_,s,e=UnitCastingInfo(u); return CreateDurationObject(s or 0,e or 0) end end
if not _G.UnitChannelDuration then _G.UnitChannelDuration = function(u) local _,_,_,s,e=UnitChannelInfo(u); return CreateDurationObject(s or 0,e or 0) end end

-- ============================================================================
-- 2. BÖLÜM: CORE MANTIK
-- ============================================================================

BreakForge = { 
    frame = nil, active = false, 
    interruptID = 0, interruptCD = 0, nextReadyTime = 0, 
    subInterrupt = nil, timer = nil, commPrefix = "BF_SYNC",
    isTesting = false, isUnlocked = false,
    -- API 12: notInterruptible "secret" olduğu için olaylarla takip ediyoruz
    targetCastShielded = false, focusCastShielded = false, displayUnit = nil
}
_G["BreakForge"] = BreakForge
local L = LibStub.GetLocale(ADDON_NAME); local MOD_KEY = "BreakForge"; local UNKNOWN_SPELL_TEXTURE = 134400

-- [VERİ] Spec Bazlı Interrupt Tablosu
local INTERRUPT_DATA = {
    WARRIOR = { DEFAULT = {id = 6552, cd = 15} },
    ROGUE   = { DEFAULT = {id = 1766, cd = 15} },
    MAGE    = { DEFAULT = {id = 2139, cd = 24} },
    DEATHKNIGHT = { DEFAULT = {id = 47528, cd = 15} },
    PALADIN = { DEFAULT = {id = 96231, cd = 15} },
    MONK    = { DEFAULT = {id = 116705, cd = 15} },
    DEMONHUNTER = { DEFAULT = {id = 183752, cd = 15} },
    EVOKER  = { DEFAULT = {id = 351338, cd = 20} },
    WARLOCK = { DEFAULT = {id = 119914, cd = 24} },
    SHAMAN  = { DEFAULT = {id = 57994, cd = 12}, [3] = {id = 57994, cd = 30} },
    PRIEST  = { DEFAULT = {id = 0, cd = 0}, [3] = {id = 15487, cd = 45} },
    HUNTER  = { DEFAULT = {id = 147362, cd = 24}, [3] = {id = 187707, cd = 15} },
    DRUID   = { DEFAULT = {id = 106839, cd = 15}, [1] = {id = 78675, cd = 60} },
}

local function LoadClassInterrupt(self)
    local class = addon.characterClass
    local data = INTERRUPT_DATA[class]
    if not data then self.interruptID = 0; self.interruptCD = 0; return end
    local specIndex = GetSpecialization() or 0
    local specData = data[specIndex] or data.DEFAULT
    if specData then self.interruptID = specData.id; self.interruptCD = specData.cd
    else self.interruptID = 0; self.interruptCD = 0 end
end

local INTERRUPT_MODIFIERS = {
    -- Death Knight: Mind Freeze
    [47528] = { 
        { talent = 378848, reduction = 2 }, -- Coldthirst (Verify ID)
        { talent = 379353, reduction = 2 }, -- Coldthirst (Alt ID)
    }
}

local function RecordInterruptUsage(self, spellID)
    if spellID == self.interruptID then 
        -- [ZERO LATENCY] Used UNIT_SPELLCAST_SENT, so we are at T=0.
        self.lastSentTime = GetServerTime()
        self.lastInteruptCastTime = GetTime() -- Heuristic Check
        self.nextReadyTime = GetTime() + self.interruptCD
        
        if BreakForge.Party then 
             -- Network Sync (Broadcast to others)
             BreakForge.Party:SendSync(spellID, self.interruptCD)
             -- Local Visual Update (Show on my screen immediately)
             BreakForge.Party:UpdateBar(UnitName("player"), spellID, self.interruptCD)
        end
    end
end

-- ...





-- [MANUEL TAKİP]
local function IsSpellReady(self)
    -- [MANUEL TAKİP]
    if self.interruptID == 0 then return false end
    if GetTime() <= self.nextReadyTime then return false end
    return true
end

local function GetInterrupter(guid) return UnitNameFromGUID(guid) end

-- Nameplate cast bar'dan kesilemezlik (asInterruptHelper gibi); secret değere dokunmadan
local function GetNamePlateCastBarShielded(unit)
    if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return nil end
    local ok, nameplate = pcall(C_NamePlate.GetNamePlateForUnit, unit, false)
    if not ok or not nameplate or not nameplate.UnitFrame or not nameplate.UnitFrame.castBar then return nil end
    local bar = nameplate.UnitFrame.castBar
    local barType = bar.barType or bar.BarType
    if barType == "uninterruptable" or barType == "UNINTERRUPTABLE" then return true end
    if barType == "interruptable" or barType == "INTERRUPTABLE" or barType == "default" then return false end
    return nil
end

local function SetBarInterruptedColor(self, interrupted)
    if interrupted then
        self.frame.statusBar:SetStatusBarColor(addon.Utilities:HexToRGB(addon.db[MOD_KEY]["InterruptedColor"]))
    else
        self.frame.statusBar:SetStatusBarColor(addon.Utilities:HexToRGB(addon.db[MOD_KEY]["ColorCooldown"]))
    end
end

local function InterruptHandler(self, guid)
    local interrupter = GetInterrupter(guid)
    self.frame.spellText:SetText(L["Interrupted"] .. ": " .. (interrupter or "Unknown"))
    SetBarInterruptedColor(self, true)
    
    -- [HEURISTIC CHECK] If we interrupt logic
    if self.interruptID > 0 and self.lastInteruptCastTime then
         if GetTime() - self.lastInteruptCastTime < 1.0 then 
              -- High Probability WE interrupted
              local mods = INTERRUPT_MODIFIERS[self.interruptID]
              local reduction = 0
              if mods then
                  for _, mod in ipairs(mods) do
                      if IsPlayerSpell(mod.talent) then
                          reduction = reduction + mod.reduction
                      end
                  end
              end
              
              if reduction > 0 then
                  self.nextReadyTime = self.nextReadyTime - reduction
                  local newDuration = self.interruptCD - reduction
                   -- [SYNC UPDATE]
                  if BreakForge.Party then 
                      BreakForge.Party:SendSync(self.interruptID, newDuration, self.lastSentTime) 
                  end
                  
                  -- [LOCAL UPDATE]
                  if self.active then
                       -- Force Update Duration
                        local startTime = (self.nextReadyTime - newDuration) * 1000
                        local endTime = self.nextReadyTime * 1000
                        self.frame.durationObj = CreateDurationObject(startTime, endTime)
                        if BreakForge.Party then BreakForge.Party:UpdateBar(UnitName("player"), self.interruptID, newDuration) end
                  end
              end
              
              self.lastInteruptCastTime = nil -- Reset to avoid double triggering
         end
    end

    self.active = false
    if self.timer then self.timer:Cancel() end
    self.timer = C_Timer.NewTimer(0.75, function() self.timer=nil; self.frame:Hide(); SetBarInterruptedColor(self, false) end)
end

local function CastsHandler(self, duration, isChannel, unit, onCastEndRefresh)
    self.displayUnit = unit
    self.frame.durationObj = duration
    self.frame.statusBar:SetMinMaxValues(0, duration:GetTotalDuration())

    self.frame:SetScript("OnUpdate", function (f)
        if self.isTesting or self.isUnlocked then return end
        if not self.active then return end
        -- API 12 uyumlu: Sadece "unit hâlâ büyü yapıyor mu?" kontrolü (isim; secret yok). Kesilemeyen dahil büyü bitince çubuk kapansın.
        local unit = self.displayUnit
        local nameCh = UnitChannelInfo(unit)
        local nameCast = UnitCastingInfo(unit)
        if not nameCh and not nameCast then
            self.active = false
            f:SetScript("OnUpdate", nil)
            f:Hide()
            if type(onCastEndRefresh) == "function" then onCastEndRefresh(self) end
            return
        end
        local dObj = f.durationObj
        if not dObj then return end

        local remaining = isChannel and dObj:GetRemainingDuration() or dObj:GetElapsedDuration()
        f.statusBar:SetValue(remaining)
        f.timeText:SetText(string.format("%.1f", dObj:GetRemainingDuration()))

        -- Kesilebilirlik: önce nameplate cast bar (barType), yoksa olay bayrakları
        local npShielded = GetNamePlateCastBarShielded(self.displayUnit)
        local isShielded
        if npShielded ~= nil then
            isShielded = npShielded
            if self.displayUnit == "target" then self.targetCastShielded = npShielded elseif self.displayUnit == "focus" then self.focusCastShielded = npShielded end
        else
            isShielded = (self.displayUnit == "target" and self.targetCastShielded) or (self.displayUnit == "focus" and self.focusCastShielded)
        end

        local db = addon.db[MOD_KEY]
        local r,g,b = 1,1,1
        if self.isInterrupted then
             r,g,b = addon.Utilities:HexToRGB(db.InterruptedColor)
        elseif isShielded then
             r,g,b = addon.Utilities:HexToRGB(db.NotInterruptibleColor)
        elseif IsSpellReady(self) then
             r,g,b = addon.Utilities:HexToRGB(db.ColorReady)
        else
             r,g,b = addon.Utilities:HexToRGB(db.ColorCooldown)
        end
        f.statusBar:SetStatusBarColor(r,g,b)
    end)
    self.frame:SetAlphaFromBoolean(addon.db[MOD_KEY]["Hidden"], 0, 255)
    self.frame:Show()
end

-- Update CheckInterruptSuccess to effectively update the local bar
local function CheckInterruptSuccess(self, spellID)
    local mods = INTERRUPT_MODIFIERS[spellID]
    if not mods then return end
    
    local reduction = 0
    for _, mod in ipairs(mods) do
        if IsPlayerSpell(mod.talent) then
            reduction = reduction + mod.reduction
        end
    end
    
    if reduction > 0 then
        self.nextReadyTime = self.nextReadyTime - reduction
        local newDuration = self.interruptCD - reduction
        
        -- [SYNC UPDATE]
        if BreakForge.Party then 
            BreakForge.Party:SendSync(spellID, newDuration, self.lastSentTime) 
        end
        
        -- [LOCAL UPDATE]
        if self.frame and self.active then
            local startTime = (self.nextReadyTime - newDuration) * 1000
            local endTime = self.nextReadyTime * 1000
            self.frame.durationObj = CreateDurationObject(startTime, endTime)
            -- Update party bar for self too
            if BreakForge.Party then BreakForge.Party:UpdateBar(UnitName("player"), spellID, newDuration) end
        end
    end
end

-- ...



local function Handler(self)
    if self.isTesting or self.isUnlocked then return end
    if not addon.db[MOD_KEY]["Enabled"] then self.frame:Hide(); return end
    local unit = "target"; if not UnitExists("target") then unit = "focus" end
    -- API 12: notInterruptible secret; sadece isim/doku/süre alıyoruz, kesilebilirlik UNIT_SPELLCAST_* olaylarından
    local name, _, texture = UnitChannelInfo(unit)
    local isChannel = false
    if name then isChannel = true else name, _, texture = UnitCastingInfo(unit) end
    if not name then self.active = false; self.frame:Hide(); return end
    -- Kesilemezlik: önce nameplate cast bar (güvenilir), yoksa olay bayrakları
    local npShielded = GetNamePlateCastBarShielded(unit)
    if npShielded ~= nil then
        if unit == "target" then self.targetCastShielded = npShielded elseif unit == "focus" then self.focusCastShielded = npShielded end
    end
    local duration = isChannel and _G.UnitChannelDuration(unit) or _G.UnitCastingDuration(unit)
    local targetName = UnitSpellTargetName(unit)
    self.frame.spellText:SetText(targetName and (name.." -> "..targetName) or name)
    self.frame.icon:SetTexture(texture or UNKNOWN_SPELL_TEXTURE)
    self.isInterrupted = false
    CastsHandler(self, duration, isChannel, unit, Handler)
end

function BreakForge:Initialize()
    if not addon.db[MOD_KEY]["Enabled"] then return nil end
    self.frame = CreateFrame("Frame", "BreakForge_MainFrame", UIParent)
    self.frame:SetFrameStrata("HIGH")
    self.frame:Hide()
    AddMixin(self.frame)

    if self.Party then self.Party:Initialize() end

    self.frame:SetMovable(true)
    self.frame:EnableMouse(false)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local x, y = f:GetCenter(); local ux, uy = UIParent:GetCenter()
        addon.db[MOD_KEY].X = math.floor(x - ux)
        addon.db[MOD_KEY].Y = math.floor(y - uy)
    end)

    if ForgeSkin and ForgeSkin.ApplyBackdrop then
        ForgeSkin:ApplyBackdrop(self.frame)
        self.frame:SetBackdropColor(0,0,0, addon.db[MOD_KEY].BackgroundAlpha)
    else
        self.frame.bg = self.frame:CreateTexture(nil,"BACKGROUND"); self.frame.bg:SetAllPoints(); self.frame.bg:SetColorTexture(0,0,0,0.5)
    end

    -- [İKON ÇERÇEVESİ]
    self.frame.iconBox = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.frame.iconBox:SetPoint("LEFT", 0, 0)
    self.frame.iconBox:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    self.frame.iconBox:SetBackdropBorderColor(0,0,0,1)

    self.frame.icon = self.frame.iconBox:CreateTexture(nil, "ARTWORK")
    self.frame.icon:SetPoint("TOPLEFT", 1, -1) -- 1px içeriden başlat
    self.frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    
    self.frame.statusBar = CreateFrame("StatusBar", nil, self.frame); self.frame.statusBar:SetPoint("RIGHT"); AddMixin(self.frame.statusBar)
    -- Single Bar Mode: removed extra bars

    self.frame.textFrame = CreateFrame("Frame", nil, self.frame); self.frame.textFrame:SetAllPoints(true); self.frame.textFrame:SetFrameLevel(self.frame.statusBar:GetFrameLevel() + 1)
    self.frame.spellText = self.frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.frame.spellText:SetJustifyH("LEFT")
    self.frame.timeText = self.frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.frame.timeText:SetJustifyH("RIGHT")

    self.active = false; self:UpdateStyle(); 
    LoadClassInterrupt(self)
    return self
end

function BreakForge:UpdateStyle()
    local db = addon.db[MOD_KEY]
    if not self.frame then return end
    
    if not self.isUnlocked then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", db.X, db.Y)
    end

    self.frame:SetSize(db.Width, db.Height)
    
    if ForgeSkin and ForgeSkin.SetSmartBorder then
        ForgeSkin:SetSmartBorder(self.frame, db.BorderSize or 1, nil, db.BorderPosition or "OUTSIDE")
        self.frame:SetBackdropColor(0, 0, 0, db.BackgroundAlpha)
    end
    
    -- İkon Kutusu Boyutu
    self.frame.iconBox:SetSize(db.Height, db.Height)
    local barWidth = db.Width - db.Height
    
    local texturePath = "Interface\\TargetingFrame\\UI-StatusBar"
    if ForgeSkin and ForgeSkin.Media and ForgeSkin.Media.Textures then texturePath = ForgeSkin.Media.Textures[db.Texture] or texturePath end
    local fontPath = "Fonts\\FRIZQT__.TTF"
    if ForgeSkin and ForgeSkin.Media and ForgeSkin.Media.Fonts then fontPath = ForgeSkin.Media.Fonts[db.Font] or fontPath end
    local fontSize = db.FontSize or 12
    local fontOutline = db.FontOutline or "OUTLINE"

    local function UpdateBar(bar, colorHex)
        bar:SetSize(barWidth, db.Height)
        bar:SetStatusBarTexture(texturePath)
        bar:SetStatusBarColor(addon.Utilities:HexToRGB(colorHex))
    end
    
    UpdateBar(self.frame.statusBar, db.ColorCooldown)
    -- Single Bar Mode: removed extra updates
    
    self.frame.spellText:SetPoint("LEFT", self.frame, "LEFT", db.Height + 5, 0)
    self.frame.spellText:SetSize(0.7 * barWidth, fontSize)
    self.frame.spellText:SetFont(fontPath, fontSize, fontOutline)
    
    self.frame.timeText:SetPoint("RIGHT", self.frame, "RIGHT", -5, 0)
    self.frame.timeText:SetFont(fontPath, fontSize, fontOutline)
end

function BreakForge:RegisterEvents()
    local Start = function() if self.timer then self.timer:Cancel(); self.timer=nil end; self.active=true; Handler(self) end
    local Stop = function(ev,...) if ev=="UNIT_SPELLCAST_INTERRUPTED" then local _,_,_,g=...; if g then InterruptHandler(self,g); self.isInterrupted=true end end; if not self.timer then self.active=false; self.frame:Hide() end end
    
    -- [ZERO LATENCY FIX] Use SENT -> Instant Customer Side Response
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")

    eventFrame:HookScript("OnEvent", function(_, event, unit, target, castGUID, spellID) 
        if event == "UNIT_SPELLCAST_SENT" and unit == "player" then 
             -- Note: SENT args: unit, target, castGUID, spellID
             RecordInterruptUsage(BreakForge, spellID) 
        end 
    end)
    
    -- Kesilebilirlik: API 12 secret değer yerine olaylarla takip (asInterruptHelper gibi)
    addon.eventsHandler:Register(function(_, unit) if unit == "target" then self.targetCastShielded = true elseif unit == "focus" then self.focusCastShielded = true end end, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target")
    addon.eventsHandler:Register(function(_, unit) if unit == "target" then self.targetCastShielded = false elseif unit == "focus" then self.focusCastShielded = false end end, "UNIT_SPELLCAST_INTERRUPTIBLE", "target")
    addon.eventsHandler:Register(function(_, unit) if unit == "target" then self.targetCastShielded = false elseif unit == "focus" then self.focusCastShielded = false end end, "UNIT_SPELLCAST_START", "target")
    addon.eventsHandler:Register(function(_, unit) if unit == "target" then self.targetCastShielded = false elseif unit == "focus" then self.focusCastShielded = false end end, "UNIT_SPELLCAST_CHANNEL_START", "target")
    addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_START", "target"); addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_START", "focus")
    addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_CHANNEL_START", "target"); addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_CHANNEL_START", "focus")
    addon.eventsHandler:Register(Start, "PLAYER_TARGET_CHANGED"); addon.eventsHandler:Register(Start, "PLAYER_FOCUS_CHANGED")
    addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_STOP", "target"); addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_STOP", "focus")
    addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_INTERRUPTED", "target"); addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_INTERRUPTED", "focus")
    -- Savaştan çıkınca çubuk gizlensin (hedef/odak yoksa veya büyü yoksa)
    addon.eventsHandler:Register(function() Handler(self) end, "PLAYER_REGEN_ENABLED")
    addon.eventsHandler:Register(function() LoadClassInterrupt(BreakForge) end, "PLAYER_SPECIALIZATION_CHANGED")
    C_ChatInfo.RegisterAddonMessagePrefix(self.commPrefix)
    addon.eventsHandler:Register(function(event, ...) 
        local prefix, text, channel, sender = ...
        if BreakForge.Party then BreakForge.Party:OnCommReceived(prefix, text, channel, sender) end 
    end, "CHAT_MSG_ADDON")
end

function BreakForge:Test(toggle)
    if not addon.db[MOD_KEY]["Enabled"] then return end
    if toggle == nil then self.isTesting = not self.isTesting else self.isTesting = toggle end

    if self.isTesting then
        self.active = true; self.frame:Show()
        self.frame.spellText:SetText("Test Mode")
        self.frame.icon:SetTexture(UNKNOWN_SPELL_TEXTURE)
        self.frame.statusBar:SetMinMaxValues(0, 10); self.frame.statusBar:SetValue(10)
        self.frame.statusBar:SetStatusBarColor(addon.Utilities:HexToRGB(addon.db[MOD_KEY].ColorReady)) -- Default to ready color for test
        self.frame.timeText:SetText("10.0")
        if self.Party then self.Party:Test(true) end
    else
        self.active = false; self.frame:Hide()
        if self.Party then self.Party:Test(false) end
    end
end

function BreakForge:ToggleUnlock()
    if not self.frame then return end
    self.isUnlocked = not self.isUnlocked
    if self.isUnlocked then
        self.frame:Show(); self.frame:EnableMouse(true)
        self.frame.spellText:SetText("|cff00ff00MAIN BAR (DRAG)|r")
        self.frame.statusBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        if self.Party then self.Party:ToggleUnlock(true) end
    else
        self.frame:EnableMouse(false); self.frame:Hide()
        self.frame.spellText:SetText(""); self:UpdateStyle()
        if self.Party then self.Party:ToggleUnlock(false) end
    end
end

local loader = CreateFrame("Frame"); loader:RegisterEvent("PLAYER_LOGIN"); loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if not BreakForgeDB then BreakForgeDB = addon.dbDefault end
        addon.db = BreakForgeDB
        if not addon.db.BreakForge then addon.db.BreakForge = {} end
        for k,v in pairs(addon.dbDefault.BreakForge) do if addon.db.BreakForge[k] == nil then addon.db.BreakForge[k] = v end end
    elseif event == "PLAYER_LOGIN" then
        local bf = BreakForge:Initialize()
        if bf then bf:RegisterEvents() end
    end
end)

SLASH_BREAKFORGE1 = "/bf"
SlashCmdList["BREAKFORGE"] = function(msg) 
    if msg == "debug" then
        local self = BreakForge
        -- [COMPLIANT] No API Call
        local now = GetTime()
        local cdRem = (self.nextReadyTime > now) and (self.nextReadyTime - now) or 0
        print("BF Debug (Manual): Class="..tostring(addon.characterClass).." IntID="..tostring(self.interruptID))
        print("BF Debug: NextReady="..tostring(self.nextReadyTime).." Now="..tostring(now).." Rem="..string.format("%.1f", cdRem))
    elseif BreakForge.ToggleConfig then 
        BreakForge:ToggleConfig() 
    else 
        print("BreakForge: /bf debug or Config UI missing.") 
    end 
end