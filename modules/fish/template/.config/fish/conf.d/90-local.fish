# Machine-specific fish settings and overrides.
#
# This file is created once by the installer and then left alone - it is not
# tracked in the dotfiles repo and will never be overwritten, so it is the
# right place for anything that should not be committed.
#
# It sorts last in conf.d/, and config.fish is deliberately empty, so whatever
# you set here overrides the repo defaults.
#
# Examples:
#
#   set -gx ANTHROPIC_API_KEY 'sk-ant-...'
#   set -gx OPENAI_API_KEY 'sk-...'
#   fish_add_path -g /opt/some-tool/bin
#   set -g fish_color_host brcyan
#
# The bash/zsh equivalent is ~/.shellrc-local.
