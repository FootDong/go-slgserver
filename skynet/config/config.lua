local config = {}

config.mysql = {
  host = "177.8.0.11",
  port = 3306,
  user = "root",
  password = "123456abc",
  dbname = "slgdb",
  charset = "utf8",
  max_idle = 2,
  max_conn = 10,
}

config.http = { host = "0.0.0.0", port = 8088 }

config.gate = {
  host = "0.0.0.0",
  port = 8004,
  need_secret = true,
}

config.services = {
  slg = { port = 8001, need_secret = false },
  chat = { port = 8002, need_secret = false },
  login = { port = 8003, need_secret = false },
}

config.logic = {
  map_data = "../data/conf/mapRes_0.json",
  json_data = "../data/conf/json/",
  server_id = 1,
}

config.log = {
  dir = "../logs",
}

return config