#!/bin/bash

# check ~/bin/ exists. if not, create it
if [ ! -d "$HOME/bin" ]; then
  mkdir $HOME/bin/ 2>/dev/null
fi


# copy squash executable to ~/bin/
cp ./squash $HOME/bin/
chmod +x $HOME/bin/squash


# remove existing autocomplete from ~/.bashrc
starts=($(grep -nFx "# >>> squash-autocomplete >>>" $HOME/.bashrc | cut -f1 -d:))
ends=($(grep -nFx "# <<< squash-autocomplete <<<" $HOME/.bashrc | cut -f1 -d:))

if (( ${#starts[@]} )); then
  # not empty array

  # find lines to delete
  del_lines=""
  for idx in "${!starts[@]}"; do
    # loop through pairs
    start=${starts[$idx]}  # start line
    start="$(($start-1))"
    end=${ends[$idx]}  # end line
    del_lines="${del_lines}${start},${end}d;"
  done
  del_lines=${del_lines::-1}  # remove last semicolon

  # delete lines in between
  sed -e "$del_lines" $HOME/.bashrc > tmpfile
  mv tmpfile $HOME/.bashrc
fi


# add autocomplete to .bashrc
cat <<EOF >> $HOME/.bashrc

# >>> squash-autocomplete >>>
_squash()
{
    local cur=\${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( \$(compgen -W "\$(git branch -l 2>/dev/null | grep -oP "^(\*\s|\s{2})\K(\S*)" | tr '\n' ' ')" -- \$cur) )
}
complete -F _squash squash
# <<< squash-autocomplete <<<
EOF
