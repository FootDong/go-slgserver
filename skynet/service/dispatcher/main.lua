local skynet = require "skynet"

local M = {}

-- name -> address
local service_map = {}

local function prefix_of(name)
  local s, e = string.find(name, "%.")
  if s then
    return string.sub(name, 1, s-1)
  end
  return ""
end

function M.register(prefix, address)
  service_map[prefix] = address
end

function M.dispatch(req)
  -- req: {name, msg, seq}
  local pf = prefix_of(req.name)
  local addr = service_map[pf] or service_map["*"]
  if not addr then
    return { code = 404, name = req.name, seq = req.seq, msg = { err = "no handler" } }
  end
  return skynet.call(addr, "lua", "handle", req)
end

skynet.start(function()
  skynet.dispatch("lua", function(_, _, cmd, ...)
    if cmd == "register" then
      M.register(...)
      skynet.retpack(true)
    elseif cmd == "dispatch" then
      skynet.retpack(M.dispatch(...))
    else
      skynet.retpack(false)
    end
  end)
end)