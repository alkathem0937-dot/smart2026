"""
SmartJudi Project Cleanup Script
================================
Safely removes all build artifacts, caches, temp files, and large
generated files while preserving all source code and critical configs.

Usage:
    python scripts/cleanup_project.py          # Dry run (shows what will be deleted)
    python scripts/cleanup_project.py --run    # Actually delete
"""
import os
import sys
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRY_RUN = '--run' not in sys.argv

# ──────────────────────────────────────────────────────────
# 1. Directories to DELETE entirely (safe — all regenerable)
# ──────────────────────────────────────────────────────────
DELETE_DIRS = [
    # Flutter / Android build artifacts
    'build',
    '.dart_tool',
    'android/.gradle',
    'android/.kotlin',
    'android/app/build',

    # Python virtual environments (NOT source code)
    'my_smart',
    'my_smart_new',

    # RAG vector database (regenerable via index command)
    'rag_engine/chroma_db',

    # Django media uploads (user-generated, not source)
    'smartju/media',

    # Django collected static files
    'smartju/staticfiles',
]

# ──────────────────────────────────────────────────────────
# 2. File patterns to DELETE anywhere in project
# ──────────────────────────────────────────────────────────
DELETE_PATTERNS_EXACT = {
    '__pycache__',      # Python bytecode cache dirs
}

DELETE_FILE_EXTENSIONS = {
    '.pyc', '.pyo', '.pyd',      # Python compiled
    '.log',                       # Log files
    '.bak', '.swp', '.swo',      # Editor temp files
    '.DS_Store',                  # macOS junk
}

# ──────────────────────────────────────────────────────────
# 3. Specific files to DELETE (large/unnecessary)
# ──────────────────────────────────────────────────────────
DELETE_FILES = [
    # Local SQLite databases (regenerable via migrate)
    'smartju/db.sqlite3',
    'legal.db',
    'legal_search.db',

    # Large data dumps (keep data.json for loaddata, remove others)
    'smartju/mysite_data.json',

    # SQL files in root that are not needed in repo
    'dbsmart.sql',

    # Dart/Flutter generated
    '.flutter-plugins',
    '.flutter-plugins-dependencies',

    # Old analysis script
    'scripts/_analyze_project.py',
]

# ──────────────────────────────────────────────────────────
# 4. QA_REPORTS — old reports, already captured in docs/
# ──────────────────────────────────────────────────────────
DELETE_DIRS.append('QA_REPORTS')


def fmt_size(n):
    if n > 1024 * 1024:
        return f"{n / 1024 / 1024:.1f} MB"
    if n > 1024:
        return f"{n / 1024:.0f} KB"
    return f"{n} B"


def dir_size(path):
    total = 0
    count = 0
    for dp, _, fns in os.walk(path):
        for f in fns:
            try:
                total += os.path.getsize(os.path.join(dp, f))
                count += 1
            except:
                pass
    return total, count


def main():
    if DRY_RUN:
        print("=" * 60)
        print("  DRY RUN — nothing will be deleted")
        print("  Run with --run to actually delete")
        print("=" * 60)
    else:
        print("=" * 60)
        print("  EXECUTING CLEANUP — files will be PERMANENTLY deleted")
        print("=" * 60)

    total_freed = 0
    total_files_removed = 0

    # --- Phase 1: Delete entire directories ---
    print("\n### Phase 1: Remove build/cache directories ###")
    for rel in DELETE_DIRS:
        full = os.path.join(ROOT, rel)
        if os.path.isdir(full):
            sz, cnt = dir_size(full)
            total_freed += sz
            total_files_removed += cnt
            print(f"  DEL  {fmt_size(sz):>10s}  {cnt:>5d} files  {rel}/")
            if not DRY_RUN:
                shutil.rmtree(full, ignore_errors=True)
        # else: silently skip missing

    # --- Phase 2: Delete __pycache__ everywhere ---
    print("\n### Phase 2: Remove __pycache__ dirs ###")
    pycache_total = 0
    pycache_count = 0
    for dp, dns, _ in os.walk(ROOT):
        if '.git' in dp:
            continue
        for d in list(dns):
            if d in DELETE_PATTERNS_EXACT:
                full = os.path.join(dp, d)
                sz, cnt = dir_size(full)
                pycache_total += sz
                pycache_count += cnt
                if not DRY_RUN:
                    shutil.rmtree(full, ignore_errors=True)
                dns.remove(d)
    print(f"  DEL  {fmt_size(pycache_total):>10s}  {pycache_count:>5d} files  (all __pycache__/ dirs)")
    total_freed += pycache_total
    total_files_removed += pycache_count

    # --- Phase 3: Delete specific files ---
    print("\n### Phase 3: Remove specific large files ###")
    for rel in DELETE_FILES:
        full = os.path.join(ROOT, rel)
        if os.path.isfile(full):
            sz = os.path.getsize(full)
            total_freed += sz
            total_files_removed += 1
            print(f"  DEL  {fmt_size(sz):>10s}          {rel}")
            if not DRY_RUN:
                os.remove(full)

    # --- Phase 4: Delete files by extension ---
    print("\n### Phase 4: Remove temp files by extension ###")
    ext_stats = {}
    for dp, dns, fns in os.walk(ROOT):
        if '.git' in dp:
            continue
        dns[:] = [d for d in dns if d != '.git']
        for f in fns:
            ext = os.path.splitext(f)[1].lower()
            if ext in DELETE_FILE_EXTENSIONS or f in ('.DS_Store', 'Thumbs.db', 'Desktop.ini'):
                full = os.path.join(dp, f)
                try:
                    sz = os.path.getsize(full)
                    total_freed += sz
                    total_files_removed += 1
                    key = ext or f
                    ext_stats[key] = ext_stats.get(key, (0, 0))
                    ext_stats[key] = (ext_stats[key][0] + 1, ext_stats[key][1] + sz)
                    if not DRY_RUN:
                        os.remove(full)
                except:
                    pass
    for ext, (cnt, sz) in sorted(ext_stats.items(), key=lambda x: -x[1][1]):
        print(f"  DEL  {fmt_size(sz):>10s}  {cnt:>5d} files  *{ext}")

    # --- Summary ---
    print("\n" + "=" * 60)
    print(f"  Total freed:   {fmt_size(total_freed)}")
    print(f"  Files removed: {total_files_removed}")
    if DRY_RUN:
        print("\n  This was a DRY RUN. Run with --run to actually delete.")
    else:
        print("\n  Cleanup complete!")
    print("=" * 60)


if __name__ == '__main__':
    main()
