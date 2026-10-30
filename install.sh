#!/bin/bash
#
# install.sh [options] [install_dir] : install squash.sh as the "squash" command in install_dir (default: $HOME/bin)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DIR="$HOME/bin"

Help()
{
  echo "help"
  echo "  ./install.sh [options] [install_dir] : install the \"squash\" command in install_dir (default: $DEFAULT_DIR)"
  echo "  ./install.sh -h : help"
  echo ""
  echo "options (saved in global git config, unchanged if not given)"
  echo "  --rename                   : rename <src_branch> after merging (default)"
  echo "  --no-rename                : do not rename <src_branch> after merging"
  echo "  --rename-pattern <pattern> : new branch name, <branch> is replaced by the"
  echo "                               original name (default: \"merged/<branch>\")"
}

RENAME=""
RENAME_PATTERN=""
INSTALL_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) Help; exit 0;;
    --rename) RENAME=true;;
    --no-rename) RENAME=false;;
    --rename-pattern)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "[squash ERROR] Missing value for --rename-pattern"
        exit 1
      fi
      RENAME_PATTERN="$2"
      shift;;
    --rename-pattern=*)
      RENAME_PATTERN="${1#*=}"
      if [ -z "$RENAME_PATTERN" ]; then
        echo "[squash ERROR] Missing value for --rename-pattern"
        exit 1
      fi;;
    -*) echo "[squash ERROR] Invalid option \"$1\""; Help; exit 1;;
    *)
      if [ -n "$INSTALL_DIR" ]; then
        echo "[squash ERROR] Too many arguments"
        Help
        exit 1
      fi
      INSTALL_DIR="$1";;
  esac
  shift
done

# validate rename pattern
if [ -n "$RENAME_PATTERN" ]; then
  if [[ "$RENAME_PATTERN" != *"<branch>"* ]]; then
    echo "[squash ERROR] Rename pattern \"$RENAME_PATTERN\" must contain <branch>"
    exit 1
  fi
  if ! git check-ref-format --branch "${RENAME_PATTERN//<branch>/example}" >/dev/null 2>&1; then
    echo "[squash ERROR] Rename pattern \"$RENAME_PATTERN\" does not produce a valid branch name"
    exit 1
  fi
fi

# resolve install dir to an absolute path
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_DIR}"
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

# save rename configuration
if [ -n "$RENAME" ]; then
  git config --global squash.renameMerged "$RENAME" || exit 1
  echo "[squash INFO] Set squash.renameMerged=$RENAME"
fi
if [ -n "$RENAME_PATTERN" ]; then
  git config --global squash.renamePattern "$RENAME_PATTERN" || exit 1
  echo "[squash INFO] Set squash.renamePattern=$RENAME_PATTERN"
fi

echo "[squash INFO] Installed \"squash\" in $TARGET"
echo "[squash INFO] Restart the terminal or run \"source ~/.bashrc\" to use it"
