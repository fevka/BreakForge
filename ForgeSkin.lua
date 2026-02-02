ForgeSkin = {}
local Skin = ForgeSkin

Skin.Clipboard = nil 

-------------------------------------------------------------------------
-- 1. DESIGN PARAMETERS (Colors & Fonts)
-------------------------------------------------------------------------
Skin.Colors = {
    bg = {0.05, 0.05, 0.05, 0.95},      
    titleBg = {0.1, 0.1, 0.1, 1},       
    border = {0.2, 0.2, 0.2, 1},        
    accent = {0, 0.8, 1, 1},            
    accentHover = {0.2, 0.9, 1, 1},     
    ready = {0, 1, 0.5, 1},             
    cd = {1, 0.3, 0.3, 1},              
    text = {0.9, 0.9, 0.9, 1},          
    textDim = {0.6, 0.6, 0.6, 1},       
    button = {0.15, 0.15, 0.15, 0.9},
    buttonHover = {0.25, 0.25, 0.25, 0.9},
}

Skin.Constants = {
    FONT_NORMAL = "Fonts\\FRIZQT__.TTF",
    FONT_SIZE_NORMAL = 12,
    FONT_SIZE_SMALL = 10,
    BACKDROP_EDGE_SIZE = 1,
}

-- MEDIA LIBRARY
Skin.Media = {
    Textures = {
        ["1. Flat"] = "Interface\\Buttons\\WHITE8x8",
        ["2. Smooth"] = "Interface\\TargetingFrame\\UI-StatusBar",
        ["3. Blizzard"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
        ["4. Aluminium"] = "Interface\\RaidFrame\\Shield-Fill",
        ["5. Grayscale"] = "Interface\\RaidFrame\\Raid-Bar-Resource-Fill",
        ["6. Character"] = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
        ["7. Absorb"] = "Interface\\RaidFrame\\Absorb-Fill",
        ["8. Otter"] = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
    },
    Fonts = {
        ["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF",
        ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\skurri.ttf",
        ["2002"] = "Fonts\\2002.ttf",
        ["Damage"] = "Fonts\\K_Damage.TTF", 
    },
    Outlines = {
        {text = "None", value = ""},
        {text = "Outline", value = "OUTLINE"},
        {text = "Thick", value = "THICKOUTLINE"},
        {text = "Monochrome", value = "MONOCHROME"},
        {text = "Mono+Outline", value = "MONOCHROME,OUTLINE"},
    }
}

-------------------------------------------------------------------------
-- COLOR UTILITIES
-------------------------------------------------------------------------
function Skin:RGBToHSV(r, g, b)
    local min = math.min(r, g, b)
    local max = math.max(r, g, b)
    local delta = max - min
    local h, s, v = 0, 0, max
    if delta ~= 0 then
        s = delta / max
        local dr = (((max - r) / 6) + (delta / 2)) / delta
        local dg = (((max - g) / 6) + (delta / 2)) / delta
        local db = (((max - b) / 6) + (delta / 2)) / delta
        if r == max then h = db - dg
        elseif g == max then h = (1 / 3) + dr - db
        else h = (2 / 3) + dg - dr end
        if h < 0 then h = h + 1 end
        if h > 1 then h = h - 1 end
    end
    return h, s, v
end

function Skin:HSVToRGB(h, s, v)
    if s == 0 then return v, v, v end
    local var_h = h * 6
    if var_h == 6 then var_h = 0 end
    local var_i = math.floor(var_h)
    local var_1 = v * (1 - s)
    local var_2 = v * (1 - s * (var_h - var_i))
    local var_3 = v * (1 - s * (1 - (var_h - var_i)))
    if var_i == 0 then return v, var_3, var_1
    elseif var_i == 1 then return var_2, v, var_1
    elseif var_i == 2 then return var_1, v, var_3
    elseif var_i == 3 then return var_1, var_2, v
    elseif var_i == 4 then return var_3, var_1, v
    else return v, var_1, var_2 end
end

function Skin:ApplyBackdrop(frame, bgAlpha, borderAlpha)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, edgeSize = Skin.Constants.BACKDROP_EDGE_SIZE,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    local bg = Skin.Colors.bg
    local border = Skin.Colors.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bgAlpha or bg[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], borderAlpha or border[4])
end

-------------------------------------------------------------------------
-- WIDGET FACTORY
-------------------------------------------------------------------------
function Skin:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 120, height or 30)
    self:ApplyBackdrop(btn)
    btn:SetBackdropColor(unpack(Skin.Colors.button))
    btn:SetBackdropBorderColor(unpack(Skin.Colors.border))
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetFont(Skin.Constants.FONT_NORMAL, Skin.Constants.FONT_SIZE_NORMAL, "OUTLINE")
    btn.text:SetTextColor(unpack(Skin.Colors.text))
    
    btn:SetScript("OnEnter", function(self)
        if self.IsEnabled and not self:IsEnabled() then return end
        self:SetBackdropColor(unpack(Skin.Colors.buttonHover))
        self:SetBackdropBorderColor(unpack(Skin.Colors.accent))
    end)
    btn:SetScript("OnLeave", function(self)
        if self.IsEnabled and not self:IsEnabled() then return end
        self:SetBackdropColor(unpack(Skin.Colors.button))
        self:SetBackdropBorderColor(unpack(Skin.Colors.border))
    end)
    btn:SetScript("OnMouseDown", function(self) if self.IsEnabled and not self:IsEnabled() then return end self.text:SetPoint("CENTER", 1, -1) end)
    btn:SetScript("OnMouseUp", function(self) self.text:SetPoint("CENTER", 0, 0) end)
    return btn
end

function Skin:CreateCheckbox(parent, text, checked, callback)
    local cb = CreateFrame("Frame", nil, parent)
    cb:SetSize(200, 20)
    cb.box = CreateFrame("Frame", nil, cb, "BackdropTemplate")
    cb.box:SetSize(18, 18); cb.box:SetPoint("LEFT", 0, 0)
    self:ApplyBackdrop(cb.box); cb.box:SetBackdropColor(0.15, 0.15, 0.15, 1)
    
    cb.check = cb.box:CreateTexture(nil, "OVERLAY")
    cb.check:SetTexture("Interface\\Buttons\\WHITE8x8")
    cb.check:SetPoint("CENTER"); cb.check:SetSize(10, 10)
    cb.check:SetVertexColor(unpack(Skin.Colors.accent))
    cb.check:Hide()
    
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.label:SetPoint("LEFT", cb.box, "RIGHT", 8, 0)
    cb.label:SetText(text)
    cb.label:SetFont(Skin.Constants.FONT_NORMAL, 11, "OUTLINE")
    cb.label:SetTextColor(unpack(Skin.Colors.text))
    
    cb.checked = checked; cb.callback = callback
    function cb:SetChecked(val)
        self.checked = val
        if val then self.check:Show() else self.check:Hide() end
        if self.callback then self.callback(val) end
    end
    cb.box:EnableMouse(true); cb.box:SetScript("OnMouseDown", function() cb:SetChecked(not cb.checked) end)
    cb:EnableMouse(true); cb:SetScript("OnMouseDown", function() cb:SetChecked(not cb.checked) end)
    if checked then cb.check:Show() else cb.check:Hide() end
    return cb
end

function Skin:CreateSlider(parent, min, max, step, value, callback, width)
    local slider = CreateFrame("Frame", nil, parent)
    slider:SetSize(width or 220, 30)
    local trackWidth = (width or 220) - 45
    slider.track = CreateFrame("Frame", nil, slider, "BackdropTemplate")
    slider.track:SetPoint("LEFT", 0, 0); slider.track:SetSize(trackWidth, 4)
    slider.track:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", tile=false, edgeSize=1})
    slider.track:SetBackdropColor(0.1, 0.1, 0.1, 1); slider.track:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    slider.fill = slider.track:CreateTexture(nil, "ARTWORK")
    slider.fill:SetTexture("Interface\\Buttons\\WHITE8x8"); slider.fill:SetPoint("LEFT", 1, 0); slider.fill:SetSize(1, 2)
    slider.fill:SetVertexColor(unpack(Skin.Colors.accent))
    
    slider.thumb = CreateFrame("Frame", nil, slider.track, "BackdropTemplate")
    slider.thumb:SetSize(14, 20); self:ApplyBackdrop(slider.thumb)
    slider.thumb:SetBackdropColor(0.6, 0.6, 0.6, 1); slider.thumb:SetBackdropBorderColor(0, 0, 0, 1)
    slider.thumb:EnableMouse(true)
    
    slider.min = min or 0; slider.max = max or 100; slider.step = step or 1; slider.value = value or slider.min; slider.callback = callback
    local edit = CreateFrame("EditBox", nil, slider, "BackdropTemplate")
    edit:SetSize(40, 20); edit:SetPoint("LEFT", slider.track, "RIGHT", 5, 0)
    edit:SetFont(Skin.Constants.FONT_NORMAL, 10, "OUTLINE"); edit:SetAutoFocus(false); edit:SetJustifyH("CENTER")
    self:ApplyBackdrop(edit); edit:SetBackdropColor(0, 0, 0, 0.5)
    
    edit:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then slider:SetValue(val) end
        self:ClearFocus()
    end)
    function slider:SetValue(val)
        val = math.max(self.min, math.min(self.max, val))
        if self.step then val = math.floor((val / self.step) + 0.5) * self.step end
        self.value = val
        local w = self.track:GetWidth()
        local pct = (val - self.min) / (self.max - self.min)
        if pct < 0 then pct = 0 end; if pct > 1 then pct = 1 end
        self.thumb:SetPoint("CENTER", self.track, "LEFT", pct * w, 0)
        self.fill:SetWidth(math.max(1, pct * (w - 2)))
        local text = (val < 1) and string.format("%.1f", val) or string.format("%.0f", val)
        if not edit:HasFocus() then edit:SetText(text) end
        if self.callback then self.callback(val) end
    end
    local function UpdateFromMouse()
        local px = GetCursorPosition() / UIParent:GetEffectiveScale()
        local trackLeft = slider.track:GetLeft()
        local trackWidth = slider.track:GetWidth()
        if not trackLeft or not trackWidth then return end
        local relative = (px - trackLeft) / trackWidth
        relative = math.max(0, math.min(1, relative))
        slider:SetValue(slider.min + (relative * (slider.max - slider.min)))
    end
    slider.thumb:SetScript("OnMouseDown", function() slider.dragging = true end)
    slider.thumb:SetScript("OnMouseUp", function() slider.dragging = false end)
    slider.track:EnableMouse(true)
    slider.track:SetScript("OnMouseDown", function() slider.dragging = true; UpdateFromMouse() end)
    slider.track:SetScript("OnMouseUp", function() slider.dragging = false end)
    slider.track:SetScript("OnUpdate", function() if slider.dragging then if IsMouseButtonDown("LeftButton") then UpdateFromMouse() else slider.dragging = false end end end)
    
    local cb = slider.callback; slider.callback = nil; slider:SetValue(value); slider.callback = cb
    return slider
end

function Skin:CreateScrollFrame(parent, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetSize(width, height)
    scrollFrame:EnableMouseWheel(true)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(width - 16, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    local scrollBar = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollBar:SetWidth(10)
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 0)
    scrollBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    scrollBar:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    
    local thumb = CreateFrame("Frame", nil, scrollBar, "BackdropTemplate")
    thumb:SetWidth(8); thumb:SetHeight(30); thumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)
    thumb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"}); thumb:SetBackdropColor(unpack(Skin.Colors.accent))
    thumb:EnableMouse(true); thumb:SetMovable(true)
    
    local function UpdateThumb()
        local range = scrollFrame:GetVerticalScrollRange()
        local barHeight = scrollBar:GetHeight()
        thumb:SetFrameLevel(scrollBar:GetFrameLevel() + 5)
        if range < 1 then
            scrollBar:SetAlpha(0.3); thumb:Hide(); thumb:EnableMouse(false)
        else
            scrollBar:SetAlpha(1); thumb:Show(); thumb:SetAlpha(1); thumb:EnableMouse(true); thumb:SetBackdropColor(unpack(Skin.Colors.accent))
            local viewRatio = height / (height + range)
            local thumbH = math.max(20, barHeight * viewRatio)
            thumbH = math.min(barHeight, thumbH)
            thumb:SetHeight(thumbH)
            local curr = scrollFrame:GetVerticalScroll()
            local pct = curr / range; if pct ~= pct then pct = 0 end
            local travel = barHeight - thumbH
            thumb:SetPoint("TOP", scrollBar, "TOP", 0, -(travel * pct))
        end
    end
    scrollFrame:SetScript("OnScrollRangeChanged", UpdateThumb)
    scrollFrame:SetScript("OnVerticalScroll", UpdateThumb)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll(); local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - (delta * 20))))
    end)
    thumb:SetScript("OnMouseDown", function(self)
        self.isDragging = true; self.startY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        self.startScroll = scrollFrame:GetVerticalScroll(); self:SetBackdropColor(1,1,1,1)
    end)
    thumb:SetScript("OnMouseUp", function(self) self.isDragging = false; self:SetBackdropColor(unpack(Skin.Colors.accent)) end)
    thumb:SetScript("OnUpdate", function(self)
        if self.isDragging then
            local currY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta = self.startY - currY
            local range = scrollFrame:GetVerticalScrollRange(); local travel = scrollBar:GetHeight() - self:GetHeight()
            if travel > 0 then
                local scrollDelta = (delta / travel) * range
                scrollFrame:SetVerticalScroll(math.max(0, math.min(range, self.startScroll + scrollDelta)))
            end
        end
    end)
    C_Timer.After(0.1, UpdateThumb)
    scrollFrame.scrollBar = scrollBar; scrollFrame.scrollThumb = thumb
    return scrollFrame, scrollChild
end

function Skin:CreateDropdown(parent, width, items, callback)
    local dd = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dd:SetSize(width, 25)
    self:ApplyBackdrop(dd, 0.6, 1) 
    
    dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dd.text:SetPoint("LEFT", 10, 0); dd.text:SetText("Select...")
    dd.text:SetWidth(width - 25); dd.text:SetJustifyH("LEFT")
    
    local btn = CreateFrame("Button", nil, dd); btn:SetAllPoints()
    local arrow = dd:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(8, 8); arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTexture("Interface\\Buttons\\WHITE8x8"); arrow:SetVertexColor(unpack(Skin.Colors.accent))
    
    local listContainer = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    listContainer:SetFrameStrata("FULLSCREEN_DIALOG") 
    listContainer:SetClampedToScreen(true)
    listContainer:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
    listContainer:SetWidth(width)
    
    self:ApplyBackdrop(listContainer, 0.95, 1)
    listContainer:SetBackdropBorderColor(unpack(Skin.Colors.accent))
    listContainer:Hide()
    
    dd:SetScript("OnHide", function() listContainer:Hide() end)
    
    local listScroll, listChild = Skin:CreateScrollFrame(listContainer, width - 4, 200) 
    listScroll:SetPoint("TOPLEFT", 2, -2); listScroll:SetPoint("BOTTOMRIGHT", -16, 2)
    
    local function RefreshList(newItems)
        items = newItems or items or {}
        for _, child in ipairs({listChild:GetChildren()}) do child:Hide() end
        local h = 0
        local btnWidth = listChild:GetWidth()
        for i, item in ipairs(items) do
            local b = CreateFrame("Button", nil, listChild)
            b:SetSize(btnWidth, 20)
            b:SetPoint("TOPLEFT", 0, -((i-1)*20))
            
            local t = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            t:SetPoint("LEFT", 5, 0)
            t:SetText(item.text)
            t:SetWidth(btnWidth - 10)
            t:SetJustifyH("LEFT")
            
            if item.font then
                t:SetFont(item.font, 12, "OUTLINE")
            end
            
            b:SetScript("OnEnter", function() t:SetTextColor(unpack(Skin.Colors.accent)) end)
            b:SetScript("OnLeave", function() t:SetTextColor(1, 1, 1) end)
            b:SetScript("OnClick", function()
                dd.text:SetText(item.text)
                listContainer:Hide()
                if callback then callback(item.value) end
            end)
            h = h + 20
        end
        
        listChild:SetHeight(h) 
        
        if h < 200 then
            listContainer:SetHeight(h + 4)
            listScroll:SetHeight(h)
        else
            listContainer:SetHeight(204)
            listScroll:SetHeight(200)
        end
    end
    
    if items then RefreshList(items) end
    dd.Refresh = RefreshList
    
    btn:SetScript("OnClick", function()
        if listContainer:IsShown() then listContainer:Hide() 
        else listContainer:Show(); listScroll:SetVerticalScroll(0) end
    end)
    
    listContainer:SetScript("OnShow", function(self)
        self:SetScript("OnUpdate", function(frame)
            if not MouseIsOver(frame) and not MouseIsOver(dd) then
                local mouseOver = false
                if MouseIsOver(frame) or MouseIsOver(dd) then mouseOver = true end
                if not mouseOver then
                    C_Timer.After(0.1, function()
                        if frame:IsShown() and not MouseIsOver(frame) and not MouseIsOver(dd) then frame:Hide() end
                    end)
                    frame:SetScript("OnUpdate", nil)
                end
            end
        end)
    end)
    listContainer:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    return dd
end

function Skin:GetColorPickerFrame()
    if Skin.ColorPickerFrame then return Skin.ColorPickerFrame end
    local f = CreateFrame("Frame", "ForgeColorPicker", UIParent, "BackdropTemplate")
    f:SetSize(350, 260); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing); f:Hide()
    self:ApplyBackdrop(f); f:SetBackdropColor(unpack(Skin.Colors.bg))
    Skin:CreateTitleBar(f, "Color Picker", function() if f.cancelFunc then f.cancelFunc() end f:Hide() end)
    
    local pickerHeight = 140; local pickerWidth = 140; local sliderWidth = 21; local gap = 10
    local sv = CreateFrame("Button", nil, f); sv:SetSize(pickerWidth, pickerHeight); sv:SetPoint("TOPLEFT", 10, -40)
    sv.hueBg = sv:CreateTexture(nil, "BACKGROUND", nil, 1); sv.hueBg:SetAllPoints(); sv.hueBg:SetColorTexture(1, 0, 0, 1)
    sv.satBg = sv:CreateTexture(nil, "BACKGROUND", nil, 2); sv.satBg:SetAllPoints(); sv.satBg:SetColorTexture(1, 1, 1, 1)
    if sv.satBg.SetGradient then sv.satBg:SetGradient("HORIZONTAL", CreateColor(1,1,1,1), CreateColor(1,1,1,0)) end
    sv.valBg = sv:CreateTexture(nil, "BACKGROUND", nil, 3); sv.valBg:SetAllPoints(); sv.valBg:SetColorTexture(0, 0, 0, 1)
    if sv.valBg.SetGradient then sv.valBg:SetGradient("VERTICAL", CreateColor(0,0,0,1), CreateColor(0,0,0,0)) end
    sv.thumb = CreateFrame("Frame", nil, sv, "BackdropTemplate"); sv.thumb:SetSize(8, 8); self:ApplyBackdrop(sv.thumb); sv.thumb:SetBackdropColor(1, 1, 1, 1); sv.thumb:SetBackdropBorderColor(0, 0, 0, 1); sv.thumb:SetPoint("CENTER", sv, "BOTTOMLEFT", 0, 0)
    
    local hue = CreateFrame("Button", nil, f); hue:SetSize(sliderWidth, pickerHeight); hue:SetPoint("TOPLEFT", sv, "TOPRIGHT", gap, 0)
    hue.bg = hue:CreateTexture(nil, "BACKGROUND"); hue.bg:SetAllPoints(); hue.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    local function CreateGradientSeg(parent, r1,g1,b1, r2,g2,b2, yStart, h)
        local t = parent:CreateTexture(nil, "ARTWORK"); t:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, yStart); t:SetSize(sliderWidth, h); t:SetColorTexture(1,1,1,1)
        if t.SetGradient then t:SetGradient("VERTICAL", CreateColor(r1,g1,b1,1), CreateColor(r2,g2,b2,1)) end
        return t
    end
    local segH = pickerHeight / 6
    CreateGradientSeg(hue, 1,0,1, 1,0,0, segH*5, segH); CreateGradientSeg(hue, 0,0,1, 1,0,1, segH*4, segH)
    CreateGradientSeg(hue, 0,1,1, 0,0,1, segH*3, segH); CreateGradientSeg(hue, 0,1,0, 0,1,1, segH*2, segH)
    CreateGradientSeg(hue, 1,1,0, 0,1,0, segH*1, segH); CreateGradientSeg(hue, 1,0,0, 1,1,0, 0, segH)
    hue.thumb = hue:CreateTexture(nil, "OVERLAY"); hue.thumb:SetSize(sliderWidth + 4, 6); hue.thumb:SetColorTexture(1,1,1,1); hue.thumb:SetPoint("CENTER")
    
    local alpha = CreateFrame("Button", nil, f); alpha:SetSize(sliderWidth, pickerHeight); alpha:SetPoint("TOPLEFT", hue, "TOPRIGHT", gap, 0)
    alpha.checkers = alpha:CreateTexture(nil, "BACKGROUND"); alpha.checkers:SetAllPoints(); alpha.checkers:SetColorTexture(0.5, 0.5, 0.5, 1)
    alpha.bg = alpha:CreateTexture(nil, "ARTWORK"); alpha.bg:SetAllPoints(); alpha.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    alpha.thumb = alpha:CreateTexture(nil, "OVERLAY"); alpha.thumb:SetSize(sliderWidth + 4, 6); alpha.thumb:SetColorTexture(1,1,1,1)
    
    local function CreateInput(label, parent, x, w, boxW, maxChars)
        local container = CreateFrame("Frame", nil, parent); container:SetSize(w, 24); container:SetPoint("TOPLEFT", sv, "BOTTOMLEFT", x, -10)
        local lbl = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); lbl:SetText(label); lbl:SetPoint("LEFT", 0, 0); lbl:SetTextColor(0.6, 0.6, 0.6)
        local eb = CreateFrame("EditBox", nil, container, "BackdropTemplate"); eb:SetSize(boxW, 18); eb:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        eb:SetFontObject("GameFontHighlightSmall"); eb:SetAutoFocus(false); Skin:ApplyBackdrop(eb); eb:SetBackdropColor(0,0,0,0.5); eb:SetJustifyH("CENTER"); eb:SetMaxLetters(maxChars or 3)
        return eb
    end
    local ebR = CreateInput("R", f, 0, 42, 28, 3); local ebG = CreateInput("G", f, 45, 42, 28, 3); local ebB = CreateInput("B", f, 90, 42, 28, 3)
    local ebHex = CreateInput("#", f, 135, 70, 57, 7)
    
    local rightStart = 10 + (140 + 10 + sliderWidth + 10 + sliderWidth) + 20; local totalWidth = 350; local previewX = rightStart; local endX = totalWidth - 10; local previewW = endX - previewX; local previewH = 80
    local preview = f:CreateTexture(nil, "ARTWORK"); preview:SetSize(previewW, previewH); preview:SetPoint("TOPLEFT", f, "TOPLEFT", previewX, -40); preview:SetColorTexture(1,1,1,1)
    local previewLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); previewLabel:SetPoint("CENTER", preview, "CENTER", 0, 0); previewLabel:SetText("NEW"); previewLabel:SetShadowColor(0,0,0,1); previewLabel:SetShadowOffset(1,-1); previewLabel:SetTextColor(1,1,1)
    local previewOld = f:CreateTexture(nil, "ARTWORK"); previewOld:SetSize(previewW, previewH); previewOld:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -10); previewOld:SetColorTexture(1,1,1,1)
    local previewOldLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); previewOldLabel:SetPoint("CENTER", previewOld, "CENTER", 0, 0); previewOldLabel:SetText("OLD"); previewOldLabel:SetShadowColor(0,0,0,1); previewOldLabel:SetShadowOffset(1,-1); previewOldLabel:SetTextColor(1,1,1)
    f.previewOld = previewOld
    
    local btnW, btnH = 70, 22; local bY = 10
    local btnCopy = Skin:CreateButton(f, "Copy", btnW, btnH); btnCopy:SetPoint("BOTTOMLEFT", 10, bY)
    local btnPaste = Skin:CreateButton(f, "Paste", btnW, btnH); btnPaste:SetPoint("LEFT", btnCopy, "RIGHT", 5, 0)
    local btnOk = Skin:CreateButton(f, "Okay", btnW, btnH); btnOk:SetPoint("BOTTOMRIGHT", -10, bY)
    local btnCancel = Skin:CreateButton(f, "Cancel", btnW, btnH); btnCancel:SetPoint("RIGHT", btnOk, "LEFT", -5, 0)
    
    f.h, f.s, f.v, f.a = 0, 1, 1, 1; local isUpdating = false
    local function UpdateColor(updateFields, sendCallback)
        if isUpdating then return end
        isUpdating = true
        local r, g, b = Skin:HSVToRGB(f.h, f.s, f.v)
        preview:SetColorTexture(r, g, b, f.a)
        if alpha.bg.SetGradient then alpha.bg:SetGradient("VERTICAL", CreateColor(r,g,b,0), CreateColor(r,g,b,1)) end
        local hr, hg, hb = Skin:HSVToRGB(f.h, 1, 1); sv.hueBg:SetColorTexture(hr, hg, hb, 1)
        local s = math.max(0, math.min(1, f.s)); local v = math.max(0, math.min(1, f.v))
        local h = math.max(0, math.min(1, f.h)); local a = math.max(0, math.min(1, f.a))
        sv.thumb:ClearAllPoints(); sv.thumb:SetPoint("CENTER", sv, "BOTTOMLEFT", s * pickerWidth, v * pickerHeight)
        hue.thumb:ClearAllPoints(); hue.thumb:SetPoint("CENTER", hue, "BOTTOMLEFT", sliderWidth/2, h * pickerHeight)
        alpha.thumb:ClearAllPoints(); alpha.thumb:SetPoint("CENTER", alpha, "BOTTOMLEFT", sliderWidth/2, a * pickerHeight)
        if updateFields then
            ebR:SetText(math.floor(r*255)); ebG:SetText(math.floor(g*255)); ebB:SetText(math.floor(b*255))
            ebHex:SetText(string.format("%02X%02X%02X", r*255, g*255, b*255))
        end
        if f.callback and sendCallback then f.callback({r, g, b, f.a}) end
        isUpdating = false
    end
    sv:SetScript("OnMouseDown", function() sv.down = true end); sv:SetScript("OnMouseUp", function() sv.down = false end)
    sv:SetScript("OnUpdate", function() if sv.down then local mx, my = GetCursorPosition(); local s = sv:GetEffectiveScale(); local x = (mx/s) - sv:GetLeft(); local y = (my/s) - sv:GetBottom(); f.s = math.max(0, math.min(1, x/pickerWidth)); f.v = math.max(0, math.min(1, y/pickerHeight)); UpdateColor(true, true) end end)
    hue:SetScript("OnMouseDown", function() hue.down = true end); hue:SetScript("OnMouseUp", function() hue.down = false end)
    hue:SetScript("OnUpdate", function() if hue.down then local _, my = GetCursorPosition(); local s = hue:GetEffectiveScale(); local y = (my/s) - hue:GetBottom(); f.h = math.max(0, math.min(1, y/pickerHeight)); UpdateColor(true, true) end end)
    alpha:SetScript("OnMouseDown", function() alpha.down = true end); alpha:SetScript("OnMouseUp", function() alpha.down = false end)
    alpha:SetScript("OnUpdate", function() if alpha.down then local _, my = GetCursorPosition(); local s = alpha:GetEffectiveScale(); local y = (my/s) - alpha:GetBottom(); f.a = math.max(0, math.min(1, y/pickerHeight)); UpdateColor(true, true) end end)
    local function OnInputChange()
        local r = tonumber(ebR:GetText()) or 0; local g = tonumber(ebG:GetText()) or 0; local b = tonumber(ebB:GetText()) or 0
        r = math.min(255, math.max(0, r)); g = math.min(255, math.max(0, g)); b = math.min(255, math.max(0, b))
        r, g, b = r/255, g/255, b/255; f.h, f.s, f.v = Skin:RGBToHSV(r, g, b); UpdateColor(true, true); ebR:ClearFocus(); ebG:ClearFocus(); ebB:ClearFocus()
    end
    ebR:SetScript("OnEnterPressed", OnInputChange); ebG:SetScript("OnEnterPressed", OnInputChange); ebB:SetScript("OnEnterPressed", OnInputChange)
    local function OnHexChange()
        local text = ebHex:GetText(); text = text:gsub("#", "")
        if #text == 6 then
            local r = tonumber(string.sub(text, 1, 2), 16); local g = tonumber(string.sub(text, 3, 4), 16); local b = tonumber(string.sub(text, 5, 6), 16)
            if r and g and b then f.h, f.s, f.v = Skin:RGBToHSV(r/255, g/255, b/255); UpdateColor(true, true) end
        end
        ebHex:ClearFocus()
    end
    ebHex:SetScript("OnEnterPressed", OnHexChange)
    btnOk:SetScript("OnClick", function() f:Hide() end)
    btnCancel:SetScript("OnClick", function() if f.cancelFunc then f.cancelFunc() end f:Hide() end)
    btnCopy:SetScript("OnClick", function() local r, g, b = Skin:HSVToRGB(f.h, f.s, f.v); Skin.Clipboard = {r, g, b, f.a}; print("|cff00ccffCopied color.|r") end)
    btnPaste:SetScript("OnClick", function() if not Skin.Clipboard then print("No color in clipboard.") return end local r, g, b, a = unpack(Skin.Clipboard); f.h, f.s, f.v = Skin:RGBToHSV(r, g, b); f.a = a; UpdateColor(true, true) end)
    f.UpdateColor = UpdateColor
    Skin.ColorPickerFrame = f
    return f
end

function Skin:ShowColorPicker(info)
    local f = self:GetColorPickerFrame()
    f.callback = info.swatchFunc; f.cancelFunc = info.cancelFunc
    local r, g, b, a = info.r, info.g, info.b, info.opacity or 1
    f.h, f.s, f.v = self:RGBToHSV(r, g, b); f.a = a
    if f.previewOld then f.previewOld:SetColorTexture(r, g, b, a) end
    f.UpdateColor(true, false); f:Show()
end

function Skin:CreateColorPicker(parent, label, defaultColor, callback, width)
    local cp = CreateFrame("Button", nil, parent); cp:SetSize(width or 460, 30); cp.colorData = defaultColor or {1, 1, 1, 1}
    local swatch = cp:CreateTexture(nil, "ARTWORK"); swatch:SetSize(40, 20); swatch:SetPoint("LEFT", 0, 0); swatch:SetColorTexture(unpack(cp.colorData))
    local border = CreateFrame("Frame", nil, cp, "BackdropTemplate"); border:SetAllPoints(swatch); self:ApplyBackdrop(border, 0, 1)
    local t = cp:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); t:SetPoint("LEFT", swatch, "RIGHT", 15, 0); t:SetText(label)
    cp:SetScript("OnClick", function()
        local r, g, b, a = unpack(cp.colorData)
        local info = {
            r = r, g = g, b = b, opacity = a,
            swatchFunc = function(c) local nr, ng, nb, na = unpack(c); cp.colorData = {nr, ng, nb, na}; swatch:SetColorTexture(nr, ng, nb, na); if callback then callback({nr, ng, nb, na}) end end,
            cancelFunc = function() cp.colorData = {r, g, b, a}; swatch:SetColorTexture(r, g, b, a); if callback then callback({r, g, b, a}) end end,
        }
        Skin:ShowColorPicker(info)
    end)
    return cp
end

function Skin:CreateSectionHeader(parent, text, width, showLine)
    local h = CreateFrame("Frame", nil, parent)
    h:SetSize(width or 450, 30)
    
    local t = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("BOTTOMLEFT", 0, 8) 
    t:SetText(string.upper(text))
    t:SetTextColor(unpack(Skin.Colors.accent))
    
    if showLine ~= false then 
        local line = h:CreateLine()
        line:SetColorTexture(0.2, 0.2, 0.2, 1)
        line:SetStartPoint("BOTTOMLEFT", 0, 0)
        line:SetEndPoint("BOTTOMRIGHT", 0, 0)
        line:SetThickness(1) 
    end
    
    return h
end

function Skin:CreateTitleBar(parent, titleText, onClose)
    local tb = CreateFrame("Frame", nil, parent, "BackdropTemplate"); tb:SetPoint("TOPLEFT", 1, -1); tb:SetPoint("TOPRIGHT", -1, -1); tb:SetHeight(30)
    tb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", tile = false, edgeSize = 1, insets = { left=0, right=0, top=0, bottom=0 }})
    tb:SetBackdropColor(unpack(Skin.Colors.titleBg)); tb:SetBackdropBorderColor(0, 0, 0, 1)
    local shadow = tb:CreateTexture(nil, "BACKGROUND"); shadow:SetPoint("TOPLEFT", tb, "BOTTOMLEFT", 0, 0); shadow:SetPoint("TOPRIGHT", tb, "BOTTOMRIGHT", 0, 0); shadow:SetHeight(8); shadow:SetTexture("Interface\\Buttons\\WHITE8x8")
    if shadow.SetGradient then shadow:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.6), CreateColor(0, 0, 0, 0)) else shadow:SetColorTexture(0, 0, 0, 0.3) end
    local line = tb:CreateLine(); line:SetColorTexture(0, 0, 0, 1); line:SetStartPoint("BOTTOMLEFT", 0, 0); line:SetEndPoint("BOTTOMRIGHT", 0, 0); line:SetThickness(1)
    
    local t = tb:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("LEFT", 10, 0)
    t:SetText(string.upper(titleText)) 
    t:SetTextColor(1, 1, 1, 1) 
    
    tb.text = t -- [GÜNCELLEME] Başlığı sonradan değiştirebilmek için referans eklendi
    
    if onClose then
        local cb = CreateFrame("Button", nil, tb, "BackdropTemplate")
        cb:SetSize(18, 18) 
        cb:SetPoint("RIGHT", -5, 0)
        
        cb:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false, edgeSize = 1.5,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        cb:SetBackdropColor(0, 0, 0, 0) 
        cb:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) 
        
        local innerBox = CreateFrame("Frame", nil, cb, "BackdropTemplate")
        innerBox:SetSize(8, 8) 
        innerBox:SetPoint("CENTER", 0, 0)
        
        innerBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false, edgeSize = 1.5,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        
        local monoColor = {0.8, 0.8, 0.8, 1}
        innerBox:SetBackdropColor(0, 0, 0, 0) 
        innerBox:SetBackdropBorderColor(unpack(monoColor))
        innerBox:SetMouseClickEnabled(false)
        
        cb:SetScript("OnEnter", function(self) 
            innerBox:SetBackdropColor(unpack(monoColor)) 
            self:SetBackdropBorderColor(unpack(monoColor)) 
        end)
        
        cb:SetScript("OnLeave", function(self) 
            innerBox:SetBackdropColor(0, 0, 0, 0) 
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) 
            self:SetBackdropColor(0, 0, 0, 0)
        end)
        
        cb:SetScript("OnMouseDown", function(self) 
            self:SetBackdropColor(unpack(monoColor)) 
            innerBox:SetBackdropColor(unpack(Skin.Colors.titleBg)) 
            innerBox:SetPoint("CENTER", 0, 0) 
        end)
        
        cb:SetScript("OnMouseUp", function(self) 
            if MouseIsOver(self) then
                self:SetBackdropColor(0, 0, 0, 0) 
                innerBox:SetBackdropColor(unpack(monoColor))
            else
                self:SetBackdropColor(0, 0, 0, 0)
                innerBox:SetBackdropColor(0, 0, 0, 0)
            end
        end)
        
        cb:SetScript("OnClick", onClose)
    end
    
    parent:SetMovable(true); parent:SetClampedToScreen(true); parent:SetToplevel(true); tb:EnableMouse(true); tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() parent:StartMoving() end); tb:SetScript("OnDragStop", function() parent:StopMovingOrSizing() end)
    return tb
end

function Skin:SetSmartBorder(parentFrame, thickness, color, position)
    if not parentFrame then return end
    
    if not thickness or thickness <= 0 then 
        if parentFrame.smartBorder then parentFrame.smartBorder:Hide() end
        return 
    end
    
    if not parentFrame.smartBorder then
        local b = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        b:SetFrameLevel(parentFrame:GetFrameLevel() + 5) 
        parentFrame.smartBorder = b
    end
    
    local b = parentFrame.smartBorder
    b:Show()
    b:SetFrameLevel(parentFrame:GetFrameLevel() + 5)
    b:ClearAllPoints()
    
    position = position or "OUTSIDE"
    local offset = 0
    
    if position == "OUTSIDE" then
        offset = thickness 
    elseif position == "CENTER" then
        offset = thickness / 2
    else 
        offset = 0
    end
    
    b:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -offset, offset)
    b:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", offset, -offset)
    
    b:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = thickness,
        bgFile = nil,
    })
    
    if color then
        b:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
    else
        b:SetBackdropBorderColor(0, 0, 0, 1)
    end
end

-- =========================================================================
--  [YENİ] IMPORT / EXPORT WINDOW (SINGLETON + Z-INDEX FIX + CUSTOM SCROLL)
-- =========================================================================
function Skin:CreateTextWindow(title, defaultText, onAccept)
    if Skin.TextWindow then
        local f = Skin.TextWindow
        f:Show()
        if f.titleBar and f.titleBar.text then
            f.titleBar.text:SetText(string.upper(title))
        end
        
        f.editBox:SetText(defaultText or "")
        if defaultText then 
            f.editBox:HighlightText() 
            f.editBox:SetFocus() 
        else
            f.editBox:SetFocus() 
        end
        
        if onAccept then
            f.btnImport:Show()
            f.btnImport:SetScript("OnClick", function()
                local text = f.editBox:GetText()
                if text and text ~= "" then
                    onAccept(text)
                    f:Hide()
                end
            end)
            f.smartBorder:SetBackdropBorderColor(1, 0.5, 0, 1) 
        else
            f.btnImport:Hide()
            f.smartBorder:SetBackdropBorderColor(0, 0, 0, 1) 
        end
        return f
    end

    local f = CreateFrame("Frame", "ForgeTextWindow", UIParent, "BackdropTemplate")
    f:SetSize(500, 400)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG") 
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    self:ApplyBackdrop(f)
    f:SetBackdropColor(unpack(Skin.Colors.bg))
    
    Skin.TextWindow = f
    f.titleBar = Skin:CreateTitleBar(f, title, function() f:Hide() end)

    local scrollFrame, scrollChild = Skin:CreateScrollFrame(f, 460, 310)
    scrollFrame:SetPoint("TOPLEFT", 20, -40)
    
    local editBox = CreateFrame("EditBox", nil, scrollChild)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(450)
    editBox:SetPoint("TOPLEFT", 0, 0)
    editBox:SetAutoFocus(false)
    
    -- [CRITICAL FIX] "GetStringHeight" yerine gizli FontString kullanma
    local measure = f:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    measure:SetWidth(450) 
    measure:SetWordWrap(true)
    measure:Hide() -- Gizli kalacak
    
    editBox:SetScript("OnTextChanged", function(self)
        measure:SetText(self:GetText()) -- Gizli yazıya kopyala
        local h = measure:GetStringHeight() -- FontString'den yüksekliği al (Hata vermez)
        scrollChild:SetHeight(math.max(310, h + 20))
    end)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    
    f.editBox = editBox 
    
    if defaultText then
        editBox:SetText(defaultText)
        editBox:HighlightText()
        editBox:SetFocus()
    else
        editBox:SetText("")
        editBox:SetFocus() 
    end

    self:SetSmartBorder(f, 1)

    local btnClose = Skin:CreateButton(f, "Close", 100, 25)
    btnClose:SetPoint("BOTTOMRIGHT", -20, 15)
    btnClose:SetScript("OnClick", function() f:Hide() end)
    
    local btnImport = Skin:CreateButton(f, "Import", 100, 25)
    btnImport:SetPoint("RIGHT", btnClose, "LEFT", -10, 0)
    f.btnImport = btnImport 
    
    if onAccept then
        btnImport:SetScript("OnClick", function()
            local text = editBox:GetText()
            if text and text ~= "" then
                onAccept(text)
                f:Hide()
            end
        end)
        f.smartBorder:SetBackdropBorderColor(1, 0.5, 0, 1)
    else
        btnImport:Hide()
        f.smartBorder:SetBackdropBorderColor(0, 0, 0, 1)
    end
    
    f:Show()
    return f
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    for name, path in pairs(Skin.Media.Fonts) do
        LSM:Register("font", name, path)
    end
    for _, name in ipairs(LSM:List("font")) do
        Skin.Media.Fonts[name] = LSM:Fetch("font", name)
    end
end

return ForgeSkin