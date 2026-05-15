#!/bin/bash
# .claude/hooks/block-destructive-commands.sh
# Blocks destructive shell commands for subagents via PreToolUse hook.
# Define this as a PreToolUse hook on the Bash tool in the agent's frontmatter.
# Uses tool_input.command from the hook JSON input.

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0  # No command, nothing to check
fi

# Destructive command patterns (extended regex, matched against the full command)
# Anything that destroys local work, rewrites shared git history, bypasses safety
# checks, or affects the host system should live here.
BLOCKED_PATTERNS=(
  # Filesystem destruction
  '(^|[^a-zA-Z_])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|-rf|-fr)([[:space:]]|$)'
  '(^|[^a-zA-Z_])(mkfs|dd[[:space:]]+if=|shred|mv[[:space:]]+.*[[:space:]]+/dev/null)([[:space:]]|$)'
  ':\(\)\{[[:space:]]*:\|:&[[:space:]]*\};:'  # fork bomb

  # Git history rewriting / forced operations
  'git[[:space:]]+push[[:space:]].*(--force|-f([[:space:]]|$))'
  'git[[:space:]]+reset[[:space:]]+.*--hard'
  'git[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f'
  'git[[:space:]]+(checkout|restore)[[:space:]]+(--|\.)'
  'git[[:space:]]+branch[[:space:]]+.*-D'
  'git[[:space:]]+rebase[[:space:]]+.*(-i|--interactive)'
  'git[[:space:]]+(commit|merge|rebase)[[:space:]]+.*--no-verify'
  'git[[:space:]]+.*--no-gpg-sign'
  'git[[:space:]]+config[[:space:]]+'
  'git[[:space:]]+tag[[:space:]]+.*-d'
  'git[[:space:]]+update-ref[[:space:]]+-d'

  # Package publishing / dependency removal
  '(dart|flutter)[[:space:]]+pub[[:space:]]+publish'
  'npm[[:space:]]+publish'
  '(npm|yarn|pnpm)[[:space:]]+(uninstall|remove)'

  # Process / system manipulation
  '(^|[^a-zA-Z_])kill[[:space:]]+-9'
  '(^|[^a-zA-Z_])(shutdown|reboot|halt|poweroff)([[:space:]]|$)'
  '(^|[^a-zA-Z_])chmod[[:space:]]+(-R[[:space:]]+)?777'
  'sudo[[:space:]]+'

  # Pipe-to-shell (remote code execution)
  '(curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash|zsh|powershell)'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$command" =~ $pattern ]]; then
    echo "Blocked: destructive command pattern matched: $pattern" >&2
    echo "Command: $command" >&2
    exit 2  # Exit 2 = block the tool call
  fi
done

exit 0
