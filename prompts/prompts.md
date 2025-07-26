# LAE项目 AI指令库

## 代码生成 (Code Generation)

### 指令：根据schema创建新表的访问函数
这是我的数据库结构，定义在 database/schema.sql 文件中：
[在这里粘贴你的schema.sql内容]

请为 user_manual_inputs 表编写一个Python函数，名为 add_manual_input，它接收一个包含状态信息的字典作为参数，并将其插入到数据库中。请使用supabase-py库。


## 文档生成 (Documentation)

### 指令：为Python函数生成Docstring
这是我写的一个Python函数，请遵循Google风格，为它生成清晰、完整的Docstring，包括对参数、返回值和可能引发的异常的说明。

[在这里粘贴你的Python函数代码]


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