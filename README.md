# 欠款记账App

## 项目简介
欠款记账App是一个基于Flutter跨平台开发的个人财务管理应用，专门用于记录和管理个人之间的借款和贷款信息。

## 核心功能

### 1. 新增欠款
- 支持记录借款人/出借人信息
- 金额、日期、备注
- 到期日、利率设置
- 状态管理（待还/已还/逾期）

### 2. 列表查看
- 按时间/金额/状态排序
- 筛选未还/已还/逾期记录
- 支持滑动操作（编辑/标记已还/删除）

### 3. 详情/编辑/删除
- 查看完整欠款详情
- 编辑现有记录
- 删除不需要的记录
- 一键标记已还

### 4. 统计功能
- 总借出/借入金额
- 待收/待还金额
- 逾期金额统计
- 按月汇总图表

### 5. 其他功能
- 深色模式支持
- 逾期提醒
- 数据导入/导出功能
- 数据本地存储（内存数据库）

## 技术栈

- **前端框架**：Flutter 3.0+
- **状态管理**：Flutter内置StatefulWidget
- **数据库**：内存数据库（开发阶段使用，便于测试）
- **UI组件**：Material Design
- **其他依赖**：flutter_slidable、intl、file_picker、path_provider

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── models/               # 数据模型
│   └── debt_model.dart   # 借款记录模型
├── screens/              # 页面
│   ├── home_screen.dart        # 首页（欠款列表）
│   ├── add_edit_debt_screen.dart  # 新增/编辑欠款
│   ├── statistics_screen.dart     # 统计页面
│   └── profile_screen.dart        # 个人中心
├── database/             # 数据库
│   └── database_helper.dart  # 数据库操作助手
├── widgets/              # 自定义组件
└── utils/                # 工具类
```

## 依赖清单

| 依赖包 | 版本 | 用途 |
|-------|------|------|
| flutter | SDK | 核心框架 |
| cupertino_icons | ^1.0.2 | iOS风格图标 |
| flutter_slidable | ^3.1.0 | 滑动操作组件 |
| intl | ^0.18.0 | 国际化和日期格式化 |
| path_provider | ^2.1.0 | 文件路径处理 |
| file_picker | ^8.0.0 | 文件选择器，用于数据导入 |

## 运行说明

### 前置条件
- 安装Flutter SDK 3.0或更高版本
- 安装Dart SDK
- 配置好Android或iOS开发环境

### 步骤

1. **克隆项目**
   ```bash
   git clone <项目地址>
   cd debt_tracker
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行项目**
   - Android模拟器/真机：
     ```bash
     flutter run
     ```
   - iOS模拟器/真机：
     ```bash
     flutter run
     ```
   - Web端：
     ```bash
     flutter run -d chrome
     ```

### 构建发布版本

- Android：
  ```bash
  flutter build apk
  ```

- iOS：
  ```bash
  flutter build ios
  ```

- Web：
  ```bash
  flutter build web
  ```

## 注意事项

1. **数据存储**：所有数据存储在内存数据库中（开发阶段），不会上传到服务器
2. **权限**：不需要特殊权限
3. **性能**：应用采用内存存储，操作响应迅速
4. **深色模式**：支持系统自动切换和手动切换
5. **备份**：建议定期备份应用数据

## 数据导入/导出使用说明

### 导出数据
1. 进入"我的"页面
2. 点击"导出数据"按钮
3. 系统会根据当前日期生成备份文件（格式：debt_tracker_backup_yyyy-MM-dd.json）
4. Web平台：文件会直接下载到浏览器默认下载文件夹
5. 移动平台：文件会保存在应用文档目录，具体路径会在导出成功后显示

### 导入数据
1. 进入"我的"页面
2. 点击"导入数据"按钮
3. 在弹出的文件选择器中选择之前导出的JSON文件
4. 确认导入操作（导入会覆盖现有数据）
5. 导入成功后，系统会自动刷新首页数据

### 备份建议
- 定期导出数据备份到安全位置
- 在进行重要操作前先导出数据
- 更换设备时可通过导入/导出功能迁移数据

## 未来计划

- [x] 支持数据导出/导入
- [ ] 添加还款提醒通知
- [ ] 实现多用户支持
- [ ] 添加更多统计分析功能
- [ ] 支持云同步

## 许可证

MIT License
