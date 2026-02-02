local ADDON_NAME, ns = ...
local addon = ns
local BF = BreakForge
local Skin = ForgeSkin
local MOD_KEY = "BreakForge"

-- ============================================================================
-- YARDIMCI FONKSİYONLAR
-- ============================================================================

-- 1. SKIN UYUMLU SLIDER
local function CreateSkinSlider(parent, labelText, key, minVal, maxVal, step)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 40)
    
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(labelText)
    
    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
    slider:SetWidth(200)
    slider:SetHeight(15)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    
    -- ForgeSkin ile Süsleme
    if Skin.ApplyBackdrop then
        Skin:ApplyBackdrop(slider)
        if Skin.Colors and Skin.Colors.bg then 
            slider:SetBackdropColor(unpack(Skin.Colors.bg)) 
        else
            slider:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if Skin.SetSmartBorder then Skin:SetSmartBorder(slider) end
    end

    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("CENTER", slider, "CENTER", 0, 0)
    
    -- Değer Yükleme
    local currentVal = addon.db[MOD_KEY][key] or minVal
    slider:SetValue(currentVal)
    valueText:SetText(currentVal)

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10 
        addon.db[MOD_KEY][key] = value
        valueText:SetText(value)
        BF:UpdateStyle()
    end)
    
    return frame
end

-- 2. RENK SEÇİCİ (YENİ WOW API UYUMLU)
local function CreateColorButton(parent, labelText, key)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 30)
    
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)
    
    -- Butonu Skin'in kendi fonksiyonuyla oluşturuyoruz (Varsa)
    local btn
    if Skin.CreateButton then
        btn = Skin:CreateButton(frame, "", 40, 20)
    else
        btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(40, 20)
        Skin:ApplyBackdrop(btn)
    end
    btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    
    local function UpdateBtnColor()
        local hex = addon.db[MOD_KEY][key]
        local r, g, b = addon.Utilities:HexToRGB(hex)
        -- ForgeSkin buton rengini eziyoruz ki seçilen renk görünsün
        btn:SetBackdropColor(r, g, b, 1)
    end
    UpdateBtnColor()
    
    btn:SetScript("OnClick", function()
        local r, g, b = addon.Utilities:HexToRGB(addon.db[MOD_KEY][key])
        
        -- [FIX] YENİ API (ColorPickerFrame)
        local info = {
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local hex = string.format("%02x%02x%02x", nr*255, ng*255, nb*255)
                addon.db[MOD_KEY][key] = hex
                UpdateBtnColor()
                BF:UpdateStyle()
            end,
            cancelFunc = function(restore)
                -- restore eski API'de değerler listesiyken, yenisinde obje dönebilir.
                -- Güvenlik için yeniden eski değeri hesaplıyoruz.
                local hex = string.format("%02x%02x%02x", r*255, g*255, b*255)
                addon.db[MOD_KEY][key] = hex
                UpdateBtnColor()
                BF:UpdateStyle()
            end,
            r = r, g = g, b = b,
            hasOpacity = false,
            opacity = 1.0,
        }
        
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    return frame
end

-- ============================================================================
-- ANA PENCERE (ForgeSkin Style)
-- ============================================================================

function BF:ToggleConfig()
    if BF.ConfigFrame then
        if BF.ConfigFrame:IsShown() then BF.ConfigFrame:Hide() else BF.ConfigFrame:Show() end
        return
    end

    local f = CreateFrame("Frame", "BreakForgeConfig", UIParent)
    f:SetSize(320, 520)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- 1. ForgeSkin Ana Zemin
    Skin:ApplyBackdrop(f)
    if Skin.Colors and Skin.Colors.bg then
        f:SetBackdropColor(unpack(Skin.Colors.bg))
    else
        f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    end
    Skin:SetSmartBorder(f)

    -- 2. Title Bar (Header)
    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(25)
    if Skin.Colors and Skin.Colors.titleBg then
        header:SetColorTexture(unpack(Skin.Colors.titleBg))
    else
        header:SetColorTexture(0.1, 0.1, 0.1, 1)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", header, "LEFT", 10, 0)
    title:SetText("Break Forge")

    -- 3. Kapat Butonu (ForgeSkin Button)
    local closeBtn = Skin:CreateButton(f, "X", 20, 20)
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    -- Kapat butonu kırmızı olsun
    closeBtn:SetBackdropColor(0.6, 0.1, 0.1, 1)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ==========================================================
    -- AYARLAR
    -- ==========================================================
    local offsetY = -40

    -- [BOYUTLAR]
    local sWidth = CreateSkinSlider(f, "Bar Genisligi", "Width", 100, 600, 10)
    sWidth:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 50

    local sHeight = CreateSkinSlider(f, "Bar Yuksekligi", "Height", 10, 100, 1)
    sHeight:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 50

    -- [POZİSYON]
    local sX = CreateSkinSlider(f, "X Konumu", "X", -1000, 1000, 10)
    sX:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 50

    local sY = CreateSkinSlider(f, "Y Konumu", "Y", -1000, 1000, 10)
    sY:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 50

    -- [RENKLER]
    local cBar = CreateColorButton(f, "Cast Bar Rengi", "CooldownColor")
    cBar:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 35

    local cShield = CreateColorButton(f, "Shield (Kesilemez) Rengi", "NotInterruptibleColor")
    cShield:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 35

    local cInt = CreateColorButton(f, "Interrupt Hazir Rengi", "InterruptibleColor")
    cInt:SetPoint("TOP", 0, offsetY); offsetY = offsetY - 50

    -- [TEST BUTONU]
    local testBtn = Skin:CreateButton(f, "Test Modu", 120, 30)
    testBtn:SetPoint("BOTTOM", 0, 20)
    if Skin.Colors and Skin.Colors.accent then
        testBtn:SetBackdropColor(unpack(Skin.Colors.accent)) -- Varsa tema rengini kullan
    end
    
    testBtn:SetScript("OnClick", function()
        BF:Test(true)
        C_Timer.After(3, function() BF:Test(false) end)
    end)

    BF.ConfigFrame = f
end