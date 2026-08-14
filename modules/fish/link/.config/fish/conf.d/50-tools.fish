# Third-party tool integration.

# fnm (Fast Node Manager). Replaced nvm; installed by the fnm module.
if type -q fnm
	fnm env --use-on-cd --shell fish | source
end
