local ADDON_NAME, ns = ...
local addon = ns
local BF = BreakForge
local Skin = ForgeSkin
local MOD_KEY = "BreakForge"

local function HexToColorTable(hex) local r, g, b, a = addon.Utilities:HexToRGB(hex); return {r, g, b, a or 1} end
local function ColorTableToHex(c) return string.format("%02x%02x%02x", c[1]*255, c[2]*255, c[3]*255) end

function BF:ToggleConfig()
    if BF.ConfigFrame then if BF.ConfigFrame:IsShown() then BF.ConfigFrame:Hide() else BF.ConfigFrame:Show() end return end

    local f = CreateFrame("Frame", "BreakForgeConfig", UIParent, "BackdropTemplate")
    f:SetSize(380, 850)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true)
    Skin:ApplyBackdrop(f); f:SetBackdropColor(unpack(Skin.Colors.bg)); Skin:SetSmartBorder(f)
    local titleBar = Skin:CreateTitleBar(f, "Break Forge Settings", function() f:Hide() end)

    local startY = -50
    local function CreateLabel(text, relativeTo, yOffset)
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); lbl:SetText(text)
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT", 20, yOffset)
        return lbl
    end

    -- === VISUAL SETTINGS ===
    Skin:CreateSectionHeader(f, "Visual Settings", 340):SetPoint("TOP", 0, startY + 10)
    
    local lblTex = CreateLabel("Texture", f, startY - 30)
    local texItems = {}
    for name, _ in pairs(Skin.Media.Textures) do table.insert(texItems, {text = name, value = name}) end
    table.sort(texItems, function(a,b) return a.text < b.text end)
    local ddTex = Skin:CreateDropdown(f, 200, texItems, function(val) addon.db[MOD_KEY].Texture = val; BF:UpdateStyle() end)
    ddTex:SetPoint("LEFT", lblTex, "LEFT", 0, -25); ddTex.text:SetText(addon.db[MOD_KEY].Texture or "Select..."); ddTex:SetFrameLevel(f:GetFrameLevel() + 10)

    -- FONT
    local lblFont = CreateLabel("Font", f, startY - 80)
    local fontItems = {}
    for name, _ in pairs(Skin.Media.Fonts) do table.insert(fontItems, {text = name, value = name}) end
    table.sort(fontItems, function(a,b) return a.text < b.text end)
    local ddFont = Skin:CreateDropdown(f, 200, fontItems, function(val) addon.db[MOD_KEY].Font = val; BF:UpdateStyle() end)
    ddFont:SetPoint("LEFT", lblFont, "LEFT", 0, -25); ddFont.text:SetText(addon.db[MOD_KEY].Font or "Select..."); ddFont:SetFrameLevel(f:GetFrameLevel() + 10)

    -- FONT OUTLINE [YENİ]
    local lblOutline = CreateLabel("Font Outline", f, startY - 130)
    local outlineItems = { {text="None", value=""}, {text="Outline", value="OUTLINE"}, {text="Thick", value="THICKOUTLINE"}, {text="Monochrome", value="MONOCHROME"} }
    local ddOutline = Skin:CreateDropdown(f, 200, outlineItems, function(val) addon.db[MOD_KEY].FontOutline = val; BF:UpdateStyle() end)
    ddOutline:SetPoint("LEFT", lblOutline, "LEFT", 0, -25); ddOutline.text:SetText(addon.db[MOD_KEY].FontOutline or "OUTLINE"); ddOutline:SetFrameLevel(f:GetFrameLevel() + 10)

    -- FONT SIZE
    local lblFSize = CreateLabel("Font Size", f, startY - 180)
    local sFSize = Skin:CreateSlider(f, 8, 30, 1, addon.db[MOD_KEY].FontSize or 12, function(val) addon.db[MOD_KEY].FontSize = val; BF:UpdateStyle() end, 200)
    sFSize:SetPoint("LEFT", lblFSize, "LEFT", 0, -25)

    -- BORDER
    local lblBorder = CreateLabel("Border", f, startY - 230)
    local sBorder = Skin:CreateSlider(f, 0, 10, 1, addon.db[MOD_KEY].BorderSize or 1, function(val) addon.db[MOD_KEY].BorderSize = val; BF:UpdateStyle() end, 100)
    sBorder:SetPoint("LEFT", lblBorder, "LEFT", 0, -25)
    
    local posItems = {{text="Inside", value="INSIDE"}, {text="Center", value="CENTER"}, {text="Outside", value="OUTSIDE"}}
    local ddPos = Skin:CreateDropdown(f, 110, posItems, function(val) addon.db[MOD_KEY].BorderPosition = val; BF:UpdateStyle() end)
    ddPos:SetPoint("LEFT", sBorder, "RIGHT", 15, 0); ddPos.text:SetText(addon.db[MOD_KEY].BorderPosition or "OUTSIDE"); ddPos:SetFrameLevel(f:GetFrameLevel() + 20) 

    -- === MAIN BAR ===
    local mainY = startY - 300
    Skin:CreateSectionHeader(f, "Main Bar Size", 340):SetPoint("TOP", 0, mainY + 10)
    
    local sWidth = Skin:CreateSlider(f, 100, 600, 10, addon.db[MOD_KEY].Width, function(val) addon.db[MOD_KEY].Width = val; BF:UpdateStyle() end, 150)
    sWidth:SetPoint("TOPLEFT", 20, mainY - 40)
    
    local sHeight = Skin:CreateSlider(f, 10, 100, 1, addon.db[MOD_KEY].Height, function(val) addon.db[MOD_KEY].Height = val; BF:UpdateStyle() end, 150)
    sHeight:SetPoint("LEFT", sWidth, "RIGHT", 10, 0)

    -- === PARTY BARS [GÜNCELLENDİ - X/Y SİLİNDİ, YENİ AYARLAR GELDİ] ===
    local partyY = mainY - 90
    Skin:CreateSectionHeader(f, "Party Bars", 340):SetPoint("TOP", 0, partyY + 10)
    
    local sPWidth = Skin:CreateSlider(f, 100, 400, 10, addon.db[MOD_KEY].PartyWidth or 200, function(val) addon.db[MOD_KEY].PartyWidth = val end, 150)
    sPWidth:SetPoint("TOPLEFT", 20, partyY - 40)
    
    local sPHeight = Skin:CreateSlider(f, 10, 50, 1, addon.db[MOD_KEY].PartyHeight or 30, function(val) addon.db[MOD_KEY].PartyHeight = val end, 150)
    sPHeight:SetPoint("LEFT", sPWidth, "RIGHT", 10, 0)

    local sPIcon = Skin:CreateSlider(f, 10, 50, 1, addon.db[MOD_KEY].PartyIconSize or 30, function(val) addon.db[MOD_KEY].PartyIconSize = val end, 150)
    sPIcon:SetPoint("TOPLEFT", sPWidth, "BOTTOMLEFT", 0, -30)

    local sPSpacing = Skin:CreateSlider(f, 0, 20, 1, addon.db[MOD_KEY].PartySpacing or 5, function(val) addon.db[MOD_KEY].PartySpacing = val end, 150)
    sPSpacing:SetPoint("LEFT", sPIcon, "RIGHT", 10, 0)

    -- === COLORS ===
    local colorY = partyY - 160
    Skin:CreateSectionHeader(f, "Colors", 340):SetPoint("TOP", 0, colorY + 10)

    local cpBar = Skin:CreateColorPicker(f, "Cooldown Color", HexToColorTable(addon.db[MOD_KEY].ColorCooldown), function(c) addon.db[MOD_KEY].ColorCooldown = ColorTableToHex(c); BF:UpdateStyle() end, 340)
    cpBar:SetPoint("TOPLEFT", 20, colorY - 30)

    local cpInt = Skin:CreateColorPicker(f, "Ready Color", HexToColorTable(addon.db[MOD_KEY].ColorReady), function(c) addon.db[MOD_KEY].ColorReady = ColorTableToHex(c); BF:UpdateStyle() end, 340)
    cpInt:SetPoint("TOPLEFT", 20, colorY - 70)

    local cpShield = Skin:CreateColorPicker(f, "Shield Color", HexToColorTable(addon.db[MOD_KEY].NotInterruptibleColor), function(c) addon.db[MOD_KEY].NotInterruptibleColor = ColorTableToHex(c); BF:UpdateStyle() end, 340)
    cpShield:SetPoint("TOPLEFT", 20, colorY - 110)

    -- === BUTTONS ===
    local btnTest = Skin:CreateButton(f, "Toggle Test", 140, 30)
    btnTest:SetPoint("BOTTOMLEFT", 20, 40)
    btnTest:SetScript("OnClick", function() BF:Test() end)
    
    local btnUnlock = Skin:CreateButton(f, "Unlock / Move", 140, 30)
    btnUnlock:SetPoint("BOTTOMRIGHT", -20, 40)
    if Skin.Colors and Skin.Colors.accent then btnUnlock:SetBackdropColor(unpack(Skin.Colors.accent)) end
    btnUnlock:SetScript("OnClick", function() BF:ToggleUnlock() end)

    BF.ConfigFrame = f
end