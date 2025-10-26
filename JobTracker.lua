_addon.name = 'JobTracker'
_addon.author = 'Furyex'
_addon.version = '0.2.0'
_addon.commands = {'jobtracker', 'jt'}

local texts = require('texts')
local config = require('config')
local res = require('resources')
require('logger')

local jobs = {
    'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG',
    'SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN'
}

local job_states = {} -- job_name => 'unused'|'used'
for _, job in ipairs(jobs) do
    job_states[job] = 'unused'
end

local job_colors = {
    unused = '\\cs(0,191,255)', -- blue
    used = '\\cs(255,255,0)', -- yellow
}

-- Settings (persisted)
local defaults = { pos = { x = 100, y = 200 } }
local settings = config.load(defaults)

-- UI layout settings
local base_pos = settings.pos
local spacing_px = 10 -- horizontal spacing between labels
local font_size = 12
local columns = 11 -- two rows of 11
local cell_width = 40 -- fixed width per label to avoid extents timing
local row_spacing = 6 -- vertical spacing between rows
local handle_width = 28 -- space reserved for drag handle

-- One text object per job for precise click detection
local job_texts = {} -- job_name => texts object
local drag_handle -- small handle to drag whole group

local function create_text(job)
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
            job_texts[job] = create_text(job)
        end
    end
end

local function update_display()
    ensure_texts()
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

    -- layout in two rows using fixed cell width
    for i, job in ipairs(jobs) do
        local t = job_texts[job]
        local color = job_colors[job_states[job]] or job_colors.unused
        t:text(string.format('%s%s\\cr', color, job))

        local idx = i - 1
        local row = math.floor(idx / columns)
        local col = idx % columns
        local x = base_pos.x + handle_width + spacing_px + col * (cell_width + spacing_px)
        local y = base_pos.y + row * (font_size + row_spacing)
        t:pos(x, y)
    end
end

update_display()

-- Command: //jt use WAR
-- Command: //jt reset
windower.register_event('addon command', function(cmd, job)
    cmd = cmd and cmd:lower()
    job = job and job:upper()

    if cmd == 'use' and job_states[job] then
        job_states[job] = 'used'
    elseif cmd == 'unused' and job_states[job] then
        job_states[job] = 'unused'
    elseif cmd == 'reset' then
        for _, j in ipairs(jobs) do job_states[j] = 'unused' end
    end
    update_display()
end)

-- Mouse interaction: click a job label to toggle used/unused
-- Left click down/up handling similar to common Windower patterns
do
    local mouse_moved = true
    local ignore_release = false
    local dragging = false
    local drag_dx, drag_dy = 0, 0

    windower.register_event('mouse', function(eventtype, x, y, delta, blocked)
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
            if drag_handle and drag_handle:hover(x, y) then
                local hx, hy = drag_handle:pos_x(), drag_handle:pos_y()
                drag_dx = x - hx
                drag_dy = y - hy
                dragging = true
                return true
            end
            for _, job in ipairs(jobs) do
                local t = job_texts[job]
                if t and t:hover(x, y) then
                    ignore_release = true
                    return true
                end
            end
            ignore_release = false
        -- Left click release
        elseif eventtype == 2 then
            if dragging then
                dragging = false
                config.save(settings, 'all')
                return true
            end
            for _, job in ipairs(jobs) do
                local t = job_texts[job]
                if t and t:hover(x, y) and t:visible() and not mouse_moved then
                    job_states[job] = (job_states[job] == 'used') and 'unused' or 'used'
                    update_display()
                    return true
                end
            end
            if ignore_release then
                return true
            end
        end

        return false
    end)
end

-- Cleanup on unload
windower.register_event('unload', function()
    for _, t in pairs(job_texts) do
        if t and t.destroy then
            t:destroy()
        end
    end
    config.save(settings, 'all')
end)
