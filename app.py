"""
FCMS Analytics Web Application Launcher: app.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Developer: Ayush Rai
Description: Root entrypoint shortcut that delegates execution to Python/app.py.
"""
import os
import sys

# Append Python subfolder to sys.path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "Python"))

# Execute the core Streamlit application module
import Python.app
