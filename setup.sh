#!/bin/zsh
# Bootstrap script for ai-shared symlinks
# Run: ~/.ai-shared/setup.sh

set -e

AI="$HOME/.ai-shared"

echo "Setting up ai-shared symlinks..."

# Create target directories
mkdir -p ~/.github ~/.copilot ~/.copilot/research ~/.codex/skills ~/.config/opencode/commands

# Helper: create symlink (safe — only removes existing symlinks, backs up real files)
link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    local backup="${dest}.bak.$(date +%s)"
    echo "  ⚠ $dest is not a symlink — backing up to $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  echo "  $dest -> $src"
}

# Global instructions
link "$AI/instructions.md" ~/.github/copilot-instructions.md
link "$AI/instructions.md" ~/.codex/instructions.md
link "$AI/instructions.md" ~/.config/opencode/AGENTS.md

# Directory symlinks
link "$AI/skills"           ~/.copilot/skills
link "$AI/agents"           ~/.copilot/agents
link "$AI/prompts"          "$HOME/Library/Application Support/Code/User/prompts"
link "$AI/prompts"          ~/.codex/prompts
link "$AI/research/skills"  ~/.copilot/research/skills
link "$AI/skills"           ~/.config/opencode/skills
# agents/ not symlinked for OpenCode — incompatible frontmatter format

# Codex per-skill symlinks (codex needs individual skill links)
for skill in "$AI"/skills/*/; do
  name=$(basename "$skill")
  link "$AI/skills/$name" "$HOME/.codex/skills/$name"
done

# OpenCode per-command symlinks (rename *.prompt.md → *.md so command names are clean)
for prompt in "$AI"/prompts/*.prompt.md; do
  name=$(basename "$prompt" .prompt.md)
  link "$prompt" "$HOME/.config/opencode/commands/${name}.md"
done

echo ""
echo "Done. $(find ~ -maxdepth 4 -type l -exec readlink {} \; 2>/dev/null | grep -c ai-shared) symlinks active."
