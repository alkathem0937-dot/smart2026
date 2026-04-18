import os
import re

files = [
    r'lib\screens\legal_library_screen.dart',
    r'lib\screens\archive_screen.dart',
    r'lib\screens\calendar_screen.dart'
]

replacements = {
    '0xFF1A237E': '0xFF1B5E3B', # AppColors.brand
    '0xFF3949AB': '0xFF2D8B57', # AppColors.brandLight
    '0xFFE91E63': '0xFFD4A940', # AppColors.gold
    '0xFFF5F7FA': '0xFFF7F8FA', # AppColors.lightBackground
    '0xFFE8A54B': '0xFFD4A940', # AppColors.gold
    '0xFFFAF6F1': '0xFFF7F8FA', # AppColors.lightBackground
    '0xFF1A1A1A': '0xFF1A2138', # AppColors.lightTextPrimary
}

for file_path in files:
    if not os.path.exists(file_path): 
        print(f"Not found: {file_path}")
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    import_statement = "import 'package:flutter_animate/flutter_animate.dart';\nimport '../theme/app_colors.dart';\nimport '../theme/app_spacing.dart';\nimport '../theme/app_theme.dart';"
    if 'app_colors.dart' not in content:
        content = re.sub(r"(import 'package:flutter/material.dart';)", r"\1\n" + import_statement, content)
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
print("Colors updated successfully")
