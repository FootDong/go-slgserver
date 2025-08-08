local skynet = require "skynet"

local dispatcher

local function handle(req)
  local name = req.name or ""
  local seq = req.seq or 0
  local rsp = { code = 0, name = name, seq = seq, msg = {} }

  if name == "account.login" then
    -- return a dummy token
    rsp.msg = { token = string.format("tk_%d", math.floor(skynet.now())) }
  else
    rsp.msg = { ok = true }
  end

  return rsp
end

skynet.start(function(...)
  dispatcher = select(1, ...)
  skynet.call(dispatcher, "lua", "register", "account", skynet.self())

  skynet.dispatch("lua", function(_,_, cmd, ...)
    if cmd == "handle" then
      skynet.retpack(handle(...))
    else
      skynet.retpack({ code = 404, name = cmd, seq = 0, msg = { err = "unknown" } })
    end
  end)
end)