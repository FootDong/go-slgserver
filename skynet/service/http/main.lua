local skynet = require "skynet"
local httpd = require "http.httpd"
local socket = require "skynet.socket"
local sockethelper = require "http.sockethelper"
local config = require "config"

local function response(id, ...)
  local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
  if not ok then
    skynet.error(string.format("fd = %d, %s", id, err))
  end
end

local function dispatch(id)
  socket.start(id)
  local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
  if code then
    if url == "/health" then
      response(id, 200, "ok")
    else
      response(id, 404, "not found")
    end
  else
    if url == false then
      skynet.error("socket closed")
    else
      skynet.error(url)
    end
  end
  socket.close(id)
end

skynet.start(function()
  local host = config.http.host
  local port = config.http.port
  local listen = socket.listen(host, port)
  socket.start(listen, function(id, addr)
    skynet.fork(dispatch, id)
  end)
  skynet.error("http listen on ", host, port)
end)