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

# ─── Restore skills ─────────────────────────────────────────────────────────
[ -f "${WORKSPACE_ROOT}/skills-lock.json" ] && \
  cd "${WORKSPACE_ROOT}" && npx -y skills experimental_install

echo "✓ Devcontainer setup complete"
