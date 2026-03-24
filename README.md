```bash
curl --fail-with-body -L https://github.com/audivir/zshrc/raw/refs/heads/main/install.sh | sh

# add to .bashrc
export PATH="$PATH:$HOME/.local/bin"
if command zsh --help; then
    exec zsh "$@"
fi
```
