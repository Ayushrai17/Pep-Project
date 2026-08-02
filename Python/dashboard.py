"""
Root Dashboard Entrypoint Shortcut: dashboard.py
Delegates execution to Python/dashboard.py.
"""
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "Python"))
from Python.dashboard import render_cli_dashboard, render_streamlit_dashboard

if __name__ == "__main__":
    if "streamlit" in sys.modules:
        render_streamlit_dashboard()
    else:
        render_cli_dashboard()
