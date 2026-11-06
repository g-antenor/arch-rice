#!/usr/bin/env python3
"""Install application integration after bootstrap-apps.py. Existing files are backed up."""
from pathlib import Path
import datetime,os,shutil,subprocess,urllib.request,json,argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--without-docker',action='store_true',help='Do not configure or start rootless Docker')
args=parser.parse_args()
home=Path.home();project=Path(__file__).resolve().parents[1];config=Path(os.environ.get('XDG_CONFIG_HOME',home/'.config'));runtime=home/'.local/lib/dark-mountain/apps-runtime/usr'
backup=home/'.local/state/dark-mountain/app-backups'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup.mkdir(parents=True)
preserved=set()
manifest=[]
def preserve(path):
 if path in preserved:return
 preserved.add(path)
 exists=path.exists() or path.is_symlink()
 manifest.append({'path':str(path),'existed':exists,'saved':str(path.relative_to(home)) if exists else None})
 (backup/'manifest.json').write_text(json.dumps(manifest,indent=2))
 if not exists:return
 target=backup/path.relative_to(home);target.parent.mkdir(parents=True,exist_ok=True)
 if path.is_symlink():target.symlink_to(os.readlink(path))
 elif path.is_dir():shutil.copytree(path,target,symlinks=True)
 else:shutil.copy2(path,target)
def link(source,target):
 target.parent.mkdir(parents=True,exist_ok=True)
 if target.is_symlink() and target.resolve()==source.resolve():return
 if target.exists() or target.is_symlink():
  preserve(target)
  moved=backup/'replaced'/target.relative_to(home);moved.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(target),str(moved))
 target.symlink_to(source,target_is_directory=source.is_dir())
for name in 'btop ffmpegthumbnailer fastfetch swappy nvim lazygit lazydocker tmux yazi ya wl-copy wl-paste cliphist chafa mpv wf-recorder fzf fd magick convert identify jq zoxide tdf gcc g++ cc c++ as ld ar nm strip make tree-sitter docker dockerd containerd containerd-shim-runc-v2 runc rootlesskit rootlessctl slirp4netns fuse-overlayfs iptables ip6tables iptables-nft ip6tables-nft xtables-nft-multi'.split():
 if (runtime/'bin'/name).exists():link(project/'scripts/app-run',home/'.local/bin'/name)
for name in ['rice-tools','rice-apps','rice-pdf','rice-video','rice-record','rice-image']:link(project/'scripts/tools.py',home/'.local/bin'/name)
for name in ['nvim','yazi','tmux','lazydocker','mpv','fastfetch','btop']:link(project/'app-configs'/name,config/name)
link(project/'app-configs/lazydocker',config/'jesseduffield/lazydocker')
plugin=runtime/'lib/docker/cli-plugins/docker-compose'
if plugin.exists():link(plugin,home/'.docker/cli-plugins/docker-compose')
rootless=home/'.local/bin/dockerd-rootless.sh'
if not args.without_docker and not rootless.exists():
 with urllib.request.urlopen('https://raw.githubusercontent.com/moby/moby/master/contrib/dockerd-rootless.sh',timeout=30) as response:rootless.write_bytes(response.read())
 rootless.chmod(0o755)
services={
'rice-clipboard.service':f'''[Unit]
Description=Dark Mountain clipboard history
PartOf=graphical-session.target
After=graphical-session.target
[Service]
ExecStart={home}/.local/bin/wl-paste --watch {home}/.local/bin/cliphist store
Restart=on-failure
RestartSec=2
StandardOutput=null
[Install]
WantedBy=graphical-session.target
''',
'rice-docker.service':f'''[Unit]
Description=Rootless Docker for Dark Mountain
After=network-online.target
[Service]
Environment=PATH={home}/.local/bin:/usr/local/bin:/usr/bin
Environment=DOCKERD_ROOTLESS_ROOTLESSKIT_NET=slirp4netns
ExecStart={home}/.local/bin/dockerd-rootless.sh
Restart=on-failure
RestartSec=3
TimeoutStartSec=90
Delegate=yes
KillMode=mixed
TasksMax=infinity
LimitNOFILE=infinity
LimitNPROC=infinity
[Install]
WantedBy=default.target
'''}
if args.without_docker:services.pop('rice-docker.service')
for name,text in services.items():
 target=config/'systemd/user'/name;target.parent.mkdir(parents=True,exist_ok=True);preserve(target);target.write_text(text)
apps=[('rice-btop','Btop','System','terminal btop',''),('rice-lazyvim','LazyVim','TextEditor','terminal nvim %F','text/plain;'),('rice-yazi','Yazi','FileManager','terminal yazi','inode/directory;'),('rice-tmux','Tmux','TerminalEmulator','terminal tmux new-session -A -s main',''),('rice-lazydocker','Lazydocker','Development','terminal lazydocker',''),('rice-record','Gravador de tela','AudioVideo','record','')]
folder=home/'.local/share/applications';folder.mkdir(parents=True,exist_ok=True)
for ident,label,category,command,mimes in apps:
 target=folder/(ident+'.desktop');preserve(target)
 target.write_text(f'[Desktop Entry]\nType=Application\nName={label}\nExec={home}/.local/bin/rice-tools {command}\nIcon=utilities-terminal\nTerminal=false\nCategories={category};\nMimeType={mimes}\n')
for ident,label,command,mimes in [('rice-pdf','PDF no terminal','rice-pdf','application/pdf;'),('rice-video','Vídeo no terminal','rice-video','video/mp4;video/x-matroska;video/webm;video/quicktime;'),('rice-image','Imagem no terminal','rice-image','image/png;image/jpeg;image/webp;image/gif;image/bmp;image/svg+xml;')]:
 target=folder/(ident+'.desktop');preserve(target);target.write_text(f'[Desktop Entry]\nType=Application\nName={label}\nExec={home}/.local/bin/{command} %f\nIcon=utilities-terminal\nTerminal=false\nCategories=AudioVideo;\nMimeType={mimes}\n')
 if shutil.which('xdg-mime'):
  preserve(config/'mimeapps.list')
  for mime in mimes.split(';'):
   if mime:subprocess.run(['xdg-mime','default',ident+'.desktop',mime],check=True,timeout=5,env=dict(os.environ,XDG_CURRENT_DESKTOP='X-Generic'))
if shutil.which('update-desktop-database'):subprocess.run(['update-desktop-database',str(folder)],check=False)
subprocess.run(['systemctl','--user','daemon-reload'],check=True)
subprocess.run(['systemctl','--user','enable','--now',*services],check=True)
print('Integração instalada. Backup:',backup)

# Interactive shell customization, with the existing rc preserved in the manifest.
link(project/'app-configs/bash/rice.bash',config/'dark-mountain/bashrc')
rc=home/'.bashrc'
line='source "${XDG_CONFIG_HOME:-$HOME/.config}/dark-mountain/bashrc"'
if line not in (rc.read_text() if rc.exists() else ''):
 preserve(rc)
 with rc.open('a') as stream:stream.write('\n# Dark Mountain\n'+line+'\n')
