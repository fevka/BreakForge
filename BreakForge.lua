local ADDON_NAME, ns = ...

-- ============================================================================
-- 1. BÖLÜM: ZEMİN (MOCK)
-- ============================================================================

local addon = ns
addon.db = {
    BreakForge = {
        Enabled = true, Hidden = false, Mute = false, Width = 300, Height = 30,
        X = 0, Y = -150, IconZoom = 0.1, Texture = "Solid", Font = "Standard",
        FontSize = 12, BackgroundAlpha = 0.8,
        CooldownColor = "FF0000", InterruptibleColor = "FF0000",
        NotInterruptibleColor = "808080", InterruptedColor = "00FF00",
        CooldownHide = false, NotInterruptibleHide = false, SoundMedia = "RaidWarning"
    }
}
addon.characterClass = select(2, UnitClass("player"))

-- [MOCK] LibSharedMedia & Utilities
addon.LSM = {
    Fetch = function(self, type, key)
        if type == "font" then return "Fonts\\FRIZQT__.TTF" end
        if type == "statusbar" then return "Interface\\TargetingFrame\\UI-StatusBar" end
        if type == "sound" then return 8959 end
        return nil
    end
}
addon.Utilities = {
    HexToRGB = function(self, hex)
        if not hex then return 1,1,1,1 end
        local r, g, b = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
        return tonumber(r, 16)/255, tonumber(g, 16)/255, tonumber(b, 16)/255, 1
    end,
    -- MakeFrameDragPosition artık Config içinde manuel yapılacak
    MakeFrameDragPosition = function(self, frame) end 
}

-- [MOCK] Event Handler
local eventFrame = CreateFrame("Frame")
local eventRegistry = {}
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if eventRegistry[event] then for _, func in ipairs(eventRegistry[event]) do func(event, ...) end end
end)
addon.eventsHandler = {
    Register = function(self, func, event, unit)
        if not eventRegistry[event] then
            eventRegistry[event] = {}
            if unit then eventFrame:RegisterUnitEvent(event, "target", "focus") else eventFrame:RegisterEvent(event) end
        end
        table.insert(eventRegistry[event], func)
    end
}

-- [MOCK] Locale & SetAlphaFromBoolean
local LibStub = { GetLocale = function() return { ["Interrupted"] = "KESILDI" } end }

local function SetAlphaFromBoolean(self, condition, trueAlpha, falseAlpha)
    local success, _ = pcall(function()
        if condition then self:SetAlpha(trueAlpha or 1) else self:SetAlpha(falseAlpha or 0) end
    end)
    if not success then self:SetAlpha(falseAlpha or 0) end
end
local function AddMixin(frame) if not frame.SetAlphaFromBoolean then frame.SetAlphaFromBoolean = SetAlphaFromBoolean end end

-- Duration Object Wrapper
local function CreateDurationObject(startTime, endTime)
    local obj = {}
    obj.GetTotalDuration = function() return (endTime - startTime) / 1000 end
    obj.GetRemainingDuration = function() local t = (endTime - (GetTime()*1000))/1000; return (t<0) and 0 or t end
    obj.GetElapsedDuration = function() local t = ((GetTime()*1000) - startTime)/1000; return (t<0) and 0 or t end
    return obj
end
if not _G.UnitCastingDuration then _G.UnitCastingDuration = function(u) local _,_,_,s,e=UnitCastingInfo(u); return CreateDurationObject(s or 0,e or 0) end end
if not _G.UnitChannelDuration then _G.UnitChannelDuration = function(u) local _,_,_,s,e=UnitChannelInfo(u); return CreateDurationObject(s or 0,e or 0) end end

-- ============================================================================
-- 2. BÖLÜM: CORE MANTIK
-- ============================================================================

BreakForge = { frame = nil, active = false, interruptID = 119914, subInterrupt = nil, timer = nil, commPrefix = "BF_SYNC" }
_G["BreakForge"] = BreakForge

local L = LibStub.GetLocale(ADDON_NAME)
local MOD_KEY = "BreakForge"
local UNKNOWN_SPELL_TEXTURE = 134400

local function GetInterruptSpellID(self, class) return 0 end -- Simplified
local function GetInterrupter(guid) local name = UnitNameFromGUID(guid); return name end
local function SetBarInterruptedColor(self, interrupted)
    if interrupted then
        self.frame.notInterruptibleBar:SetAlpha(0); self.frame.interruptReadyBar:SetAlpha(0); self.frame.statusBar:SetAlpha(1)
        self.frame.statusBar:SetStatusBarColor(addon.Utilities:HexToRGB(addon.db[MOD_KEY]["InterruptedColor"]))
    else
        self.frame.statusBar:SetStatusBarColor(addon.Utilities:HexToRGB(addon.db[MOD_KEY]["CooldownColor"]))
    end
end

local function InterruptHandler(self, guid)
    local interrupter = GetInterrupter(guid)
    self.frame.spellText:SetText(L["Interrupted"] .. ": " .. (interrupter or "Unknown"))
    SetBarInterruptedColor(self, true)
    self.active = false
    if self.timer then self.timer:Cancel() end
    self.timer = C_Timer.NewTimer(0.75, function() self.timer=nil; self.frame:Hide(); SetBarInterruptedColor(self, false) end)
end

local function CastsHandler(self, duration, isChannel, notInterruptible)
    self.frame.notInterruptibleBar:SetMinMaxValues(0, duration:GetTotalDuration())
    self.frame.interruptReadyBar:SetMinMaxValues(0, duration:GetTotalDuration())
    self.frame.statusBar:SetMinMaxValues(0, duration:GetTotalDuration())
    
    self.frame:SetScript("OnUpdate", function ()
        if not self.active then return end
        local remaining = isChannel and duration:GetRemainingDuration() or duration:GetElapsedDuration()
        self.frame.notInterruptibleBar:SetValue(remaining)
        self.frame.interruptReadyBar:SetValue(remaining)
        self.frame.statusBar:SetValue(remaining)
        self.frame.timeText:SetText(string.format("%.1f", duration:GetRemainingDuration()))
        
        self.frame.notInterruptibleBar:SetAlphaFromBoolean(notInterruptible)
        self.frame.interruptReadyBar:SetAlphaFromBoolean(false) -- CD logic simplified
    end)
    self.frame:SetAlphaFromBoolean(addon.db[MOD_KEY]["Hidden"], 0, 255)
    self.frame:Show()
end

local function Handler(self)
    if not addon.db[MOD_KEY]["Enabled"] then self.frame:Hide(); return end
    local unit = "target"; if not UnitExists("target") then unit = "focus" end
    local name, _, texture, _, _, _, notInterruptible = UnitChannelInfo(unit)
    local isChannel = false
    if name then isChannel = true else name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo(unit) end
    if not name then self.active = false; self.frame:Hide(); return end
    local duration = isChannel and _G.UnitChannelDuration(unit) or _G.UnitCastingDuration(unit)
    local targetName = UnitSpellTargetName(unit)
    self.frame.spellText:SetText(targetName and (name.." -> "..targetName) or name)
    self.frame.icon:SetTexture(texture or UNKNOWN_SPELL_TEXTURE)
    CastsHandler(self, duration, isChannel, notInterruptible)
end

function BreakForge:Initialize()
    if not addon.db[MOD_KEY]["Enabled"] then return nil end
    self.frame = CreateFrame("Frame", "BreakForge_MainFrame", UIParent)
    self.frame:SetFrameStrata("HIGH")
    self.frame:Hide()
    AddMixin(self.frame)

    -- ForgeSkin ile Arkaplan (Manuel yapıyoruz ki Config ile uyumlu olsun)
    if ForgeSkin then
        ForgeSkin:ApplyBackdrop(self.frame)
        self.frame:SetBackdropColor(0,0,0, addon.db[MOD_KEY].BackgroundAlpha)
    else
        self.frame.bg = self.frame:CreateTexture(nil,"BACKGROUND"); self.frame.bg:SetAllPoints(); self.frame.bg:SetColorTexture(0,0,0,0.5)
    end

    self.frame.icon = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.icon:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
    
    self.frame.notInterruptibleBar = CreateFrame("StatusBar", nil, self.frame); self.frame.notInterruptibleBar:SetPoint("RIGHT"); AddMixin(self.frame.notInterruptibleBar)
    self.frame.interruptReadyBar = CreateFrame("StatusBar", nil, self.frame); self.frame.interruptReadyBar:SetPoint("RIGHT"); AddMixin(self.frame.interruptReadyBar)
    self.frame.statusBar = CreateFrame("StatusBar", nil, self.frame); self.frame.statusBar:SetPoint("RIGHT"); AddMixin(self.frame.statusBar)

    self.frame.textFrame = CreateFrame("Frame", nil, self.frame); self.frame.textFrame:SetAllPoints(true)
    self.frame.spellText = self.frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.frame.spellText:SetJustifyH("LEFT")
    self.frame.timeText = self.frame.textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.frame.timeText:SetJustifyH("RIGHT")

    self.active = false; self:UpdateStyle()
    return self
end

function BreakForge:UpdateStyle()
    local db = addon.db[MOD_KEY]
    if not self.frame then return end
    self.frame:SetSize(db.Width, db.Height)
    self.frame:SetPoint("CENTER", UIParent, "CENTER", db.X, db.Y)
    if self.frame.SetBackdropColor then self.frame:SetBackdropColor(0,0,0, db.BackgroundAlpha) end
    
    self.frame.icon:SetSize(db.Height, db.Height)
    local barWidth = db.Width - db.Height
    
    local function UpdateBar(bar, colorHex)
        bar:SetSize(barWidth, db.Height)
        bar:SetStatusBarTexture(addon.LSM:Fetch("statusbar", db.Texture))
        bar:SetStatusBarColor(addon.Utilities:HexToRGB(colorHex))
    end
    
    UpdateBar(self.frame.statusBar, db.CooldownColor)
    UpdateBar(self.frame.notInterruptibleBar, db.NotInterruptibleColor)
    UpdateBar(self.frame.interruptReadyBar, db.InterruptibleColor)
    
    self.frame.spellText:SetPoint("LEFT", self.frame, "LEFT", db.Height + 5, 0)
    self.frame.spellText:SetSize(0.7 * barWidth, db.FontSize)
    self.frame.timeText:SetPoint("RIGHT", self.frame, "RIGHT", -5, 0)
end

function BreakForge:RegisterEvents()
    local Start = function() if self.timer then self.timer:Cancel(); self.timer=nil; SetBarInterruptedColor(self,false) end; self.active=true; Handler(self) end
    local Stop = function(ev,...) 
        if ev=="UNIT_SPELLCAST_INTERRUPTED" then local _,_,_,g=...; if g then InterruptHandler(self,g) end end
        if not self.timer then self.active=false; self.frame:Hide() end 
    end
    
    addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_START", "target"); addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_START", "focus")
    addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_CHANNEL_START", "target"); addon.eventsHandler:Register(Start, "UNIT_SPELLCAST_CHANNEL_START", "focus")
    addon.eventsHandler:Register(Start, "PLAYER_TARGET_CHANGED"); addon.eventsHandler:Register(Start, "PLAYER_FOCUS_CHANGED")
    addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_STOP", "target"); addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_STOP", "focus")
    addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_INTERRUPTED", "target"); addon.eventsHandler:Register(Stop, "UNIT_SPELLCAST_INTERRUPTED", "focus")
end

function BreakForge:Test(on)
    if not addon.db[MOD_KEY]["Enabled"] then return end
    if on then
        self.active = true; self.frame:Show()
        self.frame.spellText:SetText("Test Cast"); self.frame.icon:SetTexture(UNKNOWN_SPELL_TEXTURE)
        self.frame.statusBar:SetMinMaxValues(0,10); self.frame.statusBar:SetValue(5); self.frame.timeText:SetText("5.0")
    else self.active=false; self.frame:Hide() end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if not BreakForgeDB then BreakForgeDB = addon.db end
        addon.db = BreakForgeDB
        if not addon.db.BreakForge then addon.db.BreakForge = {} end
        for k,v in pairs(ns.db.BreakForge) do if addon.db.BreakForge[k] == nil then addon.db.BreakForge[k] = v end end
    elseif event == "PLAYER_LOGIN" then
        local bf = BreakForge:Initialize()
        if bf then bf:RegisterEvents() end
    end
end)

SLASH_BREAKFORGE1 = "/bf"
SlashCmdList["BREAKFORGE"] = function(msg)
    if BreakForge.ToggleConfig then BreakForge:ToggleConfig() else print("Config yuklenemedi.") end
end