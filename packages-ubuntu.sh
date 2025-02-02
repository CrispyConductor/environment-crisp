packages="
fish
zsh
curl
gawk
tmux
neovim
python3-pip
python3-pynvim
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

