#!/bin/bash

# help
Help()
{
  echo "help"
  echo "  squash <src_branch> : squash-merge <src_branch> into current branch"
  echo "  squash -h : help"
  echo ""
  echo "configuration (git config, use --global for all repositories)"
  echo "  squash.renameMerged <bool>   : rename <src_branch> after merging (default: true)"
  echo "  squash.renamePattern <name>  : new branch name, <branch> is replaced by the"
  echo "                                 original name (default: \"merged/<branch>\")"
}

while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
     \?) # incorrect option
         echo "[squash ERROR] Invalid option"
         Help
         exit 1;;
   esac
done
shift $((OPTIND-1))

# check git repository exists
if [ -z "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
  echo "[squash ERROR] Git repository not found in current directory"
  exit 1
fi

# read input
BRANCH=$1
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ -z "$BRANCH" ]; then
  echo "[squash ERROR] Missing argument <src_branch>"
  exit 1
fi
if ! git rev-parse --verify -q "$BRANCH^{commit}" >/dev/null; then
  echo "[squash ERROR] Branch \"$BRANCH\" does not exist"
  exit 1
fi
if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
  echo "[squash ERROR] <src_branch> cannot be current branch"
  exit 1
fi

# read configuration
RENAME_MERGED=$(git config --bool --get squash.renameMerged || echo true)
RENAME_PATTERN=$(git config --get squash.renamePattern || echo "merged/<branch>")

# main program

GIT_DIR=$(git rev-parse --git-dir)
STASHED=false

Unstash()
{
  if [ "$STASHED" == true ]; then
    echo "[squash INFO] Unstashing saved local changes"
    git stash pop -q || echo "[squash WARNING] Could not restore local changes, they are kept in the stash"
  fi
}

echo "[squash INFO] Stash current local changes"
STASH_BEFORE=$(git rev-parse -q --verify refs/stash)
if ! git stash push -q -m "squash_tmp_${CURRENT_BRANCH}"; then
  echo "[squash ERROR] Could not stash local changes. Aborting squash..."
  exit 1
fi
if [ "$(git rev-parse -q --verify refs/stash)" != "$STASH_BEFORE" ]; then
  STASHED=true
fi

echo "[squash INFO] Squashing branch \"$BRANCH\" into \"$CURRENT_BRANCH\""
if ! git merge --squash "$BRANCH"; then
  echo "[squash ERROR] Merge failed. Aborting squash..."
  git reset -q --hard HEAD  # tracked local changes are safe in the stash
  rm -f "$GIT_DIR/SQUASH_MSG"
  Unstash
  exit 1
fi

if [ ! -f "$GIT_DIR/SQUASH_MSG" ] || git diff --cached --quiet; then
  echo "[squash INFO] Nothing to squash, \"$CURRENT_BRANCH\" is up to date with \"$BRANCH\""
  rm -f "$GIT_DIR/SQUASH_MSG"
  Unstash
  exit 0
fi

# prepend branch name to squash msg
if ! { printf '[squash] %s\n\n' "$BRANCH"; cat "$GIT_DIR/SQUASH_MSG"; } | git commit -F -; then
  echo "[squash ERROR] Commit failed. Squashed changes are left staged"
  if [ "$STASHED" == true ]; then
    echo "[squash ERROR] Local changes are kept in the stash, restore them with \"git stash pop\""
  fi
  exit 1
fi

# rename merged branch (only local branches)
if [ "$RENAME_MERGED" == true ] && git show-ref -q --verify "refs/heads/$BRANCH"; then
  NEW_BRANCH=${RENAME_PATTERN//<branch>/$BRANCH}
  if ! git check-ref-format --branch "$NEW_BRANCH" >/dev/null 2>&1; then
    echo "[squash WARNING] Invalid rename pattern \"$RENAME_PATTERN\", branch \"$BRANCH\" not renamed"
  elif git show-ref -q --verify "refs/heads/$NEW_BRANCH"; then
    echo "[squash WARNING] Branch \"$NEW_BRANCH\" already exists, branch \"$BRANCH\" not renamed"
  else
    echo "[squash INFO] Renaming branch \"$BRANCH\" to \"$NEW_BRANCH\""
    git branch -m "$BRANCH" "$NEW_BRANCH" \
      || echo "[squash WARNING] Could not rename branch \"$BRANCH\""
  fi
fi

Unstash
