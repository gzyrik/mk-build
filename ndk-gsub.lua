#!/usr/bin/env lua
local lfs = require('lfs')
local SEP = package.config:sub(1,1)
-----------------------------------------------------
local function isdir(p)
    if SEP ~= '/' then p = p:gsub(SEP,'/') end
    if p:match('/$') then p = p:sub(1,-2) end
    return lfs.attributes(p,'mode') == 'directory'
end
-----------------------------------------------------
local function _mkdir(p)
    if SEP ~= '/' and p:find '^%a:/*$' then -- Windows root drive case
        return true
    end
    if not isdir(p) then
        local subp = p:match '^(.+)/[^/]+$'
        if subp and not _mkdir(subp) then
            return nil,'mkdir:cannot create '..subp
        end
        return lfs.mkdir(p)
    else
        return true
    end
end
-----------------------------------------------------
local function mkdir (p)
    if SEP ~= '/' then p = p:gsub(SEP,'/') end
    return _mkdir(p)
end
-----------------------------------------------------
local dstdir=nil
local macro={}
local files={}
local skip=nil
for i=1,#arg do
    if skip then
        skip = nil
    elseif arg[i] == '-h' then
        print('Replace  multiple files by multiple regular expressions')
        print('Usage: '..arg[0]..' [options]')
        print('OPTIONS:','[-d dir] [pattern=replace ...] [file ...]')
        print('    -d','\tWrite replaced file to the output directory')
        print('    pattern','% works as an escape character,as string.gsub')
        return
    elseif arg[i] == '-d' then
        assert(i+1 <= #arg, 'no output directory')
        dstdir = arg[i+1]
        local ret, err = mkdir(dstdir)
        assert(ret, err)
        --确保末尾为'/'
        if dstdir:byte(-1) ~= 47 then dstdir = dstdir ..'/' end
        skip = true
    else
        local src, dst = arg[i]:match('^(.-)=(.-)$')
        if src and dst then
            macro[src] = dst
        else
            assert(lfs.attributes(arg[i],'mode') == 'file', arg[i]..' isnot a file')
            table.insert(files, arg[i])
        end
    end
end
for _, src in ipairs(files) do
    local file = io.open(src, 'rb')
    local str = file:read('*a')
    file:close()
    for s, d in pairs(macro) do
        str = str:gsub(s, d)
    end
    if dstdir then
        src = dstdir .. src:match('.-([^/]+)$');
    end
    file = io.open(src, 'w+b')
    file:write(str)
    file:close()
end
