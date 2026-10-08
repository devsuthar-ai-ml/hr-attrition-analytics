"""Run every query in sql/analysis_queries.sql and print the result tables.

Usage (project root):  python scripts/run_queries.py
"""
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
sql = (ROOT / "sql" / "analysis_queries.sql").read_text()
queries = [q.strip() for q in sql.split(";") if "SELECT" in q or "WITH" in q]

with sqlite3.connect(ROOT / "data" / "hr.db") as con:
    for q in queries:
        title = next(l for l in q.splitlines() if l.startswith("-- Q"))
        print("\n" + title)
        print(pd.read_sql_query(q, con).to_string(index=False))
