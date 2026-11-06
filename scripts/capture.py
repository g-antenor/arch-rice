"""Finish the frozen capture; only crop the immutable image shown by the overlay."""
from pathlib import Path
import datetime,json,os,subprocess,time
STATE=Path(os.environ.get('XDG_STATE_HOME',Path.home()/'.local/state'))/'dark-mountain';BIN=Path.home()/'.local/bin'
def done():
 subprocess.run([str(BIN/'dark-mountain'),'ipc','call','desktop','captureDone'],check=True,timeout=5)
def editor(path):
 environment=os.environ.copy();environment['GTK_THEME']='DarkMountain:dark'
 subprocess.Popen([str(BIN/'swappy'),'-f',str(path),'-o',str(path)],env=environment,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
def main(args):
 action=args[0]
 if action=='capture-edit-last':
  try:path=Path(json.loads((STATE/'last-screenshot.json').read_text())['file'])
  except FileNotFoundError:
   files=list((Path.home()/'Pictures/Screenshots').glob('*.png'))
   if not files:raise ValueError('Tire uma captura com Print antes de abrir o editor.')
   path=max(files,key=lambda p:p.stat().st_mtime)
  if not path.is_file():raise ValueError('A última captura não está mais disponível.')
  from tools import close_island
  close_island();time.sleep(.2);editor(path);return
 info=json.loads((STATE/'capture.json').read_text());source=Path(info['source'])
 if source.parent!=STATE or not source.name.startswith('freeze-'):raise ValueError('Captura inválida')
 if action=='capture-cancel':
  done();source.unlink(missing_ok=True);return
 if action!='capture-finish':raise ValueError('Ação de captura inválida')
 x,y,w,h,vw,vh=map(float,args[1:7])
 if min(w,h,vw,vh)<=0 or x<0 or y<0 or x+w>vw+.5 or y+h>vh+.5:raise ValueError('Seleção inválida')
 iw,ih=map(int,subprocess.check_output([str(BIN/'magick'),'identify','-format','%w %h',str(source)],text=True).split())
 geometry=f'{max(1,round(w*iw/vw))}x{max(1,round(h*ih/vh))}+{round(x*iw/vw)}+{round(y*ih/vh)}'
 folder=Path.home()/'Pictures/Screenshots';folder.mkdir(parents=True,exist_ok=True)
 target=folder/(datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.png')
 subprocess.run([str(BIN/'magick'),str(source),'-crop',geometry,'+repage',str(target)],check=True)
 subprocess.run([str(BIN/'wl-copy'),'--type','image/png'],input=target.read_bytes(),check=True)
 (STATE/'last-screenshot.json').write_text(json.dumps({'file':str(target)}))
 done();source.unlink(missing_ok=True)
 if args[7]=='edit':time.sleep(.2);editor(target)
 else:
  from tools import notify
  notify('Captura salva e copiada',str(target))
