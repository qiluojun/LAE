# 更新日志



## [0.1.7] - 2025-08-09

### 新增 (Added)
- **云端同步功能**:
    - 在 `lae_app/lib/services/` 目录下创建了 `supabase_service.dart`，用于处理本地数据到Supabase的上传。
    - 实现了将本地 `status_records` 表中的问卷数据上传到云端 `survey_records` 表的逻辑。
- **记录删除功能**:
    - 在 `database_helper.dart` 中添加了 `deleteStatusRecord` 方法。
    - 在历史记录详情弹窗 (`records_display_page.dart`) 中增加了“删除”按钮，允许用户删除本地存储的问卷记录。

### 修复 (Fixed)
- **云端同步重复上传**: 解决了数据上传时因时间戳格式和时区问题导致的重复上传错误。现在通过将所有时间转换为UTC标准格式进行比较和上传，确保了数据同步的幂等性。

### 文档 (Documentation)
- 在 `database/schema.sql` 中为 `survey_records` 表添加了完整的表和列注释。
- 更新了 `database/schema.sql` 底部的数据库同步说明，以反映 `survey_records` 表的数据流向。


## [0.1.6] - 2025-07-28

### 变更 (Changed)
- **问卷功能重构**:
    - 根据开发计划，将状态问卷中的“睡眠质量”、“LAE状态”等评分项从离散选择改为 `Slider` 控件，支持0.1步长的精细打分。
    - 将“昨晚睡着时间”和“今早离开床的时间”从自由文本输入改为 `ChoiceChip` 单选题，优化了输入体验。
    - 在 `status_record.dart` 模型中，将对应的评分字段类型从 `int` 修改为 `double`。
- **数据库结构更新**:
    - 在 `database_helper.dart` 中更新了 `status_records` 表的 `CREATE TABLE` 语句，将评分相关的列类型从 `INTEGER` 改为 `REAL`，并添加了新字段。

### 新增 (Added)
- **问卷内容扩充**:
    - 在状态问卷中增加了三个新问题：“昨夜入睡用时”（单选）、“今早起床用时”（单选）和“睡眠相关异常情况”（自由输入）。
    - 相应地，在 `status_record.dart` 数据模型和 `status_records` 数据库表中添加了 `timeToFallAsleep`, `timeToGetUp`, `sleepAbnormalities` 字段。

### 修复 (Fixed)
- **数据显示不完整**: 修复了历史记录详情弹窗 (`records_display_page.dart`) 未显示所有问卷项的问题，现在可以完整展示包括新增字段在内的所有数据。
- **问卷提交逻辑**: 移除了问卷页面的输入校验，允许所有题目留空提交，符合“全部非必答题”的要求。


## [0.1.5] - 2025-07-27

### 新增 (Added)
- 在主界面添加了“查看历史状态记录”按钮，允许用户浏览所有已提交的问卷数据。
- 创建了新的UI页面 `lae_app/lib/pages/records_display_page.dart`，用于以列表形式展示历史记录。
- 在 `database_helper.dart` 中添加了 `getAllStatusRecords` 方法，用于从本地数据库中按时间倒序查询所有状态记录。
- 引入 `intl` 包以优化日期和时间的显示格式。

### 变更 (Changed)
- 在 `status_record.dart` 模型中添加了 `fromMap` 工厂构造函数，方便将数据库查询结果转换为对象。

### 修复 (Fixed)
- 修正了 `database_helper.dart` 中 `getAllStatusRecords` 方法的定义位置，解决了其无法被外部调用的编译错误。


## [0.1.4] - 2025-07-26

### 新增 (Added)
- 创建了状态问卷UI页面 `lae_app/lib/pages/status_survey_page.dart`，包含文本输入、评分选择和滑块控件。
- 引入 `flutter_local_notifications` 和 `timezone` 依赖，以实现定时本地通知功能。
- 创建了 `lae_app/lib/services/notification_service.dart`，用于封装和管理本地通知的初始化、调度和响应逻辑。
- 在应用启动时，实现了每日23:00定时发送问卷通知的功能。

### 变更 (Changed)
- 在 `lae_app/lib/` 下创建了 `pages/` 目录，用于存放UI页面文件，以优化项目结构。
- 更新了 `lae_app/lib/main.dart`，增加了全局 `NavigatorKey` 和路由 `/survey`，用于处理通知点击后的页面跳转。


## [0.1.3] - 2025-07-13-2

### 变更 (Changed)
- 再次重构了 `README.md` 中的开发计划，采纳了更为敏捷和迭代的开发模式。
- 新的开发路线图分为三个阶段：基础框架与MVP（探索期）、迭代开发与试用优化（扩张期）、演示与推广（成熟期）。
- 该计划强调先构建一个最小化的端到端可用系统，然后在此基础上逐步扩展功能，而非按技术层（后端、前端）分步开发。

### 文档 (Documentation)
- 更新了 `README.md` 中的长期开发计划部分，以反映新的迭代式开发策略。

## [0.1.2] - 2025-07-13-1

### 变更 (Changed)
- 重构了 `README.md` 中的开发计划，明确了以PC端为核心、Supabase为同步桥梁、移动端为交互界面的新架构。
- 更新了开发路线图，分为四个阶段：核心后端与数据库、云同步与移动客户端、数据集成与干预、优化与扩展。
- 明确了Python后端将作为长期运行的服务，而非简单的命令行脚本。
- 调整了设备间通信机制，从文件同步模式更新为通过Supabase数据库进行数据交换。
- 在项目结构文档中，将 `docs/develop_plan` 更新为 `docs/weekly_develop_plan`。

### 文档 (Documentation)
- 完善了 `README.md` 中的系统架构和数据流说明，以匹配新的开发计划。

## [0.1.1] - 2025-07-10

### 新增 (Added)
- 创建了完整的项目结构文档 `docs/project_structure.md`，包含智能更新机制
- 在项目结构文档中添加了AI自动更新指令，支持全项目和局部扫描更新
- 完善了数据库架构文档，明确区分本地SQLite和Supabase PostgreSQL的用途

### 变更 (Changed)
- 全面校正了 `database/schema.sql` 文件，使其与实际数据库DDL完全匹配
- 重新组织了schema.sql的结构，清晰区分本地和云端数据库表
- 修正了LAE系统全称为"Live And Enjoy"
- 更新了所有表结构定义，移除了不匹配的约束条件
- 标准化了本地SQLite和Supabase PostgreSQL的命名规范

### 修复 (Fixed)
- 修正了Activities表中importance和priority字段的CHECK约束问题
- 修正了Risk_Patterns表的字段名（risk_pattern_id vs id）
- 修正了System_Triggers表的related_risk_pattern_ids字段类型
- 修正了Routine_Plan表中plan_type字段的约束定义

### 文档 (Documentation)
- 完善了项目结构说明，包含所有文件夹和文件的详细功能定位
- 添加了数据库同步机制说明和数据流向图解
- 更新了系统架构说明，明确了多平台协作模式
- 为未来的项目维护提供了自动化文档更新机制

## [0.1.0] - 2025-07-04

### 新增 (Added)
- 搭建了标准化的项目文件结构。
- 初始化了Git版本控制。
- 创建了 `README.md` 作为项目入口。
- 创建了 `database/schema.sql` 用于固化数据库结构。
- 创建了 `prompts/prompts.md` 作为AI指令库。
- 创建了 `CHANGELOG.md` 用于记录项目进展。

### 变更 (Changed)
- 将所有项目元信息从NotebookLM迁移至项目仓库内。
- 为 `src/supabase_client.py` 脚本添加了基础的文档字符串。