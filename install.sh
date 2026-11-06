#!/usr/bin/env bash
# Download and apply Dark Mountain. Run as your desktop user, never with sudo.
set -Eeuo pipefail
trap 'printf "Erro na linha %s. Instalação interrompida; os backups existentes foram mantidos.\n" "$LINENO" >&2' ERR

usage() {
    cat <<'HELP'
Uso: bash install.sh [opções]
  --repo URL         Clona o repositório (HTTPS ou SSH).
  --branch REF       Branch/tag para clonar (padrão: main).
  --dir CAMINHO      Destino do clone (padrão: ~/dark-mountain).
  --minimal          Instala apenas Hyprland, Kitty e Quickshell.
  --skip-deps        Usa dependências de sistema já instaladas.
  --no-browsers      Não instala Brave, Chromium e Firefox.
  --with-docker      Configura e inicia também o Docker rootless.
  --sddm             Instala o tema de login com sudo, sem reiniciar o SDDM.
  --no-start         Aplica os arquivos sem recarregar a sessão.
  -h, --help         Mostra esta ajuda.

Dentro do projeto: bash install.sh
Instalador avulso: bash install.sh --repo https://github.com/USUARIO/dark-mountain.git
Requer Arch Linux, configuração Hyprland Lua existente e systemd do usuário.
O perfil usa teclado ABNT2 e fuso Brasília; preserva os monitores da configuração base.
HELP
}
die() { printf 'Erro: %s\n' "$*" >&2; exit 1; }
need_value() { [[ $# -ge 2 && -n $2 && $2 != -* ]] || die "Falta valor para $1"; }

rice_repo=''
rice_branch=main
rice_dest="$HOME/dark-mountain"
rice_apps=1
rice_deps=1
rice_docker=0
rice_sddm=0
rice_start=1
rice_dir_set=0
rice_browsers=1
while (($#)); do
    case "$1" in
        --repo) need_value "$@"; rice_repo=$2; shift 2 ;;
        --branch) need_value "$@"; rice_branch=$2; shift 2 ;;
        --dir) need_value "$@"; rice_dest=$2; rice_dir_set=1; shift 2 ;;
        --minimal) rice_apps=0; shift ;;
        --skip-deps) rice_deps=0; shift ;;
        --no-browsers) rice_browsers=0; shift ;;
        --with-docker) rice_docker=1; shift ;;
        --sddm) rice_sddm=1; shift ;;
        --no-start) rice_start=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Opção desconhecida: $1. Use --help." ;;
    esac
done
((EUID != 0)) || die 'Execute como usuário normal. O script chama sudo somente nas etapas de sistema.'
((!rice_docker || rice_apps)) || die '--with-docker não pode ser combinado com --minimal.'
[[ $rice_dest = /* ]] || rice_dest="$PWD/$rice_dest"
rice_config="${XDG_CONFIG_HOME:-$HOME/.config}"
[[ -f "$rice_config/hypr/hyprland.lua" ]] || die "Crie primeiro sua configuração Hyprland Lua: $rice_config/hypr/hyprland.lua"
command -v pacman >/dev/null || die 'Este instalador requer Arch Linux/pacman.'
command -v systemctl >/dev/null || die 'systemctl ausente.'
systemctl --user show-environment >/dev/null || die 'O gerenciador systemd do usuário não está disponível.'
if ((rice_docker)); then
    command -v newuidmap >/dev/null && command -v newgidmap >/dev/null || die 'Docker rootless requer newuidmap e newgidmap (pacote shadow).'
    rice_user=$(id -un)
    for rice_mapping in /etc/subuid /etc/subgid; do
        awk -F: -v user="$rice_user" -v uid="$(id -u)" '($1 == user || $1 == uid) && $3 >= 65536 {found=1} END {exit !found}' "$rice_mapping" || die "Configure um intervalo de ao menos 65536 IDs para $rice_user em $rice_mapping."
    done
fi

rice_packages=(git python quickshell qt6-svg ripgrep iproute2 kitty ttf-jetbrains-mono-nerd)
if ((rice_apps)); then
    rice_packages+=(libarchive grim slurp wofi poppler glib2)
fi
if ((rice_sddm)); then rice_packages+=(sddm); fi
if ((rice_deps)); then
    command -v sudo >/dev/null || die 'sudo ausente; instale as dependências manualmente e use --skip-deps.'
    printf 'Instalando dependências de sistema com pacman (pode solicitar senha)...\n'
    sudo pacman -S --needed -- "${rice_packages[@]}"
fi
for rice_cmd in git python3 quickshell rg ip kitty hyprctl; do
    command -v "$rice_cmd" >/dev/null || die "Dependência ausente: $rice_cmd"
done
if ((rice_apps)); then
    for rice_cmd in bsdtar grim slurp wofi pdftoppm gdbus; do
        command -v "$rice_cmd" >/dev/null || die "Dependência ausente: $rice_cmd"
    done
fi
if ((rice_sddm)); then
    command -v sudo >/dev/null || die 'sudo ausente para instalar SDDM.'
    pacman -Q sddm >/dev/null || die 'Instale o pacote sddm antes de usar --sddm.'
fi

rice_script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ -n $rice_repo ]]; then
    [[ ! -e $rice_dest && ! -L $rice_dest ]] || die "O destino já existe: $rice_dest. Execute o install.sh dessa pasta para reaplicar; escolha outro --dir para um novo clone."
    mkdir -p -- "$(dirname -- "$rice_dest")"
    git clone --depth 1 --branch "$rice_branch" -- "$rice_repo" "$rice_dest"
    rice_project=$rice_dest
elif [[ -f "$rice_script_dir/scripts/install.py" && $rice_dir_set = 0 ]]; then
    rice_project=$rice_script_dir
elif [[ -f "$rice_dest/scripts/install.py" ]]; then
    rice_project=$rice_dest
else
    die 'Informe --repo URL para baixar o projeto, ou execute dentro de uma cópia existente.'
fi
[[ -f "$rice_project/scripts/check.py" && -f "$rice_project/themes.json" ]] || die 'A pasta não contém um projeto Dark Mountain completo.'
export PATH="$HOME/.local/bin:$PATH"
python3 "$rice_project/scripts/check.py"
if ((rice_apps && rice_browsers)); then
    if ((rice_deps)); then
        bash "$rice_project/scripts/install-browsers.sh"
    else
        for rice_browser in firefox chromium; do
            command -v "$rice_browser" >/dev/null || die "Navegador ausente: $rice_browser. Instale-o ou use --no-browsers."
        done
        command -v brave >/dev/null || command -v brave-browser >/dev/null || die 'Brave ausente. Instale-o ou use --no-browsers.'
    fi
fi
printf 'Aplicando o projeto em %s\n' "$rice_project"
printf 'Perfil: ABNT2 e Brasília. Monitores, resolução, taxa e escala seguem sua configuração Hyprland existente.\n'
if ((rice_apps)); then
    # Download first: a failed download must not replace desktop configuration.
    python3 "$rice_project/scripts/bootstrap-apps.py"
fi
python3 "$rice_project/scripts/install.py"
if ((rice_apps)); then
    rice_setup_args=()
    if ((!rice_docker)); then rice_setup_args+=(--without-docker); fi
    python3 "$rice_project/scripts/setup-apps.py" "${rice_setup_args[@]}"
    # LazyVim downloads its plugins on the first editor launch.
fi
if ((rice_sddm)); then
    sudo python3 "$rice_project/scripts/install-login.py"
fi
if ((rice_start)) && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload
    rice_errors=$(hyprctl configerrors)
    [[ -z ${rice_errors//[[:space:]]/} ]] || die "Hyprland reportou erros; corrija antes de iniciar a Island: $rice_errors"
    "$HOME/.local/bin/dark-mountain" restart
else
    printf 'Na sessão Hyprland, ative com: hyprctl reload && ~/.local/bin/dark-mountain restart\n'
fi
printf '\nRice aplicado. Mantenha a pasta %s no local atual (links simbólicos).\n' "$rice_project"
printf 'Backup principal: %s/dark-mountain/backups\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
printf 'Restaurar configuração principal: python3 "%s/scripts/restore.py"\n' "$rice_project"
if ((rice_apps)); then
    printf 'Backups de aplicativos: ~/.local/state/dark-mountain/app-backups (restauração manual).\n'
    printf 'Abra um novo terminal para carregar o shell; abra nvim para instalar os plugins.\n'
fi
