#!/usr/bin/env python3
"""Convert a SQLite .dump SQL file to a PostgreSQL-compatible SQL.

Usage: python tools/sqlite_to_postgres.py dump.sql > pg_dump.sql

This script performs simple, best-effort transformations:
- removes PRAGMA, BEGIN/COMMIT, sqlite_sequence lines
- converts 'INTEGER PRIMARY KEY' to 'SERIAL PRIMARY KEY'
- removes AUTOINCREMENT keywords
- adjusts some SQLite-specific constructs

Note: This is not a perfect converter. Review `pg_dump.sql` before
importing and fix any type differences or constraint issues manually.
"""

import re
import sys


def convert(sql_text: str) -> str:
    out_lines = []
    for line in sql_text.splitlines():
        # skip sqlite pragmas and transactions
        if line.strip().upper().startswith("PRAGMA "):
            continue
        if line.strip().upper() in ("BEGIN TRANSACTION;", "BEGIN;", "COMMIT;", "END;"):
            continue
        if line.strip().startswith("--"):
            # keep comments
            out_lines.append(line)
            continue

        # skip sqlite_sequence handling
        if line.startswith("CREATE TABLE sqlite_sequence") or line.startswith("INSERT INTO \"sqlite_sequence\""):
            continue

        # remove AUTOINCREMENT
        line = line.replace("AUTOINCREMENT", "")

        # convert INTEGER PRIMARY KEY to SERIAL PRIMARY KEY
        # handle cases like: "id" INTEGER PRIMARY KEY,
        line = re.sub(r"\bINTEGER\s+PRIMARY\s+KEY\b", "SERIAL PRIMARY KEY", line, flags=re.IGNORECASE)

        # replace double quoted empty string with NULL default (edge cases)
        # keep as-is otherwise

        # convert "CREATE TABLE x (...) WITHOUT ROWID;" remove WITHOUT ROWID
        line = line.replace("WITHOUT ROWID", "")

        # SQLite uses " to quote identifiers; Postgres accepts this.
        out_lines.append(line)

    return "\n".join(out_lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: sqlite_to_postgres.py dump.sql > pg_dump.sql", file=sys.stderr)
        sys.exit(2)
    path = sys.argv[1]
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        src = f.read()
    converted = convert(src)
    sys.stdout.write(converted)


if __name__ == "__main__":
    main()
