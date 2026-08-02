"""
Database Connection & DAO Layer: db.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Description: Modular Python database connector utilizing mysql-connector-python with 
connection pooling/reconnect logic, robust error handling, parameterized execution, 
and reusable query/fetch utility functions.
"""

import logging
import mysql.connector
from mysql.connector import Error, errorcode

# Configure module logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

import os

# Default Database Configuration (Supports environment variables for cloud deployment)
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "Ayush@8287"),
    "database": os.getenv("DB_NAME", "freelance_management"),
    "raise_on_warnings": False,
    "autocommit": False,
    "connect_timeout": 10
}

_connection = None


def get_connection(config=None):
    """
    Establishes or retrieves an active connection to the MySQL database.
    Includes automatic reconnect logic if the connection is dropped or stale.
    
    :param config: Optional dictionary overriding default DB_CONFIG parameters.
    :return: Active MySQLConnection object or None if connection fails.
    """
    global _connection
    connection_config = config if config else DB_CONFIG

    try:
        if _connection is None or not _connection.is_connected():
            logger.info("Initializing new connection to MySQL database '%s'...", connection_config.get("database"))
            _connection = mysql.connector.connect(**connection_config)
            logger.info("Database connection successfully established.")
        else:
            # Ping connection to verify active state; reconnect if dropped
            _connection.ping(reconnect=True, attempts=3, delay=2)
            
        return _connection

    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            logger.error("Authentication Error: Invalid username or password.")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            logger.error("Database Error: Target database '%s' does not exist.", connection_config.get("database"))
        else:
            logger.error("MySQL Connection Error [%d]: %s", err.errno, err.msg)
        return None


def execute_query(query, params=None, commit=True, config=None):
    """
    Executes a Data Manipulation (INSERT, UPDATE, DELETE) or DDL query safely 
    using parameterized binding to prevent SQL injection vulnerabilities.
    
    :param query: SQL query string containing parameter placeholders (%s).
    :param params: Tuple or list of parameter values to bind.
    :param commit: Boolean indicating whether to commit the transaction (Default: True).
    :param config: Optional DB configuration overrides.
    :return: Dictionary containing 'lastrowid' and 'rowcount', or None if execution failed.
    """
    conn = get_connection(config)
    if conn is None:
        logger.error("Query Execution Aborted: Unable to establish database connection.")
        return None

    cursor = None
    try:
        cursor = conn.cursor()
        logger.debug("Executing Query: %s | Params: %s", query, params)
        
        cursor.execute(query, params or ())
        
        result = {
            "lastrowid": cursor.lastrowid,
            "rowcount": cursor.rowcount
        }

        if commit:
            conn.commit()
            logger.debug("Transaction committed successfully. Affected rows: %d", cursor.rowcount)

        return result

    except Error as err:
        if commit and conn.is_connected():
            conn.rollback()
            logger.warning("Transaction rolled back due to error.")
        logger.error("Database Query Execution Error [%d]: %s", err.errno, err.msg)
        return None

    finally:
        if cursor:
            cursor.close()


def fetch_data(query, params=None, fetch_one=False, dictionary=True, config=None):
    """
    Executes a SELECT query and fetches returned records. Supports dictionary cursors
    for key-value column mapping and parameterized queries.
    
    :param query: SQL SELECT query string containing parameter placeholders (%s).
    :param params: Tuple or list of parameter values to bind.
    :param fetch_one: If True, returns a single record dict; if False, returns a list of record dicts.
    :param dictionary: If True, returns results as dictionaries (column_name: value).
    :param config: Optional DB configuration overrides.
    :return: List of dicts, single dict, or empty list/None on failure.
    """
    conn = get_connection(config)
    if conn is None:
        logger.error("Fetch Aborted: Unable to establish database connection.")
        return None if fetch_one else []

    cursor = None
    try:
        cursor = conn.cursor(dictionary=dictionary)
        logger.debug("Fetching Data: %s | Params: %s", query, params)
        
        cursor.execute(query, params or ())

        if fetch_one:
            record = cursor.fetchone()
            return record
        else:
            records = cursor.fetchall()
            return records

    except Error as err:
        logger.error("Database Fetch Error [%d]: %s", err.errno, err.msg)
        return None if fetch_one else []

    finally:
        if cursor:
            cursor.close()


def close_connection():
    """
    Gracefully closes the active database connection if open.
    """
    global _connection
    if _connection and _connection.is_connected():
        _connection.close()
        _connection = None
        logger.info("Database connection closed gracefully.")


if __name__ == "__main__":
    # Internal Unit Verification & Test Check
    print("Testing db.py module connection handler...")
    test_conn = get_connection()
    if test_conn and test_conn.is_connected():
        print("Success: Connected to MySQL database.")
        db_info = test_conn.get_server_info()
        print(f"MySQL Server Version: {db_info}")
        close_connection()
    else:
        print("Notice: MySQL connection test failed (Verify local MySQL server status & credentials).")
