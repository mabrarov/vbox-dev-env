function view_md { pandoc "$1" | lynx -stdin; }
export -f view_md
function set_java_home {
  export JAVA_HOME="$1"
  export PATH="${JAVA_HOME}/bin:${PATH}"
}
export -f set_java_home
alias d="docker"
alias di="docker images"
alias dps="docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias drma="docker ps -aq | xargs -r -I{} docker rm -f {}"
alias drmi="docker rmi"
alias drmid="docker images -aq -f dangling=true | xargs -r -I{} docker rmi -f {}"
alias gitclean="echo 'Removing files not tracked by git except files in .idea and .vs directories, *.iml, *.iws and *.ipr files...' && git clean -fdx -e \".idea/\" -e \".vs/\" -e \"*.iml\" -e \"*.iws\" -e \"*.ipr\" > /dev/null && echo '...finished'"
alias lsk="eval \"\$(ssh-agent -s)\" && ssh-add  ~/.ssh/\"\$([[ -f ~/.ssh/id_ed25519 ]] && echo \"id_ed25519\" || echo \"id_rsa\")\""
alias j8="set_java_home /opt/jdk"
alias j11="set_java_home /opt/jdk-11"
alias j17="set_java_home /opt/jdk-17"
