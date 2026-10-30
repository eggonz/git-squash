# git-squash customized tool

The `squash` command performs a squash-merge from `<src_branch>` to the current branch.
The squash commit message (`[squash] <src_branch>`) contains the name of the merged branch and information about the squashed commits from the original branch.
The commits in the original branch are kept unsquashed.
Uncommitted local changes are stashed before the merge and restored afterwards.
After merging, `<src_branch>` is renamed to `merged/<src_branch>` (configurable, see below).

## use

Run the following command from a folder with a git project:

```bash
squash <src_branch>
```

- `<src_branch>` can be tab-autocompleted with the branches of the current git repository.
- `<src_branch>` cannot be null, and it must exist in the repository.
- If the merge fails (e.g. conflicts), the squash is aborted and local changes are restored.

## configuration

Settings are read with `git config` (add `--global` to apply them to all repositories).
They can also be set globally when installing (see [install](#install)).

```bash
# enable/disable renaming <src_branch> after merging (default: true)
git config squash.renameMerged false

# new name of the merged branch, <branch> is replaced by the original name (default: "merged/<branch>")
git config squash.renamePattern "done/<branch>"
```

Only local branches are renamed. The rename is skipped if the target branch already exists.


## install

```bash
./install.sh [options] [install_dir]
```

- `install_dir` is the folder where the `squash` command is installed (default: `~/bin`).
  It is created if it does not exist, and it must be writable by the current user.
- Options to set the [configuration](#configuration) (saved in the global git config, left unchanged if not given):
  - `--rename` / `--no-rename`: enable/disable renaming `<src_branch>` after merging
  - `--rename-pattern <pattern>`: new name of the merged branch, must contain `<branch>`

```bash
# example: install in ~/.local/bin, rename merged branches to "done/<branch>"
./install.sh --rename-pattern "done/<branch>" ~/.local/bin
```
- Restart the terminal or run `source ~/.bashrc` after installation.

The script will do the following:
1. Remove any existing installation (same as `./uninstall.sh`), wherever it was installed
2. Install `squash.sh` as the executable command `install_dir/squash`
3. Save the given configuration options with `git config --global`
4. Append a block to `~/.bashrc` that adds `install_dir` to `PATH` (if not already there) and enables autocomplete

The tool can be reinstalled, updated or moved to another folder by running `./install.sh` again.
The configuration is kept, since it is stored in git config.
An existing `install_dir/squash` file that does not belong to this tool is never overwritten.

## uninstall

```bash
./uninstall.sh
```

The script will do the following:
1. Remove the `squash` command from the folder where it was installed
2. Remove the `PATH` and autocomplete block from `~/.bashrc`

---

## reference / sources

- script v0.2
  - https://andy-carter.com/blog/automating-git-commit-messages-with-git-hooks
  - https://git-scm.com/docs/githooks
  - https://stackoverflow.com/questions/6245570/how-do-i-get-the-current-branch-name-in-git
- script v0.1
  - https://stackoverflow.com/questions/30136558/how-to-squash-commits-which-have-merge-commit-in-between
  - https://superuser.com/questions/289539/custom-bash-tab-completion
  - https://unix.stackexchange.com/questions/13466/can-grep-output-only-specified-groupings-that-match
  - https://unix.stackexchange.com/questions/26788/using-sed-to-convert-newlines-into-spaces
  - https://stackoverflow.com/questions/44758736/redirect-stderr-to-dev-null
  - https://stackoverflow.com/questions/2180270/check-if-current-directory-is-a-git-repository
  - https://www.cyberciti.biz/faq/unix-linux-bash-script-check-if-variable-is-empty/
  - https://stackoverflow.com/questions/5167957/is-there-a-better-way-to-find-out-if-a-local-git-branch-exists
  - https://opensource.com/article/19/12/help-bash-program
  - https://linuxize.com/post/how-to-compare-strings-in-bash/
  - https://askubuntu.com/questions/29370/how-to-check-if-a-command-succeeded
  - https://www.ionos.com/digitalguide/websites/web-development/renaming-a-git-branch/
- install.sh
  - https://linuxconfig.org/bash-scripting-check-if-directory-exists
  - https://unix.stackexchange.com/questions/253892/syntax-error-unexpected-when-creating-an-array
- uninstall.sh
  - https://www.baeldung.com/linux/delete-lines-containing-string-from-file
  - https://stackoverflow.com/questions/23929235/multi-line-string-with-extra-space-preserved-indentation
  - https://stackoverflow.com/questions/6958841/use-grep-to-report-back-only-line-numbers
  - https://stackoverflow.com/questions/2112469/delete-specific-line-numbers-from-a-text-file-using-sed
  - https://unix.stackexchange.com/questions/283407/can-sed-save-its-output-to-a-file
  - https://stackoverflow.com/questions/28725333/looping-over-pairs-of-values-in-bash
  - https://askubuntu.com/questions/656817/remove-any-trailing-blank-lines-or-lines-with-whitespaces-from-end-of-file
  - https://stackoverflow.com/questions/9293887/reading-a-space-delimited-string-into-an-array-in-bash
  - https://stackoverflow.com/questions/27658675/how-to-remove-last-n-characters-from-a-string-in-bash
  - https://serverfault.com/questions/477503/check-if-array-is-empty-in-bash