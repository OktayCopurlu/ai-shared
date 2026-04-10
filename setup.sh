#!/bin/zsh
# Bootstrap script for ai-shared symlinks
# Run: ~/.ai-shared/setup.sh

set -e

AI="$HOME/.ai-shared"

echo "Setting up ai-shared symlinks..."

# Create target directories
mkdir -p ~/.github ~/.copilot ~/.copilot/research ~/.codex/skills ~/.config/opencode/commands ~/.config/opencode/references

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
link "$AI/references"       ~/.copilot/references
link "$AI/research/skills"  ~/.copilot/research/skills
link "$AI/skills"           ~/.config/opencode/skills
link "$AI/references"       ~/.config/opencode/references
# agents/ not symlinked for OpenCode — incompatible frontmatter format

# Codex per-skill symlinks (codex needs individual skill links)
# Clean up stale Codex skill symlinks first
for existing in "$HOME"/.codex/skills/*; do
  [[ -L "$existing" ]] || continue
  name=$(basename "$existing")
  if [[ ! -d "$AI/skills/$name" ]]; then
    echo "  🧹 Removing stale Codex symlink: ~/.codex/skills/$name"
    rm "$existing"
  fi
done

for skill in "$AI"/skills/*/; do
  name=$(basename "$skill")
  link "$AI/skills/$name" "$HOME/.codex/skills/$name"
done

# Codex references symlink
link "$AI/references" "$HOME/.codex/references"

# OpenCode per-command symlinks (rename *.prompt.md → *.md so command names are clean)
# Clean up stale OpenCode command symlinks first
for existing in "$HOME"/.config/opencode/commands/*; do
  [[ -L "$existing" ]] || continue
  name=$(basename "$existing" .md)
  if [[ ! -f "$AI/prompts/${name}.prompt.md" ]]; then
    echo "  🧹 Removing stale OpenCode command symlink: ~/.config/opencode/commands/$(basename "$existing")"
    rm "$existing"
  fi
done

for prompt in "$AI"/prompts/*.prompt.md; do
  name=$(basename "$prompt" .prompt.md)
  link "$prompt" "$HOME/.config/opencode/commands/${name}.md"
done

echo ""
echo "Done. $(find ~ -maxdepth 4 -type l -exec readlink {} \; 2>/dev/null | grep -c ai-shared) symlinks active."
