# setup-scrt

Bootstrap script for a local developer environment focused on Go, Python, Java, and Neovim (LazyVim).

## Script

- `bootstrap-go-dev.sh`

## What it does

The script installs and configures the following under `~/.local` (and related paths):

- Go `1.22.3` (if `go` is not already installed)
- Go tools:
  - `gopls`
  - `goimports`
  - `dlv`
- Python `3.12.3` from source (portable install to `~/.local/python`)
- OpenJDK 21 (Oracle tarball, extracted to `~/.local/jdk`)
- Neovim `v0.11.6`
- CLI tools:
  - `ripgrep` (`rg`)
  - `fd`
  - `fzf`
- LazyVim starter config at `~/.config/nvim`
- LazyVim plugin file for language support (`gopls`, `pyright`, `jdtls`)

It also appends environment variables to `~/.bashrc` for:

- `GOPATH`, `GOBIN`, `GOMODCACHE`
- Go binary path (`~/.local/go/bin`)
- Python binary path (`~/.local/python/bin`)
- `JAVA_HOME` and Java binary path

## Requirements

- Linux (script currently targets `linux-amd64` for Go/JDK and `aarch64` archives for `ripgrep`/`fd`)
- `bash`, `curl`, `tar`, `git`, `make`, compiler toolchain (for building Python)
- Internet access

## Usage

Run from this repository:

```bash
chmod +x bootstrap-go-dev.sh
./bootstrap-go-dev.sh
```

After completion:

```bash
source ~/.bashrc
nvim
```

## Notes and caveats

- The script is not fully idempotent for all components (some downloads/builds always run).
- Python build can take significant time and CPU.
- The script currently hardcodes mixed CPU architectures for downloads:
  - Go/JDK use `linux-amd64`
  - `ripgrep`/`fd` use `aarch64-unknown-linux-gnu`
- Re-running may append duplicate PATH lines in `~/.bashrc` for Python.
- Existing Neovim config is only used if `~/.config/nvim` does not already exist.

## Suggested improvements

If you want this script to be more robust, consider:

- Auto-detecting CPU architecture and selecting matching archives
- Adding checksums/signature verification for downloads
- Cleaning up source tarballs after install
- Making `.bashrc` updates strictly deduplicated
- Adding `set -euo pipefail` and better error messages
