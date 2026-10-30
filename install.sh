#!/bin/bash
#
# install.sh [install_dir] : install squash.sh as the "squash" command in install_dir (default: $HOME/bin)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DIR="$HOME/bin"

Help()
{
  echo "help"
  echo "  ./install.sh [install_dir] : install the \"squash\" command in install_dir (default: $DEFAULT_DIR)"
  echo "  ./install.sh -h : help"
}

case "${1:-}" in
  -h|--help) Help; exit 0;;
  -*) echo "[squash ERROR] Invalid option \"$1\""; Help; exit 1;;
esac
if [ $# -gt 1 ]; then
  echo "[squash ERROR] Too many arguments"
  Help
  exit 1
fi

# resolve install dir to an absolute path
INSTALL_DIR="${1:-$DEFAULT_DIR}"
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
  echo "[squash ERROR] Cannot write to \"$INSTALL_DIR\" (check permissions)"
  exit 1
fi
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd)"
TARGET="$INSTALL_DIR/squash"

if [ -e "$TARGET" ] && ! grep -qF "[squash INFO]" "$TARGET" 2>/dev/null; then
  echo "[squash ERROR] \"$TARGET\" already exists and is not a squash installation"
  exit 1
fi


# remove existing installation, if any
if grep -qFx "# >>> squash-autocomplete >>>" "$HOME/.bashrc" 2>/dev/null || [ -e "$TARGET" ]; then
  echo "[squash INFO] Existing installation found, reinstalling"
fi
bash "$SCRIPT_DIR/uninstall.sh" || exit 1


# install executable as "squash"
install -m 755 "$SCRIPT_DIR/squash.sh" "$TARGET" || exit 1


# add PATH and autocomplete to ~/.bashrc
cat <<EOF >> "$HOME/.bashrc"

# >>> squash-autocomplete >>>
# squash-install-dir: $INSTALL_DIR
case ":\$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) export PATH="$INSTALL_DIR:\$PATH" ;;
esac
_squash()
{
    local cur=\${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( \$(compgen -W "\$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)" -- "\$cur") )
}
complete -F _squash squash
# <<< squash-autocomplete <<<
EOF

echo "[squash INFO] Installed \"squash\" in $TARGET"
echo "[squash INFO] Restart the terminal or run \"source ~/.bashrc\" to use it"
