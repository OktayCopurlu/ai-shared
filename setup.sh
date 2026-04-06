#!/bin/zsh
# Bootstrap script for ai-shared symlinks
# Run: ~/.ai-shared/setup.sh

set -e

AI="$HOME/.ai-shared"

echo "Setting up ai-shared symlinks..."

# Create target directories
mkdir -p ~/.github ~/.copilot ~/.copilot/research ~/.codex/skills ~/.config/opencode

# Helper: create symlink (remove existing first)
link() {
  local src="$1" dest="$2"
  [[ -L "$dest" || -e "$dest" ]] && rm -rf "$dest"
  ln -s "$src" "$dest"
  echo "  $dest -> $src"
}

# Global instructions
link "$AI/instructions.md" ~/.github/copilot-instructions.md
link "$AI/instructions.md" ~/.codex/instructions.md
link "$AI/instructions.md" ~/.config/opencode/instructions.md

# Directory symlinks
link "$AI/skills"           ~/.copilot/skills
link "$AI/agents"           ~/.copilot/agents
link "$AI/prompts"          ~/.codex/prompts
link "$AI/research/skills"  ~/.copilot/research/skills
link "$AI/skills"           ~/.config/opencode/skills

# Codex per-skill symlinks (codex needs individual skill links)
for skill in "$AI"/skills/*/; do
  name=$(basename "$skill")
  link "$AI/skills/$name" "$HOME/.codex/skills/$name"
done

echo ""
echo "Done. $(find ~ -maxdepth 4 -type l -exec readlink {} \; 2>/dev/null | grep -c ai-shared) symlinks active."
