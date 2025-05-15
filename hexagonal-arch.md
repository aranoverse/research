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

```text
infra/                  // 基础设施层，提供外部依赖的支持
  ├── api/              // 外部 API 交互
  ├── persistence/      // 数据存储（数据库、缓存）
  ├── web3/             // Web3 相关逻辑（如区块链交互）
  ├── mq/               // mq（kafka,rabbit）

example/              // 业务模块（可能是一个 Bounded Context）
  ├── adapter/          // 适配层，外部输入输出（I/O 适配）
  │   ├── cli/         // 命令行接口（CLI）
  │   ├── grpc/        // gRPC 适配层
  │   ├── rest/        // REST API 适配层
  │   ├── persistence/  // 数据存储 适配层
  │   ├── listener/     // mq消费入口
  │   ├── scheduler/    // 定时任务（调度器）
  │
  ├── application/      // 应用服务层（业务编排、事务管理）
  │   ├── service/     // 应用层服务（调用 domain/service 进行业务编排）
  │   ├── port/        // 端口（接口，定义对外的业务契约）
  │
  ├── domain/           // 领域层（核心业务逻辑）
      ├── model/       // 领域模型（实体、值对象）
      ├── port/        // 端口（接口，定义对外的业务契约）
      ├── service/     // 领域服务（无状态的核心业务逻辑）
```


- 外部交互接口 比如api/consumer/ listener 可以单独一个module
- application-starter单独一个module
- basic types 一个module
- 注意adapter层的service stub来源于 applicaton层
- 依赖关系 
  - domain ← application ← adaptor 
  - infra ← application ← adaptor 
- 流量路径  adaptor -> application ->  infra