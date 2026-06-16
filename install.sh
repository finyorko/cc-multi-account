#!/bin/bash
# Install ccm into ~/.local/bin and check PATH.
set -eu

src="$(cd "$(dirname "$0")" && pwd)/ccm"
dest_dir="$HOME/.local/bin"
dest="$dest_dir/ccm"

[ -f "$src" ] || { echo "ccm not found: $src" >&2; exit 1; }
mkdir -p "$dest_dir"
install -m 0755 "$src" "$dest"
echo "✓ Installed: $dest"

case ":$PATH:" in
  *":$dest_dir:"*) echo "✓ $dest_dir is on PATH — open a new terminal and run: ccm" ;;
  *)
    echo "⚠ $dest_dir is not on PATH. Add it for your shell:"
    echo "    zsh/bash:  export PATH=\"\$HOME/.local/bin:\$PATH\"   # add to ~/.zshrc or ~/.bashrc"
    echo "    fish:      fish_add_path \$HOME/.local/bin"
    ;;
esac
