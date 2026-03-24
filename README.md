```bash
curl --fail-with-body -L https://github.com/audivir/zshrc/raw/refs/heads/main/install.sh | sh

# add to .bashrc
export PATH="$PATH:$HOME/.local/bin"
if command zsh --help; then
    exec zsh "$@"
fi

# convert bash history to zsh
cat ~/.bash_history | python3 \
    <(curl --fail-with-body -L https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/bash-to-zsh-hist.py) \
    >>"$HISTFILE"
```
