# src/supabase_client.py

"""
Supabase客户端模块

负责处理本地Python环境与Supabase数据库之间的所有通信，
包括数据的读取、写入，以及实时监听（未来实现）。
"""

# 1. 导入必要的库
import os
import time
from datetime import datetime
from supabase import create_client, Client

# --- 初始化与连接 (脚本开始时执行一次) ---

print("LAE 核心引擎启动...")

# 2. 配置 Supabase 连接
# 建议使用环境变量来存储密钥，而不是直接写在代码里。
# 但为了演示方便，我们先直接写在这里。
SUPABASE_URL = "https://vwryhiqjlclhkhczpyza.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3cnloaXFqbGNsaGtoY3pweXphIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTE3NDU1OSwiZXhwIjoyMDY2NzUwNTU5fQ.eaum2sXRrjfA-gAub9EcW_8vmnDXmiCljoxwKEhrnw4" # 替换成你的 service_role Key

try:
    # 3. 创建 Supabase 客户端实例
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("成功连接到 Supabase！")
except Exception as e:
    print(f"连接 Supabase 失败: {e}")
    exit() # 如果连接失败，直接退出程序

# 4. 初始化内存中的状态变量
# 这个字典用于跟踪夜间App使用次数
app_usage_counter = {
    'bilibili': 0,
    'xiaohongshu': 0
}
# 记录上次检查 user_inputs 表的时间戳，避免重复处理
last_checked_timestamp = datetime.utcnow().isoformat()

# --- 核心逻辑循环 (持续运行) ---

def main_loop():
    """
    核心函数，作为程序的入口和主干。

    此函数包含一个无限循环 (while True)，永不停止，除非手动中断。
    循环内主要执行三个任务：
    A. 定时任务检查：根据预设的硬编码时间（如20:00和00:00）执行特定操作。
    B. 用户输入轮询：从 Supabase 的 user_inputs 表中拉取新的用户事件。
    C. 延时等待：在每次循环后暂停，以防止CPU占用过高。

    全局变量:
        last_checked_timestamp (str): 用于增量轮询，记录上次查询的时间点。
        app_usage_counter (dict): 用于在内存中累计特定App的使用次数。
    """
    global last_checked_timestamp, app_usage_counter

    while True:
        current_time_str = datetime.now().strftime('%H:%M')
        current_hour = datetime.now().hour

        # --- A. 定时任务逻辑 ---
        # 1. 检查是否到了20:00，触发自评提醒
        if current_time_str == '20:00':
            print("[定时任务] 20:00到达，触发风险自评提醒...")
            supabase.table('system_outputs').insert({
                "event_type": "SYSTEM_TRIGGER",
                "source": "SYSTEM_PYTHON_ENGINE",
                "action_to_perform": "REQUEST_SELF_ASSESSMENT",
                "content": "现在是晚间八点，请进行风险自评。"
            }).execute()
            time.sleep(61) 

        # 2. 检查是否到了午夜，清零计数器
        if current_time_str == '00:00':
            print("[定时任务] 午夜到达，清零App使用计数器...")
            app_usage_counter = {'bilibili': 0, 'xiaohongshu': 0}
            time.sleep(61)

        # --- B. 轮询处理用户输入 ---
        try:
            # 查询 user_inputs 表中在上次检查之后的新记录
            response = supabase.table('user_inputs').select('*').gt('timestamp', last_checked_timestamp).execute()
            
            if response.data:
                print(f"检测到 {len(response.data)} 条新用户输入...")
                for event in response.data:
                    process_user_event(event, current_hour)
                
                # 更新最后检查的时间戳为最新一条记录的时间戳
                last_checked_timestamp = response.data[-1]['timestamp']

        except Exception as e:
            print(f"查询 user_inputs 出错: {e}")

        # --- C. 循环间隔 ---
        # 每隔10秒检查一次，避免过于频繁地请求数据库
        time.sleep(10)

def process_user_event(event, current_hour):
    """
    事件处理器，根据从 user_inputs 表获取的单条事件记录进行逻辑分发和处理。

    Args:
        event (dict): 从 Supabase `user_inputs` 表中获取的单条事件记录。
                      结构通常包含 'event_type', 'details', 'timestamp' 等字段。
        current_hour (int): 当前的小时数 (0-23)，用于执行与时间相关的判断逻辑，
                            例如判断是否处于夜间时段。

    Returns:
        None: 此函数没有返回值，它的主要作用是根据事件内容产生副作用，
              即将决策结果（如提醒、干预指令）写入到 `system_outputs` 表中。
    """
    event_type = event.get('event_type')
    details = event.get('details', {})

    if event_type == 'STATE_CHECK_IN':
        # 处理用户自评结果
        print(f"[事件处理] 收到用户自评: {details}")
        anxiety = details.get('anxiety_level', 0)
        binge_risk = details.get('binge_eating_risk', 0)
        
        message = "状态良好，继续保持！"
        if anxiety > 3 or binge_risk > 3:
            message = "似乎有些压力，建议进行放松活动，比如听听音乐或进行5分钟冥想。"
        
        # 将反馈插入 system_outputs
        supabase.table('system_outputs').insert({
            "event_type": "INTERVENTION_TRIGGERED",
            "source": "SYSTEM_PYTHON_ENGINE",
            "intervention_type": "REMINDER",
            "content": message
        }).execute()

    elif event_type == 'APP_USAGE_DETECTED':
        # 处理模拟App使用事件
        app_name = details.get('app_name')
        print(f"[事件处理] 收到App使用模拟事件: {app_name}")

        # 判断是否在22:00-24:00 (即 hour 是 22 或 23)
        if app_name in ['bilibili', 'xiaohongshu'] and current_hour in [22, 23]:
            app_usage_counter[app_name] += 1
            count = app_usage_counter[app_name]
            print(f"夜间使用 {app_name}，当前计数: {count}")

            intervention_type = "REMINDER"
            message = f"您已在夜间使用 {app_name} {count} 次，请注意休息哦。"

            if count >= 3:
                intervention_type = "LOCK_SCREEN" # 这是给手机端的指令类型
                message = f"已多次检测到夜间娱乐应用使用 ({app_name})，即将触发锁屏（模拟）。"
            
            # 将干预指令插入 system_outputs
            supabase.table('system_outputs').insert({
                "event_type": "INTERVENTION_TRIGGERED",
                "source": "SYSTEM_PYTHON_ENGINE",
                "intervention_type": intervention_type,
                "content": message
            }).execute()


if __name__ == '__main__':
    """
    脚本的标准启动入口。
    
    它调用 main_loop() 来启动整个程序，并使用 try...except 结构
    来优雅地处理用户通过 Ctrl+C 发出的中断信号。
    """
    try:
        main_loop()
    except KeyboardInterrupt:
        print("\nLAE 核心引擎已手动停止。")
