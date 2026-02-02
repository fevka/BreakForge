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
    f:SetSize(380, 750) -- Party ayarları için uzattık
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
    ddTex:SetPoint("LEFT", lblTex, "LEFT", 0, -25)
    ddTex.text:SetText(addon.db[MOD_KEY].Texture or "Select...")

    local lblFont = CreateLabel("Font", f, startY - 80)
    local fontItems = {}
    for name, _ in pairs(Skin.Media.Fonts) do table.insert(fontItems, {text = name, value = name}) end
    table.sort(fontItems, function(a,b) return a.text < b.text end)
    local ddFont = Skin:CreateDropdown(f, 200, fontItems, function(val) addon.db[MOD_KEY].Font = val; BF:UpdateStyle() end)
    ddFont:SetPoint("LEFT", lblFont, "LEFT", 0, -25)
    ddFont.text:SetText(addon.db[MOD_KEY].Font or "Select...")

    local lblFSize = CreateLabel("Font Size", f, startY - 130)
    local sFSize = Skin:CreateSlider(f, 8, 30, 1, addon.db[MOD_KEY].FontSize or 12, function(val) 
        addon.db[MOD_KEY].FontSize = val; BF:UpdateStyle() 
    end, 200)
    sFSize:SetPoint("LEFT", lblFSize, "LEFT", 0, -25)

    local lblBorder = CreateLabel("Border", f, startY - 180)
    local sBorder = Skin:CreateSlider(f, 0, 10, 1, addon.db[MOD_KEY].BorderSize or 1, function(val)
        addon.db[MOD_KEY].BorderSize = val; BF:UpdateStyle()
    end, 100)
    sBorder:SetPoint("LEFT", lblBorder, "LEFT", 0, -25)
    
    local posItems = {{text = "Inside", value = "INSIDE"}, {text = "Center", value = "CENTER"}, {text = "Outside", value = "OUTSIDE"}}
    local ddPos = Skin:CreateDropdown(f, 95, posItems, function(val) addon.db[MOD_KEY].BorderPosition = val; BF:UpdateStyle() end)
    ddPos:SetPoint("LEFT", sBorder, "RIGHT", 5, 0)
    ddPos.text:SetText(addon.db[MOD_KEY].BorderPosition or "OUTSIDE")

    -- === SIZE & POSITION ===
    local sizeY = startY - 250
    Skin:CreateSectionHeader(f, "Main Bar", 340):SetPoint("TOP", 0, sizeY + 10)
    
    local sWidth = Skin:CreateSlider(f, 100, 600, 10, addon.db[MOD_KEY].Width, function(val) addon.db[MOD_KEY].Width = val; BF:UpdateStyle() end, 150)
    sWidth:SetPoint("TOPLEFT", 20, sizeY - 40)
    
    local sHeight = Skin:CreateSlider(f, 10, 100, 1, addon.db[MOD_KEY].Height, function(val) addon.db[MOD_KEY].Height = val; BF:UpdateStyle() end, 150)
    sHeight:SetPoint("LEFT", sWidth, "RIGHT", 10, 0)

    local sX = Skin:CreateSlider(f, -1000, 1000, 10, addon.db[MOD_KEY].X, function(val) addon.db[MOD_KEY].X = val; BF:UpdateStyle() end, 150)
    sX:SetPoint("TOPLEFT", sWidth, "BOTTOMLEFT", 0, -30)
    
    local sY = Skin:CreateSlider(f, -1000, 1000, 10, addon.db[MOD_KEY].Y, function(val) addon.db[MOD_KEY].Y = val; BF:UpdateStyle() end, 150)
    sY:SetPoint("LEFT", sX, "RIGHT", 10, 0)

    -- === PARTY SETTINGS [YENİ] ===
    local partyY = sizeY - 140
    Skin:CreateSectionHeader(f, "Party Bars", 340):SetPoint("TOP", 0, partyY + 10)
    
    local sPWidth = Skin:CreateSlider(f, 100, 400, 10, addon.db[MOD_KEY].PartyWidth or 200, function(val) addon.db[MOD_KEY].PartyWidth = val end, 150)
    sPWidth:SetPoint("TOPLEFT", 20, partyY - 40)
    
    local sPHeight = Skin:CreateSlider(f, 10, 50, 1, addon.db[MOD_KEY].PartyHeight or 20, function(val) addon.db[MOD_KEY].PartyHeight = val end, 150)
    sPHeight:SetPoint("LEFT", sPWidth, "RIGHT", 10, 0)
    
    local sPX = Skin:CreateSlider(f, -1000, 1000, 10, addon.db[MOD_KEY].PartyX or -200, function(val) addon.db[MOD_KEY].PartyX = val; BF:UpdateStyle() end, 150)
    sPX:SetPoint("TOPLEFT", sPWidth, "BOTTOMLEFT", 0, -30)
    
    local sPY = Skin:CreateSlider(f, -1000, 1000, 10, addon.db[MOD_KEY].PartyY or 0, function(val) addon.db[MOD_KEY].PartyY = val; BF:UpdateStyle() end, 150)
    sPY:SetPoint("LEFT", sPX, "RIGHT", 10, 0)

    -- === COLORS ===
    local colorY = partyY - 140
    Skin:CreateSectionHeader(f, "Colors", 340):SetPoint("TOP", 0, colorY + 10)

    local cpBar = Skin:CreateColorPicker(f, "Cooldown Color", HexToColorTable(addon.db[MOD_KEY].CooldownColor), function(c) addon.db[MOD_KEY].CooldownColor = ColorTableToHex(c); BF:UpdateStyle() end, 340)
    cpBar:SetPoint("TOPLEFT", 20, colorY - 30)

    local cpInt = Skin:CreateColorPicker(f, "Ready Color", HexToColorTable(addon.db[MOD_KEY].InterruptibleColor), function(c) addon.db[MOD_KEY].InterruptibleColor = ColorTableToHex(c); BF:UpdateStyle() end, 340)
    cpInt:SetPoint("TOPLEFT", 20, colorY - 70)

    local cpShield = Skin:CreateColorPicker(f, "Shield Color", HexToColorTable(addon.db[MOD_KEY].NotInterruptibleColor), function(c) addon.db[MOD_KEY].NotInterruptibleColor = ColorTableToHex(c); BF:UpdateStyle() end, 340)
    cpShield:SetPoint("TOPLEFT", 20, colorY - 110)

    -- === BUTTONS ===
    local btnTest = Skin:CreateButton(f, "Toggle Test", 140, 30)
    btnTest:SetPoint("BOTTOMLEFT", 20, 30)
    btnTest:SetScript("OnClick", function() BF:Test() end)
    
    local btnUnlock = Skin:CreateButton(f, "Unlock / Move", 140, 30)
    btnUnlock:SetPoint("BOTTOMRIGHT", -20, 30)
    if Skin.Colors and Skin.Colors.accent then btnUnlock:SetBackdropColor(unpack(Skin.Colors.accent)) end
    btnUnlock:SetScript("OnClick", function() BF:ToggleUnlock() end)

    BF.ConfigFrame = f
end