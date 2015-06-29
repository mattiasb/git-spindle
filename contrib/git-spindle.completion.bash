#!/bin/bash

# Copyright ⓒ 2015 Mattias Bengtsson
#
# git-spindle is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# git-spindle is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with git-spindle.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Mattias Bengtsson <mattias.jc.bengtsson@gmail.com>

###########
# HELPERS #
###########

# Logging
function __gs_log {
    echo -e $@ >> "${HOME}/git-spindle.log"
}

# I have yet to find out how to make bash completion not fallback to file
# completion when returning an empty COMPREPLY.
# As a workaround return a COMPREPLY with one element: the empty string and
# echo the bel character.
__gs_none () {
    echo -en "\a"
    COMPREPLY=( '' )
}

# A version of _filedir that lets you override $cur
function __gs_filedir {
    local tmp="${cur}"
    cur="${2-$cur}"

    _filedir "${1}"

    cur="${tmp}"
}

# Adapted version of __git_find_on_cmdline from git bash-completion that also
# finds prefixes instead of just full commands. Useful for looking for flags like
# "--what=<something>"
__gs_find_on_cmdline () {
    local word subcommand c=1
    while [ $c -lt $cword ]; do
        word="${words[c]}"
        for subcommand in $1; do
            if [[ "$word" == "${subcommand}"* ]]; then
                echo "$word"
                return
            fi
        done
        ((c++))
    done
}

# TODO: Make this work also when adding flags/params in the middle of the
#       argument list.
function __gs_compappend_once {
    [ -z "${1}" ] && return -1
    [[ "${cur}" == "${1}" ]] && return -1

    if [ -z "$(__gs_find_on_cmdline "${1}")" ]; then
        __gitcompappend "${1}" "${2-}" "${3-$cur}" "${4- }"
        return 0
    fi

    return -1
}

function __gs_comp_once {
    COMPREPLY=()
    __gs_compappend_once "$@"
}

# # Runs _filedir in the top git folder
# # Hopefully not needed because of
# # https://github.com/seveas/git-spindle/issues/82
# function __gs_comp_topdir {
#     local topdir gitdir="$(__gitdir)"
#
#     case "${gitdir}" in
#         */.git)
#             topdir="${gitdir%%.git}"
#             ;;
#         .git)
#             topdir="${PWD}/"
#             ;;
#         *)
#             __gs_none
#             return
#             ;;
#     esac

#     cd "${topdir}"
#     # __gitcomp_file "$(__git_index_files "$1" ${topdir})" "$pfx" "$cur_"
#     # _filedir "$@"
#     __git_complete_index_file "$@"
#     cd ->/dev/null
# }

##########
# GITHUB #
##########

#######################################################################
# TODO                                                                #
# - Complete:                                                         #
#   - pull-requests                                                   #
#   - issues                                                          #
#   - hooks                                                           #
#   - config key/values                                               #
# - longopt completion shouldn't remove flag when completing value    #
#######################################################################

_git_hub () {
    local subcommands="add-account                \
                       add-hook                   \
                       add-public-keys            \
                       add-remote                 \
                       apply-pr                   \
                       browse                     \
                       calendar                   \
                       cat                        \
                       clone                      \
                       config                     \
                       create                     \
                       edit-hook                  \
                       fork                       \
                       forks                      \
                       gist                       \
                       gists                      \
                       hooks                      \
                       ignore                     \
                       issue                      \
                       issues                     \
                       log                        \
                       ls                         \
                       mirror                     \
                       network                    \
                       public-keys                \
                       pull-request               \
                       remove-hook                \
                       render                     \
                       repos                      \
                       say                        \
                       set-origin                 \
                       setup-goblet               \
                       status                     \
                       whoami                     \
                       whois                      "
    local subcommand="$(__git_find_on_cmdline "$subcommands")"
    if [ -z "$subcommand" ]; then
        case "${cur}" in
            --account=*) __gs_none                                        ;;
            --*)         __gs_comp_once       "--account=" "" "${cur}" ""
                         __gs_compappend_once "--help"                    ;;
            *)           __gitcomp            "$subcommands"              ;;
        esac
        return
    fi

    case "$subcommand" in
        add-account)     _git_hub_add_account     ;;
        add-hook)        _git_hub_add_hook        ;;
        add-public-keys) _git_hub_add_public_keys ;;
        add-remote)      _git_hub_add_remote      ;;
        apply-pr)        _git_hub_apply_pr        ;;
        browse)          _git_hub_browse          ;;
        calendar)        _git_hub_calendar        ;;
        cat)             _git_hub_cat             ;;
        clone)           _git_hub_clone           ;;
        config)          _git_hub_config          ;;
        create)          _git_hub_create          ;;
        edit-hook)       _git_hub_edit_hook       ;;
        fork)            _git_hub_fork            ;;
        forks)           _git_hub_forks           ;;
        gist)            _git_hub_gist            ;;
        gists)           _git_hub_gists           ;;
        hooks)           _git_hub_hooks           ;;
        ignore)          _git_hub_ignore          ;;
        issue)           _git_hub_issue           ;;
        issues)          _git_hub_issues          ;;
        log)             _git_hub_log             ;;
        ls)              _git_hub_ls              ;;
        mirror)          _git_hub_mirror          ;;
        network)         _git_hub_network         ;;
        public-keys)     _git_hub_public_keys     ;;
        pull-request)    _git_hub_pull_request    ;;
        remove-hook)     _git_hub_remove_hook     ;;
        render)          _git_hub_render          ;;
        repos)           _git_hub_repos           ;;
        say)             _git_hub_say             ;;
        set-origin)      _git_hub_set_origin      ;;
        setup-goblet)    _git_hub_setup_goblet    ;;
        status)          _git_hub_status          ;;
        whoami)          _git_hub_whoami          ;;
        whois)           _git_hub_whois           ;;
        *)               __gs_none                ;;
    esac
}

####################
# GITHUB — HELPERS #
####################

function __gs_gh_account {
    local ddaccount=$(__gs_find_on_cmdline "--account=")
    git hub $ddaccount config user 2>/dev/null || echo ""
}

function __gs_gh_comp_browse_section {
    local sections="issues       \
                    pulls        \
                    wiki         \
                    branches     \
                    releases     \
                    contributors \
                    graphs       \
                    releases     \
                    settings     "

    __gs_comp_once "${sections}" && return 0 || return -1
}

function __gs_gh_comp_issues_filter () {
    local filters="assignee     \
                   labels       \
                   mentioned    \
                   number       \
                   direction    \
                   milestone    \
                   since        \
                   sort         \
                   state        "
    local diropts="asc desc"
    local stateopts="all open closed"
    local sortopts="created updated comments created"

    case "$cur" in
        direction=*) __gitcomp "${diropts}"   "" "${cur##direction=}" ;;
        state=*)     __gitcomp "${stateopts}" "" "${cur##state=}"     ;;
        sort=*)      __gitcomp "${sortopts}"  "" "${cur##sort=}"      ;;
        assignee=*|milestone=*|mentioned=*|labels=*|since=*|number=*) __gs_none ;;
        *)           __gitcompappend "${filters}" "" "${cur}" "=" ;;
    esac
}

declare -A __gs_gh_users_cache
function __gs_gh_compappend_users {
    local account="$(__gs_gh_account)"

    test -z "${account}" && return -1

    if [ -z "${__gs_gh_users_cache[$account]}" ]; then
        __gs_gh_users_cache[$account]="$(git hub following 2>/dev/null && echo $account)"
    fi

    __gitcompappend "${__gs_gh_users_cache[$account]}" "${1-}" "${2-$cur}" "${3- }"
}

function __gs_gh_comp_users {
    COMPREPLY=()
    __gs_gh_compappend_users "$@"
}

declare -A __gs_gh_repos_cache
function __gs_gh_compappend_repos {
    local user="${1-$(__gs_gh_account)}"

    test -z "${user}" && return -1

    if [[ -z "${__gs_gh_repos_cache[$user]}" ]]; then
        __gs_gh_repos_cache[$user]="$(git hub repos --no-forks $user 2>/dev/null | sed -n -e 's/ .*//p' | grep -v '\/')"
    fi

    __gitcomp_nl_append "${__gs_gh_repos_cache[$user]}" "${2-}" "${3-$cur}" "${4- }"
}

function __gs_gh_comp_repo {
    case "$cur" in
        */*)
            local user="${cur%%/*}"
            __gs_gh_compappend_repos $user "$user/" "${cur##*/}" " "
            ;;

        *)
            __gs_gh_compappend_users "" "${cur}" "/"
            __gs_gh_compappend_repos
            ;;
    esac
}

#####################
# GITHUB — COMMANDS #
#####################

# git hub add-account [--host=<host>] <alias>
function _git_hub_add_account () {
    case "$cur" in
        --host=*) _known_hosts_real "${cur##--host=}"                  ;;
        --*)      __gs_comp_once "--host=" "" "${cur}" "" || __gs_none ;;
        *)        __gs_none                                            ;;
    esac
}

# git hub add-hook <name> [<setting>...]
function _git_hub_add_hook () {
    # TODO: #1 Read up on hooks
    __gs_none
}

# git hub add-public-keys [<key>...]
function _git_hub_add_public_keys () {
    _filedir '@(pub)'
    return
}

# git hub add-remote [--ssh|--http|--git] <user>...
function _git_hub_add_remote () {
    if [ "${cur}" == --* ]; then
        __gs_comp_once "--ssh --http --git"  || __gs_none
        return
    fi

    __gs_gh_comp_users || __gs_none
}

# git hub apply-pr <pr-number>
function _git_hub_apply_pr () {
    # TODO: #8 Complete pull requests
    __gs_none
}

# git hub browse [--parent] [<repo>] [<section>]
function _git_hub_browse () {
    if [[ "${prev}" != ?(browse|--parent) ]]; then
        __gs_gh_comp_browse_section || __gs_none
        return
    fi

    case "$cur" in
        --*) __gs_comp_once "--parent" || __gs_none;;
        *)   __gs_gh_comp_repo ;;
    esac
}

# git hub calendar [<user>]
function _git_hub_calendar () {
    if [[ "${prev}" != calendar ]]; then
        __gs_none
        return
    fi

    __gs_gh_comp_users || __gs_none
}

# git hub cat <file>...
function _git_hub_cat () {
    __git_complete_index_file ""
    return
}

# git hub clone [--ssh|--http|--git]
#               [--parent]
#               [git-clone-options] <repo> [<dir>]
function _git_hub_clone () {
    if [[ "${prev}" != ?(--*|clone) ]]; then
        _filedir -d
        return
    fi

    case "$cur" in
        --*) _git_clone
             __gs_compappend_once "--ssh --http --git"
             __gs_compappend_once "--parent"           ;;
        *) __gs_gh_comp_repo                           ;;
    esac
}

# git hub config [--unset] <key> [<value>]
function _git_hub_config () {
    # TODO: #2 Complete config key/values
    case "$cur" in
        --*) __gs_comp_once "--unset" || __gs_none ;;
        *)  __gs_none                              ;;
    esac
}

# git hub create [--private] [-d <description>]
function _git_hub_create () {
    case "$cur" in
        --*) __gs_compappend_once "--private" ;;
        -*)  __gs_compappend_once "-d"
             __gs_compappend_once "--private" ;;
        *)   __gs_none                        ;;
    esac
}

# git hub edit-hook <name> [<setting>...]
function _git_hub_edit_hook () {
    # TODO: #1 Read up on hooks
    __gs_none
}

# git hub fork [--ssh|--http|--git] [<repo>]
function _git_hub_fork () {
    if [[ "${prev}" != ?(--*|fork) ]]; then
        __gs_none
        return
    fi

    case "$cur" in
        --*) __gs_comp_once "--ssh --http --git" || __gs_none ;;
        *)   __gs_gh_comp_repo                                ;;
    esac
}

# git hub forks [<repo>]
function _git_hub_forks () {
    if [[ "${prev}" != forks ]]; then
        __gs_none
        return
    fi

    __gs_gh_comp_repo
}

# git hub gist [-d <description>] <file>...
function _git_hub_gist () {
    case "${prev}" in
        gist) [[ "$cur" == -* ]] && __gs_comp_once "-d" ;;
        -d)   __gs_none                                 ;;
    esac
}

# git hub gists [<user>]
function _git_hub_gists () {
    __gs_gh_comp_users || __gs_none
}

# git hub hooks
function _git_hub_hooks () {
    # TODO: #1 Read up on hooks
    __gs_none
}

# git hub ignore [<language>...]
function _git_hub_ignore () {
    if [ -z "${__git_hub_ignore_cache}" ]; then
        __git_hub_ignore_cache="$(git hub ignore 2>/dev/null | sed -n -e 's/  \* //p')"
    fi

    __gitcomp_nl "${__git_hub_ignore_cache}"
}

# git hub issue [<repo>] [--parent] [<issue>...]
function _git_hub_issue () {
    if [[ "${prev}" != ?(--parent|issue) ]]; then
        #  TODO: #4 Complete issue number
        __gs_none
        return
    fi

    case "$cur" in
        --*) __gs_comp_once "--parent" ;;
        *)   __gs_gh_comp_repo         ;;
    esac
}

# git hub issues [<repo>] [--parent] [<filter>...]
function _git_hub_issues () {
    if [[ "${prev}" != ?(--parent|issues) ]]; then
        __gs_gh_comp_issues_filter
        return
    fi

    case "$cur" in
        --*) __gs_comp_once "--parent" || __gs_none ;;
        *)   __gs_gh_comp_repo         || __gs_none ;;
    esac
}

# git hub log [--type=<type>] [<what>]
function _git_hub_log () {
    #  TODO: Complete <what> (repo, user and org?)
    local log_types="CommitComment                \
                     Create                       \
                     Delete                       \
                     Download                     \
                     Follow                       \
                     Fork                         \
                     ForkApply                    \
                     Gist                         \
                     Gollum                       \
                     IssueComment                 \
                     Issues                       \
                     Member                       \
                     Public                       \
                     PullRequestReviewComment     \
                     PullRequest                  \
                     Push                         \
                     Release                      \
                     Status                       \
                     TeamAdd                      \
                     Watch                        \
                     GistHistory                  "
    case "$cur" in
        --type=*) __gitcomp "${log_types}" "" "${cur##--type=}"              ;;
        --*)      __gs_comp_once "--type=" "" "${cur}" ""       || __gs_none ;;
        *)        __gs_none                                                  ;;
    esac
}

# git hub ls <dir>...
function _git_hub_ls () {
    # FIXME: Only complete dirs in index
    __git_complete_index_file ""
}

# git hub mirror [--ssh|--http|--git] [--goblet] [<repo>]
function _git_hub_mirror () {
    if [[ "${prev}" != ?(--*|mirror) ]]; then
        __gs_none
        return
    fi

    case "$cur" in
        --*) __gs_compappend_once "--ssh --http --git"
             __gs_compappend_once "--goblet"           ;;
        *)  __gs_gh_comp_repo                          ;;
    esac
}

# git hub network [<level>]
function _git_hub_network () {
    __gs_none
}

# git hub public-keys [<user>]
function _git_hub_public_keys () {
    if [[ "${prev}" != public-keys ]]; then
        __gs_none
        return
    fi

    __gs_gh_comp_users || __gs_none
}

# git hub pull-request [--issue=<issue>] [<branch1:branch2>]
function _git_hub_pull_request () {
    if [[ "${prev}" != ?(--issue=*|pull-request) ]]; then
        __gs_none
        return
    fi

    case "$cur" in
        # TODO: #4 Complete issue number
        --issue=*) __gs_none                                             ;;
        --*)       __gs_comp_once "--issue=" "" "${cur}" "" || __gs_none ;;
        *:*)       __gitcomp_nl "$(__git_refs)" "" "${cur##*:}" " "      ;;
        *)         __gitcomp_nl "$(__git_refs)" "" "${cur}"     ""       ;;
    esac
}

# git hub remove-hook <name>
function _git_hub_remove_hook () {
    # TODO: #1 Read up on hooks
    __gs_none
}

# git hub render [--save=<outfile>] <file>
function _git_hub_render () {
    case "$cur" in
        --save=*) __gs_filedir '@(htm|html)' "${cur##--save=}" ;;
        --*)      __gs_comp_once "--save=" "" "${cur}" ""      ;;
        *)        _filedir '@(md|markdown)'                    ;;
    esac
}

# git hub repos [--no-forks] [<user>]
function _git_hub_repos () {
    if [[ "${prev}" != ?(--no-forks|repos) ]]; then
        __gs_none
        return
    fi

    case "${cur}" in
        --*) __gs_comp_once "--no-forks" || __gs_none ;;
        *)   __gs_gh_comp_users          || __gs_none ;;
    esac
}

# git hub say [<msg>]
function _git_hub_say () {
    __gs_none
}

# git hub set-origin [--ssh|--http|--git]
function _git_hub_set_origin () {
    if [[ "$cur" != --* ]]; then
        __gs_none
        return
    fi

    __gs_comp_once "--ssh --http --git" || __gs_none
}

# git hub setup-goblet
function _git_hub_setup_goblet () {
    __gs_none
}

# git hub status
function _git_hub_status () {
    __gs_none
}

# git hub whoami
function _git_hub_whoami () {
    __gs_none
}

# git hub whois <user>...
function _git_hub_whois () {
    __gs_gh_comp_users || __gs_none
}
