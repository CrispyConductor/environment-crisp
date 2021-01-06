packages="
zsh
curl
tmux
neovim
git
command-not-found
"

# Old:
# realpath (included by default now)

lst=''
for p in $packages; do
	lst="$lst $p"
done

sudo apt-get install $lst

