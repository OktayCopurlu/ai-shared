#!/bin/zsh
# Validate ai-shared repo: symlinks, frontmatter, structure, duplicates
# Run: zsh validate.sh  (requires zsh — uses zsh-specific syntax)

set -eo pipefail

AI="${0:a:h}"  # resolve to script's own directory (zsh-only)
errors=0
warnings=0

red()    { printf "\033[31m✗ %s\033[0m\n" "$1"; }
yellow() { printf "\033[33m⚠ %s\033[0m\n" "$1"; }
green()  { printf "\033[32m✓ %s\033[0m\n" "$1"; }

fail() { red "$1"; errors=$((errors + 1)); }
warn() { yellow "$1"; warnings=$((warnings + 1)); }

# ─── 1. Broken symlinks ───────────────────────────────────────────────

echo "\n── Symlink health ──"

symlink_targets=(
  "$HOME/.github/copilot-instructions.md"
  "$HOME/.codex/instructions.md"
  "$HOME/.config/opencode/AGENTS.md"
  "$HOME/.copilot/skills"
  "$HOME/.copilot/agents"
  "$HOME/Library/Application Support/Code/User/prompts"
  "$HOME/.copilot/research/skills"
  "$HOME/.copilot/references"
  "$HOME/.codex/prompts"
  "$HOME/.codex/references"
  "$HOME/.config/opencode/skills"
  "$HOME/.config/opencode/references"
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

# OpenCode per-command symlinks
for prompt in "$AI"/prompts/*.prompt.md; do
  [[ -f "$prompt" ]] || continue
  name=$(basename "$prompt" .prompt.md)
  oc_link="$HOME/.config/opencode/commands/${name}.md"
  if [[ ! -L "$oc_link" ]]; then
    fail "Missing OpenCode command symlink: $oc_link"
  elif [[ ! -e "$oc_link" ]]; then
    fail "Broken OpenCode command symlink: $oc_link -> $(readlink "$oc_link")"
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

# ─── 3b. Frontmatter name must match directory name ───────────────────

echo "\n── Name == directory ──"

for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  dir_name=$(basename "$(dirname "$f")")
  fm_name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name: *//; s/^["'"'"']//; s/["'"'"']$//; p; }; }' "$f")
  if [[ -z "$fm_name" ]]; then
    continue  # already caught by frontmatter check
  fi
  if [[ "$fm_name" != "$dir_name" ]]; then
    fail "$rel: frontmatter name '$fm_name' does not match directory '$dir_name'"
  fi
done

for f in "$AI"/agents/*.agent.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  file_name=$(basename "$f" .agent.md)
  fm_name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name: *//; s/^["'"'"']//; s/["'"'"']$//; p; }; }' "$f")
  if [[ -z "$fm_name" ]]; then
    continue
  fi
  if [[ "$fm_name" != "$file_name" ]]; then
    fail "$rel: frontmatter name '$fm_name' does not match file stem '$file_name'"
  fi
done

green "Name == directory check done"

# ─── 3c. Minimum skill structure ──────────────────────────────────────

echo "\n── Minimum skill structure ──"

for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"

  # Every skill must have an H1 title
  if ! grep -q '^# ' "$f"; then
    fail "$rel: missing H1 heading (skill title)"
  fi

  # Every skill must have at least one substantive H2 section.
  if ! grep -q '^## ' "$f"; then
    fail "$rel: missing H2 sections (expected at least one section such as 'When to Use', 'Procedure', or 'Rules')"
  fi
done

green "Minimum skill structure check done"

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

# ─── 7. Reference files: must not be empty ─────────────────────────────

echo "\n── Reference files ──"

for f in "$AI"/references/*.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  if [[ ! -s "$f" ]]; then
    fail "$rel: empty reference file"
  fi
done

green "Reference file check done"

# ─── 8. Cross-references in See Also sections ─────────────────────────

echo "\n── Cross-references ──"

for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"

  # Check references/ mentions
  grep -oE 'references/[a-zA-Z0-9_-]+\.md' "$f" 2>/dev/null | sort -u | while read -r ref; do
    if [[ ! -f "$AI/$ref" ]]; then
      fail "$rel: broken reference '$ref'"
    fi
  done

  # Check skill cross-references (backtick-wrapped names in See Also)
  in_see_also=false
  while IFS= read -r line; do
    if [[ "$line" == "## See Also" ]]; then
      in_see_also=true
      continue
    elif [[ "$line" == \#\#\ * ]]; then
      in_see_also=false
      continue
    fi
    if $in_see_also; then
      # Skip lines that reference prompts (e.g. "`spec` prompt")
      [[ "$line" == *" prompt"* ]] && continue
      # Extract backtick-wrapped skill names (e.g. `debugging`, `applying-coding-style`)
      echo "$line" | grep -oE '`[a-zA-Z0-9_-]+`' | tr -d '`' | while read -r skill_ref; do
        # Skip if it looks like a code keyword, not a skill name
        [[ "$skill_ref" == references* ]] && continue
        # Check if it's a known skill
        if [[ ! -d "$AI/skills/$skill_ref" ]] && [[ ! -d "$AI/research/skills/$skill_ref" ]]; then
          warn "$rel: See Also references unknown skill '$skill_ref'"
        fi
      done
    fi
  done < "$f"
done

green "Cross-reference check done"

# ─── 9. Skill smoke tests ─────────────────────────────────────────────

echo "\n── Skill smoke tests ──"

# 9a. Internal file references: check that paths mentioned in skills resolve
for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"

  # Extract references/ paths (e.g. references/security-checklist.md)
  grep -oE 'references/[a-zA-Z0-9_/-]+\.md' "$f" 2>/dev/null | sort -u | while read -r ref; do
    if [[ ! -f "$AI/$ref" ]]; then
      fail "$rel: references non-existent file '$ref'"
    fi
  done

  # Extract docs/ paths (e.g. docs/skill-anatomy.md)
  grep -oE 'docs/[a-zA-Z0-9_/-]+\.md' "$f" 2>/dev/null | sort -u | while read -r ref; do
    if [[ ! -f "$AI/$ref" ]]; then
      fail "$rel: references non-existent file '$ref'"
    fi
  done
done

# 9b. Description quality: must contain a trigger phrase ("USE FOR:", "Use for", or "Use when")
for f in "$AI"/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  desc=$(sed -n '/^---$/,/^---$/{ /^description:/{ s/^description: *//; s/^["'"'"']//; s/["'"'"']$//; p; }; }' "$f")
  if [[ -n "$desc" ]] && ! echo "$desc" | grep -qiE 'use for|use when'; then
    warn "$rel: description missing trigger phrase (one of: 'USE FOR:', 'Use for', 'Use when')"
  fi
done

# 9c. Skill size: warn if over 500 lines (per skill-anatomy.md guideline)
for f in "$AI"/skills/*/SKILL.md "$AI"/research/skills/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  rel="${f#$AI/}"
  line_count=$(wc -l < "$f" | tr -d ' ')
  if (( line_count > 500 )); then
    warn "$rel: $line_count lines (guideline is under 500)"
  fi
done

# 9d. instructions.md alignment: every skill dir should appear in Skill Awareness
instructions_file="$AI/instructions.md"
if [[ -f "$instructions_file" ]]; then
  for skill_dir in "$AI"/skills/*/; do
    [[ -d "$skill_dir" ]] || continue
    name=$(basename "$skill_dir")
    if ! grep -q "$name" "$instructions_file"; then
      warn "Skill '$name' not referenced in instructions.md Skill Awareness section"
    fi
  done
fi

# 9e. Supporting files: check that non-SKILL.md files in skill dirs are referenced
for skill_dir in "$AI"/skills/*/ "$AI"/research/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  [[ -f "$skill_file" ]] || continue

  for support_file in "$skill_dir"*.md; do
    [[ -f "$support_file" ]] || continue
    support_name=$(basename "$support_file")
    [[ "$support_name" == "SKILL.md" ]] && continue
    if ! grep -q "$support_name" "$skill_file"; then
      warn "skills/$name/$support_name: supporting file not referenced in SKILL.md"
    fi
  done
done

green "Skill smoke test done"

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
