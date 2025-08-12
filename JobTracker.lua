_addon.name = 'JobTracker'
_addon.author = 'Furyex'
_addon.version = '0.1.0'
_addon.commands = {'jobtracker', 'jt'}

local texts = require('texts')
local res = require('resources')
require('logger')

local jobs = {
    'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG',
    'SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN'
}

local job_states = {} -- job_name => 'unused'|'in_use'|'used'
for _, job in ipairs(jobs) do
    job_states[job] = 'unused'
end

local job_colors = {
    unused = '\\cs(0,191,255)', -- blue
    used = '\\cs(255,255,0)', -- yellow
}

local display = texts.new('', {pos={x=100, y=200}, size=12, bg={alpha=128}})
display:show()


function update_display()
    local lines = {}
    for _, job in ipairs(jobs) do
        local color = job_colors[job_states[job]]
        table.insert(lines, string.format('%s%s\\cr', color, job))
    end
    display:text(table.concat(lines, '  '))
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