local ADDON_NAME, ns = ...
local addon = ns
local Skin = ForgeSkin
local MOD_KEY = "BreakForge"

-- Modül Tanımlaması
BreakForge.Party = {
    bars = {},         -- Aktif parti barları
    container = nil,   -- Taşıyıcı çerçeve
    commPrefix = "BF_SYNC"
}

local Party = BreakForge.Party

-- ============================================================================
-- 1. İLETİŞİM (SYNC)
-- ============================================================================

-- [GÖNDERİCİ] Sen interrupt attığında burası çalışır
function Party:SendSync(spellID, duration)
    if not IsInGroup() then return end
    
    -- Mesaj Formatı: "INT:SpellID:Duration"
    local msg = string.format("INT:%d:%d", spellID, duration)
    local channel = IsInRaid() and "RAID" or "PARTY"
    
    -- C_ChatInfo ile gönder
    C_ChatInfo.SendAddonMessage(self.commPrefix, msg, channel)
end

-- [ALICI] Başkası interrupt attığında burası çalışır
function Party:OnCommReceived(prefix, text, channel, sender)
    if prefix ~= self.commPrefix then return end
    
    -- Kendimizden gelen mesajı yoksay
    if sender == UnitName("player") then return end
    
    local cmd, spellID, duration = strsplit(":", text)
    spellID = tonumber(spellID)
    duration = tonumber(duration)
    
    if cmd == "INT" and spellID and duration then
        self:UpdateBar(sender, spellID, duration)
    end
end

-- ============================================================================
-- 2. GÖRSELLEŞTİRME (BARLAR)
-- ============================================================================

function Party:Initialize()
    -- Taşıyıcı Çerçeve (Container)
    self.container = CreateFrame("Frame", "BreakForge_PartyContainer", UIParent, "BackdropTemplate")
    local db = addon.db[MOD_KEY]
    
    self.container:SetSize(200, 200) -- Dinamik değişecek, başlangıç boyutu
    self.container:SetPoint("CENTER", db.PartyX or -200, db.PartyY or 0)
    
    -- Sürükleme Özelliği
    self.container:SetMovable(true)
    self.container:EnableMouse(false) -- Varsayılan kapalı (Unlock ile açılır)
    self.container:RegisterForDrag("LeftButton")
    self.container:SetScript("OnDragStart", self.container.StartMoving)
    self.container:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local x, y = f:GetCenter()
        local ux, uy = UIParent:GetCenter()
        addon.db[MOD_KEY].PartyX = math.floor(x - ux)
        addon.db[MOD_KEY].PartyY = math.floor(y - uy)
    end)
    
    -- Etiket (Sadece kilit açılınca görünür)
    self.container.label = self.container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.container.label:SetPoint("CENTER")
    self.container.label:SetText("PARTY FRAMES (DRAG)")
    self.container.label:Hide()
    
    -- Addon Mesajlarını Dinle
    C_ChatInfo.RegisterAddonMessagePrefix(self.commPrefix)
    addon.eventsHandler:Register(function(...) self:OnCommReceived(...) end, "CHAT_MSG_ADDON")
end

function Party:CreateBar(name)
    local db = addon.db[MOD_KEY]
    local f = CreateFrame("Frame", nil, self.container, "BackdropTemplate")
    f:SetSize(db.PartyWidth, db.PartyHeight)
    
    -- Skin Uygula
    if Skin and Skin.ApplyBackdrop then
        Skin:ApplyBackdrop(f)
        f:SetBackdropColor(0,0,0,0.8)
        Skin:SetSmartBorder(f, 1)
    end
    
    -- İkon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(db.PartyHeight, db.PartyHeight)
    f.icon:SetPoint("LEFT", 0, 0)
    
    -- Bar
    f.statusBar = CreateFrame("StatusBar", nil, f)
    f.statusBar:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 0, 0)
    f.statusBar:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Texture
    local texture = "Interface\\TargetingFrame\\UI-StatusBar"
    if Skin and Skin.Media and Skin.Media.Textures then 
        texture = Skin.Media.Textures[db.Texture] or texture 
    end
    f.statusBar:SetStatusBarTexture(texture)
    
    -- Renk (Turuncu - CD rengi)
    local r, g, b = addon.Utilities:HexToRGB(db.CooldownColor)
    f.statusBar:SetStatusBarColor(r, g, b, 1)
    
    -- İsim
    f.nameText = f.statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.nameText:SetPoint("LEFT", 5, 0)
    f.nameText:SetText(name)
    
    -- Süre
    f.timeText = f.statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.timeText:SetPoint("RIGHT", -5, 0)
    
    return f
end

function Party:UpdateBar(senderName, spellID, duration)
    local db = addon.db[MOD_KEY]
    if not db.PartyEnabled then return end
    
    -- Bar yoksa oluştur
    if not self.bars[senderName] then
        self.bars[senderName] = self:CreateBar(senderName)
    end
    
    local bar = self.bars[senderName]
    local _, _, icon = GetSpellInfo(spellID) -- Yeni API'de C_Spell.GetSpellInfo olabilir, 11.0 için kontrol gerekebilir
    if not icon then icon = 134400 end
    
    bar.icon:SetTexture(icon)
    bar.statusBar:SetMinMaxValues(0, duration)
    bar.endTime = GetTime() + duration
    bar.duration = duration
    
    -- Bar Rengini Güncelle (DB'den al)
    local r, g, b = addon.Utilities:HexToRGB(db.CooldownColor)
    bar.statusBar:SetStatusBarColor(r, g, b, 1)
    
    -- Bar Boyutlarını Güncelle
    bar:SetSize(db.PartyWidth, db.PartyHeight)
    bar.icon:SetSize(db.PartyHeight, db.PartyHeight)
    
    bar:Show()
    
    -- Geri Sayım Scripti
    bar:SetScript("OnUpdate", function(f, elapsed)
        local remaining = f.endTime - GetTime()
        if remaining <= 0 then
            f:Hide()
            f:SetScript("OnUpdate", nil)
            Party:LayoutBars() -- Gizlenince düzeni yenile
        else
            f.statusBar:SetValue(remaining)
            f.timeText:SetText(string.format("%.1f", remaining))
        end
    end)
    
    self:LayoutBars()
end

function Party:LayoutBars()
    local db = addon.db[MOD_KEY]
    local prev = nil
    local spacing = 5
    
    local sorted = {}
    for name, bar in pairs(self.bars) do
        if bar:IsShown() then table.insert(sorted, bar) end
    end
    -- İsteğe bağlı sıralama eklenebilir
    
    for i, bar in ipairs(sorted) do
        bar:ClearAllPoints()
        if i == 1 then
            bar:SetPoint("TOPLEFT", self.container, "TOPLEFT", 0, 0)
        else
            bar:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -spacing)
        end
        prev = bar
    end
end

-- ============================================================================
-- 3. KONTROLLER (TEST & UNLOCK)
-- ============================================================================

function Party:Test(on)
    if on then
        self:UpdateBar("PartyMember1", 1766, 15) -- Rogue Kick
        self:UpdateBar("PartyMember2", 6552, 10) -- Warrior Pummel
    else
        for _, bar in pairs(self.bars) do bar:Hide() end
    end
end

function Party:ToggleUnlock(isUnlocked)
    if isUnlocked then
        self.container:Show()
        self.container:EnableMouse(true)
        self.container.label:Show()
        if Skin then 
            Skin:ApplyBackdrop(self.container)
            self.container:SetBackdropColor(0, 1, 0, 0.3) -- Yeşil highlight
        end
    else
        self.container:EnableMouse(false)
        self.container.label:Hide()
        self.container:SetBackdropColor(0, 0, 0, 0) -- Görünmez
    end
end