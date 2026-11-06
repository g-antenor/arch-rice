#!/usr/bin/env python3
"""Install verified Arch application packages into a private user runtime."""
from pathlib import Path
import concurrent.futures,hashlib,json,subprocess,tarfile,urllib.request,sys,os
HOME=Path.home(); CACHE=HOME/'.cache/dark-mountain/app-packages'; RUNTIME=HOME/'.local/lib/dark-mountain/apps-runtime'
PACKAGES=['btop','ffmpegthumbnailer','fastfetch','swappy','neovim','lazygit','lazydocker','tmux','yazi','wl-clipboard','cliphist','chafa','mpv','wf-recorder','fzf','fd','imagemagick','jq','zoxide','tdf','gcc','binutils','make','tree-sitter-cli','docker','docker-compose','rootlesskit','slirp4netns','fuse-overlayfs','iptables-nft','patchelf']
CACHE.mkdir(parents=True,exist_ok=True);RUNTIME.mkdir(parents=True,exist_ok=True)
checks={}
for db in Path('/var/lib/pacman/sync').glob('*.db'):
 with tarfile.open(db) as archive:
  for member in archive:
   if member.name.endswith('/desc'):
    lines=archive.extractfile(member).read().decode().splitlines()
    if '%FILENAME%' in lines and '%SHA256SUM%' in lines:checks[lines[lines.index('%FILENAME%')+1]]=lines[lines.index('%SHA256SUM%')+1]
selected=sys.argv[1:] or PACKAGES
urls=subprocess.check_output(['pacman','-Sp','--print-format','%l',*selected],text=True).splitlines()
def download(url):
 name=url.rsplit('/',1)[-1];target=CACHE/name;expected=checks[name]
 if not target.exists() or hashlib.sha256(target.read_bytes()).hexdigest()!=expected:
  for attempt in range(3):
   try:
    with urllib.request.urlopen(url,timeout=90) as response:data=response.read()
    if hashlib.sha256(data).hexdigest()!=expected:raise ValueError('Checksum inválido: '+name)
    target.write_bytes(data);break
   except Exception:
    if attempt==2:raise
 return target
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
 for package in pool.map(download,urls):
  subprocess.run(['bsdtar','-xf',str(package),'-C',str(RUNTIME),'usr'],check=True)
  print('Verificado:',package.name,flush=True)
manifest=RUNTIME/'packages.json'
previous=json.loads(manifest.read_text()).get('packages',[]) if manifest.exists() else []
manifest.write_text(json.dumps({'requested':PACKAGES,'packages':list(dict.fromkeys(previous+[u.rsplit('/',1)[-1] for u in urls]))},indent=2))
print('Runtime de aplicativos:',RUNTIME)

# Arch occasionally records absolute DT_NEEDED paths; relocate only the private copies.
patcher=RUNTIME/'usr/bin/patchelf'
if patcher.exists():
 env=dict(os.environ,LD_LIBRARY_PATH=str(RUNTIME/'usr/lib'))
 seen=set()
 for folder in [RUNTIME/'usr/bin',RUNTIME/'usr/lib']:
  for binary in folder.rglob('*'):
   if not binary.is_file() or binary.is_symlink():continue
   with binary.open('rb') as stream:
    if stream.read(4)!=b'\x7fELF':continue
   deps=subprocess.run([str(patcher),'--print-needed',str(binary)],capture_output=True,text=True,env=env)
   if deps.returncode:continue
   for dependency in deps.stdout.splitlines():
    private=RUNTIME/dependency.lstrip('/')
    if dependency.startswith('/usr/') and private.exists():
     subprocess.run([str(patcher),'--replace-needed',dependency,str(private),str(binary)],check=True,env=env)
     print('Relocado:',binary.name,dependency,flush=True)
