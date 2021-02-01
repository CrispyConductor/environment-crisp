packages="
zsh
curl
gawk
tmux
neovim
python3-pip
git
command-not-found
ripgrep
universal-ctags
"

# Old:
# realpath (included by default now)

lst=''
for p in $packages; do
	lst="$lst $p"
done

sudo apt-get install $lst

