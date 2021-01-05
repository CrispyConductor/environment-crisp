
local user='%{$fg[magenta]%}%n@%{$fg[magenta]%}%m%{$reset_color%}'
local pwd='%{$fg[blue]%}%3~%{$reset_color%}'
local return_code='%(?.%{$fg[green]%}✔.%{$fg[red]%}↵%?)%{$reset_color%}'
local time_info='%{$FG[240]%}%T%{$reset_color%}'
local git_branch='%{$reset_color%}$(git_prompt_info)$(git_prompt_status)%{$reset_color%}'
local prompt_char='%(!.#.$)'

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}✹"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_GIT_PROMPT_ADDED=""
ZSH_THEME_GIT_PROMPT_MODIFIED=""
ZSH_THEME_GIT_PROMPT_DELETED=""
ZSH_THEME_GIT_PROMPT_RENAMED=""
ZSH_THEME_GIT_PROMPT_UNMERGED=""
ZSH_THEME_GIT_PROMPT_UNTRACKED=""
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[blue]%}✚"

PROMPT="${user} ${pwd}${prompt_char} "
RPROMPT="${return_code}${git_branch} ${time_info}"

