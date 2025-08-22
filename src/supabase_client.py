# src/supabase_client.py

"""
Supabase客户端模块

负责处理本地Python环境与Supabase数据库之间的所有通信。
核心功能是实现本地SQLite数据库到云端Supabase的单向数据同步。
"""

# 1. 导入必要的库
import os
import sqlite3
import json
from supabase import create_client, Client

# --- 初始化与连接 ---

print("LAE 核心引擎启动...")

# 2. 配置 Supabase 连接
SUPABASE_URL = "https://vwryhiqjlclhkhczpyza.supabase.co"
# 强烈建议使用环境变量来存储密钥，而不是直接写在代码里。
# 为了安全，请在实际部署时替换为环境变量。
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3cnloaXFqbGNsaGtoY3pweXphIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTE3NDU1OSwiZXhwIjoyMDY2NzUwNTU5fQ.eaum2sXRrjfA-gAub9EcW_8vmnDXmiCljoxwKEhrnw4")

try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("Supabase 连接成功。")
except Exception as e:
    print(f"Supabase 连接失败: {e}")
    exit()

# 3. 配置本地数据库路径
# 使用相对路径定位到项目根目录下的 database 文件夹
DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'database', 'data_base.db')

def get_local_db_connection():
    """建立并返回一个到本地SQLite数据库的连接。"""
    try:
        conn = sqlite3.connect(DB_PATH)
        # 设置 row_factory 以便将查询结果作为字典访问
        conn.row_factory = sqlite3.Row
        print(f"本地数据库连接成功: {DB_PATH}")
        return conn
    except sqlite3.Error as e:
        print(f"本地数据库连接失败: {e}")
        return None

def sync_table(local_table_name: str, supabase_table_name: str, conn: sqlite3.Connection, supabase_client: Client):
    """
    通用的数据同步函数，将本地表数据同步到Supabase。
    策略：先清空云端表，再插入本地所有数据。
    """
    print(f"--- 开始同步表: {local_table_name} -> {supabase_table_name} ---")
    cursor = conn.cursor()
    
    try:
        # 1. 从本地数据库读取数据
        cursor.execute(f"SELECT * FROM {local_table_name}")
        rows = cursor.fetchall()
        
        if not rows:
            print(f"本地表 {local_table_name} 为空，跳过同步。")
            # 仍然清空云端表以保持一致
            supabase_client.table(supabase_table_name).delete().neq('id', -1).execute()
            print(f"已清空云端表: {supabase_table_name}")
            return

        # 将 sqlite3.Row 对象转换为标准字典列表
        # 同时处理JSON字符串，将其转换为Python对象
        data_to_insert = []
        for row in rows:
            row_dict = dict(row)
            for key, value in row_dict.items():
                # 检查是否为JSON字符串
                if isinstance(value, str) and value.strip().startswith(('[', '{')):
                    try:
                        row_dict[key] = json.loads(value)
                    except json.JSONDecodeError:
                        # 如果解析失败，则保持原样
                        pass
            data_to_insert.append(row_dict)

        print(f"从本地表 {local_table_name} 读取了 {len(data_to_insert)} 条记录。")

        # 2. 清空Supabase云端对应的表
        # 使用 neq('id', -1) 作为删除所有行的安全方式
        print(f"正在清空云端表: {supabase_table_name}...")
        delete_response = supabase_client.table(supabase_table_name).delete().neq('id', -1).execute()
        if delete_response.data:
            print(f"成功清空 {len(delete_response.data)} 条记录。")
        else:
            print(f"云端表 {supabase_table_name} 已为空或清空失败。")

        # 3. 将本地数据插入到Supabase
        print(f"正在向云端表 {supabase_table_name} 插入数据...")
        insert_response = supabase_client.table(supabase_table_name).insert(data_to_insert).execute()

        if len(insert_response.data) == len(data_to_insert):
            print(f"成功向 {supabase_table_name} 插入 {len(insert_response.data)} 条记录。")
        else:
            print(f"警告: 插入记录数与预期不符。预期: {len(data_to_insert)}, 实际: {len(insert_response.data)}")
            # print("插入错误详情:", insert_response.error)

    except sqlite3.Error as e:
        print(f"同步表 {local_table_name} 时发生数据库错误: {e}")
    except Exception as e:
        print(f"同步表 {local_table_name} 时发生未知错误: {e}")
    finally:
        print(f"--- 表 {local_table_name} -> {supabase_table_name} 同步完成 ---\n")


def main_sync():
    """执行所有表的同步任务。"""
    local_conn = get_local_db_connection()
    if not local_conn:
        return

    # 定义需要同步的表名映射关系
    # key: 本地SQLite表名 (大小写敏感)
    # value: 云端Supabase表名 (通常为小写)
    tables_to_sync = {
        "Quests": "quests",
        "Schedules": "schedules",
        "Routine_Plan": "routine_plan", # 移到 Reminders 之前
        "Reminders": "reminders"
    }

    try:
        for local_table, supabase_table in tables_to_sync.items():
            sync_table(local_table, supabase_table, local_conn, supabase)
        
        print("所有指定表的同步任务已执行。")

    finally:
        local_conn.close()
        print("本地数据库连接已关闭。")
        print("LAE 核心引擎本次同步任务完成。")

# --- 主程序入口 ---
if __name__ == "__main__":
    main_sync()
