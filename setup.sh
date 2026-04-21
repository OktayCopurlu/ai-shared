#!/bin/zsh
# Bootstrap script for ai-shared symlinks
# Run: ~/.ai-shared/setup.sh

set -e

AI="$HOME/.ai-shared"

echo "Setting up ai-shared symlinks..."

# Create target directories
mkdir -p ~/.github ~/.copilot ~/.codex/skills ~/.config/opencode/commands ~/.config/opencode/references

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

# ─── Self-evolution jobs (launchd plists) ─────────────────────────────
AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$AGENTS_DIR"

if [[ -d "$AI/self-evolution/jobs" ]]; then
  echo ""
  echo "Setting up self-evolution jobs..."

  for job_dir in "$AI"/self-evolution/jobs/*/; do
    [[ -d "$job_dir" ]] || continue
    job_name=$(basename "$job_dir")
    job_file="$job_dir/job.json"
    [[ -f "$job_file" ]] || continue

    label=$(jq -r '.label' "$job_file")
    target_dir=$(jq -r '.target_dir' "$job_file" | sed "s|~|$HOME|")

    echo "  Job: $job_name (label: $label)"
    mkdir -p "$job_dir/logs"

    # Build schedule XML
    schedule_xml=""
    while IFS= read -r entry; do
      hour=$(echo "$entry" | jq -r '.hour')
      minute=$(echo "$entry" | jq -r '.minute')
      schedule_xml+="
        <dict>
            <key>Hour</key>
            <integer>$hour</integer>
            <key>Minute</key>
            <integer>$minute</integer>
        </dict>"
    done < <(jq -c '.schedule[]' "$job_file")

    plist_file="$AGENTS_DIR/${label}.plist"
    cat > "$plist_file" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$AI/self-evolution/runner.sh</string>
        <string>$job_name</string>
    </array>

    <key>StartCalendarInterval</key>
    <array>$schedule_xml
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:$HOME/.nvm/versions/node/v22.17.0/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>

    <key>StandardOutPath</key>
    <string>${job_dir}logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${job_dir}logs/launchd-stderr.log</string>

    <key>WorkingDirectory</key>
    <string>$target_dir</string>

    <key>Nice</key>
    <integer>10</integer>
</dict>
</plist>
PLIST

    launchctl unload "$plist_file" 2>/dev/null || true
    launchctl load "$plist_file"
    echo "  Loaded: $label"
  done
fi

echo ""
echo "Done. $(find ~ -maxdepth 4 -type l -exec readlink {} \; 2>/dev/null | grep -c ai-shared) symlinks active."
