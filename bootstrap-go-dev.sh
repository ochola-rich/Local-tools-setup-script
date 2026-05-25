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
echo "Installing Brave-Browser"
# 1. Back to applications folder and clean up any broken error pages
mkdir -p ~/Applications
cd ~/Applications
rm -rf opt/ debian-binary control.tar.xz data.tar.xz brave-browser*

# 2. Extract the actual download URL for the absolute latest stable release package dynamically
LATEST_URL=$(curl -s https://brave-browser-apt-release.s3.brave.com/dists/stable/main/binary-amd64/Packages | grep -E '^Filename: pool/' | head -n 1 | awk '{print $2}')

# 3. Pull down the clean package file directly
curl -L -o brave-latest.deb "https://brave-browser-apt-release.s3.brave.com/$LATEST_URL"

# 4. Unpack the production archive binaries safely
ar x brave-latest.deb
tar -xf data.tar.xz

# 5. Drop the temporary archive payloads to keep your user directory clean
rm -f control.tar.xz data.tar.xz debian-binary brave-latest.deb
echo "alias brave='~/Applications/opt/brave.com/brave/brave-browser --no-sandbox &'" >> ~/.bashrc && source ~/.bashrc
mkdir -p ~/.local/share/applications

cat << 'EOF' > ~/.local/share/applications/brave-local.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Brave Browser (Local)
Comment=Web Browser
Exec=/home/riotieno/Applications/opt/brave.com/brave/brave-browser --no-sandbox %U
Icon=/home/riotieno/Applications/opt/brave.com/brave/product_logo_128.png
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;
EOF

# Make the desktop entry executable
chmod +x ~/.local/share/applications/brave-local.desktop

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