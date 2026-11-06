#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
state = Path(os.environ.get('XDG_STATE_HOME', Path.home()/'.local/state'))/'dark-mountain'
backup = Path(sys.argv[1]) if len(sys.argv) > 1 else Path((state/'latest-backup').read_text().strip())
manifest = json.loads((backup/'manifest.json').read_text())
launcher = Path.home()/'.local/bin/dark-mountain'
if launcher.exists(): subprocess.run([str(launcher), 'stop'], check=False)
for entry in manifest:
    target = Path(entry['path'])
    if target.is_symlink() or target.is_file(): target.unlink()
    elif target.is_dir(): shutil.rmtree(target)
    if entry['saved'] is not None:
        source = backup/entry['saved']
        if source.is_symlink(): target.symlink_to(os.readlink(source))
        elif source.is_dir(): shutil.copytree(source, target, symlinks=True)
        else: shutil.copy2(source, target)
print('Configurações restauradas de', backup)
print('Execute hyprctl reload na sessão gráfica.')
