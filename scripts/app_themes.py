"""Theme GTK launchers while terminal TUIs follow the current ANSI palette."""
from pathlib import Path
import os,configparser,json

def apply(palette):
 config=Path(os.environ.get('XDG_CONFIG_HOME',Path.home()/'.config'))
 folder=config/'wofi';folder.mkdir(parents=True,exist_ok=True)
 style='''* {{ font-family: "Adwaita Sans"; font-size: 14px; color: {text}; }}
window {{ background-color: {background}; border: 1px solid {border}; border-radius: 6px; }}
#outer-box {{ padding: 12px; }}
#input {{ padding: 10px; margin-bottom: 10px; background: {surface}; color: {text}; border: 1px solid {border}; border-radius: 6px; box-shadow: none; }}
#inner-box, #scroll {{ background: transparent; }}
#entry {{ padding: 8px; border: 1px solid transparent; border-radius: 6px; }}
#entry:selected {{ background: {surface}; border: 1px solid {accent}; }}
#text:selected {{ color: {accent}; }}
#img {{ margin-right: 10px; }}
'''.format(**palette)
 (folder/'style.css').write_text(style)

 theme=Path.home()/'.local/share/themes/DarkMountain/gtk-3.0'
 theme.mkdir(parents=True,exist_ok=True)
 gtk='@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");\n'+'''
window, .background {{ background-color: {background}; color: {text}; }}
headerbar, toolbar, .toolbar {{ background: {surface}; color: {text}; border-color: {border}; box-shadow: none; }}
button, entry {{ border-radius: 6px; border-color: {border}; color: {text}; }}
button:checked, button:active, selection {{ background: {accent}; color: {background}; }}
'''.format(**palette)
 (theme/'gtk.css').write_text(gtk)
 (theme/'gtk-dark.css').write_text(gtk)

 # GTK 3 follows the rice; GTK 4/libadwaita follows prefer-dark.
 for version in ('gtk-3.0','gtk-4.0'):
  folder=config/version;folder.mkdir(parents=True,exist_ok=True)
  path=folder/'settings.ini';settings=configparser.ConfigParser(interpolation=None)
  if path.exists():settings.read(path)
  if not settings.has_section('Settings'):settings.add_section('Settings')
  settings['Settings']['gtk-application-prefer-dark-theme']='true'
  settings['Settings']['gtk-font-name']='Adwaita Sans 10'
  if version=='gtk-3.0':settings['Settings']['gtk-theme-name']='DarkMountain'
  with path.open('w') as stream:settings.write(stream)

 # btop reads the active palette from a generated theme.
 folder=config/'btop/themes';folder.mkdir(parents=True,exist_ok=True)
 colors={'main_bg':palette['background'],'main_fg':palette['text'],
 'title':palette['text'],'hi_fg':palette['accent'],'selected_bg':palette['surface'],
 'selected_fg':palette['accent'],'inactive_fg':palette['muted'],
 'graph_text':palette['text'],'meter_bg':palette['border'],
 'proc_misc':palette['accent'],'cpu_box':palette['accent'],
 'mem_box':palette['accent'],'net_box':palette['accent'],'proc_box':palette['accent'],
 'div_line':palette['border'],'temp_start':palette['muted'],
 'temp_mid':palette['accent'],'temp_end':palette['danger']}
 for metric in ('cpu','free','cached','available','used','download','upload','process'):
  colors.update({metric+'_start':palette['muted'],metric+'_mid':palette['accent'],metric+'_end':palette['text']})
 (folder/'dark-mountain.theme').write_text(''.join(f'theme[{key}]="{value}"\n' for key,value in colors.items()))

 # Keep the compact Arch logo in sync with every palette change.
 project=Path(__file__).resolve().parents[1]
 for path in (project/'app-configs/fastfetch/config.jsonc',config/'fastfetch/config.jsonc'):
  if not path.exists():continue
  settings=json.loads(path.read_text())
  settings['logo']={'type':'builtin','source':'arch_small','color':{'1':palette['accent'],'2':palette['accent']}}
  settings.setdefault('display',{}).setdefault('color',{}).update(keys=palette['accent'],title=palette['accent'])
  path.write_text(json.dumps(settings,ensure_ascii=False,indent=2)+'\n')
