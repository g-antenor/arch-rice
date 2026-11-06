#!/usr/bin/env python3
"""Local theme, wallpaper, focus-mode and power actions. No shell interpolation."""
from pathlib import Path
import fcntl
import json
import os
import signal
import subprocess
import sys
import time

PROJECT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(PROJECT/"scripts"))
STATE=Path(os.environ.get('XDG_STATE_HOME',Path.home()/'.local/state'))/'dark-mountain'
STATE.mkdir(parents=True,exist_ok=True)
THEMES=json.loads((PROJECT/'themes.json').read_text())
NAMES=list(THEMES)

def atomic(path,text):
    path.parent.mkdir(parents=True,exist_ok=True)
    temp=path.with_name(path.name+'.tmp')
    temp.write_text(text)
    temp.replace(path)

def read(path,default):
    try:return json.loads(path.read_text())
    except (OSError,ValueError):return default

def lua(value):
    if value is None:return 'nil'
    if isinstance(value,bool):return 'true' if value else 'false'
    if isinstance(value,(int,float)):return str(value)
    if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
    if isinstance(value,dict):return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
    raise ValueError('Unsupported Lua value')

def hypr_json(query):
    return json.loads(subprocess.check_output(['hyprctl','-j',query],text=True,timeout=5))

def eval_hypr(code):
    return subprocess.run(['hyprctl','eval',code],check=True,text=True,capture_output=True,timeout=5)

def dispatch(code):
    return subprocess.run(['hyprctl','dispatch',code],check=True,text=True,capture_output=True,timeout=5)

def current_theme():
    result=read(STATE/'theme.json',{})
    return result if result.get('name') in THEMES else {'name':'mountain','wallpaperName':'mountain'}

def apply_theme(name,wallpaper=None,live=True):
    if name not in THEMES:raise ValueError('Tema desconhecido: '+name)
    paper=wallpaper or name
    if paper not in THEMES:raise ValueError('Wallpaper desconhecido: '+paper)
    palette=THEMES[name]
    result={k:v for k,v in palette.items() if k!='ansi'}
    result.update(wallpaperName=paper,wallpaper=(PROJECT/'quickshell/assets/wallpapers'/f'{paper}.svg').as_uri())
    color_config={'general':{'col':{'active_border':'rgba('+palette['border'][1:]+'ff)','inactive_border':'rgba('+palette['border'][1:]+'ff)'}},'decoration':{'shadow':{'color':0x99000000}}}
    code='hl.config('+lua(color_config)+')\n'
    atomic(STATE/'colors.lua',code)
    # Keep user font and terminal options; replace only palette values.
    target=PROJECT/'kitty/theme.conf'
    terminal={**{k:palette[k] for k in ['background','text']},'foreground':palette['text'],'selection_background':palette['accent'],'selection_foreground':'#000000','cursor':palette['accent'],'url_color':palette['accent']}
    terminal.pop('text')
    terminal.update(active_tab_foreground=palette['accent'],active_tab_background=palette['background'],inactive_tab_foreground=palette['muted'],inactive_tab_background=palette['background'])
    terminal.update({f'color{i}':color for i,color in enumerate(palette['ansi'])})
    lines=target.read_text().replace('# Dark Mountain — TokyoNight Moon','# Dark Mountain — paleta gerenciada').splitlines();seen=set();output=[]
    for line in lines:
        parts=line.split()
        if parts and parts[0] in terminal:
            seen.add(parts[0]);line=parts[0]+' '+terminal[parts[0]]
        output.append(line)
    output.extend(k+' '+v for k,v in terminal.items() if k not in seen)
    text='\n'.join(output)+'\n'
    if target.read_text()!=text:atomic(target,text)
    from app_themes import apply as apply_application_themes
    apply_application_themes(palette)
    atomic(STATE/'theme.json',json.dumps(result,ensure_ascii=False)+'\n')
    if live:
        try:
            eval_hypr(code)
            for client in hypr_json('clients'):
                if client['class'] in ('kitty','org.darkmountain.terminal'):os.kill(client['pid'],signal.SIGUSR1)
        except (OSError,subprocess.SubprocessError,ValueError) as error:
            print('Paleta salva; recarregue a sessão se necessário:',error,file=sys.stderr)
    print('Tema:',palette['label'],'| wallpaper:',paper)

def set_monitor_margin(monitor,margin):
    spec={'output':monitor['name'],'mode':f"{monitor['width']}x{monitor['height']}@{monitor['refreshRate']}",'position':f"{monitor['x']}x{monitor['y']}",'scale':monitor['scale'],'reserved':margin}
    eval_hypr('hl.monitor('+lua(spec)+')')

def focus_state():return read(STATE/'focus.json',{'hidden':False})

def same_client(snapshot,clients):
    return next((c for c in clients if c.get('address')==snapshot.get('address') and c.get('pid')==snapshot.get('pid') and c.get('stableId')==snapshot.get('stableId')),None)

def toggle_focus():
    saved=focus_state();clients=hypr_json('clients');monitors=hypr_json('monitors')
    if saved.get('hidden'):
        monitor=next((m for m in monitors if m['name']==saved.get('monitor')),None)
        if monitor:set_monitor_margin(monitor,0)
        client=same_client(saved,clients)
        if client:
            spec={'window':'address:'+client['address'],'action':'set','internal':saved.get('fullscreen',0),'client':saved.get('fullscreenClient',0),'layout_aware':False}
            dispatch('hl.dsp.window.fullscreen_state('+lua(spec)+')')
        atomic(STATE/'focus.json',json.dumps({'hidden':False})+'\n')
        print('Island visível; janela restaurada')
        return
    active=hypr_json('activewindow')
    monitor=next((m for m in monitors if m['id']==active.get('monitor')),None) or next((m for m in monitors if m.get('focused')),None)
    if not monitor:raise RuntimeError('Nenhum monitor ativo')
    # A layer-shell popup owns keyboard focus, so activewindow can be empty.
    if not active.get('address'):
        workspace=monitor.get('activeWorkspace',{}).get('id')
        candidates=[c for c in clients if c.get('mapped') and not c.get('hidden') and c.get('monitor')==monitor['id'] and c.get('workspace',{}).get('id')==workspace]
        candidates.sort(key=lambda c:c.get('focusHistoryID',9999) if c.get('focusHistoryID',-1)>=0 else 9999)
        active=candidates[0] if candidates else {}
    saved={k:active.get(k) for k in ['address','pid','stableId','fullscreen','fullscreenClient']}
    saved.update(hidden=True,monitor=monitor['name'])
    atomic(STATE/'focus.json',json.dumps(saved)+'\n')
    # Wait briefly for the shell's layer surface to release its exclusive zone.
    for _ in range(30):
        layers=hypr_json('layers')
        active_layers=[s for m in layers.values() for level in m.get('levels',{}).values() for s in level if s.get('namespace')=='dark-mountain-island']
        if not active_layers:break
        time.sleep(.05)
    set_monitor_margin(monitor,0)
    if active.get('address'):
        dispatch('hl.dsp.window.fullscreen('+lua({'window':'address:'+active['address'],'mode':'maximized','action':'set','layout_aware':False})+')')
    print('Island oculta; janela maximizada com margem de 2 px')

def power_menu():
    if focus_state().get('hidden'):toggle_focus()
    subprocess.run([str(Path.home()/'.local/bin/dark-mountain'),'ipc','call','desktop','powerMenu'],check=True,timeout=5)

def main(args):
    action=args[0] if args else 'init'
    current=current_theme()
    if action=='init':
        if not (STATE/'focus.json').exists():atomic(STATE/'focus.json','{"hidden":false}\n')
        elif focus_state().get('hidden') and not same_client(focus_state(),hypr_json('clients')):
            saved=focus_state()
            for monitor in hypr_json('monitors'):
                if monitor['name']==saved.get('monitor'):set_monitor_margin(monitor,0)
            atomic(STATE/'focus.json','{"hidden":false}\n')
        apply_theme(current['name'],current.get('wallpaperName'),live=False)
    elif action=='theme':apply_theme(args[1])
    elif action=='next-theme':apply_theme(NAMES[(NAMES.index(current['name'])+1)%len(NAMES)])
    elif action=='wallpaper':apply_theme(current['name'],args[1])
    elif action=='next-wallpaper':apply_theme(current['name'],NAMES[(NAMES.index(current.get('wallpaperName',current['name']))+1)%len(NAMES)])
    elif action=='focus':toggle_focus()
    elif action=='restore-focus':
        if focus_state().get('hidden'):toggle_focus()
    elif action in ('search-menu','logout-menu','clipboard-menu'):
        if focus_state().get('hidden'):toggle_focus()
        subprocess.run([str(Path.home()/'.local/bin/dark-mountain'),'ipc','call','desktop',{'search-menu':'searchMenu','logout-menu':'logoutMenu','clipboard-menu':'clipboardMenu'}[action]],check=True,timeout=5)
    elif action=='clipboard-copy':
        from tools import clipboard_copy
        clipboard_copy(args[1])
    elif action.startswith('capture-'):
        import capture
        capture.main(args)
    elif action=='power-menu':power_menu()
    elif action=='power':
        if len(args)!=2 or args[1] not in ('suspend','poweroff','reboot','logout'):raise ValueError('Ação de energia inválida')
        if args[1]=='logout':dispatch('hl.dsp.exit()')
        else:subprocess.run(['systemctl',args[1]],check=True,timeout=30)
    else:raise ValueError('Comando desconhecido: '+action)

if __name__=='__main__':
    try:
        with (STATE/'control.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            main(sys.argv[1:])
    except (OSError,ValueError,RuntimeError,subprocess.SubprocessError) as error:
        print(str(error),file=sys.stderr);sys.exit(1)
