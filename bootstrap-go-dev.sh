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

export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"
export GOMODCACHE="$HOME/go/pkg/mod"
export PATH="$GOBIN:$BIN:$PATH"

#################################
# INSTALL GO
#################################
clear
echo "Installing Go..."

GO_VERSION="1.22.3"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"

if ! command -v go &> /dev/null; then

cd "$SRC"

curl -LO https://go.dev/dl/$GO_TAR

rm -rf "$BASE/go"

tar -C "$BASE" -xzf "$GO_TAR"

export PATH="$BASE/go/bin:$PATH"

if ! grep -q ".local/go/bin" "$HOME/.bashrc"; then
echo 'export PATH="$HOME/.local/go/bin:$PATH"' >> "$HOME/.bashrc"
fi

fi

#################################
# GO TOOLS
#################################

# echo "Installing Go tools..."

go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest

#################################
# INSTALL PYTHON TOOLS
#################################
clear
echo "Installing portable Python..."

PY_VERSION="3.12.3"
cd "$SRC"

curl -LO https://www.python.org/ftp/python/$PY_VERSION/Python-$PY_VERSION.tgz
tar -xzf Python-$PY_VERSION.tgz

cd Python-$PY_VERSION

./configure --prefix=$HOME/.local/python --enable-optimizations
make -j$(nproc)
make install
export PATH="$HOME/.local/python/bin:$PATH"
echo 'export PATH="$HOME/.local/python/bin:$PATH"' >> ~/.bashrc

#################################
# INSTALL JAVA
#################################

echo "Installing OpenJDK..."

JDK_VERSION="21"

cd "$SRC"

curl -LO https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz

tar -xzf jdk-21_linux-x64_bin.tar.gz

mv jdk-21* "$BASE/jdk"

if ! grep -q "JAVA_HOME" "$HOME/.bashrc"; then
echo 'export JAVA_HOME="$HOME/.local/jdk"' >> "$HOME/.bashrc"
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi

export JAVA_HOME="$BASE/jdk"
export PATH="$JAVA_HOME/bin:$PATH"

#################################
# INSTALL NEOVIM
#################################

cd ~/.local/src

curl -fL -o nvim.tar.gz \
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.6/nvim-linux-x86_64.tar.gz
tar xzf nvim.tar.gz

mv nvim-linux64 ~/.local/nvim

ln -sf ~/.local/nvim/bin/nvim ~/.local/bin/nvim

#################################
# INSTALL RIPGREP
#################################

echo "Installing ripgrep..."

if ! command -v rg &> /dev/null; then

cd "$SRC"

curl -LO https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-aarch64-unknown-linux-gnu.tar.gz

tar xzf ripgrep-*.tar.gz

cp ripgrep*/rg "$BIN"

fi

#################################
# INSTALL FD
#################################

echo "Installing fd..."

if ! command -v fd &> /dev/null; then

cd "$SRC"

curl -LO https://github.com/sharkdp/fd/releases/download/v10.3.0/fd-v10.3.0-aarch64-unknown-linux-gnu.tar.gz

tar xzf fd-*.tar.gz

cp fd*/fd "$BIN"

fi

#################################
# INSTALL FZF
#################################

echo "Installing fzf..."

if [ ! -d "$HOME/.fzf" ]; then

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

fi

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

#################################
# FINISH
#################################

echo ""
echo "================================"
echo "Environment Ready"
echo "================================"
echo ""

echo "Reload shell:"
echo "source ~/.bashrc"

echo ""
echo "Run:"
echo "nvim"
echo ""
echo "LazyVim will install plugins automatically."