#!/usr/bin/env bash
set -e

echo "=============================="
echo "Bootstrapping Dev Environment"
echo "=============================="

BASE="$HOME/.local"
BIN="$BASE/bin"
SRC="$BASE/src"

mkdir -p "$BIN"
mkdir -p "$SRC"

export PATH="$BIN:$PATH"

#################################
# GO ENVIRONMENT
#################################
clear
echo "Configuring Go environment..."

GO_ENV='
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export GOMODCACHE="$HOME/go/pkg/mod"
export PATH="$GOBIN:$HOME/.local/bin:$PATH"
'

mkdir -p "$HOME/go/bin"
mkdir -p "$HOME/go/pkg"
mkdir -p "$HOME/go/src"

if ! grep -q "GOPATH" "$HOME/.bashrc"; then
    echo "$GO_ENV" >> "$HOME/.bashrc"
fi

# Set variables for the current script session
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export GOMODCACHE="$HOME/go/pkg/mod"
export PATH="$GOBIN:$BIN:$PATH"

#################################
# GO TOOLS
#################################
echo "Installing Go tools..."
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest

#################################
# INSTALL HomeBrew (No Sudo)
#################################
echo "--- Setting up Homebrew ---"
mkdir -p ~/.linuxbrew/Homebrew
mkdir -p ~/.linuxbrew/bin

# Network Stability Fixes
echo "--http1.1" > ~/.curlrc
export HOMEBREW_CURL_RETRIES=10

if [ ! -d "$HOME/.linuxbrew/Homebrew/.git" ]; then
    echo "--- Cloning Homebrew ---"
    git clone --depth=1 https://github.com/Homebrew/brew ~/.linuxbrew/Homebrew
fi

ln -sf ../Homebrew/bin/brew ~/.linuxbrew/bin/brew

if ! grep -q "linuxbrew/bin/brew shellenv" ~/.bashrc; then
    echo 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
fi

# CRITICAL: Activate brew for the rest of this script
eval "$($HOME/.linuxbrew/bin/brew shellenv)"

#################################
# INSTALL TOOLS VIA BREW
#################################
echo "Installing Neovim, Ripgrep, fd, and fzf..."
brew install neovim ripgrep fd fzf

#################################
# INSTALL LAZYVIM
#################################
echo "Installing LazyVim..."
NVIM_CONFIG="$HOME/.config/nvim"

if [ ! -d "$NVIM_CONFIG" ]; then
    git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
    rm -rf "$NVIM_CONFIG/.git"
fi

#################################
# ENABLE LANGUAGE SUPPORT
#################################
mkdir -p "$NVIM_CONFIG/lua/plugins"

cat <<EOF > "$NVIM_CONFIG/lua/plugins/lang.lua"
return {
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "gopls",
        "pyright",
        "jdtls",
      },
    },
  },
}
EOF

echo "================================"
echo "Environment Ready"
echo "================================"
echo "Run: source ~/.bashrc && nvim"