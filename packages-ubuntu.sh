packages="
zsh
curl
gawk
tmux
neovim
git
command-not-found
ripgrep
"

# Old:
# realpath (included by default now)

lst=''
for p in $packages; do
	lst="$lst $p"
done

sudo apt-get install $lst

