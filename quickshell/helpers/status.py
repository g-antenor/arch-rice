#!/usr/bin/env python3
"""Read local link/address state and known active screen recorder processes."""
import json
import os
from pathlib import Path
import subprocess
network = {'connected': False, 'interface': '', 'address': '', 'wireless': False}
try:
    routes = json.loads(subprocess.check_output(['ip', '-j', 'route', 'show', 'default'], timeout=1))
    routes += json.loads(subprocess.check_output(['ip', '-j', '-6', 'route', 'show', 'default'], timeout=1))
    for route in routes:
        interface = route.get('dev', '')
        if not interface or interface == 'lo': continue
        base = Path('/sys/class/net') / interface
        if (base/'operstate').read_text().strip() not in ('up', 'unknown'): continue
        addresses = json.loads(subprocess.check_output(['ip', '-j', 'address', 'show', 'dev', interface], timeout=1))
        ips = [a['local'] for link in addresses for a in link.get('addr_info', []) if a.get('scope') == 'global']
        network = {'connected': bool(ips), 'interface': interface, 'address': ips[0] if ips else '', 'wireless': (base/'wireless').exists()}
        break
except (OSError, subprocess.SubprocessError, ValueError): pass
recording = False
for proc in Path('/proc').iterdir():
    if not proc.name.isdigit(): continue
    try:
        if proc.stat().st_uid != os.getuid(): continue
        args = (proc/'cmdline').read_bytes().split(b'\0')
        executable = Path(args[0].decode()).name
        # OBS being open does not mean it is recording. OBS integrations use IPC.
        if executable in ('wf-recorder', 'wl-screenrec', 'gpu-screen-recorder') and (proc/'stat').read_text().split(') ')[1][0] != 'Z':
            recording = True
            break
    except (OSError, ValueError, IndexError): continue
print(json.dumps({'network': network, 'recording': recording}))
