local skynet = require "skynet"
local httpd = require "http.httpd"
local socket = require "skynet.socket"
local sockethelper = require "http.sockethelper"
local websocket = require "http.websocket"
local json = require "cjson.safe"
local config = require "config"

local dispatcher

local HeartbeatMsg = "HeartbeatMsg"
local HandshakeMsg = "HandshakeMsg"

local function encode(tbl)
  return json.encode(tbl)
end

local function decode(s)
  return json.decode(s)
end

local function send(ws_id, body)
  local data = encode(body)
  websocket.write(ws_id, data)
end

local function on_message(ws_id, raw)
  local body = decode(raw)
  if not body then
    send(ws_id, { Name = HandshakeMsg, Msg = { Key = "" }, Seq = 0 })
    return
  end

  if body.Name == HeartbeatMsg then
    local now_ms = math.floor(skynet.time() * 1000)
    send(ws_id, { Name = HeartbeatMsg, Seq = body.Seq, Msg = { STime = now_ms } })
    return
  elseif body.Name == HandshakeMsg then
    send(ws_id, { Name = HandshakeMsg, Seq = 0, Msg = { Key = "" } })
    return
  end

  local req = { name = body.Name, msg = body.Msg, seq = body.Seq or 0, proxy = body.Proxy }
  local ok, rsp = pcall(skynet.call, dispatcher, "lua", "dispatch", req)
  if not ok then
    send(ws_id, { Name = body.Name, Seq = body.Seq or 0, Code = 500, Msg = { err = tostring(rsp) } })
  else
    send(ws_id, { Name = rsp.name or body.Name, Seq = rsp.seq or body.Seq, Code = rsp.code or 0, Msg = rsp.msg })
  end
end

local function handle_ws(ws_id, addr)
  while true do
    local msg, opcode = websocket.read(ws_id)
    if not msg then break end
    if opcode == "text" or opcode == "binary" then
      on_message(ws_id, msg)
    end
  end
  websocket.close(ws_id)
end

local function http_dispatch(id, addr)
  socket.start(id)
  local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
  if code then
    if header and header.upgrade == "websocket" then
      local ok, err = websocket.accept(id, header, nil, addr)
      if not ok then
        skynet.error("websocket accept failed:", err)
        socket.close(id)
        return
      end
      -- id becomes websocket id
      skynet.fork(handle_ws, id, addr)
      return
    end
    httpd.write_response(sockethelper.writefunc(id), 404, "not found")
  else
    if url == false then
      skynet.error("socket closed")
    else
      skynet.error(url)
    end
  end
  socket.close(id)
end

skynet.start(function(...)
  dispatcher = select(1, ...)

  local host = config.gate.host
  local port = config.gate.port
  local listen = assert(socket.listen(host, port))
  socket.start(listen, function(id, addr)
    skynet.fork(http_dispatch, id, addr)
  end)
  skynet.error("gate listen on ", host, port)
end)