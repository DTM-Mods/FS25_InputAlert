-- InputAlertMenu: draws a status box next to every input in the "RECIPE: ..." list of the Production Chains menu.
--   green tick  = plenty in storage (InputAlert.GOOD_CYCLES or more production cycles)
--   yellow plus = okay, no action needed yet
--   red X       = low or empty (under InputAlert.LOW_CYCLES cycles), deliver
-- Read only: it reads the production's own storage (synced to every client by the game) and changes nothing.
-- The menu's Lua/XML is encrypted, so the recipe rows are found at runtime by their text, like ProductionBoostMenu.
-- Author: PropaineX

InputAlert = {}
InputAlert.LOW_CYCLES = 2
InputAlert.GOOD_CYCLES = 10
InputAlert.loggedNoRows = false

local BOX_EDGE = {0.43, 0.43, 0.43, 1}
local BOX_FILL = {0.27, 0.28, 0.27, 1}
local GREEN = {0.55, 0.75, 0.12, 1}
local YELLOW = {0.92, 0.70, 0.16, 1}
local RED = {0.88, 0.20, 0.20, 1}

local STATE_GOOD, STATE_OK, STATE_LOW = 1, 2, 3

function InputAlert.log(fmt, ...)
    print("[InputAlert] " .. string.format(fmt, ...))
end

local function walk(element, fn)
    if element == nil or element.elements == nil then
        return
    end
    for _, child in ipairs(element.elements) do
        fn(child)
        walk(child, fn)
    end
end

local function getClip(element)
    local x1, y1, x2, y2 = 0, 0, 1, 1
    local e = element.parent
    while e ~= nil do
        if e.clipping then
            x1 = math.max(x1, e.absPosition[1])
            y1 = math.max(y1, e.absPosition[2])
            x2 = math.min(x2, e.absPosition[1] + e.absSize[1])
            y2 = math.min(y2, e.absPosition[2] + e.absSize[2])
        end
        e = e.parent
    end
    return x1, y1, x2, y2
end

local function rect(x, y, w, h, c)
    drawFilledRect(x, y, w, h, c[1], c[2], c[3], c[4])
end

-- a line from (ax, ay) to (bx, by), in 0..1 box coordinates, made of small squares
local function line(x, y, w, h, ax, ay, bx, by, c)
    local s = h * 0.14
    local sx = s / g_screenAspectRatio
    local steps = 10
    for i = 0, steps do
        local t = i / steps
        rect(x + (ax + (bx - ax) * t) * w - sx / 2, y + (ay + (by - ay) * t) * h - s / 2, sx, s, c)
    end
end

local function drawBox(x, y, w, h, state)
    local border = h * 0.08
    local borderX = border / g_screenAspectRatio
    rect(x, y, w, h, BOX_EDGE)
    rect(x + borderX, y + border, w - 2 * borderX, h - 2 * border, BOX_FILL)
    if state == STATE_GOOD then
        line(x, y, w, h, 0.22, 0.52, 0.42, 0.28, GREEN)
        line(x, y, w, h, 0.42, 0.28, 0.80, 0.76, GREEN)
    elseif state == STATE_OK then
        line(x, y, w, h, 0.50, 0.22, 0.50, 0.78, YELLOW)
        line(x, y, w, h, 0.22, 0.50, 0.78, 0.50, YELLOW)
    else
        line(x, y, w, h, 0.25, 0.25, 0.75, 0.75, RED)
        line(x, y, w, h, 0.25, 0.75, 0.75, 0.25, RED)
    end
end

-- how many production cycles the stock lasts -> state
function InputAlert.getInputState(productionPoint, input)
    local amount = input.amount or 0
    if amount <= 0 then
        return STATE_GOOD
    end
    local storage = productionPoint.storage
    local fillLevel = 0
    if storage ~= nil and storage.getFillLevel ~= nil then
        fillLevel = storage:getFillLevel(input.type) or 0
    end
    local cycles = fillLevel / amount
    if cycles < InputAlert.LOW_CYCLES then
        return STATE_LOW
    elseif cycles < InputAlert.GOOD_CYCLES then
        return STATE_OK
    end
    return STATE_GOOD
end

-- input fill type title (upper case) -> input
local function getInputsByTitle(production)
    local byTitle = {}
    for _, input in ipairs(production.inputs or {}) do
        local fillType = g_fillTypeManager:getFillTypeByIndex(input.type)
        if fillType ~= nil and type(fillType.title) == "string" and fillType.title ~= "" then
            byTitle[string.upper(fillType.title)] = input
        end
    end
    return byTitle
end

-- text "400x Napa Cabbage" (or a separate "Napa Cabbage") -> matching input
-- the text ends with the input's title and what comes before it holds no letters other than the "x" of the amount
-- (the amount can be "400x", "400 x", "400×", or a separate text element)
local function matchInput(text, byTitle)
    local upper = string.upper(text):gsub("%s+$", "")
    for title, input in pairs(byTitle) do
        if #upper >= #title and upper:sub(-#title) == title then
            local prefix = upper:sub(1, #upper - #title):gsub("X", "")
            if not prefix:find("%a") then
                return input
            end
        end
    end
    return nil
end

-- the "RECIPE: <production name>" text element
local function findRecipeHeading(frame, production)
    local name = production.name
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local wanted = string.upper(name)
    local found = nil
    walk(frame, function(element)
        local text = element.text
        if found == nil and type(text) == "string" and element.textSize ~= nil and text:find(":", 1, true) ~= nil then
            local upper = string.upper(text)
            if #upper > #wanted and upper:sub(-#wanted) == wanted and element:getIsVisible() then
                found = element
            end
        end
    end)
    return found
end

-- left edge of the row's icon (a non-text sibling left of the text on the same line)
local function getIconLeft(textElement)
    local parent = textElement.parent
    local tx = textElement.absPosition[1]
    local ty1, ty2 = textElement.absPosition[2], textElement.absPosition[2] + textElement.absSize[2]
    local left = nil
    if parent ~= nil and parent.elements ~= nil then
        for _, sibling in ipairs(parent.elements) do
            if sibling ~= textElement and sibling.text == nil and sibling.absPosition ~= nil and sibling:getIsVisible() then
                local sx, sy = sibling.absPosition[1], sibling.absPosition[2]
                local sy2 = sy + sibling.absSize[2]
                if sx < tx and sy < ty2 and sy2 > ty1 and sibling.absSize[1] > 0 and sibling.absSize[1] < 0.1 then
                    left = math.min(left or sx, sx)
                end
            end
        end
    end
    return left
end

-- INCOMING MATERIALS list (top of the right panel): every input material at InputAlert.LOW_PERCENT or less of its
-- capacity gets a soft red highlight over its row. Not tied to the selected product.
InputAlert.LOW_PERCENT = 0.10
local HIGHLIGHT_FILL = {0.92, 0.35, 0.31, 0.35}
local HIGHLIGHT_EDGE = {0.94, 0.43, 0.39, 0.80}

-- inputs of the switched-on products only (a material nothing active uses doesn't need a warning)
local function getInputMaterialsByTitle(productionPoint)
    local byTitle = {}
    for _, production in ipairs(productionPoint.activeProductions or {}) do
        for _, input in ipairs(production.inputs or {}) do
            local fillType = g_fillTypeManager:getFillTypeByIndex(input.type)
            if fillType ~= nil and type(fillType.title) == "string" and fillType.title ~= "" then
                byTitle[string.upper(fillType.title)] = input.type
            end
        end
    end
    return byTitle
end

local function isLow(productionPoint, fillTypeIndex)
    local storage = productionPoint.storage
    if storage == nil or storage.getFillLevel == nil or storage.getCapacity == nil then
        return false
    end
    local capacity = storage:getCapacity(fillTypeIndex) or 0
    if capacity <= 0 then
        return false
    end
    return (storage:getFillLevel(fillTypeIndex) or 0) / capacity <= InputAlert.LOW_PERCENT
end

function InputAlert.drawIncoming(frame, productionPoint, recipeHeading)
    local byTitle = getInputMaterialsByTitle(productionPoint)
    if next(byTitle) == nil then
        return
    end
    -- the list rows show the title alone ("BUFFALO MILK"); recipe rows have an amount in front, so they never match
    local stopY = recipeHeading ~= nil and (recipeHeading.absPosition[2] + recipeHeading.absSize[2]) or nil
    walk(frame, function(element)
        local text = element.text
        if type(text) ~= "string" or element.textSize == nil or element.absPosition == nil or not element:getIsVisible() then
            return
        end
        if stopY ~= nil and element.absPosition[2] <= stopY then
            return
        end
        -- right-hand column only: never anything over or left of the PRODUCTS list
        local products = frame.productsList
        if products ~= nil and products.absPosition ~= nil and products.absSize ~= nil
            and element.absPosition[1] < products.absPosition[1] + products.absSize[1] then
            return
        end
        local fillTypeIndex = byTitle[(string.upper(text):gsub("^%s+", ""):gsub("%s+$", ""))]
        if fillTypeIndex == nil or not isLow(productionPoint, fillTypeIndex) then
            return
        end
        -- only storage rows: their cell also shows "<level> / <capacity>" (the PRODUCTS list has product names
        -- that can equal a material's name, e.g. MANURE, but no amounts)
        local row = element.parent
        local hasAmount = false
        if row ~= nil and row.elements ~= nil then
            for _, sibling in ipairs(row.elements) do
                if sibling ~= element and type(sibling.text) == "string" and sibling.text:find("%d.*/.*%d") then
                    hasAmount = true
                    break
                end
            end
        end
        if not hasAmount then
            return
        end
        -- the row = the text's parent cell when it is wider than the text, else a band around the text
        local x, y, w, h
        if row ~= nil and row.absSize ~= nil and row.absSize[1] > element.absSize[1] * 1.5 and row.absSize[2] < element.textSize * 6 then
            x, y, w, h = row.absPosition[1], row.absPosition[2], row.absSize[1], row.absSize[2]
        else
            local T = element.textSize
            x, y = element.absPosition[1] - 2.5 * T / g_screenAspectRatio, element.absPosition[2] - 0.6 * T
            w, h = 0.36, element.absSize[2] + 1.2 * T
        end
        local _, cy1, _, cy2 = getClip(element)
        local y1, y2 = math.max(y, cy1), math.min(y + h, cy2)
        if y2 <= y1 then
            return
        end
        local edge = 0.0015
        local edgeX = edge / g_screenAspectRatio
        rect(x, y1, w, y2 - y1, HIGHLIGHT_FILL)
        rect(x, y1, w, edge, HIGHLIGHT_EDGE)
        rect(x, y2 - edge, w, edge, HIGHLIGHT_EDGE)
        rect(x, y1, edgeX, y2 - y1, HIGHLIGHT_EDGE)
        rect(x + w - edgeX, y1, edgeX, y2 - y1, HIGHLIGHT_EDGE)
    end)
end

function InputAlert.draw(frame)
    local production, productionPoint = nil, nil
    if frame.getSelectedProduction ~= nil then
        production, productionPoint = frame:getSelectedProduction()
    end
    productionPoint = productionPoint or frame.selectedProductionPoint
    if productionPoint ~= nil then
        local heading = production ~= nil and findRecipeHeading(frame, production) or nil
        InputAlert.drawIncoming(frame, productionPoint, heading)
    end
    InputAlert.drawRecipe(frame)
end

function InputAlert.drawRecipe(frame)
    if frame.getSelectedProduction == nil then
        return
    end
    local production, productionPoint = frame:getSelectedProduction()
    if production == nil or productionPoint == nil or production.inputs == nil then
        return
    end
    local byTitle = getInputsByTitle(production)
    if next(byTitle) == nil then
        return
    end

    -- only rows under "RECIPE: <name>" (the INCOMING MATERIALS list above it shows every stored material)
    local heading = findRecipeHeading(frame, production)
    if heading == nil then
        if not InputAlert.loggedNoRows then
            InputAlert.loggedNoRows = true
            InputAlert.log("could not find the recipe heading for '%s'; status boxes not shown", tostring(production.name))
        end
        return
    end
    local headingBottom = heading.absPosition[2]
    local headingLeft = heading.absPosition[1] - 0.01

    -- the left-most visible text per input (an output with the same fill type sits further right)
    local rows = {}
    walk(frame, function(element)
        local text = element.text
        if type(text) == "string" and element.textSize ~= nil and element.absPosition ~= nil and element ~= heading
            and element.absPosition[2] + element.absSize[2] <= headingBottom + 0.001
            and element.absPosition[1] >= headingLeft and element:getIsVisible() then
            local input = matchInput(text, byTitle)
            if input ~= nil then
                local row = rows[input]
                if row == nil or element.absPosition[1] < row.absPosition[1] - 0.001 then
                    rows[input] = element
                end
            end
        end
    end)

    local found = false
    for input, element in pairs(rows) do
        found = true
        local T = element.textSize
        local h = T * 1.15
        local w = h / g_screenAspectRatio
        local centreY = element.absPosition[2] + element.absSize[2] / 2
        local _, cy1, _, cy2 = getClip(element)
        if centreY - h / 2 >= cy1 and centreY + h / 2 <= cy2 then
            local iconLeft = getIconLeft(element) or (element.absPosition[1] - 1.6 * T / g_screenAspectRatio)
            local x = iconLeft - w - 0.35 * T / g_screenAspectRatio
            drawBox(x, centreY - h / 2, w, h, InputAlert.getInputState(productionPoint, input))
        end
    end

    if not found and not InputAlert.loggedNoRows then
        InputAlert.loggedNoRows = true
        InputAlert.log("no recipe rows found for '%s'; status boxes not shown", tostring(production.name))
        -- what the rows actually say, to fix the matching
        for title in pairs(byTitle) do
            InputAlert.log("  input title: '%s'", title)
        end
        local n = 0
        walk(frame, function(element)
            if n < 20 and type(element.text) == "string" and element.text ~= "" and element.absPosition ~= nil
                and element.absPosition[2] + (element.absSize[2] or 0) <= headingBottom + 0.001 and element:getIsVisible() then
                n = n + 1
                local bytes = {}
                for i = 1, math.min(#element.text, 8) do
                    bytes[i] = string.byte(element.text, i)
                end
                InputAlert.log("  text below heading: '%s' x=%.3f bytes=%s", element.text, element.absPosition[1], table.concat(bytes, ","))
            end
        end)
    end
end

if InGameMenuProductionFrame ~= nil then
    InGameMenuProductionFrame.draw = Utils.appendedFunction(InGameMenuProductionFrame.draw, InputAlert.draw)
    InGameMenuProductionFrame.onFrameOpen = Utils.prependedFunction(InGameMenuProductionFrame.onFrameOpen, function()
        InputAlert.loggedNoRows = false
    end)
    InputAlert.log("hooked the Production Chains menu")
else
    Logging.warning("[InputAlert] InGameMenuProductionFrame not found, status boxes will not be shown")
end
