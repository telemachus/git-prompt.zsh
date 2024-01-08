# git-prompt.zsh -- a lightweight git prompt for zsh.
# Copyright © 2023 Peter Aronoff
# Copyright © 2023 Wolfgang Popp
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local -A git_prompt
git_prompt=(
    # Configuration
    show_upstream_name ""
    show_upstream_missing "yes"
    no_async ""
    awk_cmd ""
    # Appearance
    theme_prefix "/"
    theme_suffix "/"
    theme_separator " "
    theme_detached "(detached head)"
    theme_upstream_missing "(No upstream repo)"
    theme_behind "<"
    theme_ahead ">"
    theme_diverged "<>"
    theme_up_to_date "="
    theme_staged "+"
    theme_unstaged "*"
    theme_stashed "%%"
)

# Disable promptinit if it is loaded
(( $+functions[promptinit] )) && {promptinit; prompt off}

# Allow parameter and command substitution in the prompt
setopt PROMPT_SUBST

# Override PROMPT if it does not use the newprompt function
[[ "$PROMPT" != *newprompt* && "$RPROMPT" != *newprompt* ]] \
    && PROMPT='%3~ $(newprompt)%# '

# Find an awk implementation
# Prefer nawk over mawk and mawk over awk
(( $+commands[mawk] ))  &&  : "${git_prompt[awk_cmd]:=mawk}"
(( $+commands[nawk] ))  &&  : "${git_prompt[awk_cmd]:=nawk}"
                            : "${git_prompt[awk_cmd]:=awk}"

function _zsh_git_prompt_git_status() {
    emulate -L zsh
    {
        command git --no-optional-locks status --branch --porcelain=v2 \
            --show-stash 2>&1 || echo "fatal: git command failed"
    } | $ZSH_GIT_PROMPT_AWK_CMD \
        -v SHOW_UPSTREAM_NAME="${git_prompt[show_upstream_name]}" \
        -v SHOW_UPSTREAM_MISSING="${git_prompt[show_upstream_missing]}" \
        -v THEME_PREFIX="${git_prompt[theme_prefix]}" \
        -v THEME_SUFFIX="${git_prompt[theme_suffix]}" \
        -v THEME_SEPARATOR="${git_prompt[theme_separator]}" \
        -v THEME_DETACHED="${git_prompt[theme_detached]}" \
        -v THEME_UPSTREAM_MISSING="${git_prompt[theme_upstream_missing]}" \
        -v THEME_BEHIND="${git_prompt[theme_behind]}" \
        -v THEME_AHEAD="${git_prompt[theme_ahead]}" \
        -v THEME_DIVERGED="${git_prompt[theme_diverged]}" \
        -v THEME_UP_TO_DATE="${git_prompt[theme_up_to_date]}" \
        -v THEME_STAGED="${git_prompt[theme_staged]}" \
        -v THEME_UNSTAGED="${git_prompt[theme_unstaged]}" \
        -v THEME_UNTRACKED="${git_prompt[theme_untracked]}" \
        -v THEME_STASHED="${git_prompt[theme_stashed]}" \
        '
            BEGIN {
                ORS = "";

                fatal = 0;
                oid = "";
                head = "";
                upstream = "";
                ahead = 0;
                behind = 0;
                untracked = 0;
                unmerged = 0;
                staged = 0;
                unstaged = 0;
                stashed = 0;
            }

            $1 == "fatal:" {
                fatal = 1;
            }

            $2 == "branch.oid" {
                oid = $3;
            }

            $2 == "branch.head" {
                head = $3;
            }

            $2 == "branch.upstream" {
                upstream = $3;
            }

            $2 == "branch.ab" {
                ahead = $3;
                behind = $4;
            }

            $1 == "?" {
                ++untracked;
            }

            $1 == "u" {
                ++unmerged;
            }

            $1 == "1" || $1 == "2" {
                split($2, arr, "");
                if (arr[1] != ".") {
                    ++staged;
                }
                if (arr[2] != ".") {
                    ++unstaged;
                }
            }

            $2 == "stash" {
                stashed = $3;
            }

            END {
                if (fatal == 1) {
                    exit(1);
                }

                # Start of git information
                print THEME_PREFIX;

                # Section one: branch_name
                if (head == "(detached)") {
                    print THEME_DETACHED;
                } else {
                    gsub("%", "%%", head);
                    print head;
                }
                print THEME_SEPARATOR;

                # Section two: upstream
                if (SHOW_UPSTREAM_NAME != "" && length(upstream) > 0) {
                    gsub("%", "%%", upstream);
                    print upstream;
                    print THEME_SEPARATOR;
                }
                if (SHOW_UPSTREAM_MISSING != "" && length(upstream) == 0) {
                    print THEME_UPSTREAM_MISSING;
                    print THEME_SEPARATOR;
                }

                # Section three: repository_state_and_tracking_status
                if (staged > 0) {
                    print THEME_STAGED;
                }
                if (unstaged > 0) {
                    print THEME_UNSTAGED;
                }
                if (untracked > 0) {
                    print THEME_UNTRACKED;
                }
                if (stashed > 0) {
                    print THEME_STASHED;
                }
                if (behind < 0 && ahead > 0) {
                    print THEME_DIVERGED;
                } else if (ahead > 0) {
                    print THEME_AHEAD;
                } else if (behind < 0) {
                    print THEME_BEHIND;
                } else {
                    print THEME_UP_TO_DATE;
                }
                print THEME_SEPARATOR;

                # Section four: hash
                print substr(oid, 0, 7);

                # End of git information
                print THEME_SUFFIX;
            }
        '
}


# The async code is taken from
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/src/async.zsh

zmodload zsh/system

function _zsh_git_prompt_async_request() {
    typeset -g _ZSH_GIT_PROMPT_ASYNC_FD _ZSH_GIT_PROMPT_ASYNC_PID

    # If we've got a pending request, cancel it
    if [[ -n "$_ZSH_GIT_PROMPT_ASYNC_FD" ]] && { true <&$_ZSH_GIT_PROMPT_ASYNC_FD } 2>/dev/null;
    then

        # Close the file descriptor and remove the handler
        exec {_ZSH_GIT_PROMPT_ASYNC_FD}<&-
        zle -F $_ZSH_GIT_PROMPT_ASYNC_FD

        # Zsh will make a new process group for the child process only if job
        # control is enabled (MONITOR option)
        if [[ -o MONITOR ]]; then
            # Send the signal to the process group to kill any processes that
            # may have been forked by the suggestion strategy
            kill -TERM -$_ZSH_GIT_PROMPT_ASYNC_PID 2>/dev/null
        else
            # Kill just the child process since it wasn't placed in a new
            # process group. If the suggestion strategy forked any child
            # processes they may be orphaned and left behind.
            kill -TERM $_ZSH_GIT_PROMPT_ASYNC_PID 2>/dev/null
        fi
    fi

    # Fork a process to fetch the git status and open a pipe to read from it
    exec {_ZSH_GIT_PROMPT_ASYNC_FD}< <(
        # Tell parent process our pid
        builtin echo $sysparams[pid]

        _zsh_git_prompt_git_status
    )

    # There's a weird bug here where ^C stops working unless we force a fork
    # See https://github.com/zsh-users/zsh-autosuggestions/issues/364
    command true

    # Read the pid from the child process
    read _ZSH_GIT_PROMPT_ASYNC_PID <&$_ZSH_GIT_PROMPT_ASYNC_FD

    # When the fd is readable, call the response handler
    zle -F "$_ZSH_GIT_PROMPT_ASYNC_FD" _zsh_git_prompt_callback
}

# Called when new data is ready to be read from the pipe
# First arg will be fd ready for reading
# Second arg will be passed in case of error
_ZSH_GIT_PROMPT_STATUS_OUTPUT=""
function _zsh_git_prompt_callback() {
    emulate -L zsh
    local old_primary="$_ZSH_GIT_PROMPT_STATUS_OUTPUT"
    local fd_data
    local -a output

    if [[ -z "$2" || "$2" == "hup" ]]; then
        # Read output from fd
        fd_data="$(cat <&$1)"
        output=( ${fd_data} )
        _ZSH_GIT_PROMPT_STATUS_OUTPUT="${output[1]}"

        if [[ "$old_primary" != "$_ZSH_GIT_PROMPT_STATUS_OUTPUT" ]]; then
            zle reset-prompt
            zle -R
        fi

        # Close the fd
        exec {1}<&-
    fi

    # Always remove the handler
    zle -F "$1"

    # Unset global FD variable to prevent closing user created FDs in the
    # precmd hook
    unset _ZSH_GIT_PROMPT_ASYNC_FD
}

function _zsh_git_prompt_precmd_hook() {
    _zsh_git_prompt_async_request
}

if (( $+commands[git] )); then
    if [[ -z "$ZSH_GIT_PROMPT_NO_ASYNC" ]]; then
        autoload -U add-zsh-hook \
            && add-zsh-hook precmd _zsh_git_prompt_precmd_hook

        function newprompt() {
            echo -n "$_ZSH_GIT_PROMPT_STATUS_OUTPUT"
        }
    else
        function newprompt() {
            _zsh_git_prompt_git_status
        }
    fi
else
    function newprompt() { }
fi
