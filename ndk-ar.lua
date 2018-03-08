-- ndk-ar.lua <ar> <ar-args> <out.a> <.o> <.a> ...
----------------------------------------------------------------
local UNIX = (package.config:sub(1,1) == '/')
local _V = os.getenv('V')
local function V(...)
    if _V then print(...) end
end
local function execute(cmd)
    V(cmd)
    local ret = os.execute(cmd)
    --For compatibility luajit
    if ret and type(ret) == 'number' then
        ret = (ret == 0)
    end
    if not ret then
        print('***************************************') 
        print(' ERROR:',cmd, ret)
        print('***************************************') 
        os.exit(-1)
    end
end
-- return current work dir
local function get_cwd()
    local f;
    if UNIX then
        f = io.popen('pwd')
    else
        f = io.popen('echo %cd%')
    end
    if not f then
        print('get_cmd failed');
        os.exit(-1)
    end
    local n = f:read('*line')
    f:close()
    return n:gsub('\\', '/')
end
local function mk_path(p, ...)
    local arg={...}
    local ret
    if p == '.' then
        ret = nil
    else
        ret = p
    end
    for _,v in pairs(arg) do
        --'.'=46,'/'=47,':'=58
        local a,b,c=v:byte(1,3)

        -- prefix '/', or '[a-z]:' is absolute path
        if a== 47 or c == 58 then 
            return v
        end

        --skip './'
        if a == 46 and b == 47 then
            v = v:sub(3,-1)
        end

        if not v then
        elseif not ret then
            ret = v
        elseif ret:byte(-1) ~= 47 then
            ret = ret .. '/' .. v
        else
            ret = ret .. v
        end
    end
    return ret or '.'
end
local function dir_name(name)
    local dir = name:match('(.+/)[^/]*$')
    return dir or '.'
end
local function file_name(name)
    local file =  name:match('.-/?([^/]+)$')
    return file or ''
end
local function mk_dir (dir)
    local cmd
    if UNIX then
        cmd = 'mkdir -p ' .. dir
    else
        local d = dir:gsub('/','\\')
        cmd = 'if not exist ' .. d .. ' (mkdir ' .. d .. ')'
    end
    execute(cmd);
end
local function rm_file (file)
    local cmd
    if UNIX then
        cmd = 'rm '..file
    else
        local f = file:gsub('/','\\')
        cmd = 'if exist '..f..' (del /Q '..f..')'
    end
    execute(cmd);
end
local function rm_dir (dir)
    local cmd
    if UNIX then
        cmd = 'rm -rf '..dir
    else
        local d = dir:gsub('/','\\')
        cmd = 'if exist '..d..' (rmdir /S /Q '..d..')'
    end
    execute(cmd);
end
local function mv_file (src, dst)
    local cmd
    if UNIX then
        cmd = 'mv '..src..' '..dst
    else
        local s = src:gsub('/','\\')
        local d = dst:gsub('/','\\')
        cmd = 'if exist '..s ..' (move /Y '..s ..' '..d..'>NUL)'
    end
    execute(cmd);
end
------------------------------------------------------------------
--print all arg for debug
--for k,v in pairs(arg) do
--    print('arg[' .. k ..']='.. v)
--end
--origin <ar>
local CWD = get_cwd()
local platform = arg[1]
local ABI = arg[2]
if platform == 'darwin' or platform == 'ios' then
    if ABI == 'x86' then
        ABI = 'i386' 
    elseif ABI == 'x86_64' then
        ABI = 'x86_64' 
    elseif ABI == 'armeabi' then
        ABI = 'arm'
    elseif ABI == 'armeabi-v7a' then
        ABI = 'armv7'
    elseif ABI == 'armeabi-v7s' then
        ABI = 'armv7s'
    elseif ABI == 'arm64-v8a' then
        ABI = 'arm64'
    else
        ABI = nil
    end
else
    ABI = nil;
end
local AR  = arg[3]
--extract <ar-args>
local i=4
local ar_arg={}
while arg[i] and arg[i]:byte(-1) ~= 97 do
    table.insert(ar_arg, arg[i])
    i = i + 1
end
local AR_ARG=table.concat(ar_arg, ' ')
V('AR_ARG=', AR_ARG)

--extract <out.a>
local OUT       = arg[i]
local OUT_name  = file_name (OUT)
local OUT_dir   = dir_name(OUT)
local OUT_tmpdir= OUT_dir .. '__' .. OUT_name

V('OUT=', OUT)
V('OUT_dir=', OUT_dir)
V('OUT_tmpdir=', OUT_tmpdir)

--delete old
rm_dir (OUT_tmpdir)
-- create file list on windows, other use command line
local count=0
local objs_list, objs_file, map_file
if UNIX then
    objs_list = {}
else
    objs_list = mk_path(OUT_dir, OUT_name .. '.list') 
    objs_file = io.open(objs_list, 'w')
    if not objs_file then
        print('ERROR: create '..objs_list..' failed')
        os.exit(-1)
    end
end
local function process_item(item)
    local a = item:byte(-1)
    if a == 111 then -- 'o' == 111
        if UNIX then
            table.insert(objs_list, item)
        else
            objs_file:write(item, '\n')
        end

    elseif a == 97 then -- 'a' == 97
        --at first make out tmp dir
        V('extract', item)
        if count == 0 then
            mk_dir (OUT_tmpdir)
            map_file = io.open(mk_path(OUT_dir, OUT_name .. '.map') , 'w')
        end
        map_file:write(item, '\n')
        --make tmp dir or extract object files
        local a_tmpdir = os.tmpname():gsub('[./\\]', '_')
        a_tmpdir = OUT_dir .. '__' .. file_name (item) .. '.' .. a_tmpdir
        mk_dir(a_tmpdir)

        -- extract cmd
        local a_libpath = mk_path(CWD, item)
        local a_cmd = 'cd ' .. a_tmpdir .. '&&' .. AR .. ' -x ' .. a_libpath
        if ABI then
            local preffix = 'Architectures in the fat file:'
            local f = io.popen('cd ' .. a_tmpdir .. '&&lipo -info ' .. a_libpath)
            local n = f:read('*a')
            f:close()
            if n:sub(1, preffix:len()) == preffix then
                local a_thin = file_name(item)
                local lipo_cmd = 'cd ' .. a_tmpdir .. '&&lipo -o '..a_thin..' -thin '..ABI..' '.. a_libpath
                execute(lipo_cmd)
                a_cmd = 'cd ' .. a_tmpdir .. '&&' .. AR .. ' -x ' .. a_thin
            end
        end
        execute (a_cmd)

        --move to out dir and encrypt
        local ls_cmd
        if UNIX then
            ls_cmd = 'ls ' .. a_tmpdir
        else
            ls_cmd = 'dir '..a_tmpdir:gsub('/','\\')..'\\*.o /b'
        end
        local f_list = io.popen(ls_cmd)
        if not f_list then
            print('ERROR: popen '..a_tmpdir..' failed')
            rm_dir (a_tmpdir)
            os.exit(-1);
        end
        for f_name in f_list:lines() do
            if f_name:byte(-1) == 111 then -- 'o' == 111
                local a_obj = OUT_tmpdir..'/_'..count..'.o'
                map_file:write('\t_', count, '.o ',f_name, '\n')
                mv_file (a_tmpdir..'/'..f_name, a_obj)
                if UNIX then
                    table.insert(objs_list, a_obj)
                else
                    objs_file:write(a_obj, '\n')
                end
                count = count + 1
            end
        end
        f_list:close()
        rm_dir (a_tmpdir)
    end
end

--walk all .o .a files
i = i + 1
while arg[i] do
    if arg[i]:byte(1) == 64 then  -- '@' == 64 
        local arlist = arg[i]:sub(2)
        V('argvlist:', arlist)
        local f = io.open(arlist, 'r')
        if not f then
            print('ERROR: fopen '..arlist..' failed')
            os.exit(-1)
        end
        local objs = f:read('*a')
        for item in string.gmatch(objs,'(.-)%s') do
            V('o:', item)
            process_item(item)
        end
    else
        process_item(arg[i])
    end
    i = i + 1
end
if map_file then map_file:close() end
if UNIX then
    execute(AR ..' '..AR_ARG..' '..OUT..' '..table.concat(objs_list, ' '))
else
    objs_file:close()
    execute(AR ..' '..AR_ARG..' '..OUT..' @'..objs_list)
    rm_file(objs_list)
end
rm_dir(OUT_tmpdir)
