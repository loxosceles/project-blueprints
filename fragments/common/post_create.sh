#!/bin/sh
set -e

# Replace default ~/.zshrc with symlink to our managed config
ln -sf "$HOME/.config/zsh/.zshrc" "$HOME/.zshrc"

git config -f "$HOME/.gitconfig" user.name "${GIT_NAME}"
git config -f "$HOME/.gitconfig" user.email "${GIT_EMAIL}"

echo "export TMUX_SESSION=\"vsc-${PROJECT_NAME}\"" >> "$HOME/.zshrc.local"
for var in PROJECT_NAME; do
  eval val=\$$var
  [ -n "$val" ] && echo "export $var=\"$val\"" >> "$HOME/.zshrc.local"
done

[ -f "$HOME/.config/tmux/tmux.conf" ] && \
  ln -sf "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

[ -f "$HOME/.config/claude-shared/settings.json" ] && \
  cp "$HOME/.config/claude-shared/settings.json" "$HOME/.claude/settings.json"

# {{STACK_INJECTIONS}}

[ -x "${WORKSPACE_ROOT}/.devcontainer/post_create_project.sh" ] && \
  "${WORKSPACE_ROOT}/.devcontainer/post_create_project.sh"

# Restore skills from lockfile
[ -f "${WORKSPACE_ROOT}/skills-lock.json" ] && \
  cd "${WORKSPACE_ROOT}" && npx -y skills experimental_install

echo "✓ Devcontainer setup complete"
