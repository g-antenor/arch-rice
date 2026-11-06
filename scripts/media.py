#!/usr/bin/env python3
"""Render original images and PDF pages in the terminal without shared memory."""
from pathlib import Path
import json,os,select,shutil,subprocess,sys,tempfile,termios,tty,re
HOME=Path.home();BIN=HOME/'.local/bin'
def clean(text):return re.sub(r'[\x00-\x1f\x7f-\x9f]',' ',str(text))
def view(file,pdf=False):
 if not sys.stdin.isatty():raise ValueError('Abra o visualizador em um terminal.')
 pages=1
 if pdf:
  info=subprocess.check_output(['pdfinfo',str(file)],text=True,stderr=subprocess.PIPE)
  match=re.search(r'^Pages:\s+(\d+)',info,re.M)
  if not match:raise ValueError('Não foi possível ler as páginas do PDF.')
  pages=int(match[1])
 try:palette=json.loads((Path(os.environ.get('XDG_STATE_HOME',HOME/'.local/state'))/'dark-mountain/theme.json').read_text())
 except (OSError,ValueError):palette={'accent':'#8f8aac'}
 rgb=tuple(bytes.fromhex(palette['accent'].lstrip('#')));accent='\033[38;2;%s;%s;%sm'%rgb
 kitty=bool(os.environ.get('KITTY_WINDOW_ID') or os.environ.get('TERM')=='xterm-kitty')
 descriptor=sys.stdin.fileno();saved=termios.tcgetattr(descriptor);page=1;last_size=None;dirty=True
 def write(s):sys.stdout.write(s);sys.stdout.flush()
 with tempfile.TemporaryDirectory(prefix='rice-pages-') as cache:
  try:
   tty.setcbreak(descriptor);write('\033[?1049h\033[?25l')
   while True:
    size=shutil.get_terminal_size();cols,rows=size
    if size!=last_size:dirty=True;last_size=size
    if dirty:
     image=file
     if pdf:
      image=Path(cache)/f'page-{page}.png'
      if not image.exists():
       subprocess.run(['pdftoppm','-f',str(page),'-l',str(page),'-singlefile','-scale-to','1800','-png',str(file),str(image.with_suffix(''))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
     if kitty:subprocess.run(['kitty','+kitten','icat','--clear','--stdin=no'],stdout=sys.stdout,stderr=subprocess.DEVNULL,check=True)
     write('\033[2J\033[H'+accent+'  '+clean(file.name)[:max(1,cols-4)]+'\033[0m')
     if kitty:
      subprocess.run(['kitty','+kitten','icat','--transfer-mode=stream','--stdin=no','--passthrough=detect','--scale-up','--place',f'{max(1,cols-4)}x{max(1,rows-5)}@2x2',str(image)],check=True,stdout=sys.stdout)
     else:
      write('\033[3;3H');subprocess.run([str(BIN/'chafa'),'--probe=off','-f','symbols','-c','full','--size',f'{max(1,cols-4)}x{max(1,rows-5)}',str(image)],check=True)
     footer=f'  {page}/{pages}   ←/→ · PgUp/PgDn: páginas   q/Esc: sair' if pdf else '  Imagem original   q/Esc: sair'
     write(f'\033[{max(1,rows-1)};1H'+accent+footer[:cols-1]+'\033[0m');dirty=False
    if not select.select([descriptor],[],[],.15)[0]:continue
    key=os.read(descriptor,1)
    if key==b'\x1b':
     while select.select([descriptor],[],[],.03)[0]:key+=os.read(descriptor,32)
    if key in (b'q',b'Q',b'\x1b',b'\x03'):break
    old=page
    if key in (b'\x1b[C',b'\x1b[B',b'\x1b[6~',b'l',b'j',b' '):page=min(pages,page+1)
    elif key in (b'\x1b[D',b'\x1b[A',b'\x1b[5~',b'h',b'k'):page=max(1,page-1)
    elif key==b'g':page=1
    elif key==b'G':page=pages
    dirty=page!=old
  finally:
   if kitty:subprocess.run(['kitty','+kitten','icat','--clear','--stdin=no'],stdout=sys.stdout,stderr=subprocess.DEVNULL)
   write('\033[0m\033[?25h\033[?1049l');termios.tcsetattr(descriptor,termios.TCSADRAIN,saved)
