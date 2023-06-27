#!/bin/bash

# remove executable from ~/bin/
rm $HOME/bin/squash 2>/dev/null


# remove autocomplete from ~/.bashrc
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
