-- #############################################################################
-- ##                                                                         ##
-- ##                     LAE (Live And Enjoy) System                        ##
-- ##                            Database Schema                              ##
-- ##                                                                         ##
-- ##  这份SQL文件定义了LAE系统的完整数据库架构，包括本地SQLite数据库和       ##
-- ##  Supabase PostgreSQL云端数据库的表结构。                               ##
-- ##                                                                         ##
-- ##  核心理念: 记录→分析→预测→干预                                          ##
-- ##  核心原则: 重逻辑，轻链路                                               ##
-- ##                                                                         ##
-- ##  数据库架构说明：                                                       ##
-- ##  - 本地SQLite数据库：存储核心业务数据，支持离线操作                     ##
-- ##  - Supabase PostgreSQL：云端数据同步，支持跨设备通信                   ##
-- ##                                                                         ##
-- #############################################################################


-- =============================================================================
--                           本地SQLite数据库表结构
--                     (用于核心业务数据和离线操作)
-- =============================================================================

-- =============================================================================
--  表 1: Activities (本地SQLite)
--  用途: 存储系统中所有个人活动的详细信息，支持层级管理和多维度属性。
--        是活动推荐模块的数据源。
-- =============================================================================
CREATE TABLE Activities (
    activity_id                INTEGER  PRIMARY KEY,                    -- 活动的唯一标识符
    name                       TEXT     NOT NULL,                       -- 活动名称
    parent_activity_id         INTEGER,                                 -- 父活动ID，用于表示层级关系 (例如大项目下的子任务)
    time_valid_range           TEXT,                                    -- 活动有效日期区间, 例如 "250531-250605"
    daily_frequency            INTEGER,                                 -- 每日适宜频率
    suitable_periods           TEXT,                                    -- 适宜时段, 例如 "上午,晚上" (可以是JSON数组或逗号分隔)
    single_length_minutes      TEXT,                                    -- 单次时长, 例如 "30-45" 分钟
    importance                 INTEGER,                                 -- 重要性 (1-5)
    priority                   INTEGER,                                 -- 动态计算的优先级 (0-5)
    cognitive_load             TEXT,                                    -- 认知负荷/烧脑程度, 例如 "3.0-4.5"
    physical_exertion_level    TEXT,                                    -- 体力消耗, 例如 "1.0-2.5"
    uncertainty_level          TEXT,                                    -- 不确定性/执行难度, 例如 "1-2"
    eye_strain_level           TEXT,                                    -- 眼部消耗, 例如 "2.0-3.0"
    self_control_risk          TEXT,                                    -- 自控风险, 例如 "1.0-4.0"
    min_focus_needed           TEXT,                                    -- 最低专注度需求, 例如 "3.0-5.0"
    mood_compatibility         TEXT,                                    -- 情绪兼容性, 例如 "uplifting,calming"
    suitable_location_tags     TEXT,                                    -- 适宜地点标签, 例如 "home,quiet_place"
    required_convenience_level INTEGER  DEFAULT 3,                     -- 所需便利性/条件要求 (1-5)
    noise_tolerance            TEXT     DEFAULT 'any',                 -- 噪音耐受度, 例如 "requires_quiet", "tolerant", "any"
    engagement_style           TEXT,                                    -- 参与方式, 例如 "passive_consumption", "active_learning"
    inline_subtasks            TEXT,                                    -- JSON列表, 用于存储行内子任务及其特定属性
    content_location           TEXT,                                    -- 主支线中的位置
    created_timestamp          DATETIME DEFAULT CURRENT_TIMESTAMP,     -- 创建时间戳
    status                     TEXT     DEFAULT 'pending',             -- 活动状态
    notes                      TEXT,                                    -- 额外备注
    FOREIGN KEY (parent_activity_id) REFERENCES Activities(activity_id) -- 外键关系，引用自身，建立层级结构
);


-- =============================================================================
--  表 2: Event_Log (本地SQLite)
--  用途: 作为核心的事件记录中心，记录系统中发生的所有关键事件，是分析和
--        预测的基础数据。
-- =============================================================================
CREATE TABLE Event_Log (
    log_id        INTEGER  PRIMARY KEY AUTOINCREMENT,                  -- 日志的唯一标识符
    timestamp     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 事件发生的精确时间
    event_type    TEXT     NOT NULL,                                   -- 事件类型, e.g., 'STATE_CHECK_IN', 'RISK_DETECTED', 'USER_RESPONSE'
    source        TEXT     NOT NULL,                                   -- 事件来源, e.g., 'USER_ANDROID', 'SYSTEM_WINDOWS_MONITOR'
    event_details TEXT,                                                -- JSON格式的详细信息，提供了极高的扩展性
    notes         TEXT                                                 -- 额外备注
);


-- =============================================================================
--  表 3: Risk_Patterns (本地SQLite)
--  用途: 存储各种需要被系统检测的风险行为模式的定义，为干预决策模块提供依据。
-- =============================================================================
CREATE TABLE Risk_Patterns (
    risk_pattern_id INTEGER PRIMARY KEY AUTOINCREMENT,                 -- 风险模式的唯一标识符
    pattern_name    TEXT    NOT NULL UNIQUE,                           -- 风险模式的名称, e.g., "深夜无效刷屏"
    description     TEXT,                                               -- 详细描述
    detection_rules TEXT    NOT NULL,                                   -- JSON格式的检测规则, e.g., '{"type":"APP_USAGE", "apps":["bilibili.exe"], "min_duration_seconds": 60}'
    is_enabled      BOOLEAN DEFAULT TRUE                                -- 是否启用此模式的监测
);


-- =============================================================================
--  表 4: System_Triggers (本地SQLite)
--  用途: 存储各种触发器及其关联的动作，例如定时自评提醒或特定行为检查。
-- =============================================================================
CREATE TABLE System_Triggers (
    trigger_id               INTEGER PRIMARY KEY AUTOINCREMENT,        -- 触发器的唯一标识符
    trigger_name             TEXT    NOT NULL,                         -- 触发器名称, e.g., "晚间8点自评"
    trigger_type             TEXT    NOT NULL,                         -- 触发类型, e.g., 'TIME', 'LOCATION_CHANGE'
    trigger_condition        TEXT    NOT NULL,                         -- 触发的具体条件, e.g., "20:00" for 'TIME' type
    action_to_perform        TEXT    NOT NULL,                         -- 定义触发后要执行的动作的逻辑名称, e.g., 'PERFORM_BINGE_RISK_SELF_ASSESSMENT'
    related_risk_pattern_ids TEXT,                                     -- [可选] 关联的Risk_Patterns ID数组 (JSON格式或逗号分隔)
    is_enabled               BOOLEAN DEFAULT TRUE                      -- 是否启用此触发器
);




-- =============================================================================
--                         Supabase PostgreSQL数据库表结构
--                      (用于云端数据同步和跨设备通信)
-- =============================================================================

-- =============================================================================
--  表 6: risk_patterns (Supabase PostgreSQL)
--  用途: 云端风险模式存储，与本地Risk_Patterns表同步
-- =============================================================================
CREATE TABLE public.risk_patterns (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,               -- 风险模式的唯一标识符
    created_at timestamp with time zone NOT NULL DEFAULT now(),        -- 记录创建时间
    pattern_name text NOT NULL,                                        -- 风险模式的名称
    description text NULL,                                              -- 详细描述
    detection_rules jsonb NULL,                                         -- JSONB格式的检测规则
    is_enabled boolean NOT NULL DEFAULT true,                          -- 是否启用此模式的监测
    CONSTRAINT risk_patterns_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;


-- =============================================================================
--  表 7: system_triggers (Supabase PostgreSQL)
--  用途: 云端触发器存储，与本地System_Triggers表同步
-- =============================================================================
CREATE TABLE public.system_triggers (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,               -- 触发器的唯一标识符
    created_at timestamp with time zone NOT NULL DEFAULT now(),        -- 记录创建时间
    trigger_name text NOT NULL,                                        -- 触发器名称
    trigger_type text NOT NULL,                                        -- 触发类型
    trigger_condition text NOT NULL,                                   -- 触发的具体条件
    action_to_perform text NOT NULL,                                   -- 定义触发后要执行的动作
    related_risk_pattern_ids bigint[] NULL,                           -- 关联的risk_patterns ID数组
    is_enabled boolean NOT NULL DEFAULT true,                         -- 是否启用此触发器
    CONSTRAINT system_triggers_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;


-- =============================================================================
--  表 8: user_inputs (Supabase PostgreSQL)
--  用途: 接收手机App上所有用户操作的数据，是 supabase_client.py 的主要输入源。
--        supabase_client.py 通过轮询此表来获取用户的最新动态。
-- =============================================================================
CREATE TABLE public.user_inputs (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,               -- 输入事件的唯一标识符
    timestamp timestamp with time zone NOT NULL DEFAULT now(),         -- 事件发生的精确时间
    event_type text NOT NULL,                                          -- 事件类型, e.g., 'STATE_CHECK_IN', 'APP_USAGE_SIMULATED'
    source text NULL,                                                  -- 事件来源, e.g., 'USER_ANDROID', 'USER_IOS'
    details jsonb NULL,                                                -- JSONB格式的详细信息，存储不同event_type特有的数据
    CONSTRAINT user_inputs_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;


-- =============================================================================
--  表 9: system_outputs (Supabase PostgreSQL)
--  用途: 记录由 supabase_client.py 脚本作出的提醒、干预指令等。Flutter App 通过
--        监听此表来接收并展示这些指令，实现系统与用户之间的交互。
-- =============================================================================
CREATE TABLE public.system_outputs (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,               -- 输出指令的唯一标识符
    timestamp timestamp with time zone NOT NULL DEFAULT now(),         -- 指令生成时间
    event_type text NOT NULL,                                          -- 事件类型, e.g., 'INTERVENTION_TRIGGERED', 'REMINDER_SENT'
    source text NULL,                                                  -- 指令来源, e.g., 'SYSTEM_ENGINE'
    intervention_type text NULL,                                       -- 干预类型, e.g., 'REMINDER', 'SUGGESTION', 'WARNING'
    content text NULL,                                                 -- 干预或提醒的具体内容
    action_to_perform text NULL,                                       -- 指导前端应用执行的动作, e.g., 'SHOW_POPUP', 'NAVIGATE_TO_ACTIVITY_LIST'
    CONSTRAINT system_outputs_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;


-- =============================================================================
--         主支线任务与目标系统 (Quest & Objective System)
-- =============================================================================


-- 建议的 objectives JSON 结构
[
  {
    "internal_id": "obj-20240812-1",
    "name": "完成奖学金面试的材料准备",
    "status": "已完成",
    "time": {"ddl_offical": "2025.8.31", "start": "2025.8.20", "ddl": "2025.8.30"},
    "description": "包括简历、个人陈述和推荐信的最终版。"
  },
  {
    "internal_id": "obj-20240812-2",
    "name": "进行三次模拟面试",
    "status": "进行中",
    "time": {}
    "description": "一次找导师，两次找朋友。"
  }
]

-- Quests 表 (用于本地 SQLite)
CREATE TABLE Quests (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    display_id         TEXT,                             -- 用于显示和排序的ID, e.g., "1", "1.1"
    name               TEXT NOT NULL,
    parent_id          INTEGER,                          -- 指向 Quests.id, 用于构建层级关系
    status             TEXT NOT NULL DEFAULT '进行中',    -- "进行中", "已完成", "已暂停", "已放弃"
    
    -- 将 Objectives 作为 JSON 文本存储。该列可以为 NULL，代表此 Quest 没有具体目标。
    objectives         TEXT,                             -- 存储 Objectives 列表的 JSON 字符串
    
    target_rules       TEXT,                             -- JSON格式，存储频率、时长等目标
    description        TEXT,
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    LAE_id             INTEGER,
    FOREIGN KEY (parent_id) REFERENCES Quests(id)
);

-- Quests 表 (用于 Supabase/PostgreSQL)
CREATE TABLE public.Quests (
    id                 BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    display_id         TEXT,
    name               TEXT NOT NULL,
    parent_id          BIGINT,
    status             TEXT NOT NULL DEFAULT '进行中',
    
    -- 使用更高效的 JSONB 类型。该列可以为 NULL。
    objectives         JSONB,
    
    target_rules       JSONB,
    description        TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at         TIMESTAMPTZ DEFAULT NOW(),
    LAE_id             BIGINT,
    FOREIGN KEY (parent_id) REFERENCES public.Quests(id)
);


-- Schedules 表 (用于本地 SQLite)
CREATE TABLE Schedules (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    name               TEXT NOT NULL,
    status             TEXT NOT NULL DEFAULT '计划中',    -- "计划中", "已完成", "已跳过", "进行中"
    
    -- 外键变为可选 (NULLABLE)，允许存在独立的日程
    linked_quest_id    INTEGER,                          
    
    -- 用于关联到 Quest.objectives JSON中某个对象的ID。同样可选。
    linked_objective_internal_id TEXT,                     
    
    start_time         DATETIME NOT NULL,
    end_time           DATETIME NOT NULL,
    recurring_rule     TEXT,                             -- 存储周期性规则的 JSON 字符串
    notes              TEXT,
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (linked_quest_id) REFERENCES Quests(id)
);

-- Schedules 表 (用于 Supabase/PostgreSQL)
CREATE TABLE public.Schedules (
    id                 BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name               TEXT NOT NULL,
    status             TEXT NOT NULL DEFAULT '计划中',
    
    -- 外键变为可选 (NULLABLE)
    linked_quest_id    BIGINT,
    
    -- 用于关联到 Quest.objectives JSON中某个对象的ID。同样可选。
    linked_objective_internal_id TEXT,
    
    start_time         TIMESTAMPTZ NOT NULL,
    end_time           TIMESTAMPTZ NOT NULL,
    recurring_rule     JSONB,
    notes              TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (linked_quest_id) REFERENCES public.Quests(id)
);


-- Routine_Plan 表 (用于本地 SQLite)
CREATE TABLE Routine_Plan (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    activity_name      TEXT NOT NULL,
    
    -- 关联到主支线是可选的
    linked_quest_id    INTEGER,                          
    
    day_of_week        TEXT NOT NULL,                      -- e.g., 'Mon,Wed,Fri', 'Weekdays', 'All'
    start_time         TIME NOT NULL,
    end_time           TIME NOT NULL,
    notes              TEXT,
    FOREIGN KEY (linked_quest_id) REFERENCES Quests(id)
);



-- Routine_Plan 表 (用于 Supabase/PostgreSQL)
CREATE TABLE public.Routine_Plan (
    id                 BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    activity_name      TEXT NOT NULL,
    
    -- 关联到主支线是可选的
    linked_quest_id    BIGINT,
    
    day_of_week        TEXT NOT NULL,
    start_time         TIME NOT NULL,
    end_time           TIME NOT NULL,
    notes              TEXT,
    FOREIGN KEY (linked_quest_id) REFERENCES public.Quests(id)
);


-- =============================================================================
--  表 14: survey_records (Supabase PostgreSQL)
--  用途: 云端存储从移动端同步的各类问卷数据。
--        此表为通用设计，可容纳多种类型的问卷。
-- =============================================================================
CREATE TABLE public.survey_records (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    -- Supabase 自动管理的记录创建时间
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    -- 问卷在客户端记录的原始时间
    record_time timestamp with time zone NOT NULL,
    -- 问卷类型，用于区分不同问卷
    survey_type text NOT NULL,
    -- 存储问卷的具体回答，JSONB格式
    answers jsonb NULL,
    CONSTRAINT survey_records_pkey PRIMARY KEY (id),
    -- 复合唯一约束，防止同一时间、同一类型的问卷被重复提交
    CONSTRAINT survey_records_record_time_survey_type_key UNIQUE (record_time, survey_type)
);
-- 为表和关键列添加注释，方便理解
COMMENT ON TABLE public.survey_records IS '存储用户提交的各类问卷的回答记录';
COMMENT ON COLUMN public.survey_records.record_time IS '问卷提交的原始时间戳，与survey_type共同构成唯一标识';
COMMENT ON COLUMN public.survey_records.survey_type IS '问卷的类型标识符，例如: daily_status_check';
COMMENT ON COLUMN public.survey_records.answers IS '以JSONB格式存储的问卷回答键值对';

-- =============================================================================
--                              数据库同步说明
-- =============================================================================
-- 
-- 本地SQLite数据库 (data_base.db):
-- - Quests: 主支线任务数据，由 ob_quest.py 从Obsidian笔记库生成和管理。
-- - Schedules: 具体的日程安排，本地管理。
-- - Routine_Plan: 用户的日常作息规则，本地管理。
-- - Activities: 核心活动数据，本地存储和管理。
-- - Event_Log: 本地事件日志记录。
-- - Risk_Patterns: 本地风险模式定义。
-- - System_Triggers: 本地触发器配置。
--
-- Supabase PostgreSQL数据库:
-- - Quests: 云端主支线任务同步。
-- - Schedules: 云端日程安排同步。
-- - Routine_Plan: 云端日常作息规则同步。
-- - survey_records: 接收并存储来自移动端的问卷数据。
-- - user_inputs: 移动端用户输入数据接收。
-- - system_outputs: 系统输出指令发送给移动端。
-- - risk_patterns: 云端风险模式同步。
-- - system_triggers: 云端触发器同步。
--
-- 数据流向:
-- 1. Obsidian笔记库 -> ob_quest.py -> 本地 Quests 表 (data_base.db)
-- 2. 本地数据库 (Quests, Schedules, Routine_Plan) -> supabase_client.py -> 云端对应表 (Supabase)
-- 3. 云端数据 (Schedules, Routine_Plan) -> Flutter App -> 手机端提醒
-- 4. 移动端问卷数据 -> survey_records (Supabase)
-- 5. 移动端其他用户输入 -> user_inputs (Supabase) -> supabase_client.py -> 本地SQLite
-- 6. supabase_client.py -> system_outputs (Supabase) -> 移动端
--
-- =============================================================================