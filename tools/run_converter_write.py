import subprocess, sys
inp = r'D:/smartjudi2-1/dump_utf8.sql'
out = r'D:/smartjudi2-1/pg_from_new_dump_utf8.sql'
res = subprocess.run([sys.executable, 'D:/smartjudi2-1/tools/sqlite_to_postgres.py', inp], stdout=subprocess.PIPE)
open(out,'wb').write(res.stdout)
print('WROTE', out, len(res.stdout))
