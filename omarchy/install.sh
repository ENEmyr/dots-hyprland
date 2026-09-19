#!/usr/bin/env bash
# Deploy the sidebar-only build of illogical-impulse from this checkout.
#
# It copies the upstream quickshell config into ~/.config/quickshell/ii-sidebar,
# replaces shell.qml with the sidebar-only entry point from omarchy/, and
# installs the AI bridge. Nothing in ~/.config/hypr is touched, and no other
# shell is killed, so it is safe to run next to Omarchy's own quickshell.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." >/dev/null && pwd)"
CONFIG_NAME="${II_SIDEBAR_CONFIG_NAME:-ii-sidebar}"
TARGET="$HOME/.config/quickshell/$CONFIG_NAME"
BIN_DIR="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
WITH_BRIDGE=1

for arg in "$@"; do
    case "$arg" in
        --no-bridge) WITH_BRIDGE=0 ;;
        -h|--help)
            sed -n '2,12p' "$0"
            exit 0
            ;;
        *)
            echo "unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

say() { printf '==> %s\n' "$1"; }
warn() { printf 'warning: %s\n' "$1" >&2; }

say "checking dependencies"
command -v quickshell >/dev/null || warn "quickshell not found in PATH"
command -v rsync >/dev/null || { echo "rsync is required" >&2; exit 1; }
[ -d /usr/lib/qt6/qml/Qt5Compat/GraphicalEffects ] || warn "qt6-5compat missing"
[ -d /usr/lib/qt6/qml/org/kde/syntaxhighlighting ] || [ -d /usr/lib/qt6/qml/org/kde/syntaxhighlighting.disabled ] || warn "KDE syntax-highlighting QML module missing (Arch package: syntax-highlighting)"
fc-list 2>/dev/null | grep -qi 'material symbols' || warn "Material Symbols font missing (Arch package: ttf-material-symbols-variable)"

if [ ! -e "$REPO_ROOT/dots/.config/quickshell/ii/modules/common/widgets/shapes/material-shapes.js" ]; then
    echo "submodule dots/.config/quickshell/ii/modules/common/widgets/shapes is not checked out." >&2
    echo "run: git -C '$REPO_ROOT' submodule update --init --recursive --depth 1" >&2
    exit 1
fi

say "checking upstream compatibility"
bash "$REPO_ROOT/omarchy/check-compat.sh"

if qs list --all 2>/dev/null | grep -q "quickshell/$CONFIG_NAME/shell.qml"; then
    say "stopping the running instance"
    qs kill -c "$CONFIG_NAME" >/dev/null 2>&1 || true
fi

say "syncing quickshell config into $TARGET"
mkdir -p "$TARGET"
rsync -a --delete "$REPO_ROOT/dots/.config/quickshell/ii/" "$TARGET/"
install -m 0644 "$REPO_ROOT/omarchy/shell.qml" "$TARGET/shell.qml"

say "installing scripts into $BIN_DIR"
mkdir -p "$BIN_DIR"
install -m 0755 "$REPO_ROOT/omarchy/bin/ii-sidebar-toggle" "$BIN_DIR/ii-sidebar-toggle"

if [ "$WITH_BRIDGE" -eq 1 ]; then
    install -m 0755 "$REPO_ROOT/omarchy/bin/ii-ai-bridge" "$BIN_DIR/ii-ai-bridge"
    mkdir -p "$UNIT_DIR" "$HOME/.config/ii-ai-bridge"
    install -m 0644 "$REPO_ROOT/omarchy/systemd/ii-ai-bridge.service" "$UNIT_DIR/ii-ai-bridge.service"
    if [ ! -f "$HOME/.config/ii-ai-bridge/backends.json" ]; then
        install -m 0644 "$REPO_ROOT/omarchy/examples/backends.example.json" "$HOME/.config/ii-ai-bridge/backends.json"
        say "seeded ~/.config/ii-ai-bridge/backends.json from the example, edit it before use"
    fi
    systemctl --user daemon-reload
    if systemctl --user is-enabled ii-ai-bridge.service >/dev/null 2>&1; then
        systemctl --user restart ii-ai-bridge.service
    else
        say "bridge not enabled yet: systemctl --user enable --now ii-ai-bridge.service"
    fi
fi

say "starting the sidebar"
qs -d -n -c "$CONFIG_NAME" >/dev/null 2>&1 || true

cat <<EOF

Done. Next steps that this script deliberately does not do for you:

  1. Bind a key. See omarchy/examples/hypr-bindings.example.lua
  2. Register the models. Merge ai.extraModels from
     omarchy/examples/extra-models.example.json into
     ~/.config/illogical-impulse/config.json, then restart the sidebar:
       qs kill -c $CONFIG_NAME && ii-sidebar-toggle
  3. For a remote Ollama, copy omarchy/systemd/ii-ssh-ollama-tunnel.service.example
     to $UNIT_DIR, replace OLLAMA_SSH_HOST, and enable it.

Toggle by hand with: ii-sidebar-toggle
EOF
