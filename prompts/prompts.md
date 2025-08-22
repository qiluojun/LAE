# LAE项目 AI指令库

## 代码生成 (Code Generation)

### 基于plan 来开发 
你好，我目前正在按照# 单次开发计划 7.26-27的计划，已经完成了第一步到第三步，而README中有程序的结构介绍（你可以根据结构介绍，了解程序涉及的脚本以及各脚本功能）。现在我在进行第四步的任务五。请你阅读相关的脚本，告诉我如何修改相关脚本，以修改定时触发机制。如果你需要我再提供一些脚本的代码供你阅读，也请告诉我。

### 指令：根据schema创建新表的访问函数
这是我的数据库结构，定义在 database/schema.sql 文件中：
[在这里粘贴你的schema.sql内容]

请为 user_manual_inputs 表编写一个Python函数，名为 add_manual_input，它接收一个包含状态信息的字典作为参数，并将其插入到数据库中。请使用supabase-py库。


## 文档生成 (Documentation)

### 指令：为Python函数生成Docstring
这是我写的一个Python函数，请遵循Google风格，为它生成清晰、完整的Docstring，包括对参数、返回值和可能引发的异常的说明。

[在这里粘贴你的Python函数代码]


## 数据生成 

### database PC本库 
#### schedule 
```
# 请求：根据日程描述生成SQL插入语句

你好，AI助手。请根据我提供的日程描述，为每一项日程生成一条对应的 SQL `INSERT` 语句，用于插入到 `Schedules` 表中。

---
### **处理规则与字段说明**

在生成语句时，请严格遵守以下规则：

**1. 目标表结构:**
所有数据都应插入 `Schedules` 表，其结构如下：

CREATE TABLE Schedules (
    id                           INTEGER PRIMARY KEY AUTOINCREMENT,
    name                         TEXT NOT NULL,
    status                       TEXT NOT NULL DEFAULT '计划中',
    linked_quest_id              INTEGER,
    linked_objective_internal_id TEXT,
    start_time                   TEXT, -- 存储时间相关的 JSON 对象
    end_time                     TEXT, -- 最终截止日期
    attribute                    TEXT, -- 存储属性相关的 JSON 对象
    recurring_rule               TEXT,
    notes                        TEXT,
    created_at                   DATETIME DEFAULT CURRENT_TIMESTAMP
);


**2. 复杂字段解析规则:**

  * **`name`**: 从描述中提取核心事件作为标题。
  * **`linked_quest_id`**: 如果描述中明确提到了关联的主支线及其ID（例如“zeroPPD (132-研究)”），则填入ID `132`。否则，请填入 `NULL`。
  * **`start_time` (JSON对象)**:
      * **`personal_start_date`**: 我希望开始动手的时间。
      * **`personal_ddl`**: 我自己定的DDL。
      * **`official_ddl`**: 老师、学校或官方要求的DDL。
      * **`condition`**: 需要满足某个条件才能开始，请记录该条件。
      * **`estimated_start_date`**: 我预估的、不确定的开始时间。
      * **`event_dates`**: 如果是多天的课程或活动，请记录。
  * **`end_time`**: 通常应设为 `official_ddl`。如果没有，可以设为 `personal_ddl` 或 `NULL`。
  * **`attribute` (JSON对象)**:
      * **`importance`**: 我提到的“重要性”或“importance”数值。
      * **`fuzziness`**: 我提到的“模糊度”数值。
  * **`notes`**: 记录额外的细节、要求或上下文。
  * **`status`**: 所有新创建的日程，状态默认为 `'计划中'`。

-----

### **一个完整的处理示例**

**输入描述:**

> wings 面试准备，内容是slide页数5页top 8min。 8.27才会通知具体的面试时间，我希望8.20开始准备。importance 4.2 模糊程度 3.5。

**你的预期输出:**


INSERT INTO Schedules (name, status, linked_quest_id, linked_objective_internal_id, start_time, end_time, attribute, notes)
VALUES (
    'WINGS 面试准备',
    '计划中',
    NULL,
    NULL,
    '{
        "personal_start_date": "2025-08-20",
        "condition": "具体的面试时间待 2025-08-27 通知"
    }',
    NULL,
    '{
        "importance": 4.2,
        "fuzziness": 3.5
    }',
    '准备内容：Slide 5页，发表时长控制在8分钟内'
);


-----

### **【在这里填写您的日程描述】**

(请将您用自然语言描述的日程粘贴到这里，每一项日程可以用数字、项目符号或空行隔开)

1.  ...
2.  ...
3.  ...
```

#### 后续通用的自然语言转数据
    * **思路：** 为了高效、批量地将您的个人目标和作息转换为结构化数据，需要设计一个AI指令。此指令应能理解您的自然语言描述，并输出可直接用于数据库的格式（如SQL `INSERT` 语句）。
    * **示例指令框架：**
        > “你是一个数据库助理。我会用自然语言描述我的主线任务(Quests)、具体目标(Objectives)和日常作息(Routines)。请根据我提供的表结构（[在此处粘贴`Quests`, `Objectives`, `Routines`表的CREATE TABLE语句]），将我的描述转换成对应的SQL INSERT语句。
        >
        > 我的描述如下：
        > [例如：我有一个主线任务叫'硕士阶段的科研与学习'。这个主线下，我本周有一个具体目标是'完成数据分析方法文献的梳理'，计划在8月12日上午9点到11点进行。另外，我有一个每天都要执行的作息提醒，在早上8点提醒我'活动身体，晒太阳'。]”
## 流程图生成 (Flowchart Generation)

### 指令：生成系统数据流图
请为我生成一个Mermaid时序图，描述以下流程：
[这里粘贴你的流程需求]
示例：
<!-- 用户在手机App上手动输入情绪和精力。

手机App将这些信息打包成JSON，写入Supabase的input表。

电脑上的Python脚本监听到input表的变化。

脚本读取新数据，进行分析，并将结果（如推荐活动）写入Supabase的output表。

手机App监听到output表的变化，读取结果并展示给用户。 -->


### 记录当前开发进度
你好！在进行下一步开发之前，我想要拜托你基于之前所做的事情，生成（或更新）今天的开发记录（CHANGELOG），以及README里的程序框架描述（## 项目结构和## 核心文件和文件夹详细说明）。请你阅读脚本里的对应内容，并把更新后的内容发给我，我会复制到md文件的对应位置。