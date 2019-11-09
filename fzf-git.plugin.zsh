if [[ $- == *i* ]]; then

__fzf_git_is_in_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

__fzf_git_down() {
  fzf --height 50% --border "$@"
}

__fzf_git_join_lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

__fzf_git_branch() {
  __fzf_git_is_in_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort \
    | __fzf_git_down --ansi --multi --tac --preview-window right:70% \
      --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES \
    | sed 's/^..//' | cut -d' ' -f1 \
    | sed 's#^remotes/##'
}

__fzf_git_tag() {
  __fzf_git_is_in_repo || return
  git tag --sort -version:refname \
    | __fzf_git_down --multi --preview-window right:70% \
      --preview 'git show --color=always {} | head -'$LINES
}

__fzf_git_head() {
  __fzf_git_is_in_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always \
    | __fzf_git_down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
      --header 'Press CTRL-S to toggle sort' \
      --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES \
    | grep -o "[a-f0-9]\{7,\}"
}

__fzf_git_remote() {
  __fzf_git_is_in_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq \
    | __fzf_git_down --tac \
      --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' \
    | cut -d$'\t' -f1
}

__fzf_git_bind_helper() {
  eval "fzf-git-$1-widget() { \
    LBUFFER=\"\${LBUFFER}\$(__fzf_git_$1 | __fzf_git_join_lines)\"; \
    if [[ -z \"\${TMUX}\" ]]; then \
      zle reset-prompt; \
    fi \
  }"
  eval "zle -N fzf-git-$1-widget"
  eval "bindkey '$2' fzf-git-$1-widget"
}

__fzf_git_bind_helper "branch" "^G^B"
__fzf_git_bind_helper "tag" "^G^T"
__fzf_git_bind_helper "head" "^G^H"
__fzf_git_bind_helper "remote" "^G^R"

fi
