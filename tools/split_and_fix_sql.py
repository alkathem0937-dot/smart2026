import re
from pathlib import Path
p = Path('D:/smartjudi2-1/pg_from_new_dump_utf8.sql')
schema_out = Path('D:/smartjudi2-1/pg_schema.sql')
data_out = Path('D:/smartjudi2-1/pg_data.sql')
if not p.exists():
    print('INPUT_MISSING', p)
    raise SystemExit(1)
lines = p.read_text(encoding='utf-8', errors='ignore').splitlines()
schema_lines = []
data_lines = []
for line in lines:
    s = line.strip()
    if not s:
        continue
    up = s.upper()
    if up.startswith('CREATE TABLE') or up.startswith('CREATE INDEX') or up.startswith('ALTER TABLE') or up.startswith('DROP TABLE') or up.startswith('DELETE FROM "SQLITE_SEQUENCE"') or up.startswith('CREATE SEQUENCE'):
        schema_lines.append(line)
    elif up.startswith('INSERT INTO'):
        data_lines.append(line)
    else:
        # include other DDL like PRAGMA? skip PRAGMA
        if up.startswith('PRAGMA') or up in ('BEGIN TRANSACTION;','COMMIT;','END;'):
            continue
        # default to schema
        schema_lines.append(line)

schema_text = '\n'.join(schema_lines)
# fixes
schema_text = schema_text.replace(' datetime ', ' timestamp ')
schema_text = schema_text.replace(' integer unsigned ', ' integer ')
# remove JSON_VALID checks (simple approach)
schema_text = re.sub(r'CHECK\s*\([^)]*JSON_VALID\([^)]*\)[^)]*\)', '', schema_text, flags=re.IGNORECASE)
# remove sqlite-specific ''AUTOINCREMENT'' remnants
schema_text = schema_text.replace('AUTOINCREMENT', '')

data_text = '\n'.join(data_lines)

schema_out.write_text(schema_text, encoding='utf-8')
data_out.write_text(data_text, encoding='utf-8')
print('WROTE', schema_out, len(schema_text), 'bytes; and', data_out, len(data_text), 'bytes')
