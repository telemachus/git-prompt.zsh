# WARNING

This is just a highly customized version of [git-prompt.zsh](https://github.com/woefe/git-prompt.zsh) written by [Wolfgang Popp](https://github.com/woefe).
Unless you are me (and you are not), then you probably want [his version](https://github.com/woefe/git-prompt.zsh) rather than this repository.

<h2><img src="https://i.imgur.com/uRh5vOh.png" /></h2>

A fast, customizable, pure-shell, asynchronous git prompt for Zsh.
It is heavily inspired by Olivier Verdier's [zsh-git-prompt](https://github.com/olivierverdier/zsh-git-prompt) and very similar to the "Informative VCS" prompt of fish shell.

## Prompt Structure

The structure of the prompt is the following:

```
[<branch_name><upstream><repository_state_and_tracking_status><short_hash>]
```

* `branch_name`: Name of the current branch or warning message if HEAD is detached.
* `upstream`: Name of the remote branch or warning message if no remote branch
  is set.
    Since a remote either exists or does not, you will only see at most one message in this section.
    By default, the prompt will not show the name of the remote branch, but it will show if no remote is set.
    However, you can configure the two options separately as well.
    You can also configure the message displayed if no remote exists.
    See below for details on [configuration](#configuration) and
    [appearance](#appearance).
* `repository_state_and_tracking_status`:
    The symbols can be customized (see [below for details](#appearance)) but here are the defaults.
    * `+`: there are staged files
    * `*`: there are unstaged and changed files
    * `%`: there are untracked files
    * `$`: there are entries in the stash (disabled by default)
    * `>`: the repository is ahead of remote
    * `<`: the repository is behind remote
    * `<>`: the repository and remote have diverged (i.e., the repository is both ahead and behind remote)
    * `=`: the repository is up-to-date with the remote
* `short_hash`: First seven digits of the SHA-1 hash.

## Installation

### Dependencies

* [git](https://git-scm.com) with `--porcelain=v2` support, which is available since version 2.11.0.
    You can check if your installation is compatible by executing `git status --branch --porcelain=v2` inside a git repository.
* [awk](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html), which should be preinstalled on any \*nix system

### Manual installation

Clone this repo or download the [git-prompt.zsh](https://raw.githubusercontent.com/telemachus/git-prompt.zsh/master/git-prompt.zsh) file.
Then source it in your `.zshrc`. For example:

```bash
mkdir -p ~/.zsh # or in whatever directory you prefer
git clone --depth=1 https://github.com/telemachus/git-prompt.zsh ~/.zsh/git-prompt.zsh
echo "source ~/.zsh/git-prompt.zsh/git-prompt.zsh" >> .zshrc
```

### Installation as a plugin

I don't use a plugin manager for zshell, so I can't help much here.
If you use a plugin manager, you probably already know what to do.
If not, check out [the original README](https://github.com/woefe/git-prompt.zsh#installation).

## Usage

Unlike other popular prompts this prompt does not use `promptinit`, which gives you the flexibility to build your own prompt from scratch.
You can build a custom prompt by setting the `PROMPT` variable in your `.zshrc` after sourcing `git-prompt.zsh`.
Use `'$(gitprompt)'` in your `PROMPT` to get the git prompt.
You must set your `PROMPT` with **single quotes**, not double quotes, otherwise the git prompt will not update properly.
You can find more information on how to configure the `PROMPT` in [Zsh's online documentation](http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html) or the `zshmisc` manpage, section "SIMPLE PROMPT ESCAPES".

**NOTE**: if you source `git-prompt.zsh` and do not add `$(gitprompt)` somewhere in your `PROMPT` or `RPROMPT`, then `git-prompt.zsh` will enable my default `PROMPT`.
This will *overwrite* your `PROMPT`, and that may not be what you intend.

*tl;dr*—don't source `git-prompt.zsh` unless you want to use it in a prompt.

## Configuration

You can use the following options to configure the behavior of the prompt.

### Show remote name or missing remote

There are two settings for this section.

+ `ZSH_GIT_PROMPT_SHOW_UPSTREAM_NAME`
+ `ZSH_GIT_PROMPT_SHOW_UPSTREAM_MISSING`

`ZSH_GIT_PROMPT_SHOW_UPSTREAM_NAME` determines whether the prompt shows the name of the remote branch.
Since most remote names are boring (e.g., `origin/main`), this option is off by default.
To enable this display, set `ZSH_GIT_PROMPT_SHOW_UPSTREAM_NAME` to any value other than the empty string.

`ZSH_GIT_PROMPT_SHOW_UPSTREAM_MISSING` determines whether the prompt shows a message when there is no remote set.
Since I usually want to know that no remote is set, this option is on by
default.
You can turn off this display by setting `ZSH_GIT_PROMPT_SHOW_UPSTREAM_MISSING` to an empty string.
(See below for how to change the default message shown when no upstream is set.)

### Enable notification of stash state

`ZSH_GIT_PROMPT_SHOW_STASH` determines whether to indicate that the stash is not empty.
Checking the stash may affect performance of the prompt, and so the default is
off.
To enable the check and display of stash status, set `ZSH_GIT_PROMPT_SHOW_STASH` to any value other than an empty string.

If you're curious about performance, here is the explanation.
By default, the script runs only a single git command for each prompt shown.
To check the stash, the script must run a second git command for every prompt.
That said, I haven't noticed a performance hit. But YMMV.

### Disable async behavior

If you are not happy with the asynchronous behavior, you can disable it altogether.
Be warned that this may make your shell painfully slow if you enter large repositories or if your disk is slow.
Set `ZSH_GIT_PROMPT_NO_ASYNC` to anything other than an empty string **before** sourcing `git-prompt.zsh` to disable asynchronous behavior.
`ZSH_GIT_PROMPT_NO_ASYNC` cannot be adjusted in a running shell, but only in your `.zshrc`.

### Change the awk implementation

Some awk implementations are faster than others.
By default, the prompt checks for [nawk](https://github.com/onetrueawk/awk), then [mawk](https://invisible-island.net/mawk/), and finally falls back to the system's default awk.
You can override this behavior by setting `ZSH_GIT_PROMPT_AWK_CMD` to the awk implementation of your liking **before** sourcing the `git-prompt.zsh`.
`ZSH_GIT_PROMPT_AWK_CMD` cannot be adjusted in a running shell, but only in your `.zshrc`.

To benchmark an awk implementation you can use the following command.

```bash
# This example tests the default awk. Change 'awk' to 'nawk', 'mawk', or whatever.
time ZSH_GIT_PROMPT_AWK_CMD=awk zsh -f -c '
    source path/to/git-prompt.zsh
    for i in $(seq 1000); do
        print -P $(_zsh_git_prompt_git_status)
    done'
```

Again, I have not noticed any significant difference between `nawk` and `mawk`, but YMMV.

## Appearance

The appearance of the prompt can be adjusted by changing the variables that start with `ZSH_GIT_PROMPT_THEME`.
Note that some of them are named differently than in the original git prompts by Olivier Verdier or Wolfgang Popp.

You can preview your configuration by setting the `ZSH_GIT_PROMPT_THEME_*` variables in a running shell.
Remember to save them in your `.zshrc` after you tweak them to your liking.
The example below shows the defaults. You can change any of these.

```zsh
# Basics:
## These prefixes will surround the entire prompt.
## Set them to the empty string if you don't want them.
ZSH_GIT_PROMPT_THEME_PREFIX="{"
ZSH_GIT_PROMPT_THEME_SUFFIX="}"
## This controls how each section of the prompt is separated from the next.
ZSH_GIT_PROMPT_THEME_SEPARATOR=" "

# Section one:
## Message to show in case the repo is in detached head state.
ZSH_GIT_PROMPT_THEME_DETACHED="(detached head)"

# Section two:
## Message to show if there is no upstream set.
ZSH_GIT_PROMPT_THEME_UPSTREAM_MISSING="(no upstream set)"

# Section three:
## State of the repo and tracking status symbols.
## These are as in [`git-prompt.sh`](https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh)
ZSH_GIT_PROMPT_THEME_STAGED="+"
ZSH_GIT_PROMPT_THEME_UNSTAGED="*"
ZSH_GIT_PROMPT_THEME_UNTRACKED="%%" # Doubled to escape %
ZSH_GIT_PROMPT_THEME_STASHED="$" # Disabled by default; see above
ZSH_GIT_PROMPT_THEME_BEHIND="<"
ZSH_GIT_PROMPT_THEME_AHEAD=">"
ZSH_GIT_PROMPT_THEME_DIVERGED="<>"
ZSH_GIT_PROMPT_THEME_UP_TO_DATE="="

# Sometime later...
source path/to/git-prompt.zsh
```

## Features / Non-Features

* Uses the shell itself and [awk](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html); no other language or runtime required.
* Provides only git status.
    This prompt only gives you the `gitprompt` function, which you can use to build your own prompt.
* Uses standard git rather than an external git status daemon (e.g., [gitstatus](https://github.com/romkatv/gitstatus)).
* Strives for efficiency; the git command is invoked only once (twice if you enable the `ZSH_GIT_PROMPT_SHOW_STASH` option) and asynchronously when a new prompt is drawn.
* No caching feature, because it breaks reliable detection of untracked files.

## Known issues

* If the current working directory is not a git repository and some external application initializes a new repository in the same directory, the git prompt will not be shown immediately.
    Also, updates made by external programs or another shell do not show up immediately.
    Executing any command or simply pressing enter will fix the issue.
* In large repositories the prompt might slow down, because git has to find untracked files.
    See `man git-status`, Section `--untracked-files` for possible options to speed things up.
