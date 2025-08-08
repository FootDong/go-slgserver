local skynet = require "skynet"

local dispatcher

local function handle(req)
  local name = req.name or ""
  local seq = req.seq or 0
  local rsp = { code = 0, name = name, seq = seq, msg = { ok = true } }
  return rsp
end

skynet.start(function(...)
  dispatcher = select(1, ...)
  -- default handlers: register per prefix of various controllers later
  skynet.call(dispatcher, "lua", "register", "role", skynet.self())
  skynet.call(dispatcher, "lua", "register", "map", skynet.self())
  skynet.call(dispatcher, "lua", "register", "city", skynet.self())
  skynet.call(dispatcher, "lua", "register", "general", skynet.self())
  skynet.call(dispatcher, "lua", "register", "army", skynet.self())
  skynet.call(dispatcher, "lua", "register", "war", skynet.self())
  skynet.call(dispatcher, "lua", "register", "coalition", skynet.self())
  skynet.call(dispatcher, "lua", "register", "interior", skynet.self())
  skynet.call(dispatcher, "lua", "register", "skill", skynet.self())
  skynet.call(dispatcher, "lua", "register", "*", skynet.self())

  skynet.dispatch("lua", function(_,_, cmd, ...)
    if cmd == "handle" then
      skynet.retpack(handle(...))
    else
      skynet.retpack({ code = 404, name = cmd, seq = 0, msg = { err = "unknown" } })
    end
  end)
end)