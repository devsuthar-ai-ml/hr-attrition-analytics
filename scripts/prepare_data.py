"""Clean the raw HR workbook and build a SQLite database.

Run from the project root:  python scripts/prepare_data.py
"""
import re
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "HR_Data_raw.xlsx"
CLEAN = ROOT / "data" / "hr_attrition_clean.csv"
DB = ROOT / "data" / "hr.db"

df = pd.read_excel(RAW)

# 1. Drop columns that carry no information or are spreadsheet helper columns
constant_cols = [c for c in df.columns if df[c].nunique() == 1]   # Over18, Employee Count, Standard Hours, -2, 0
helper_cols = ["CF_age band", "CF_attrition label", "CF_current Employee", "emp no"]
df = df.drop(columns=constant_cols + helper_cols)

# 2. snake_case column names
df.columns = [re.sub(r"[^0-9a-z]+", "_", c.lower()).strip("_") for c in df.columns]
df = df.rename(columns={"employee_number": "employee_id"})

# 3. Sanity checks
assert df.employee_id.is_unique and df.isna().sum().sum() == 0
assert len(df) == 1470 and (df.attrition == "Yes").sum() == 237

df.to_csv(CLEAN, index=False)

# 4. SQLite database
if DB.exists():
    DB.unlink()
with sqlite3.connect(DB) as con:
    df.to_sql("employees", con, index=False)
    con.execute("CREATE INDEX idx_attr ON employees(attrition)")

print(f"dropped: {constant_cols + helper_cols}")
print(f"clean rows={len(df)}, cols={df.shape[1]} -> {CLEAN.name}, {DB.name}")
