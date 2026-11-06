#!/usr/bin/env bash
set -euo pipefail
project="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$project/scripts/bootstrap-apps.py" btop
ln -sfn "$project/scripts/app-run" "$HOME/.local/bin/btop"
python3 "$project/scripts/control.py" init
hyprctl reload
"$HOME/.local/bin/dark-mountain" restart
sudo python3 "$project/scripts/install-login.py"
