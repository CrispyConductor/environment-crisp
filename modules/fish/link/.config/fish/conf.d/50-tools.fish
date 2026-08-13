# Third-party tool integration.

# fnm (Fast Node Manager). Replaced nvm; see doc/ubuntu-setup.md for install.
if type -q fnm
	fnm env --use-on-cd --shell fish | source
end
