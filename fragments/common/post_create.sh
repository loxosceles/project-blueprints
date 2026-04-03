#!/bin/sh
set -e

# ─── Validate required environment ───────────────────────────────────────────
errors=""
[ -z "$PROJECT_NAME" ] && errors="${errors}\n  - PROJECT_NAME"
[ -z "$GIT_NAME" ] && errors="${errors}\n  - GIT_NAME"
[ -z "$GIT_EMAIL" ] && errors="${errors}\n  - GIT_EMAIL"
[ -z "$WORKSPACE_ROOT" ] && errors="${errors}\n  - WORKSPACE_ROOT"

if [ -n "$errors" ]; then
  echo "❌ Missing required environment variables:${errors}"
  echo ""
  echo "Copy .devcontainer/.env_TEMPLATE to .devcontainer/.env and fill in all values."
  exit 1
fi

# ─── Check for root-owned mount dirs ─────────────────────────────────────────
# Docker auto-creates missing mount sources as root-owned empty dirs.
# This usually means ~/.devcontainer-state wasn't cloned before first container start.
root_owned=""
for dir in "$HOME/.kiro" "$HOME/.cache" "$HOME/.claude"; do
  if [ -d "$dir" ] && [ ! -w "$dir" ]; then
    root_owned="${root_owned}\n  - $dir"
  fi
done
if [ -n "$root_owned" ]; then
  echo "⛔ Root-owned directories detected (not writable by vscode):${root_owned}"
  echo ""
  echo "This happens when Docker auto-creates mount targets before ~/.devcontainer-state is cloned."
  echo "Fix on the HOST machine:"
  echo "  1. Stop this container"
  echo "  2. sudo rm -rf ~/.devcontainer-state"
  echo "  3. git clone git@github.com:loxosceles/devcontainer-state.git ~/.devcontainer-state"
  echo "  4. Re-create per-project dirs: mkdir -p ~/.devcontainer-state/cache/${PROJECT_NAME}/{claude,kiro}"
  echo "  5. Rebuild the container"
  exit 1
fi

# ─── Claude settings check ──────────────────────────────────────────────────
if [ ! -f "$HOME/.config/claude-shared/settings.json" ]; then
  echo "⚠️  Claude settings not found."
  echo "   Copy the template and add your API key:"
  echo "   cp ~/.devcontainer-state/claude/settings.json.template ~/.devcontainer-state/claude/settings.json"
  echo ""
fi

# ─── Shell config ────────────────────────────────────────────────────────────
ln -sf "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"

[ -f "$HOME/.config/tmux/tmux.conf" ] && \
  ln -sf "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

# ─── Git identity ────────────────────────────────────────────────────────────
git config -f "$HOME/.gitconfig" user.name "${GIT_NAME}"
git config -f "$HOME/.gitconfig" user.email "${GIT_EMAIL}"

# ─── Project env ─────────────────────────────────────────────────────────────
echo "export TMUX_SESSION=\"vsc-${PROJECT_NAME}\"" >> "$HOME/.zshrc.local"
echo "export PROJECT_NAME=\"${PROJECT_NAME}\"" >> "$HOME/.zshrc.local"

# ─── Claude settings ────────────────────────────────────────────────────────
[ -f "$HOME/.config/claude-shared/settings.json" ] && \
  cp "$HOME/.config/claude-shared/settings.json" "$HOME/.claude/settings.json"

# ─── Project hook ────────────────────────────────────────────────────────────
[ -x "${WORKSPACE_ROOT}/.devcontainer/post_create_project.sh" ] && \
  "${WORKSPACE_ROOT}/.devcontainer/post_create_project.sh"

# ─── Kiro agents (seed from defaults if empty) ──────────────────────────────
if [ -d "$HOME/.config/default-agents/kiro" ] && [ ! -d "$HOME/.kiro/agents" ]; then
  mkdir -p "$HOME/.kiro/agents"
  cp "$HOME/.config/default-agents/kiro"/*.json "$HOME/.kiro/agents/" 2>/dev/null
fi

# ─── Codex agents (symlink into .github/agents/) ────────────────────────────
if [ -d "$HOME/.config/default-agents/codex" ]; then
  mkdir -p "${WORKSPACE_ROOT}/.github/agents"
  for f in "$HOME/.config/default-agents/codex"/*.md; do
    [ -f "$f" ] && ln -sf "$f" "${WORKSPACE_ROOT}/.github/agents/$(basename "$f")"
  done
fi

# ─── Restore skills ─────────────────────────────────────────────────────────
[ -f "${WORKSPACE_ROOT}/skills-lock.json" ] && \
  cd "${WORKSPACE_ROOT}" && npx -y skills add loxosceles/ai-dev --agent claude-code github-copilot codex kiro-cli -y

echo "✓ Devcontainer setup complete"
