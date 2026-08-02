"""
Root Entrypoint Shortcut: main.py
Delegates execution to Python/main.py.
"""
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "Python"))
from Python.main import main

if __name__ == "__main__":
    main()
