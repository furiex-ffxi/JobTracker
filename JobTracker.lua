_addon.name = 'JobTracker'
_addon.author = 'Furyex'
_addon.version = '0.3.0'
_addon.commands = {'jobtracker', 'jt'}

local texts = require('texts')
local config = require('config')
require('logger')

local jobs = {
    'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG',
    'SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN'
}

local job_colors = {
    unused = '\\cs(0,191,255)', -- blue
    used = '\\cs(255,255,0)', -- yellow
    selected = '\\cs(50,205,50)', -- green
}

-- Settings (persisted)
local grid_rows = 6
local grid_cols = 3

local defaults = {
    pos = { x = 100, y = 200 },
    round_names = { '', '', '' },
    assignments = {},
    debug = false,
}

local settings = config.load(defaults)
settings.pos = settings.pos or { x = defaults.pos.x, y = defaults.pos.y }
settings.pos.x = tonumber(settings.pos.x) or defaults.pos.x
settings.pos.y = tonumber(settings.pos.y) or defaults.pos.y
settings.debug = settings.debug ~= nil and settings.debug or false

local function sanitize_round_names(source)
    local sanitized = {}
    if type(source) == 'table' then
        for i = 1, grid_cols do
            local value = source[i] or source[tostring(i)]
            sanitized[i] = type(value) == 'string' and value or ''
        end
    else
        for i = 1, grid_cols do
            sanitized[i] = ''
        end
    end
    return sanitized
end

local function sanitize_assignments(source)
    local sanitized = {}
    if type(source) == 'table' then
        for r = 1, grid_rows do
            sanitized[r] = {}
            local row = source[r] or source[tostring(r)]
            if type(row) == 'table' then
                for c = 1, grid_cols do
                    local value = row[c] or row[tostring(c)]
                    sanitized[r][c] = type(value) == 'string' and value or nil
                end
            end
        end
    end
    for r = 1, grid_rows do
        sanitized[r] = sanitized[r] or {}
    end
    return sanitized
end

settings.round_names = sanitize_round_names(settings.round_names)
local assignments = sanitize_assignments(settings.assignments)
settings.assignments = assignments

local base_pos = settings.pos

local function save_settings()
    settings.round_names = sanitize_round_names(settings.round_names)
    assignments = sanitize_assignments(assignments)
    settings.assignments = assignments
    settings.pos.x = tonumber(base_pos.x) or defaults.pos.x
    settings.pos.y = tonumber(base_pos.y) or defaults.pos.y
    config.save(settings, 'all')
end

local spacing_px = 10 -- horizontal spacing between labels
local font_size = 12
local columns = 11 -- two rows of 11 (palette)
local cell_width = 40 -- fixed width per label to avoid extents timing
local row_spacing = 6 -- vertical spacing between rows
local handle_width = 28 -- space reserved for drag handle

local grid_cell_w = 44
local grid_cell_h = font_size + row_spacing
local grid_label_w = 24

local job_texts = {} -- job_name => texts object (palette)
local drag_handle -- small handle to drag whole group
local grid_cells = {} -- [row][col] -> text object
local row_labels = {} -- [row] -> text object
local col_labels = {} -- [col] -> text object

-- Assignments (persisted)
for r = 1, grid_rows do
    assignments[r] = assignments[r] or {}
end
settings.assignments = assignments

-- Currently selected palette job
local selected_job = nil

local function dbg(msg)
    if settings.debug then
        windower.add_to_chat(207, ('JT: %s'):format(tostring(msg)))
    end
end

local function create_text()
    local t = texts.new('', {
        pos = { x = base_pos.x, y = base_pos.y },
        text = { size = font_size },
        bg = { alpha = 128 },
        flags = { draggable = false },
    })
    t:show()
    return t
end

local function ensure_texts()
    for _, job in ipairs(jobs) do
        if not job_texts[job] then
            job_texts[job] = create_text()
        end
    end
end

local function ensure_grid()
    for r = 1, grid_rows do
        grid_cells[r] = grid_cells[r] or {}
        if not row_labels[r] then
            local t = texts.new('', {
                pos = { x = base_pos.x, y = base_pos.y },
                text = { size = font_size },
                bg = { alpha = 0 },
                flags = { draggable = false },
            })
            t:show()
            row_labels[r] = t
        end
        for c = 1, grid_cols do
            if not grid_cells[r][c] then
                local t = texts.new('', {
                    pos = { x = base_pos.x, y = base_pos.y },
                    text = { size = font_size },
                    bg = { alpha = 128 },
                    flags = { draggable = false },
                })
                t:show()
                grid_cells[r][c] = t
            end
        end
    end
    for c = 1, grid_cols do
        if not col_labels[c] then
            local t = texts.new('', {
                pos = { x = base_pos.x, y = base_pos.y },
                text = { size = font_size },
                bg = { alpha = 0 },
                flags = { draggable = false },
            })
            t:show()
            col_labels[c] = t
        end
    end
end

local function job_is_assigned(job)
    for r = 1, grid_rows do
        for c = 1, grid_cols do
            if assignments[r][c] == job then
                return true
            end
        end
    end
    return false
end

local function safe_hover(t, x, y)
    if not t then return false end
    local okv, vis = pcall(function() return t:visible() end)
    if okv and not vis then return false end
    local ok, res = pcall(function() return t:hover(x, y) end)
    if ok then return res else return false end
end

local function safe_pos(t)
    local okx, px = pcall(function() return t:pos_x() end)
    local oky, py = pcall(function() return t:pos_y() end)
    return (okx and px or 0), (oky and py or 0)
end

local function find_assignment(job)
    for r = 1, grid_rows do
        for c = 1, grid_cols do
            if assignments[r][c] == job then
                return r, c
            end
        end
    end
    return nil, nil
end

local function get_handle_text()
    if settings.round_names and settings.round_names[1] and settings.round_names[1] ~= '' then
        return string.format('[JT: %s]', settings.round_names[1])
    end
    return '[JT]'
end

local function update_display()
    ensure_texts()
    ensure_grid()
    -- position drag handle
    if not drag_handle then
        drag_handle = texts.new('[JT]', {
            pos = { x = base_pos.x, y = base_pos.y - (font_size + 4) },
            text = { size = font_size },
            bg = { alpha = 128 },
            flags = { draggable = false },
        })
        drag_handle:show()
    else
        drag_handle:pos(base_pos.x, base_pos.y - (font_size + 4))
    end
    drag_handle:text(get_handle_text())

    -- Grid headers
    for c = 1, grid_cols do
        local header = (settings.round_names and settings.round_names[c] and settings.round_names[c] ~= '') and settings.round_names[c] or ('R%d'):format(c)
        local hx = base_pos.x + grid_label_w + (c - 1) * (grid_cell_w + spacing_px)
        local hy = base_pos.y - (font_size + 2)
        col_labels[c]:text(('\\cs(200,200,200)%s\\cr'):format(header))
        col_labels[c]:pos(hx, hy)
    end
    -- Grid rows + cells
    for r = 1, grid_rows do
        local ry = base_pos.y + (r - 1) * grid_cell_h
        row_labels[r]:text(('\\cs(200,200,200)P%d\\cr'):format(r))
        row_labels[r]:pos(base_pos.x, ry)
        for c = 1, grid_cols do
            local val = assignments[r][c]
            local cx = base_pos.x + grid_label_w + (c - 1) * (grid_cell_w + spacing_px)
            local cy = ry
            local label
            if val then
                label = ("%s%s\\cr"):format(job_colors.used, val)
            else
                label = '\\cs(150,150,150)--\\cr'
            end
            grid_cells[r][c]:text(label)
            grid_cells[r][c]:pos(cx, cy)
        end
    end

    -- Palette in two rows
    local palette_y = base_pos.y + grid_rows * grid_cell_h + 14
    for i, job in ipairs(jobs) do
        local t = job_texts[job]
        local color
        if selected_job == job then
            color = job_colors.selected
        elseif job_is_assigned(job) then
            color = job_colors.used
        else
            color = job_colors.unused
        end
        t:text(string.format('%s%s\\cr', color, job))

        local idx = i - 1
        local prow = math.floor(idx / columns)
        local pcol = idx % columns
        local px = base_pos.x + handle_width + spacing_px + pcol * (cell_width + spacing_px)
        local py = palette_y + prow * (font_size + row_spacing)
        t:pos(px, py)
    end
end

update_display()

-- Commands: round1/2/3, reset; debug on/off/toggle
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    if not cmd then return end

    if cmd == 'round1' or cmd == 'round2' or cmd == 'round3' then
        local idx = tonumber(cmd:match('(%d)$'))
        if idx and idx >= 1 and idx <= grid_cols then
            local name = ''
            if #args >= 2 then
                name = table.concat(args, ' ', 2)
            end
            settings.round_names[idx] = name
            save_settings()
        end
    elseif cmd == 'debug' then
        local arg = (args[2] or ''):lower()
        if arg == 'on' or arg == '1' or arg == 'true' then
            settings.debug = true
        elseif arg == 'off' or arg == '0' or arg == 'false' then
            settings.debug = false
        else
            settings.debug = not settings.debug
        end
        save_settings()
        windower.add_to_chat(207, ('JT debug: %s'):format(settings.debug and 'on' or 'off'))
    elseif cmd == 'reset' then
        for r = 1, grid_rows do
            assignments[r] = assignments[r] or {}
            for c = 1, grid_cols do
                assignments[r][c] = nil
            end
        end
        selected_job = nil
        save_settings()
    end
    update_display()
end)

-- Mouse: left-click a job to select; left-click a grid cell to assign; right-click a grid cell to clear
-- Left click down/up handling similar to common Windower patterns
do
    local mouse_moved = true
    local ignore_release = false
    local dragging = false
    local drag_dx, drag_dy = 0, 0

    windower.register_event('mouse', function(eventtype, x, y, delta, blocked)
        x = tonumber(x) or 0
        y = tonumber(y) or 0
        if blocked then
            return
        end

        -- Move
        if eventtype == 0 then
            mouse_moved = true
            if dragging then
                base_pos.x = x - drag_dx
                base_pos.y = y - drag_dy
                update_display()
                return true
            end
        -- Left click down
        elseif eventtype == 1 then
            mouse_moved = false
            -- start drag if clicking handle
            if drag_handle and safe_hover(drag_handle, x, y) then
                local hx, hy = safe_pos(drag_handle)
                drag_dx = x - hx
                drag_dy = y - hy
                dragging = true
                dbg(('drag start at (%.0f,%.0f), base=(%.0f,%.0f)'):format(x, y, base_pos.x, base_pos.y))
                return true
            end
            for _, job in ipairs(jobs) do
                local t = job_texts[job]
                if safe_hover(t, x, y) then
                    ignore_release = true
                    return true
                end
            end
            ignore_release = false
        -- Left click release
        elseif eventtype == 2 then
            if dragging then
                dragging = false
                settings.pos.x = base_pos.x
                settings.pos.y = base_pos.y
                save_settings()
                return true
            end
            -- palette selection
            for _, job in ipairs(jobs) do
                local t = job_texts[job]
                if safe_hover(t, x, y) and not mouse_moved then
                    dbg(('palette click @ (%.0f,%.0f), job=%s'):format(x, y, job))
                    if selected_job == job then
                        selected_job = nil
                    else
                        selected_job = job
                    end
                    update_display()
                    return true
                end
            end
            -- grid assignment (only when a job is selected)
            if selected_job then
                for r = 1, grid_rows do
                    for c = 1, grid_cols do
                        local t = grid_cells[r][c]
                        if safe_hover(t, x, y) and not mouse_moved then
                            dbg(('assign %s -> (%d,%d)'):format(selected_job, r, c))
                            local pr, pc = find_assignment(selected_job)
                            if pr and pc then
                                dbg(('move: clearing previous (%d,%d)'):format(pr, pc))
                                assignments[pr][pc] = nil
                            end
                            assignments[r][c] = selected_job
                            save_settings()
                            selected_job = nil
                            update_display()
                            return true
                        end
                    end
                end
            end
            if ignore_release then
                return true
            end

        -- Right click release -> clear cell
        elseif eventtype == 4 then
            if dragging then
                dragging = false
                settings.pos.x = base_pos.x
                settings.pos.y = base_pos.y
                save_settings()
                return true
            end
            for r = 1, grid_rows do
                for c = 1, grid_cols do
                    local t = grid_cells[r][c]
                    if safe_hover(t, x, y) and not mouse_moved then
                        dbg(('clear (%d,%d) %s'):format(r, c, tostring(assignments[r][c])))
                        assignments[r][c] = nil
                        save_settings()
                        update_display()
                        return true
                    end
                end
            end
        end
        return false
    end)
end

-- Cleanup on unload
windower.register_event('unload', function()
    for _, t in pairs(job_texts) do
        if t and type(t.destroy) == 'function' then
            pcall(function() t:destroy() end)
        end
    end
    for r = 1, grid_rows do
        local rl = row_labels[r]
        if rl and type(rl.destroy) == 'function' then pcall(function() rl:destroy() end) end
        if grid_cells[r] then
            for c = 1, grid_cols do
                local gc = grid_cells[r][c]
                if gc and type(gc.destroy) == 'function' then pcall(function() gc:destroy() end) end
            end
        end
    end
    for c = 1, grid_cols do
        local cl = col_labels[c]
        if cl and type(cl.destroy) == 'function' then pcall(function() cl:destroy() end) end
    end
    if drag_handle and type(drag_handle.destroy) == 'function' then pcall(function() drag_handle:destroy() end) end
    settings.pos.x = base_pos.x
    settings.pos.y = base_pos.y
    save_settings()
end)
