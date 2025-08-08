local skynet = require "skynet"
local config = require "config"

skynet.start(function()
  -- dispatcher first
  local dispatcher = skynet.newservice("dispatcher/main")

  -- business services
  local login = skynet.newservice("login/main", dispatcher)
  local chat = skynet.newservice("chat/main", dispatcher)
  local slg = skynet.newservice("slg/main", dispatcher)

  -- http (optional)
  local http = skynet.newservice("http/main")

  -- gate service (websocket)
  local gate = skynet.newservice("gate/main", dispatcher)

  skynet.error("launcher started", dispatcher, login, chat, slg, http, gate)
end)