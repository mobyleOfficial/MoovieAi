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

# Match an actual `pip install` (or equivalent) invocation. Anchored to
# start-of-command, post-chain-operator, or post-env-var-prefix so that
# quoted strings inside echo/printf do not trip the check. Forms matched:
#   pip install ...        pip3 install ...
#   python -m pip install  python3 -m pip install
#   uv pip install         uv install (legacy)
#   poetry install         conda install
# uvx and `uv tool run` are skipped — they invoke transient tools, not env installs.
INSTALL_PATTERN='(^|[;&|][[:space:]]*)([A-Z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*(python3?[[:space:]]+-m[[:space:]]+pip|pip3?|uv([[:space:]]+pip)?|poetry|conda)[[:space:]]+install'
UVX_PATTERN='(^|[;&|][[:space:]]*)(uvx|uv[[:space:]]+tool[[:space:]]+run|uv[[:space:]]+run)([[:space:]]|$)'

if ! echo "$command" | grep -qE "$INSTALL_PATTERN"; then
  exit 0
fi

# Permit transient uv invocations (uvx / uv tool run / uv run)
if echo "$command" | grep -qE "$UVX_PATTERN"; then
  exit 0
fi

# Permit if a virtualenv is active
if [ -n "${VIRTUAL_ENV:-}" ] || [ -n "${CONDA_PREFIX:-}" ] || [ -n "${POETRY_ACTIVE:-}" ]; then
  exit 0
fi

echo "❌ PYTHON_ENVS rule violation: install command outside an active virtualenv." >&2
echo "   Activate a venv first: python -m venv .venv && source .venv/bin/activate" >&2
echo "   See rules/PYTHON_ENVS.md for details." >&2
exit 2
