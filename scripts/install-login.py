#!/usr/bin/env python3
"""Install the tested SDDM theme with a dated backup. Does not restart SDDM."""
from pathlib import Path
import datetime,os,shutil,sys
PROJECT=Path(__file__).resolve().parents[1]
if os.geteuid()!=0:raise SystemExit('Execute: sudo python3 '+str(Path(__file__).resolve()))
source=PROJECT/'sddm/dark-mountain';target=Path('/usr/share/sddm/themes/dark-mountain');config=Path('/etc/sddm.conf.d/90-dark-mountain.conf')
backup=Path('/var/backups/dark-mountain-sddm')/datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup.mkdir(parents=True)
for path in [target,config]:
 if path.exists():
  dest=backup/path.relative_to('/');dest.parent.mkdir(parents=True,exist_ok=True)
  if path.is_dir():shutil.copytree(path,dest,symlinks=True)
  else:shutil.copy2(path,dest)
if not (source/'Main.qml').is_file() or not (source/'fonts/Mono.ttf').is_file():raise SystemExit('Tema incompleto')
# Stage on the same filesystem before replacing the theme.
staged=target.with_name('dark-mountain.new-'+str(os.getpid()))
shutil.copytree(source,staged)
for item in [staged,*staged.rglob('*')]:os.chmod(item,0o755 if item.is_dir() else 0o644);os.chown(item,0,0)
if target.exists():target.rename(backup/'previous-theme')
staged.rename(target)
config.parent.mkdir(parents=True,exist_ok=True)
temp=config.with_suffix('.tmp');temp.write_text('[Theme]\nCurrent=dark-mountain\n');os.chmod(temp,0o644);temp.replace(config)
print('Tema SDDM instalado. Será usado no próximo login; a sessão atual permanece aberta.')
print('Backup:',backup)
