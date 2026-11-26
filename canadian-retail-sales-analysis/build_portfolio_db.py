from pathlib import Path
import sqlite3
import pandas as pd

project_root = Path(__file__).resolve().parent
processed_dir = project_root / "data" / "processed"
schema_path = project_root / "sql" / "schema.sql"
database_path = processed_dir / "retail_portfolio.sqlite"

tables = [
    "dim_date",
    "dim_province",
    "dim_category",
    "fact_retail_sales",
    "fact_province_total",
]

with sqlite3.connect(database_path) as connection:
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(schema_path.read_text(encoding="utf-8"))

    for table in tables:
        csv_path = processed_dir / f"{table}.csv"
        df = pd.read_csv(csv_path, encoding="utf-8-sig")
        df.to_sql(table, connection, if_exists="append", index=False)
        print(f"{table}: loaded {len(df)} rows")

    violations = connection.execute("PRAGMA foreign_key_check").fetchall()
    print(f"Foreign-key violations: {len(violations)}")
    print(f"Database created: {database_path}")