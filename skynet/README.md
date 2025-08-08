# Skynet 重构骨架

本目录提供将现有 Go 版 SLG 服务器迁移到 Skynet 的最小骨架与目录约定，目标是：
- 保持现有协议名路由（如 `role.enterServer`、`chat.login`）与握手/心跳语义一致
- 用 Skynet 内部服务替代原 gate→(ws proxy)→backend 的拓扑，统一在进程内路由
- 逐步迁移逻辑层，优先跑通最小链路

## 目录结构
- `config/config.lua`：业务配置（端口、MySQL、日志等），来源于 `data/conf/env.ini`
- `config/server.lua`：Skynet 运行配置（thread、logger、启动入口等）
- `service/launcher/main.lua`：启动入口，拉起 gate、dispatcher、login、chat、slg、http 等服务
- `service/gate/`：WebSocket 入口与会话 agent（握手、心跳、请求响应、推送）
- `service/dispatcher/`：按 `prefix.msg` 路由到具体业务服务（login/chat/slg）
- `service/login/`：登录/账号相关处理（原 `account.*`）
- `service/chat/`：聊天处理（原 `chat.*`）
- `service/slg/`：游戏逻辑入口（逐步从 Go 迁移）
- `service/http/`：HTTP API（对齐原 Echo 的最小接口）
- `Dockerfile-skynet`、`docker-compose.skynet.yaml`：容器化运行（依赖 MySQL）

## 运行方式（建议）
1) 获取 Skynet 运行时（任选其一）：
- 方式 A：作为子模块放入 `skynet/3rd/skynet`
  - `git submodule add https://github.com/cloudwu/skynet skynet/3rd/skynet`
  - `make` 生成 `skynet/3rd/skynet/skynet`
- 方式 B：环境变量指定已安装的 Skynet：
  - 设置 `export SKYNETHOME=/path/to/skynet`

2) 准备配置
- 确保 `config/config.lua` 中的 MySQL 与端口与 `docker-compose.yaml` 对齐（默认已对齐 `177.8.0.x`）

3) 本地启动
- `cd skynet`
- 方式 A（子模块）：`3rd/skynet/skynet config/server.lua`
- 方式 B（环境变量）：`$SKYNETHOME/skynet config/server.lua`

4) Docker 启动（可选）
- `docker compose -f docker-compose.skynet.yaml up --build -d`

## 协议兼容说明
- 现网 Go 版默认对消息体做 zip 与可选 AES-CBC 加密（握手下发密钥）
- Skynet 版本初期默认使用纯 JSON（便于先跑通链路），并保留压缩/加密的占位实现，后续可切换开关启用
- 消息字段：维持 `ReqBody{Name, Msg, Seq, Proxy}` 与 `RspBody{Name, Msg, Seq, Code}` 语义一致
- 心跳：`HeartbeatMsg` 请求返回 `STime` server time
- 握手：`HandshakeMsg` 支持返回 `Key`（开启加密时生效）

## 迁移步骤建议
- 第 1 步：替换网关（gate）为 Skynet WebSocket，转内部 dispatcher 路由（移除 ws 级 proxy）
- 第 2 步：将简单路由（login/chat）的处理内聚到 Skynet 服务，维持响应结构
- 第 3 步：按控制器逐步迁移 slg 逻辑（`server/slgserver/controller/*`）到 `service/slg`，先保留数据模型不变
- 第 4 步：压测与协议层加密/压缩回归

## 快速启动（无子模块）
- 安装 Skynet 到任意路径并编译：`git clone https://github.com/cloudwu/skynet && cd skynet && make linux`
- 设置环境变量并启动：
  ```bash
  export SKYNETHOME=/abs/path/to/skynet
  cd /workspace/skynet
  $SKYNETHOME/skynet config/server.lua
  ```
