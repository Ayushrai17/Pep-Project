import os
import sys
import mysql.connector

DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "Ayush@8287",
    "raise_on_warnings": False,
    "autocommit": True
}

SQL_DIR = os.path.join(os.path.dirname(__file__), "SQL")
SQL_FILES = [
    os.path.join(SQL_DIR, "database.sql"),
    os.path.join(SQL_DIR, "tables.sql"),
    os.path.join(SQL_DIR, "insert_data.sql"),
    os.path.join(SQL_DIR, "views.sql"),
    os.path.join(SQL_DIR, "procedures.sql"),
    os.path.join(SQL_DIR, "triggers.sql"),
    os.path.join(SQL_DIR, "queries.sql"),
    os.path.join(SQL_DIR, "window_functions.sql")
]

def execute_sql_file(file_path, conn):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    cursor = conn.cursor()
    
    # Handle DELIMITER blocks
    delimiter = ';'
    statements = []
    current_stmt = []
    
    for line in content.splitlines():
        stripped = line.strip()
        if stripped.upper().startswith('DELIMITER'):
            parts = stripped.split()
            if len(parts) > 1:
                delimiter = parts[1]
            continue
        
        if stripped.endswith(delimiter):
            # remove trailing delimiter
            line_no_delim = line[:line.rfind(delimiter)]
            current_stmt.append(line_no_delim)
            stmt_text = '\n'.join(current_stmt).strip()
            if stmt_text:
                statements.append(stmt_text)
            current_stmt = []
        else:
            current_stmt.append(line)
            
    if current_stmt:
        stmt_text = '\n'.join(current_stmt).strip()
        if stmt_text:
            statements.append(stmt_text)

    for idx, stmt in enumerate(statements):
        # Filter out empty statements or pure comment blocks
        lines = [l for l in stmt.splitlines() if l.strip() and not l.strip().startswith('--') and not l.strip().startswith('/*')]
        if not lines:
            continue
        exec_stmt = '\n'.join(lines)
        try:
            cursor.execute(exec_stmt)
            # Consume results if any (for SELECT queries)
            while cursor.nextset():
                pass
        except mysql.connector.Error as err:
            print(f"ERROR in {file_path} at statement {idx+1}:\n{exec_stmt[:200]}...\n--> {err}")
            cursor.close()
            return False, err
            
    cursor.close()
    return True, None

def main():
    sql_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "SQL")
    print(f"Connecting to MySQL server...")
    conn = mysql.connector.connect(**DB_CONFIG)
    
    for sql_file in SQL_FILES:
        file_path = os.path.join(sql_dir, sql_file)
        print(f"Executing {sql_file}...")
        success, err = execute_sql_file(file_path, conn)
        if not success:
            print(f"FAILED on {sql_file}")
            sys.exit(1)
        print(f"SUCCESS: {sql_file}")
        
    conn.close()
    print("ALL SQL SCRIPTS EXECUTED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
