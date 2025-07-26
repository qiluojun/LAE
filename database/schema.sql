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
--  表 5: Routine_Plan (本地SQLite)
--  用途: 记录用户预设的日常活动安排，辅助活动推荐与主支线管理。
-- =============================================================================
CREATE TABLE Routine_Plan (
    plan_id       INTEGER PRIMARY KEY AUTOINCREMENT,                   -- 计划的唯一标识符
    activity_id   INTEGER NOT NULL,                                    -- 关联到 Activities 表中的活动
    day_of_week   TEXT,                                                -- 适用的星期, e.g., 'Mon,Wed,Fri', 'Weekdays', 'All'
    specific_date DATE,                                                -- 特定的日期 (通常与day_of_week二选一)
    start_time    TIME    NOT NULL,                                    -- 计划的开始时间
    end_time      TIME    NOT NULL,                                    -- 计划的结束时间
    plan_type     TEXT    DEFAULT 'RECURRING' NOT NULL,               -- 计划类型: 'RECURRING' (周期性) 或 'ONE_OFF' (一次性)
    notes         TEXT,                                                -- 关于此计划的备注
    FOREIGN KEY (activity_id) REFERENCES Activities(activity_id)
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

-- =============================================================================
--  表 10: Quests (本地SQLite)
--  用途: 定义一个长期的项目、一个重要的生活领域或一个宏大的目标。任务之间
--        可以形成父子关系，构成一个任务树。
-- =============================================================================
CREATE TABLE Quests (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT, -- 内部自增主键
    quest_id           TEXT,                              -- 用户可输入的层级化ID, e.g., "1", "1.1"
    name               TEXT NOT NULL,                     -- 任务名称
    parent_id          INTEGER,                           -- 指向 Quests.id 的外键，用于构建层级关系
    status             TEXT DEFAULT '进行中',             -- 任务状态: "进行中", "已完成", "已暂停", "已放弃"
    progress           TEXT,                              -- 进度描述, e.g., "75%", "已完成文献综述"
    target_frequency   TEXT,                              -- 目标执行频率, e.g., "3次/周"
    target_duration    TEXT,                              -- 目标投入时长, e.g., "5小时/周"
    description        TEXT,                              -- 详细描述
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES Quests(id)
);

-- =============================================================================
--  表 11: Objectives (本地SQLite)
--  用途: 定义一个具体的、可操作的、与特定Quest关联的行动项。
-- =============================================================================
CREATE TABLE Objectives (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT, -- 内部自增主键
    linked_quest_id    INTEGER NOT NULL,                  -- 关联的Quest ID
    name               TEXT NOT NULL,                     -- 目标名称
    status             TEXT DEFAULT '待办',               -- 目标状态: "待办", "进行中", "已完成", "已取消"
    time_type          TEXT,                              -- 时间约束类型: "Fixed", "Range", "Recurring", "Deadline", "Flexible"
    start_date_time    DATETIME,                          -- 开始时间
    end_date_time      DATETIME,                          -- 结束时间
    recurring_rule     TEXT,                              -- 周期性任务规则, e.g., "每周一、三、五"
    conditions         TEXT,                              -- 灵活任务的执行条件 (JSON)
    description        TEXT,                              -- 详细描述
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (linked_quest_id) REFERENCES Quests(id)
);


-- =============================================================================
--  表 12: quests (Supabase PostgreSQL)
--  用途: 云端主支线任务表，与本地 Quests 表同步。
-- =============================================================================
CREATE TABLE public.quests (
    id                 bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    created_at         timestamp with time zone NOT NULL DEFAULT now(),
    quest_id           text NULL,
    name               text NOT NULL,
    parent_id          bigint NULL,
    status             text NULL DEFAULT '进行中'::text,
    progress           text NULL,
    target_frequency   text NULL,
    target_duration    text NULL,
    description        text NULL,
    updated_at         timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT quests_pkey PRIMARY KEY (id),
    CONSTRAINT quests_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.quests(id)
) TABLESPACE pg_default;

-- =============================================================================
--  表 13: objectives (Supabase PostgreSQL)
--  用途: 云端目标/日程表，与本地 Objectives 表同步。
-- =============================================================================
CREATE TABLE public.objectives (
    id                 bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    created_at         timestamp with time zone NOT NULL DEFAULT now(),
    linked_quest_id    bigint NOT NULL,
    name               text NOT NULL,
    status             text NULL DEFAULT '待办'::text,
    time_type          text NULL,
    start_date_time    timestamp with time zone NULL,
    end_date_time      timestamp with time zone NULL,
    recurring_rule     text NULL,
    conditions         jsonb NULL,
    description        text NULL,
    updated_at         timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT objectives_pkey PRIMARY KEY (id),
    CONSTRAINT objectives_linked_quest_id_fkey FOREIGN KEY (linked_quest_id) REFERENCES public.quests(id)
) TABLESPACE pg_default;


-- =============================================================================
--                              数据库同步说明
-- =============================================================================
-- 
-- 本地SQLite数据库 (data_base.db):
-- - Activities: 核心活动数据，本地存储和管理
-- - Event_Log: 本地事件日志记录
-- - Risk_Patterns: 本地风险模式定义
-- - System_Triggers: 本地触发器配置
-- - Routine_Plan: 用户日常计划安排
--
-- Supabase PostgreSQL数据库:
-- - risk_patterns: 云端风险模式同步
-- - system_triggers: 云端触发器同步  
-- - user_inputs: 移动端用户输入数据接收
-- - system_outputs: 系统输出指令发送给移动端
--
-- 数据流向:
-- 1. 移动端 → user_inputs (Supabase) → supabase_client.py → 本地SQLite
-- 2. supabase_client.py → system_outputs (Supabase) → 移动端
-- 3. 配置数据(risk_patterns, system_triggers)在本地和云端之间双向同步
--
-- =============================================================================