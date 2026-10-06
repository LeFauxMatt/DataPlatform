"""Print up to five rows from each table dbt's --store-failures wrote (schema dbt_test__audit), so a failing
test in CI shows what failed, not just that it did."""

import os

import duckdb

con = duckdb.connect(os.environ["DUCKDB_PATH"], read_only=True)
tables = con.sql(
    "select table_name from information_schema.tables where table_schema = 'dbt_test__audit' order by 1"
).fetchall()
for (table,) in tables:
    rows = con.sql(f'select * from dbt_test__audit."{table}"')
    if (count := con.sql(f'select count(*) from dbt_test__audit."{table}"').fetchone()[0]):
        print(f"== {table}: {count} row(s)")
        print(rows.limit(5))
