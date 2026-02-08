local ADDON_NAME, ns = ...
local addon = ns
local Skin = ForgeSkin
local MOD_KEY = "BreakForge"

BreakForge.Party = {
    bars = {},         
    container = nil,   
    commPrefix = "BF_SYNC",
    autoTestActive = false
}

local Party = BreakForge.Party

-- ... (SYNC FUNCTIONS ARE SAME AS BEFORE) ...
function Party:SendSync(spellID, duration, timestamp)
    if not IsInGroup() then return end
    -- [PROTOCOL v2] Add ServerTime for latency compensation
    local ts = timestamp or GetServerTime()
    local msg = string.format("INT:%d:%d:%d", spellID, duration, ts)
    local channel = "PARTY"
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then channel = "INSTANCE_CHAT"
    elseif IsInRaid() then channel = "RAID" end
    C_ChatInfo.SendAddonMessage(self.commPrefix, msg, channel)
end

function Party:OnCommReceived(prefix, text, channel, sender)
    if prefix ~= self.commPrefix then return end
    sender = Ambiguate(sender, "none")
    if sender == UnitName("player") then return end
    
    local cmd, spellID, duration, timestamp = strsplit(":", text)
    spellID = tonumber(spellID)
    duration = tonumber(duration)
    timestamp = tonumber(timestamp)
    
    if cmd == "INT" and spellID and duration then 
        -- [LATENCY COMPENSATION]
        local lag = 0
        if timestamp then
            local now = GetServerTime()
            lag = now - timestamp
            if lag < 0 then lag = 0 end -- Clock skew protection
        end
        local adjustedDuration = duration - lag
        if adjustedDuration > 0 then
            self:UpdateBar(sender, spellID, adjustedDuration) 
        end
    end
end

-- ============================================================================
-- 2. GÖRSELLEŞTİRME
-- ============================================================================

function Party:Initialize()
    local db = addon.db[MOD_KEY]
    self.container = CreateFrame("Frame", "BreakForge_PartyContainer", UIParent, "BackdropTemplate")
    self.container:SetSize(db.PartyWidth or 220, 200) 
    self.container:SetPoint("CENTER", db.PartyX or -250, db.PartyY or 0)
    self.container:SetMovable(true); self.container:EnableMouse(false)
    self.container:RegisterForDrag("LeftButton"); self.container:SetClampedToScreen(true)
    
    self.container:SetScript("OnDragStart", self.container.StartMoving)
    self.container:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local x, y = f:GetCenter(); local ux, uy = UIParent:GetCenter()
        addon.db[MOD_KEY].PartyX = math.floor(x - ux); addon.db[MOD_KEY].PartyY = math.floor(y - uy)
    end)
    
    self.container.label = self.container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.container.label:SetPoint("CENTER"); self.container.label:SetText("|cff00ff00PARTY FRAMES (DRAG)|r"); self.container.label:Hide()
end

function Party:CreateBar(name)
    local db = addon.db[MOD_KEY]
    local height = db.PartyHeight or 30
    local width = db.PartyWidth or 220
    local iconSize = db.PartyIconSize or height
    local outline = db.FontOutline or "OUTLINE"
    
    local row = CreateFrame("Frame", nil, self.container, "BackdropTemplate")
    row:SetSize(width, height)
    
    -- İKON KUTUSU (Border)
    row.iconBox = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.iconBox:SetSize(iconSize, iconSize)
    row.iconBox:SetPoint("LEFT", 4, 0)
    row.iconBox:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    row.iconBox:SetBackdropBorderColor(0, 0, 0, 1)
    
    row.classStrip = row:CreateTexture(nil, "BORDER"); row.classStrip:SetWidth(4)
    row.classStrip:SetPoint("TOPRIGHT", row.iconBox, "TOPLEFT", -1, 0); row.classStrip:SetPoint("BOTTOMRIGHT", row.iconBox, "BOTTOMLEFT", -1, 0)
    row.classStrip:SetColorTexture(1, 1, 1, 1)
    
    row.icon = row.iconBox:CreateTexture(nil, "ARTWORK"); row.icon:SetPoint("TOPLEFT", 1, -1); row.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    
    row.info = CreateFrame("Frame", nil, row); row.info:SetPoint("LEFT", row.iconBox, "RIGHT", 5, 0); row.info:SetPoint("RIGHT", 0, 0); row.info:SetHeight(height)
    
    local splitH = height / 2
    row.nameBar = CreateFrame("Frame", nil, row.info); row.nameBar:SetPoint("TOPLEFT", 0, 0); row.nameBar:SetPoint("TOPRIGHT", 0, 0); row.nameBar:SetHeight(splitH)
    
    row.nameText = row.nameBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", 2, 0)
    row.nameText:SetText(name)
    row.nameText:SetTextColor(1, 1, 1, 1)
    
    -- Font Outline Uygula
    local fName, fSize, _ = row.nameText:GetFont()
    row.nameText:SetFont(fName, fSize, outline)
    
    row.timerBar = CreateFrame("StatusBar", nil, row.info, "BackdropTemplate"); row.timerBar:SetPoint("TOPLEFT", row.nameBar, "BOTTOMLEFT", 0, 0); row.timerBar:SetPoint("BOTTOMRIGHT", 0, 0); row.timerBar:SetHeight(splitH)
    
    local texture = "Interface\\TargetingFrame\\UI-StatusBar"
    if Skin and Skin.Media and Skin.Media.Textures then texture = Skin.Media.Textures[db.Texture] or texture end
    row.timerBar:SetStatusBarTexture(texture)
    
    local r, g, b = addon.Utilities:HexToRGB(db.ColorCooldown)
    row.timerBar:SetStatusBarColor(r, g, b, 1)
    row.timerBar:SetMinMaxValues(0, 1); row.timerBar:SetValue(1)
    
    row.timerText = row.timerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.timerText:SetPoint("RIGHT", -2, 0); row.timerText:SetText("")
    row.timerText:SetFont(fName, fSize, outline) -- Timer font outline
    
    row.timerBg = row.timerBar:CreateTexture(nil, "BACKGROUND"); row.timerBg:SetAllPoints(); row.timerBg:SetColorTexture(0, 0, 0, 0.5)
    
    return row
end

function Party:UpdateBar(senderName, spellID, duration, dummyClassColor)
    local db = addon.db[MOD_KEY]
    if not db.PartyEnabled then return end
    if not self.bars[senderName] then self.bars[senderName] = self:CreateBar(senderName) end
    local bar = self.bars[senderName]
    
    -- [FIX: API 12.0]
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local icon = 134400
    if spellInfo then icon = spellInfo.iconID end
    bar.icon:SetTexture(icon)
    
    local classColor = {r=0.5, g=0.5, b=0.5}
    if dummyClassColor then classColor = dummyClassColor
    elseif IsInGroup() then
        local unit = "player"
        if UnitName("player") == senderName then unit = "player" else
            for i=1, 4 do if UnitName("party"..i) == senderName then unit = "party"..i break end end
        end
        local _, classFileName = UnitClass(unit)
        if classFileName and RAID_CLASS_COLORS[classFileName] then classColor = RAID_CLASS_COLORS[classFileName] end
    end
    bar.classStrip:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
    
    local r, g, b = addon.Utilities:HexToRGB(db.ColorCooldown)
    bar.timerBar:SetStatusBarColor(r, g, b, 1)
    
    bar.endTime = GetTime() + duration
    bar.duration = duration
    bar:Show()
    
    bar:SetScript("OnUpdate", function(f, elapsed)
        local remaining = f.endTime - GetTime()
        if remaining <= 0 then
            f:Hide(); f:SetScript("OnUpdate", nil); Party:LayoutBars()
        else
            f.timerBar:SetMinMaxValues(0, f.duration); f.timerBar:SetValue(remaining); f.timerText:SetText(string.format("%.1f", remaining))
        end
    end)
    self:LayoutBars()
end

function Party:LayoutBars()
    local db = addon.db[MOD_KEY]
    local prev = nil
    local spacing = db.PartySpacing or 5
    local sorted = {}
    for name, bar in pairs(self.bars) do if bar:IsShown() then table.insert(sorted, bar) end end
    
    for i, bar in ipairs(sorted) do
        bar:ClearAllPoints()
        if i == 1 then bar:SetPoint("TOPLEFT", self.container, "TOPLEFT", 0, 0)
        else bar:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -spacing) end
        prev = bar
    end
end

-- Kontrol Fonksiyonları
function Party:Test(on)
    if on then
        self:UpdateBar("TankZilla", 6552, 15, {r=0.78, g=0.61, b=0.43}) 
        self:UpdateBar("FrostyMage", 2139, 24, {r=0.25, g=0.78, b=0.92})
        self:UpdateBar("SneakyPete", 1766, 15, {r=1.0, g=0.96, b=0.41})
        self:UpdateBar("HealyTotem", 57994, 30, {r=0.0, g=0.44, b=0.87})
        self:UpdateBar("Huntard", 187707, 15, {r=0.67, g=0.83, b=0.45})
    else
        for _, bar in pairs(self.bars) do bar:Hide() end
    end
end

function Party:ToggleUnlock(isUnlocked)
    if not self.container then return end
    if isUnlocked then
        self.container:Show(); self.container:EnableMouse(true); self.container.label:Show()
        if Skin and Skin.ApplyBackdrop then Skin:ApplyBackdrop(self.container); self.container:SetBackdropColor(0, 1, 0, 0.3) end
        if not IsInGroup() and next(self.bars) == nil then self:Test(true); self.autoTestActive = true end
    else
        self.container:EnableMouse(false); self.container.label:Hide()
        self.container:SetBackdropColor(0, 0, 0, 0); self.container:SetBackdropBorderColor(0, 0, 0, 0)
        if self.autoTestActive then self:Test(false); self.autoTestActive = false end
    end
end