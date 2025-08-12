import os
import sqlite3
import re
from pathlib import Path

# --- 配置区 ---

# 1. 需要遍历的根目录路径
# 请确保这里的路径是你的 Obsidian 库中对应的实际路径
# 注意：Windows 路径中的反斜杠 \ 需要写成 \\ 或者使用正斜杠 /
ROOT_PATHS = [
    r"C:\OneDrive_Downloads\qiluo\1-学业与未来",
    r"C:\OneDrive_Downloads\qiluo\2-自由学习与探索",
    r"C:\OneDrive_Downloads\qiluo\3-LAE其他"
]

# 2. 数据库文件名 (已更新路径)
DB_FILE = r"database\data_base.db"

# --- 脚本核心逻辑 ---

def setup_database(db_path):
    """
    确保数据库和 Quests 表存在。
    如果表已存在，则不会重复创建或清空。
    """
    print(f"正在连接数据库: {db_path}...")
    # 确保数据库所在的目录存在
    db_dir = os.path.dirname(db_path)
    if db_dir and not os.path.exists(db_dir):
        print(f"数据库目录不存在，正在创建: {db_dir}")
        os.makedirs(db_dir)
        
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Quests 表的创建语句
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS Quests (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        display_id      TEXT UNIQUE, -- display_id 应该是唯一的，方便查询
        name            TEXT NOT NULL,
        parent_id       INTEGER,
        status          TEXT NOT NULL DEFAULT '进行中',
        objectives      TEXT,
        target_rules    TEXT,
        description     TEXT,
        created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
        LAE_id          INTEGER,
        FOREIGN KEY (parent_id) REFERENCES Quests(id)
    );
    """
    
    cursor.execute(create_table_sql)
    
    # 为 display_id 创建索引以提高查询效率
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_display_id ON Quests (display_id);")
    
    conn.commit()
    conn.close()
    print("数据库连接和表结构检查完成。")

def parse_lae_id(md_path):
    """
    解析指定的 .md 文件，查找并提取 LAE_id。
    """
    if not os.path.exists(md_path):
        return None

    try:
        with open(md_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  [警告] 无法读取文件 {md_path}: {e}")
        return None

    for i, line in enumerate(lines):
        cleaned_line = line.strip()
        if cleaned_line == "# LAE 用":
            if i + 1 < len(lines):
                next_line = lines[i+1].strip()
                match = re.match(r'【id】(\d+)', next_line)
                if match:
                    lae_id = int(match.group(1))
                    # print(f"  [信息] 在 {os.path.basename(md_path)} 中找到 LAE_id: {lae_id}")
                    return lae_id
    return None

def traverse_and_insert(cursor, current_path, parent_id, display_id_prefix):
    """
    递归遍历目录，识别并以“更新”模式插入 Quest。
    """
    print(f"正在处理目录: {current_path}")
    
    try:
        entries = os.listdir(current_path)
    except FileNotFoundError:
        print(f"[错误] 目录不存在: {current_path}。请检查 ROOT_PATHS 配置。")
        return
    except PermissionError:
        print(f"[错误] 没有权限访问目录: {current_path}。")
        return

    quest_basenames = set()
    for entry in entries:
        base, ext = os.path.splitext(entry)
        if ext.lower() == '.md' or os.path.isdir(os.path.join(current_path, entry)):
            quest_basenames.add(base)
            
    sorted_quests = sorted(list(quest_basenames))
    
    for i, basename in enumerate(sorted_quests):
        name = basename
        current_display_id = f"{display_id_prefix}{i + 1}"
        
        dir_path = os.path.join(current_path, basename)
        md_path = os.path.join(current_path, basename + ".md")
        
        is_directory = os.path.isdir(dir_path)
        has_md_file = os.path.exists(md_path)
        
        # 检查 display_id 是否已存在
        cursor.execute("SELECT id FROM Quests WHERE display_id = ?", (current_display_id,))
        existing_quest = cursor.fetchone()
        
        quest_id = None
        if existing_quest:
            quest_id = existing_quest[0]
            print(f"  [跳过] Quest '{name}' (display_id: {current_display_id}) 已存在，ID为 {quest_id}。")
        else:
            # 提取 LAE_id (仅对新 Quest)
            lae_id = None
            if has_md_file:
                lae_id = parse_lae_id(md_path)

            # 插入新 Quest
            print(f"  [新增] Quest: name='{name}', display_id='{current_display_id}', parent_id={parent_id}")
            cursor.execute("""
                INSERT INTO Quests (display_id, name, parent_id, LAE_id)
                VALUES (?, ?, ?, ?)
            """, (current_display_id, name, parent_id, lae_id))
            
            quest_id = cursor.lastrowid

        # 如果是目录，则无论新旧都递归进入，以检查其子任务
        if is_directory:
            traverse_and_insert(cursor, dir_path, quest_id, f"{current_display_id}.")

def main():
    """
    主函数，执行整个流程
    """
    print("--- 开始同步 Quest 数据库 ---")
    
    valid_paths = []
    for path in ROOT_PATHS:
        if not os.path.exists(path):
            print(f"[警告] 配置的路径不存在，将跳过: {path}")
        else:
            valid_paths.append(path)
    
    if not valid_paths:
        print("[错误] 所有配置的根路径都无效，脚本终止。")
        return

    # 初始化数据库
    setup_database(DB_FILE)
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    try:
        # 遍历每个根路径
        for i, path in enumerate(valid_paths):
            # 根目录下的 Quest 没有 parent_id
            # 使用 i + 1 作为根 display_id 前缀
            traverse_and_insert(cursor, path, None, f"{i+1}")
    except Exception as e:
        print(f"\n[严重错误] 处理过程中发生异常: {e}")
        conn.rollback()
    else:
        print("\n所有路径处理完毕，正在提交更改...")
        conn.commit()
    finally:
        conn.close()

    print(f"--- 脚本执行完毕 ---")
    print(f"数据库已同步: {os.path.abspath(DB_FILE)}")

if __name__ == "__main__":
    main()
