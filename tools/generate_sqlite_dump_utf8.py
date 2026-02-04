import sqlite3
from pathlib import Path
db = Path('D:/smartjudi2-1/smartju/db.sqlite3')
if not db.exists():
    db = Path('D:/smartjudi2-1/smartju/db.sqlite3')
# try project db location
if not db.exists():
    db = Path('D:/smartjudi2-1/smartju/db.sqlite3')

out = Path('D:/smartjudi2-1/dump_utf8.sql')
conn = sqlite3.connect(str(db))
with out.open('w', encoding='utf-8') as f:
    for line in conn.iterdump():
        f.write(line + '\n')
print('WROTE', out)
