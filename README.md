# 游戏记账小程序

一个专为棋牌游戏设计的记账小程序，支持多人房间、实时转账记分、交易历史追踪和智能结算等功能。

## 🚀 项目特性

- **多人房间管理**: 创建/加入游戏房间，实时同步
- **智能记分系统**: 支持转账、消费等多种交易类型  
- **实时交易历史**: 完整的流水记录和统计分析
- **智能结算算法**: 自动计算最优结算方案
- **用户统计系统**: 胜率、积分、排行榜等数据统计
- **GraphQL API**: 现代化的数据查询和变更接口

## 🛠 技术栈

- **前端框架**: Taro 3.6 + React 18
- **数据管理**: GraphQL + Mock数据服务  
- **UI组件**: 自定义组件库
- **样式方案**: Sass + Tailwind CSS
- **构建工具**: Webpack 5
- **测试框架**: Jest

## 📱 支持平台

- 微信小程序
- 支付宝小程序
- 字节跳动小程序
- QQ小程序
- 京东小程序
- H5网页版

## 🏗 项目结构

```
game-accounting/
├── src/
│   ├── components/           # 通用组件
│   │   ├── game-settlement.js
│   │   ├── transaction-history.js
│   │   ├── transfer-modal.js
│   │   └── ...
│   ├── pages/               # 页面组件
│   │   └── index/
│   ├── graphql/             # GraphQL相关
│   │   ├── schema.js        # GraphQL Schema定义
│   │   ├── resolvers.js     # 解析器实现
│   │   ├── client.js        # GraphQL客户端
│   │   └── mock-data.js     # Mock数据
│   ├── hooks/               # 自定义Hooks
│   │   └── useGraphQL.js    # GraphQL数据获取hooks
│   ├── services/            # 业务逻辑服务
│   │   └── gameService.js   # 游戏业务服务
│   └── assets/              # 静态资源
├── docs/                    # 项目文档
│   ├── database-design.md   # 数据库设计
│   └── graphql-usage.md     # GraphQL使用指南
├── config/                  # 配置文件
├── __tests__/              # 测试文件
└── package.json
```

## 🚀 快速开始

### 环境准备
```bash
# 安装依赖
npm install
# 或
yarn install
```

### 开发调试
```bash
# 微信小程序
npm run dev:weapp

# H5网页版
npm run dev:h5

# 支付宝小程序
npm run dev:alipay

# 字节跳动小程序  
npm run dev:tt
```

### 生产构建
```bash
# 构建微信小程序
npm run build:weapp

# 构建H5版本
npm run build:h5
```

## 📊 GraphQL集成

### 数据模型
项目采用GraphQL作为数据查询语言，主要包含以下数据类型：

- **User**: 用户信息和余额
- **Room**: 游戏房间和状态
- **Transaction**: 交易记录
- **GameStats**: 游戏统计数据
- **SettlementResult**: 结算结果

### 使用示例

#### 查询当前用户
```javascript
import { useCurrentUser } from '@/hooks/useGraphQL';

const { data, loading, error } = useCurrentUser();
```

#### 创建交易
```javascript
import { useCreateTransaction } from '@/hooks/useGraphQL';

const [createTransaction] = useCreateTransaction();

await createTransaction({
  input: {
    fromPlayerId: 'user1',
    toPlayerId: 'user2', 
    amount: 100,
    description: '游戏赔付',
    type: 'TRANSFER',
    roomId: 'room1'
  }
});
```

#### 房间结算
```javascript
import { GameService } from '@/services/gameService';

// 生成结算策略
const strategy = await GameService.calculateSettlementStrategy(roomId);

// 执行结算
const results = await GameService.settleRoom(roomId);
```

### Mock数据服务
开发阶段使用内置的Mock数据服务，模拟真实的GraphQL API：

```javascript
import { graphqlClient, QUERIES, MUTATIONS } from '@/graphql/client';

// 查询数据
const result = await graphqlClient.query(QUERIES.GET_USERS);

// 变更数据  
const result = await graphqlClient.mutate(MUTATIONS.CREATE_USER, {
  input: { name: '新用户' }
});
```

## 🎮 主要功能

### 房间管理
- 创建游戏房间，设置房间名称和规则
- 生成房间码，邀请好友加入
- 实时显示房间成员和余额状态

### 交易记分
- 支持玩家间转账记分
- 记录各种消费（茶水费、餐费等）
- 交易历史完整追踪

### 智能结算  
- 自动计算最优结算方案
- 最小化转账次数的算法
- 一键执行结算操作

### 数据统计
- 个人胜率和积分统计
- 朋友圈排行榜
- 历史房间数据查询

## 🗄 数据库设计

项目采用关系型数据库设计，主要包含以下表：

- `users` - 用户信息表
- `rooms` - 房间信息表  
- `room_members` - 房间成员关系表
- `transactions` - 交易记录表
- `game_stats` - 游戏统计表
- `settlement_results` - 结算结果表

详细设计请参考：[数据库设计文档](./docs/database-design.md)

## 📖 API文档

GraphQL API的详细使用方法请参考：[GraphQL使用指南](./docs/graphql-usage.md)

## 🧪 测试

```bash
# 运行单元测试
npm test

# 运行测试并生成覆盖率报告
npm test -- --coverage
```

## 📝 开发规范

### 代码规范
- 遵循ESLint配置规则
- 使用Prettier格式化代码
- 组件命名采用PascalCase
- 文件命名采用kebab-case

### Git提交规范
```bash
feat: 新功能
fix: 修复问题  
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建配置等
```

### 组件开发
- 优先使用函数组件和Hooks
- 合理拆分组件粒度
- 提供完整的PropTypes或TypeScript类型
- 编写组件使用示例

## 🚀 部署指南

### 小程序发布
1. 使用对应平台的开发者工具打开`dist`目录
2. 配置appid和项目信息
3. 上传代码并提交审核

### H5部署
1. 运行`npm run build:h5`生成静态文件
2. 将`dist/h5`目录上传到服务器
3. 配置nginx或其他web服务器

## 🤝 贡献指南

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看[LICENSE](LICENSE)文件了解详情

## 📞 联系方式

- 项目地址：[GitHub仓库链接]
- 问题反馈：[Issues页面]
- 技术交流：[技术交流群]

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

---

**注意**: 本项目目前处于开发阶段，使用Mock数据服务。生产环境需要替换为真实的GraphQL后端服务。 