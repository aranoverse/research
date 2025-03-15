```text
src/main/kotlin/com/example
│── domain/        # 业务逻辑（核心领域）
│   ├── model/     # 业务对象（Entities、Aggregates）
│   ├── service/   # 业务服务（Application Service）
│   ├── ports/     # 端口（接口）
│
│── application/   # 应用服务层（使用端口调用核心逻辑）
│
│── infra/         # 基础设施层（适配器 + 外部集成）
│   ├── repository/ # 数据库适配器
│   ├── messaging/  # 消息队列适配器（Kafka, RabbitMQ）
│   ├── cache/      # 缓存适配器（Redis）
│   ├── api/        # 外部 API 适配器
│
│── adapters/      # 适配器（包含 Web、CLI、gRPC 入口）
│   ├── rest/      # Web 控制器（Controller）
│   ├── cli/       # 命令行适配器（CLI）
│   ├── grpc/      # gRPC 适配器

```