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
    f:SetSize(360, 680) -- Boyutu büyüttük çünkü yeni ayarlar geldi
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

    -- === GÖRSEL AYARLAR ===
    Skin:CreateSectionHeader(f, "Visual Settings", 320):SetPoint("TOP", 0, startY + 10)
    
    -- [1] TEXTURE
    local lblTex = CreateLabel("Texture", f, startY - 30)
    local texItems = {}
    for name, _ in pairs(Skin.Media.Textures) do table.insert(texItems, {text = name, value = name}) end
    table.sort(texItems, function(a,b) return a.text < b.text end)
    local ddTex = Skin:CreateDropdown(f, 200, texItems, function(val) addon.db[MOD_KEY].Texture = val; BF:UpdateStyle() end)
    ddTex:SetPoint("LEFT", lblTex, "LEFT", 0, -25)
    ddTex.text:SetText(addon.db[MOD_KEY].Texture or "Select...")

    -- [2] FONT
    local lblFont = CreateLabel("Font", f, startY - 80)
    local fontItems = {}
    for name, _ in pairs(Skin.Media.Fonts) do table.insert(fontItems, {text = name, value = name}) end
    table.sort(fontItems, function(a,b) return a.text < b.text end)
    local ddFont = Skin:CreateDropdown(f, 200, fontItems, function(val) addon.db[MOD_KEY].Font = val; BF:UpdateStyle() end)
    ddFont:SetPoint("LEFT", lblFont, "LEFT", 0, -25)
    ddFont.text:SetText(addon.db[MOD_KEY].Font or "Select...")

    -- [3] FONT SIZE
    local lblFSize = CreateLabel("Font Size", f, startY - 130)
    local sFSize = Skin:CreateSlider(f, 8, 30, 1, addon.db[MOD_KEY].FontSize or 12, function(val) 
        addon.db[MOD_KEY].FontSize = val; BF:UpdateStyle() 
    end, 200)
    sFSize:SetPoint("LEFT", lblFSize, "LEFT", 0, -25)

    -- [4] BORDER SIZE & POSITION
    local lblBorder = CreateLabel("Border", f, startY - 180)
    local sBorder = Skin:CreateSlider(f, 0, 10, 1, addon.db[MOD_KEY].BorderSize or 1, function(val)
        addon.db[MOD_KEY].BorderSize = val; BF:UpdateStyle()
    end, 100)
    sBorder:SetPoint("LEFT", lblBorder, "LEFT", 0, -25)
    
    -- Border Position Dropdown
    local posItems = {
        {text = "Inside", value = "INSIDE"},
        {text = "Center", value = "CENTER"},
        {text = "Outside", value = "OUTSIDE"}
    }
    local ddPos = Skin:CreateDropdown(f, 95, posItems, function(val) addon.db[MOD_KEY].BorderPosition = val; BF:UpdateStyle() end)
    ddPos:SetPoint("LEFT", sBorder, "RIGHT", 5, 0)
    ddPos.text:SetText(addon.db[MOD_KEY].BorderPosition or "OUTSIDE")

    -- === BOYUT & KONUM ===
    local sizeY = startY - 250
    Skin:CreateSectionHeader(f, "Size & Position", 320):SetPoint("TOP", 0, sizeY + 10)
    
    local sWidth = Skin:CreateSlider(f, 100, 600, 10, addon.db[MOD_KEY].Width, function(val) addon.db[MOD_KEY].Width = val; BF:UpdateStyle() end, 150)
    sWidth:SetPoint("TOPLEFT", 20, sizeY - 40)
    
    local sHeight = Skin:CreateSlider(f, 10, 100, 1, addon.db[MOD_KEY].Height, function(val) addon.db[MOD_KEY].Height = val; BF:UpdateStyle() end, 150)
    sHeight:SetPoint("LEFT", sWidth, "RIGHT", 10, 0)

    local sX = Skin:CreateSlider(f, -1000, 1000, 10, addon.db[MOD_KEY].X, function(val) addon.db[MOD_KEY].X = val; BF:UpdateStyle() end, 150)
    sX:SetPoint("TOPLEFT", sWidth, "BOTTOMLEFT", 0, -30)
    
    local sY = Skin:CreateSlider(f, -1000, 1000, 10, addon.db[MOD_KEY].Y, function(val) addon.db[MOD_KEY].Y = val; BF:UpdateStyle() end, 150)
    sY:SetPoint("LEFT", sX, "RIGHT", 10, 0)

    -- === RENKLER ===
    local colorY = sizeY - 140
    Skin:CreateSectionHeader(f, "Colors", 320):SetPoint("TOP", 0, colorY + 10)

    local cpBar = Skin:CreateColorPicker(f, "Cooldown Color (Waiting)", HexToColorTable(addon.db[MOD_KEY].CooldownColor), function(c) addon.db[MOD_KEY].CooldownColor = ColorTableToHex(c); BF:UpdateStyle() end, 320)
    cpBar:SetPoint("TOPLEFT", 20, colorY - 30)

    local cpInt = Skin:CreateColorPicker(f, "Ready Color (Interrupt!)", HexToColorTable(addon.db[MOD_KEY].InterruptibleColor), function(c) addon.db[MOD_KEY].InterruptibleColor = ColorTableToHex(c); BF:UpdateStyle() end, 320)
    cpInt:SetPoint("TOPLEFT", 20, colorY - 70)

    local cpShield = Skin:CreateColorPicker(f, "Shield Color (Uninterruptible)", HexToColorTable(addon.db[MOD_KEY].NotInterruptibleColor), function(c) addon.db[MOD_KEY].NotInterruptibleColor = ColorTableToHex(c); BF:UpdateStyle() end, 320)
    cpShield:SetPoint("TOPLEFT", 20, colorY - 110)

    -- === TEST BUTONU ===
    local btnTest = Skin:CreateButton(f, "Test Mode", 140, 30)
    btnTest:SetPoint("BOTTOM", 0, 30)
    btnTest:SetScript("OnClick", function() BF:Test(true); C_Timer.After(3, function() BF:Test(false) end) end)

    BF.ConfigFrame = f
end