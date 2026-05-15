#!/bin/bash
# .claude/hooks/check-python-env.sh
# Blocks `pip install` (or equivalents) outside a virtualenv.
# Enforces rules/PYTHON_ENVS.md.
# Register as PreToolUse hook on the Bash tool in .claude/settings.json.

set -e

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Only inspect pip/uv/poetry/conda install invocations.
# Match the first command in a pipeline/chain so quoted strings or echo'd
# examples don't trigger.
first_token=$(echo "$command" | awk '{print $1}' | awk -F'[|;&]' '{print $NF}')
first_arg=$(echo "$command" | awk '{print $2}')

case "$first_token" in
  pip|pip3|uv|poetry|conda) ;;
  *) exit 0 ;;
esac

case "$first_arg" in
  install) ;;
  *) exit 0 ;;
esac

# Permit if a virtualenv is active
if [ -n "${VIRTUAL_ENV:-}" ] || [ -n "${CONDA_PREFIX:-}" ] || [ -n "${POETRY_ACTIVE:-}" ]; then
  exit 0
fi

# Permit when invoked via uvx (transient, project-scoped) — `uv tool run X` is fine
if echo "$command" | grep -qE '(^|[[:space:]])uv[[:space:]]+(tool|run|x)'; then
  exit 0
fi

echo "❌ PYTHON_ENVS rule violation: install command outside an active virtualenv." >&2
echo "   Activate a venv first (python -m venv .venv && source .venv/bin/activate)." >&2
echo "   See rules/PYTHON_ENVS.md for details." >&2
exit 2
