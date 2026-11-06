#!/usr/bin/env python3
"""Optional rootless runtime from packages verified against pacman's sync DB."""
import concurrent.futures
import hashlib
from pathlib import Path
import subprocess
import tarfile
import urllib.request

home = Path.home()
cache = home/'.cache/dark-mountain/packages'
runtime = home/'.local/lib/dark-mountain/runtime'
cache.mkdir(parents=True, exist_ok=True)
runtime.mkdir(parents=True, exist_ok=True)
checks = {}
for db in Path('/var/lib/pacman/sync').glob('*.db'):
    with tarfile.open(db) as archive:
        for member in archive:
            if member.name.endswith('/desc'):
                lines = archive.extractfile(member).read().decode().splitlines()
                if '%FILENAME%' in lines and '%SHA256SUM%' in lines:
                    checks[lines[lines.index('%FILENAME%')+1]] = lines[lines.index('%SHA256SUM%')+1]
urls = subprocess.check_output(['pacman', '-Sp', '--print-format', '%l', 'quickshell'], text=True).splitlines()
def download(url):
    filename = url.rsplit('/', 1)[1]
    expected = checks[filename]
    dest = cache/filename
    if not dest.exists() or hashlib.sha256(dest.read_bytes()).hexdigest() != expected:
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != expected:
            raise RuntimeError('Checksum inválido: '+filename)
        dest.write_bytes(data)
    return dest
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
    packages = list(pool.map(download, urls))
for package in packages:
    subprocess.run(['bsdtar', '-xf', str(package), '-C', str(runtime), 'usr'], check=True)
    print('Verificado:', package.name)
print('Runtime disponível em', runtime)
