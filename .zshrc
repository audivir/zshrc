# BEGIN ANSIBLE MANAGED BLOCK <oh-my-zsh>
export ZSH="$HOME/.config/ohmyzsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
ZSH_CACHE="$HOME/.cache/zsh"
ZSH_COMPDUMP="$ZSH_CACHE/zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME="robbyrussell"
HISTFILE="$ZSH_CACHE/zsh_history"
mkdir -p "$ZSH_CACHE"
source "$ZSH/oh-my-zsh.sh"
# END ANSIBLE MANAGED BLOCK <oh-my-zsh>

# BEGIN ANSIBLE MANAGED BLOCK <homebrew>
# eval "$(/opt/homebrew/bin/brew shellenv)"
# alias homebrewupdate='brew update && brew upgrade --formulae && brew cu --yes && cd /opt/homebrew && git stash pop &>/dev/null || true && cd -'
# END ANSIBLE MANAGED BLOCK <homebrew>

# BEGIN ANSIBLE MANAGED BLOCK <path>
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
# END ANSIBLE MANAGED BLOCK <path>

# BEGIN ANSIBLE MANAGED BLOCK <XDG>
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_STATE_HOME="$HOME/.local/state"
# END ANSIBLE MANAGED BLOCK <XDG>

# BEGIN ANSIBLE MANAGED BLOCK <micromamba>
# alias conda='micromamba'
# eval "$(micromamba shell hook --shell zsh)"
# export MAMBA_ROOT_PREFIX="$HOME/.local/share/micromamba"
# END ANSIBLE MANAGED BLOCK <micromamba>

# BEGIN ANSIBLE MANAGED BLOCK <go>
# export GOPATH="$HOME/.local/share/go"
# if [ -d "$HOME/.local/share/go/bin" ] ; then
#     PATH="$HOME/.local/share/go/bin:$PATH"
# fi
# END ANSIBLE MANAGED BLOCK <go>

eval "$($HOME/.local/bin/uvc shell zsh)"
