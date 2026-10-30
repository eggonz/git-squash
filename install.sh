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
  echo "  -y, --yes                  : do not ask for confirmation"
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
ASSUME_YES=false
DEFAULT_RENAME=true
DEFAULT_RENAME_PATTERN="merged/<branch>"

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) Help; exit 0;;
    -y|--yes) ASSUME_YES=true;;
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

# resolve install dir to an absolute path (without creating it yet)
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_DIR}"
INSTALL_DIR="$(realpath -m "${INSTALL_DIR/#\~/$HOME}")"
TARGET="$INSTALL_DIR/squash"

# check install dir is writable (or its closest existing parent, if it must be created)
check_dir="$INSTALL_DIR"
while [ ! -e "$check_dir" ]; do
  check_dir="$(dirname "$check_dir")"
done
if [ ! -d "$check_dir" ] || [ ! -w "$check_dir" ]; then
  echo "[squash ERROR] Cannot write to \"$INSTALL_DIR\" (check permissions)"
  exit 1
fi

if [ -e "$TARGET" ] && ! grep -qF "[squash INFO]" "$TARGET" 2>/dev/null; then
  echo "[squash ERROR] \"$TARGET\" already exists and is not a squash installation"
  exit 1
fi


# find existing installations (recorded in ~/.bashrc, older installations used $HOME/bin)
existing=()
while IFS= read -r dir; do
  if [ -f "$dir/squash" ] && grep -qF "[squash INFO]" "$dir/squash"; then
    existing+=("$dir/squash")
  fi
done < <({ echo "$HOME/bin"; grep -F "# squash-install-dir: " "$HOME/.bashrc" 2>/dev/null | sed "s|^# squash-install-dir: ||"; } | sort -u)


# confirm installation
ConfigLine()
{
  # ConfigLine <key> <default> <new value or empty>
  local current
  current="$(git config --global --get "squash.$1")"
  local shown="${current:-$2 (default)}"
  local next="${3:-${current:-$2}}"
  if [ -z "$3" ] || [ "$next" == "$current" ]; then
    printf '  %-21s: %s\n' "squash.$1" "$shown"
  else
    printf '  %-21s: %s -> %s\n' "squash.$1" "$shown" "$next"
  fi
}

echo "squash installation"
echo "  install path         : $TARGET"
if [ ${#existing[@]} -gt 0 ]; then
  for path in "${existing[@]}"; do
    if [ "$path" == "$TARGET" ]; then
      echo "  existing installation: $path (will be replaced)"
    else
      echo "  existing installation: $path (will be removed)"
    fi
  done
else
  echo "  existing installation: none"
fi
echo "configuration (global git config)"
ConfigLine renameMerged "$DEFAULT_RENAME" "$RENAME"
ConfigLine renamePattern "$DEFAULT_RENAME_PATTERN" "$RENAME_PATTERN"
echo ""

if [ "$ASSUME_YES" != true ]; then
  if [ ! -t 0 ]; then
    echo "[squash ERROR] Cannot ask for confirmation (not a terminal), use -y to install anyway"
    exit 1
  fi
  read -r -p "Proceed with installation? [Y/n] " answer
  case "$answer" in
    ""|[Yy]|[Yy][Ee][Ss]) ;;
    *) echo "[squash INFO] Installation cancelled"; exit 0;;
  esac
fi


# create install dir
if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
  echo "[squash ERROR] Cannot write to \"$INSTALL_DIR\" (check permissions)"
  exit 1
fi


# remove existing installation, if any
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
