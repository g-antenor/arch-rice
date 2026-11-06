#!/usr/bin/env python3
"""Themed local launchers, screenshots, clipboard, terminal media and recording."""
from pathlib import Path
import datetime,json,os,signal,subprocess,sys,time
HOME=Path.home();CONFIG=Path(os.environ.get("XDG_CONFIG_HOME",HOME/".config"));STATE=Path(os.environ.get('XDG_STATE_HOME',HOME/'.local/state'))/'dark-mountain';BIN=HOME/'.local/bin';PROJECT=Path(__file__).resolve().parents[1]
STATE.mkdir(parents=True,exist_ok=True)

def theme():
 try:return json.loads((STATE/'theme.json').read_text())
 except (OSError,ValueError):return {'background':'#000000','text':'#e7e7e7','accent':'#8f8aac'}

def notify(title,body):
 subprocess.run(['gdbus','call','--session','--dest','org.freedesktop.Notifications','--object-path','/org/freedesktop/Notifications','--method','org.freedesktop.Notifications.Notify','Dark Mountain','0','',title,body,'[]','{}','3500'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)

def close_island():
 try:
  monitors=json.loads(subprocess.check_output(['hyprctl','-j','monitors'],text=True,stderr=subprocess.DEVNULL))
  focused=next((m for m in monitors if m.get('focused')),None)
  if focused:subprocess.run([str(BIN/'dark-mountain'),'ipc','call','island-'+focused['name'],'close'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=3)
 except (OSError,ValueError,subprocess.SubprocessError):pass

def terminal(args):
 os.execvp('kitty',['kitty','--class','org.darkmountain.terminal','-e',*args])

def menu(prompt,items):
 result=subprocess.run(['wofi','--dmenu','--insensitive','--prompt',prompt,'--width','480','--height','320','--style',str(CONFIG/'wofi/style.css')],input='\n'.join(items),text=True,capture_output=True)
 return result.stdout.strip() if result.returncode==0 else ''

def screenshot(full=False):
 status=json.loads(subprocess.check_output([str(BIN/'dark-mountain'),'ipc','call','desktop','state'],text=True))
 if status.get('captureActive'):return
 time.sleep(.25)
 monitors=json.loads(subprocess.check_output(['hyprctl','-j','monitors'],text=True))
 monitor=next(m for m in monitors if m.get('focused'))
 source=STATE/('freeze-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.png')
 subprocess.run(['grim','-o',monitor['name'],str(source)],check=True)
 (STATE/'capture.json').write_text(json.dumps({'source':str(source),'screen':monitor['name']}))
 subprocess.run([str(BIN/'dark-mountain'),'ipc','call','desktop','capture',str(source),monitor['name'],str(full).lower()],check=True)

def clipboard():
 subprocess.run(['python3',str(PROJECT/'scripts/control.py'),'clipboard-menu'],check=True)

def clipboard_copy(ident):
 if not str(ident).isdigit():raise ValueError('Item de clipboard inválido')
 decoded=subprocess.run([str(BIN/'cliphist'),'decode'],input=(str(ident)+'\n').encode(),check=True,capture_output=True).stdout
 subprocess.run([str(BIN/'wl-copy')],input=decoded,check=True)

def recording():
 try:info=json.loads((STATE/'recording.json').read_text())
 except (OSError,ValueError):return None
 proc=Path('/proc')/str(info.get('pid',0))
 try:
  parts=(proc/'stat').read_text().split(') ')[1].split()
  if parts[0]=='Z' or parts[19]!=info['starttime'] or Path(os.readlink(proc/'exe')).name!='wf-recorder':return None
 except (OSError,ValueError,KeyError,IndexError):return None
 return info

def record_stop():
 info=recording()
 if not info:return
 os.kill(info['pid'],signal.SIGINT)
 for _ in range(100):
  if not recording():break
  time.sleep(.05)
 if recording():raise RuntimeError('O gravador ainda está finalizando. Aguarde e tente novamente.')
 notify('Gravação finalizada',info['file'])

def record_start(region=False,audio=False,geometry=None,output=None):
 if recording():return
 if region and not geometry:
  selected=subprocess.run(['slurp','-b','00000088','-c',theme()['accent'][1:]+'ff','-w','1'],capture_output=True,text=True)
  if selected.returncode:return
  geometry=selected.stdout.strip()
 folder=HOME/'Videos/Recordings';folder.mkdir(parents=True,exist_ok=True)
 target=Path(output) if output else folder/(datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.mp4')
 command=[str(BIN/'wf-recorder'),'--no-dmabuf','-c','libx264','-p','preset=ultrafast','-p','crf=23','-r','30','-f',str(target)]
 if geometry:command+=['-g',geometry]
 if audio:command+=['-a']
 with (STATE/'recorder.log').open('w') as log:
  process=subprocess.Popen(command,stdin=subprocess.DEVNULL,stdout=log,stderr=log,start_new_session=True)
 time.sleep(.4)
 if process.poll() is not None:raise RuntimeError('Não foi possível iniciar a gravação. Veja ~/.local/state/dark-mountain/recorder.log')
 parts=(Path('/proc')/str(process.pid)/'stat').read_text().split(') ')[1].split()
 (STATE/'recording.json').write_text(json.dumps({'pid':process.pid,'starttime':parts[19],'file':str(target)}))

def record_menu():
 if recording():record_stop();return
 options=['Gravar tela inteira','Gravar uma região','Gravar tela inteira com áudio','Gravar região com áudio']
 selected=menu('Gravador de tela',options)
 if selected in options:record_start('região' in selected,'áudio' in selected)

def main(args):
 entry=Path(sys.argv[0]).name
 action={'rice-pdf':'pdf','rice-video':'video','rice-image':'image','rice-record':'record','rice-apps':'apps'}.get(entry)
 if action is None:
  if not args:raise ValueError('Uso: rice-tools terminal|apps|clipboard|shot|record|pdf|video|image')
  action=args.pop(0)
 close_island()
 if action=='terminal':terminal(args)
 elif action=='apps':subprocess.run(['python3',str(PROJECT/'scripts/control.py'),'search-menu'],check=True)
 elif action=='clipboard':clipboard()
 elif action=='shot':screenshot(bool(args and args[0]=='full'))
 elif action=='record':record_menu()
 elif action=='record-stop':record_stop()
 elif action=='record-start':
  # Explicit CLI mode also supports scripted captures; paths are passed as argv, never shell code.
  import argparse
  parser=argparse.ArgumentParser();parser.add_argument('--geometry');parser.add_argument('--output');parser.add_argument('--audio',action='store_true');opts=parser.parse_args(args)
  record_start(audio=opts.audio,geometry=opts.geometry,output=opts.output)
 elif action in ('pdf','video','image'):
  if not args:raise ValueError('Selecione um arquivo para abrir.')
  file=Path(args[0]).expanduser().resolve()
  if not file.is_file():raise ValueError('Arquivo não encontrado: '+str(file))
  if not sys.stdin.isatty():terminal([str(BIN/('rice-'+action)),str(file)])
  if action in ('pdf','image'):
   sys.path.insert(0,str(PROJECT/'scripts'))
   from media import view
   view(file,pdf=action=='pdf')
  else:
   output=os.environ.get('RICE_VIDEO_OUTPUT') or ('kitty' if os.environ.get('KITTY_WINDOW_ID') or os.environ.get('TERM')=='xterm-kitty' else 'tct')
   if output not in ('kitty','tct'):raise ValueError('Saída de vídeo inválida: use kitty ou tct')
   os.execv(str(BIN/'mpv'),['mpv','--vo='+output,'--vo-kitty-use-shm=no',str(file)])
 else:raise ValueError('Comando desconhecido: '+action)

if __name__=='__main__':
 try:main(sys.argv[1:])
 except (OSError,ValueError,RuntimeError,subprocess.SubprocessError) as error:
  print(str(error),file=sys.stderr);notify('Dark Mountain',str(error));sys.exit(1)
