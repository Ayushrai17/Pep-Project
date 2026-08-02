"""
Database Connection & DAO Layer: db.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Description: Modular Python database connector utilizing mysql-connector-python with 
connection pooling/reconnect logic, robust error handling, parameterized execution, 
and reusable query/fetch utility functions. Includes SQLite in-memory fallback for cloud demos.
"""

import os
import re
import logging
import sqlite3
import mysql.connector
from mysql.connector import Error, errorcode

# Configure module logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Default Database Configuration (Supports environment variables for cloud deployment)
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "Ayush@8287"),
    "database": os.getenv("DB_NAME", "freelance_management"),
    "raise_on_warnings": False,
    "autocommit": False,
    "connect_timeout": 5
}

_connection = None
_sqlite_conn = None


def get_sqlite_fallback():
    """Initializes in-memory SQLite database populated with seed dataset for cloud demos."""
    global _sqlite_conn
    if _sqlite_conn is None:
        try:
            logger.info("Initializing in-memory SQLite database fallback for cloud environment...")
            _sqlite_conn = sqlite3.connect(":memory:", check_same_thread=False)
            _sqlite_conn.row_factory = sqlite3.Row
            
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            tables_path = os.path.join(base_dir, "SQL", "tables.sql")
            insert_path = os.path.join(base_dir, "SQL", "insert_data.sql")
            
            def adapt_sql(sql_str):
                sql_str = re.sub(r'USE\s+\w+;', '', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'BIGINT\s+AUTO_INCREMENT', 'INTEGER', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'INT\s+AUTO_INCREMENT', 'INTEGER', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'AUTO_INCREMENT', '', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'ENGINE\s*=\s*\w+', '', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'DEFAULT\s+CHARSET\s*=\s*\w+', '', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'CHAR\(\d+\)', 'TEXT', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'VARCHAR\(\d+\)', 'TEXT', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'DECIMAL\(\d+,\s*\d+\)', 'REAL', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'TIMESTAMP\s+DEFAULT\s+CURRENT_TIMESTAMP\s+ON\s+UPDATE\s+CURRENT_TIMESTAMP', 'DATETIME DEFAULT CURRENT_TIMESTAMP', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'TIMESTAMP', 'DATETIME', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'INSERT\s+IGNORE\s+INTO', 'INSERT OR IGNORE INTO', sql_str, flags=re.IGNORECASE)
                sql_str = re.sub(r'INSERT\s+INTO', 'INSERT OR IGNORE INTO', sql_str, flags=re.IGNORECASE)
                return sql_str

            if os.path.exists(tables_path):
                with open(tables_path, "r", encoding="utf-8") as f:
                    _sqlite_conn.executescript(adapt_sql(f.read()))
            
            if os.path.exists(insert_path):
                with open(insert_path, "r", encoding="utf-8") as f:
                    _sqlite_conn.executescript(adapt_sql(f.read()))
                    
            logger.info("SQLite fallback database successfully initialized and seeded.")
        except Exception as e:
            logger.error("Failed to initialize SQLite fallback database: %s", e)
    return _sqlite_conn


def get_connection(config=None):
    """
    Establishes or retrieves an active connection to the MySQL database.
    Includes automatic reconnect logic if the connection is dropped or stale.
    """
    global _connection
    connection_config = config if config else DB_CONFIG

    try:
        if _connection is None or not _connection.is_connected():
            logger.info("Initializing new connection to MySQL database '%s'...", connection_config.get("database"))
            _connection = mysql.connector.connect(**connection_config)
            logger.info("Database connection successfully established.")
        else:
            _connection.ping(reconnect=True, attempts=2, delay=1)
            
        return _connection

    except Exception as err:
        logger.warning("MySQL Connection Unavailable: %s. Engaging fallback engine.", err)
        return None


def execute_query(query, params=None, commit=True, config=None):
    """
    Executes a Data Manipulation (INSERT, UPDATE, DELETE) or DDL query safely 
    using parameterized binding to prevent SQL injection vulnerabilities.
    """
    conn = get_connection(config)
    if conn is not None:
        cursor = None
        try:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            result = {
                "lastrowid": cursor.lastrowid,
                "rowcount": cursor.rowcount
            }
            if commit:
                conn.commit()
            return result
        except Error as err:
            if commit and conn.is_connected():
                conn.rollback()
            logger.error("MySQL Query Error: %s", err)
            return None
        finally:
            if cursor:
                cursor.close()
    else:
        # Fallback to SQLite
        s_conn = get_sqlite_fallback()
        if s_conn:
            try:
                sql_query = query.replace("%s", "?")
                sql_query = re.sub(r'INSERT\s+INTO', 'INSERT OR IGNORE INTO', sql_query, flags=re.IGNORECASE)
                cur = s_conn.cursor()
                cur.execute(sql_query, params or ())
                if commit:
                    s_conn.commit()
                return {"lastrowid": cur.lastrowid, "rowcount": cur.rowcount}
            except Exception as err:
                logger.error("SQLite Query Error: %s", err)
                return None
        return None


def fetch_data(query, params=None, fetch_one=False, dictionary=True, config=None):
    """
    Executes a SELECT query and fetches returned records. Supports dictionary cursors
    for key-value column mapping and parameterized queries.
    """
    conn = get_connection(config)
    if conn is not None:
        cursor = None
        try:
            cursor = conn.cursor(dictionary=dictionary)
            cursor.execute(query, params or ())
            if fetch_one:
                return cursor.fetchone()
            else:
                return cursor.fetchall()
        except Error as err:
            logger.error("MySQL Fetch Error: %s", err)
            return None if fetch_one else []
        finally:
            if cursor:
                cursor.close()
    else:
        # Fallback to SQLite
        s_conn = get_sqlite_fallback()
        if s_conn:
            try:
                sql_query = query.replace("%s", "?")
                cur = s_conn.cursor()
                cur.execute(sql_query, params or ())
                if fetch_one:
                    row = cur.fetchone()
                    return dict(row) if row else None
                else:
                    rows = cur.fetchall()
                    return [dict(r) for r in rows]
            except Exception as err:
                logger.error("SQLite Fetch Error: %s", err)
                return None if fetch_one else []
        return None if fetch_one else []


def close_connection():
    global _connection
    if _connection and _connection.is_connected():
        _connection.close()
        _connection = None
        logger.info("Database connection closed gracefully.")
