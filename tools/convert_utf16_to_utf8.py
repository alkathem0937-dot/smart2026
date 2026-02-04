import sys
from pathlib import Path
inp = Path(r'D:/smartjudi2-1/pg_dump.sql')
out = Path(r'D:/smartjudi2-1/pg_dump_utf8_fixed2.sql')
with inp.open('rb') as f:
    data = f.read()
text = data.decode('utf-16')
with out.open('wb') as f:
    f.write(text.encode('utf-8'))
print('WROTE', out)
