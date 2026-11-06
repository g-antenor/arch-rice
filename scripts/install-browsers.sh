#!/usr/bin/env bash
# Native browser packages keep sandboxing and receive normal package updates.
set -Eeuo pipefail
if ((EUID == 0)); then
    echo 'Execute como usuário normal; sudo será usado pelo gerenciador de pacotes.' >&2
    exit 1
fi
command -v pacman >/dev/null
command -v sudo >/dev/null
sudo pacman -S --needed -- git base-devel firefox chromium

if command -v brave >/dev/null || command -v brave-browser >/dev/null; then
    printf 'Brave já instalado.\n'
elif command -v paru >/dev/null; then
    paru -S --needed brave-bin
elif command -v yay >/dev/null; then
    yay -S --needed brave-bin
else
    # No AUR helper is required. Build only the binary package recipe as user.
    rice_build=$(mktemp -d "${TMPDIR:-/tmp}/dark-mountain-brave.XXXXXXXX")
    trap 'rm -rf -- "$rice_build"' EXIT
    git clone --depth 1 -- https://aur.archlinux.org/brave-bin.git "$rice_build/brave-bin"
    (
        cd -- "$rice_build/brave-bin"
        makepkg --syncdeps --install --needed
    )
fi
command -v firefox >/dev/null
command -v chromium >/dev/null
command -v brave >/dev/null || command -v brave-browser >/dev/null
printf 'Brave, Chromium e Firefox instalados. Abra pela busca Super + Espaço.\n'
