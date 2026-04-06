#!/bin/zsh
# Validate ai-shared repo: symlinks, frontmatter, structure, duplicates
# Run: ./validate.sh

set -euo pipefail

AI="${0:a:h}"  # resolve to script's own directory
errors=0
warnings=0

red()    { printf "\033[31m✗ %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m⚠ %s\033[0m\n" "$1"; }
green()  { printf "\033[32m✓ %s\033[0m\n" "$1"; }

fail() { red "$1"; ((errors++)); }
warn() { yellow "$1"; ((warnings++)); }

# ─── 1. Broken symlinks ───────────────────────────────────────────────

echo "\n── Symlink health ──"

symlink_targets=(
  "$HOME/.github/copilot-instructions.md"
  "$HOME/.codex/instructions.md"
  "$HOME/.config/opencode/instructions.md"
  "$HOME/.copilot/skills"
  "$HOME/.copilot/agents"
  "$HOME/.copilot/prompts"
  "$HOME/.copilot/research/skills"
  "$HOME/.codex/prompts"
  "$HOME/.config/opencode/skills"
  "$HOME/.config/opencode/agents"
)

for target in "${symlink_targets[@]}"; do
  if [[ ! -L "$target" ]]; then
    fail "Missing symlink: $target"
  elif [[ ! -e "$target" ]]; then
    fail "Broken symlink: $target -> $(readlink "$target")"
  fi
done

# Codex per-skill symlinks
for skill_dir in "$AI"/skills/*/; do
  name=$(basename "$skill_dir")
  codex_link="$HOME/.codex/skills/$name"
  if [[ ! -L "$codex_link" ]]; then
    fail "Missing Codex per-skill symlink: $codex_link"
  elif [[ ! -e "$codex_link" ]]; then
    fail "Broken Codex per-skill symlink: $codex_link -> $(readlink "$codex_link")"
  fi
done

green "Symlink check done"

# ─── 2. Skill directories must have SKILL.md ──────────────────────────

echo "\n── Skill structure ──"

# Directories that are support folders, not skills
skip_dirs=(shared templates)

for skill_dir in "$AI"/skills/*/ "$AI"/research/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name=$(basename "$skill_dir")
  # Skip known non-skill directories
  if (( ${skip_dirs[(Ie)$name]} )); then
    continue
  fi
  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    fail "Skill '$name' missing SKILL.md: $skill_dir"
  elif [[ ! -s "$skill_dir/SKILL.md" ]]; then
    fail "Skill '$name' has empty SKILL.md: $skill_dir"
  fi
done

green "Skill structure check done"

# ─── 3. YAML frontmatter: name + description required ─────────────────

echo "\n── Frontmatter ──"

check_frontmatter() {
  local file="$1" label="$2"
  # File must start with ---
  if ! head -1 "$file" | grep -q '^---$'; then
    fail "$label: missing YAML frontmatter"
    return
  fi

  # Extract frontmatter block (between first and second ---)
  local fm
  fm=$(sed -n '2,/^---$/p' "$file" | sed '$d')

  if ! echo "$fm" | grep -q '^name:'; then
    fail "$label: frontmatter missing 'name'"
  fi
  if ! echo "$fm" | grep -q '^description:'; then
    fail "$label: frontmatter missing 'description'"
  fi
}

for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  check_frontmatter "$f" "$rel"
done

for f in "$AI"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  check_frontmatter "$f" "$rel"
done

green "Frontmatter check done"

# ─── 4. Duplicate agent names ─────────────────────────────────────────

echo "\n── Duplicate names ──"

typeset -A seen_names

for f in "$AI"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name: *//; s/^["'"'"']//; s/["'"'"']$//; p; }; }' "$f")
  if [[ -z "$name" ]]; then
    continue  # already caught by frontmatter check
  fi
  if [[ -n "${seen_names[$name]:-}" ]]; then
    fail "Duplicate agent name '$name': ${seen_names[$name]} and $f"
  else
    seen_names[$name]="$f"
  fi
done

for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name: *//; s/^["'"'"']//; s/["'"'"']$//; p; }; }' "$f")
  if [[ -z "$name" ]]; then
    continue
  fi
  if [[ -n "${seen_names[$name]:-}" ]]; then
    fail "Duplicate skill/agent name '$name': ${seen_names[$name]} and $f"
  else
    seen_names[$name]="$f"
  fi
done

green "Duplicate name check done"

# ─── 5. Empty sections in skills ──────────────────────────────────────

echo "\n── Empty sections ──"

for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"

  # Find ## headings followed immediately by another ## or end of file with no content between
  prev_heading="" prev_line=0 line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" == \#\#\ * ]]; then
      if [[ -n "$prev_heading" && $((line_num - prev_line)) -le 1 ]]; then
        warn "$rel: empty section '$prev_heading' (line $prev_line)"
      fi
      prev_heading="$line"
      prev_line=$line_num
    elif [[ -n "$line" ]] && [[ "$line" != *([[:space:]]) ]]; then
      prev_heading=""
    fi
  done < "$f"
done

green "Empty section check done"

# ─── 6. Prompt files: basic check ─────────────────────────────────────

echo "\n── Prompt files ──"

for f in "$AI"/prompts/*.prompt.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  if [[ ! -s "$f" ]]; then
    fail "$rel: empty prompt file"
  fi
done

green "Prompt file check done"

# ─── Summary ──────────────────────────────────────────────────────────

echo "\n── Summary ──"
if (( errors > 0 )); then
  red "$errors error(s), $warnings warning(s)"
  exit 1
elif (( warnings > 0 )); then
  yellow "0 errors, $warnings warning(s)"
else
  green "All checks passed"
fi
