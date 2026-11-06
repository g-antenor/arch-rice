#!/usr/bin/env python3
"""Static checks without importing installers or modifying user configuration."""
import ast
import json
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET


def main():
    root = Path(__file__).resolve().parents[1]
    errors = []
    count = 0
    lua = shutil.which('luac') or shutil.which('luac5.4')
    for path in sorted(root.rglob('*')):
        if any(part in {'.git', '__pycache__', '.venv', 'venv'} for part in path.relative_to(root).parts):
            continue
        if path.is_symlink():
            if not path.exists():
                errors.append(f'{path.relative_to(root)}: broken symlink')
            elif not path.resolve().is_relative_to(root):
                errors.append(f'{path.relative_to(root)}: symlink leaves project')
            continue
        if not path.is_file():
            continue
        try:
            suffix = path.suffix
            if suffix == '.py':
                ast.parse(path.read_text(), filename=str(path))
            elif suffix == '.json':
                json.loads(path.read_text())
            elif suffix == '.svg':
                ET.parse(path)
            elif suffix == '.lua' and lua:
                subprocess.run([lua, '-p', str(path)], check=True, capture_output=True, text=True)
            elif suffix == '.sh' or path.name in {'app-run', 'dark-mountain'}:
                subprocess.run(['bash', '-n', str(path)], check=True, capture_output=True, text=True)
            else:
                continue
            count += 1
        except (SyntaxError, ValueError, ET.ParseError, OSError, subprocess.CalledProcessError) as exc:
            errors.append(f'{path.relative_to(root)}: {getattr(exc, "stderr", None) or exc}')
    if not lua:
        print('Lua syntax skipped: install luac to enable it.')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'OK: {count} files validated; local symlinks checked.')


if __name__ == '__main__':
    main()
