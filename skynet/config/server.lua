root = "./"
thread = 8
logger = nil
harbor = 0
start = "service/launcher/main"

-- cservice search path
cpath = root .. "3rd/skynet/?.so;" .. root .. "3rd/skynet/luaclib/?.so;" .. root .. "luaclib/?.so"

-- lualib search path
luaservice = root .. "3rd/skynet/service/?.lua;service/?.lua"
lua_path = root .. "3rd/skynet/lualib/?.lua;3rd/skynet/lualib/?/init.lua;service/?.lua;config/?.lua"
lua_cpath = root .. "3rd/skynet/luaclib/?.so;luaclib/?.so"

snax = root .. "service/?.lua"

-- daemon = "run/skynet.pid"
-- bootstrap = "snlua bootstrap"