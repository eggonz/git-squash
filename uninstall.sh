#!/bin/bash
#
# uninstall.sh : remove the "squash" command and its ~/.bashrc configuration

set -u

START_MARK="# >>> squash-autocomplete >>>"
END_MARK="# <<< squash-autocomplete <<<"
DIR_MARK="# squash-install-dir: "

case "${1:-}" in
  -h|--help)
    echo "help"
    echo "  ./uninstall.sh : remove the \"squash\" command and its configuration from ~/.bashrc"
    echo "  ./uninstall.sh -h : help"
    exit 0;;
esac


# find install dirs recorded in ~/.bashrc (older installations used $HOME/bin)
install_dirs=("$HOME/bin")
if [ -f "$HOME/.bashrc" ]; then
  while IFS= read -r dir; do
    install_dirs+=("$dir")
  done < <(grep -F "$DIR_MARK" "$HOME/.bashrc" | sed "s|^$DIR_MARK||")
fi


# remove executable (only if it is a squash installation)
for dir in "${install_dirs[@]}"; do
  target="$dir/squash"
  if [ -f "$target" ] && grep -qF "[squash INFO]" "$target"; then
    rm -f "$target" && echo "[squash INFO] Removed $target"
  fi
done


# remove PATH and autocomplete from ~/.bashrc
if [ -f "$HOME/.bashrc" ]; then
  n_starts=$(grep -cFx "$START_MARK" "$HOME/.bashrc")
  n_ends=$(grep -cFx "$END_MARK" "$HOME/.bashrc")

  if [ "$n_starts" -ne "$n_ends" ]; then
    echo "[squash ERROR] Unbalanced autocomplete markers in ~/.bashrc, please remove them manually"
    exit 1
  fi

  if [ "$n_starts" -gt 0 ]; then
    # delete each block, together with the blank line added before it
    tmpfile=$(mktemp)
    awk -v s="$START_MARK" -v e="$END_MARK" '
      skip { if ($0 == e) skip = 0; next }
      $0 == s { skip = 1; has_blank = 0; next }
      has_blank { print blank; has_blank = 0 }
      /^[[:space:]]*$/ { blank = $0; has_blank = 1; next }
      { print }
      END { if (has_blank) print blank }
    ' "$HOME/.bashrc" > "$tmpfile" && cat "$tmpfile" > "$HOME/.bashrc"  # keep file permissions/symlinks
    rm -f "$tmpfile"
  fi
fi
