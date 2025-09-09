# 更新日志

## [0.2.3] - 2025-09-09

### 重大突破 (Major Breakthrough)
- **AlarmManager回调隔离问题解决**: 成功识别并解决`android_alarm_manager_plus`插件的核心技术障碍——回调函数在独立Dart隔离环境中运行，无法访问主应用MethodChannel
- **原生BroadcastReceiver架构**: 完全绕过Flutter插件限制，实现AlarmManager → BroadcastReceiver → AlarmActivity的纯原生Android调度链路

### 新增 (Added)
- **AlarmReceiver.kt**: 自定义BroadcastReceiver类，处理系统AlarmManager广播，支持强力设备唤醒和Activity启动
- **原生AlarmManager调度**: MainActivity中新增`scheduleNativeAlarm`方法，使用原生Android API直接发送广播到BroadcastReceiver
- **强化设备唤醒功能**: 
  - 实现SCREEN_BRIGHT_WAKE_LOCK + ACQUIRE_CAUSES_WAKEUP强力唤醒
  - 延长唤醒时间到10秒，提供多重降级机制
  - 添加锁屏状态检测和日志追踪
- **原生测试界面**: AlarmTestPage新增紫色测试区域，专门测试原生AlarmManager方案
- **振动权限配置**: AndroidManifest.xml中添加VIBRATE权限支持

### 修复 (Fixed)
- **Flutter回调隔离问题**: 通过原生BroadcastReceiver彻底解决AlarmManager回调无法访问MethodChannel的问题
- **OnePlus系统兼容性**: 原生方案理论上能绕过OnePlus/ColorOS的后台调度限制
- **编译错误修复**: 解决Kotlin语法错误，确保项目稳定编译

### 技术验证 (Validation)
- ✅ **原生调度成功**: 10秒、30秒延时AlarmManager触发准确
- ✅ **应用状态测试**: 前台、最小化状态下提醒正常弹出
- ❌ **息屏完全唤醒**: OnePlus设备仍需用户轻微操作才能看到弹窗
- ❌ **音频功能**: 因编译问题暂未实现提示音播放

### 已知问题 (Known Issues)
- OnePlus/ColorOS对息屏唤醒有更严格的系统限制
- 音频和振动功能需要进一步开发和测试
- 完全自主息屏唤醒仍需深入研究系统级权限

## [0.2.2] - 2025-09-09

### 新增 (Added)
- **OnePlus设备息屏弹窗技术方案**: 集成 `android_alarm_manager_plus` 和 `wakelock_plus` 插件，实现基于AlarmManager的定时提醒系统
- **原生全屏提醒Activity**: 创建Kotlin实现的 `AlarmActivity`，支持锁屏状态下的全屏弹窗显示，包含WakeLock管理和窗口唤醒功能
- **权限管理服务**: 新增 `PermissionService` 类，自动检查和请求通知权限、悬浮窗权限、精确闹钟权限和电池优化白名单
- **AlarmManager调度服务**: 创建 `AlarmManagerService` 类，封装定时提醒的调度逻辑，支持一次性和重复提醒
- **调试测试界面**: 新增 `AlarmTestPage` 可滚动测试页面，包含权限状态显示、直接测试按钮和多种延时测试选项

### 技术架构 (Architecture)
- **MethodChannel通信**: 建立Flutter与原生Android代码的双向通信，支持Activity启动和权限管理
- **多层降级机制**: 实现三层降级策略（直接启动、备选方案、通知降级）确保功能robustness
- **权限配置完善**: 在AndroidManifest.xml中配置所有必要权限，包括SYSTEM_ALERT_WINDOW、WAKE_LOCK、EXACT_ALARM等

### 技术验证 (Validation)
- ✅ **权限系统验证**: 所有必要权限可正常获取和检查
- ✅ **MethodChannel验证**: 直接调用测试成功，全屏Activity正常启动
- ✅ **AlarmManager验证**: 定时调度返回成功，OnePlus设备兼容性确认
- ✅ **AlarmActivity验证**: 全屏蓝色弹窗正常显示，WakeLock功能正常

### 发现问题 (Issues Identified)
- **AlarmManager回调隔离问题**: 发现回调函数在独立Dart隔离环境中运行，无法访问主应用MethodChannel连接
- **OnePlus系统兼容性**: 确认OnePlus/ColorOS对后台应用有特殊限制，但AlarmManager机制可绕过

### 文档 (Documentation)
- 更新 `docs/current_development_status.md` 记录详细测试结果和技术发现
- 更新 `CLAUDE.md` 添加对话开始时的状态检查指引
- 更新 `prompts/prompts.md` 添加对话结束时的文档更新模板
- 完善 `README.md` 中的文档更新说明

## [0.2.1] - 2025-08-22

### 新增 (Added)
- **手机端数据同步服务**: 扩展了 `supabase_service.dart` 的功能，实现了在应用启动时或通过手动按钮，从云端拉取 `Quests`, `Schedules`, `Routine_Plan`, 和 `Reminders` 表的全部数据。
- **本地数据缓存**: 在 `database_helper.dart` 中增加了通用的 `replaceAll` 方法，用于将从云端获取的数据高效地存入并更新本地SQLite数据库。
- **数据验证页面**: 创建了新的只读页面 `planning_data_display_page.dart`，用于直观地展示和验证从云端同步到本地的所有日程规划类数据，确保了数据流的正确性。
- **提醒表结构**: 在 `database/schema.sql` 中为本地SQLite和云端Supabase新增了 `Reminders` 表。该表设计灵活，使用JSON字段存储触发和重复规则，为未来实现从简单到复杂的各类提醒功能提供了扩展性。
- **初始提醒数据**: 基于 `Routine_Plan` 中的固定日程，生成并填充了初始的提醒数据到 `Reminders` 表中，为核心的作息时间点创建了基础的弹窗提醒。

### 文档 (Documentation)
- 更新了 `README.md` 中的项目结构和核心文件说明，加入了对 `Reminders` 表的描述。
- 更新了 `database/schema.sql` 文件末尾的“数据库同步说明”，将 `Reminders` 表纳入数据流转的描述中。
### 变更 (Changed)
- **UI优化**: 改进了 `planning_data_display_page.dart` 的UI，使用可折叠的 `ExpansionTile` 控件来展示每个数据表，解决了数据过多导致屏幕拥挤的问题，提升了可读性。

### 修复 (Fixed)
- **数据库迁移问题**: 通过在 `database_helper.dart` 中增加数据库版本号并实现 `onUpgrade` 逻辑，修复了因数据库结构更新而导致的 "no such table" 错误，确保了应用在升级后能正确创建新表。
- **云端数据同步错误**:
    - 解决了因Supabase表名大小写敏感导致的 "relation does not exist" 42P01错误。
    - 修复了将复杂数据类型（如Map, List, Boolean）直接存入SQLite导致的 `DatabaseException`。通过在存入前将数据序列化为JSON字符串或整型，保证了数据类型的兼容性。
    - 修复了因API密钥失效导致的 "Invalid API key" 401认证错误。

## [0.2.0] - 2025-08-12

### 新增 (Added)
- **提醒&日程管理系统框架**:
    - 在 `database/schema.sql` 中为本地SQLite和云端Supabase数据库正式定义了 `Quests` (主支线任务), `Schedules` (具体日程), 和 `Routine_Plan` (作息规则) 的表结构，为新的核心功能奠定数据基础。
- **Obsidian笔记库集成**:
    - 创建了新的Python脚本 `src/ob_quest.py`。该脚本能够扫描指定的Obsidian笔记库目录，根据文件夹层级结构和文件元数据（如【id】）自动生成并填充本地数据库中的 `Quests` 表，实现了从知识库到任务系统的自动化数据录入。

### 文档 (Documentation)
- 在 `docs/weekly_develop_plan.md` 中制定了“提醒&日程管理系统”的详细开发计划。并且更新了`docs\quest_objective_system_design.md`.
- 更新了 `README.md` 中的项目结构和核心文件说明，以包含新添加的 `ob_quest.py` 脚本和数据库表。




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