ARG VARIANT=22-bookworm
FROM mcr.microsoft.com/devcontainers/typescript-node:${VARIANT}

# Rename node -> vscode for image-agnostic consistency
RUN usermod -l vscode -d /home/vscode -m node && groupmod -n vscode node \
    && sed -i 's/node/vscode/g' /etc/sudoers.d/node

# Dev tooling + AWS CLI + GitHub CLI + Kiro CLI
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    neovim ranger tmux direnv zsh unzip less ripgrep \
    # AWS CLI v2
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip \
    # GitHub CLI
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get -y install --no-install-recommends gh \
    # Kiro CLI
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        KIRO_URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-aarch64-linux.tar.gz"; \
    else \
        KIRO_URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.tar.gz"; \
    fi \
    && curl -fsSL "$KIRO_URL" | tar -xz -C /tmp \
    && mv /tmp/kirocli/bin/* /usr/local/bin/ \
    && rm -rf /tmp/kirocli \
    # pnpm via corepack
    && corepack enable && corepack prepare pnpm@latest --activate \
    # Claude Code CLI
    && npm install -g @anthropic-ai/claude-code \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && usermod -s /usr/bin/zsh vscode

ENV ZDOTDIR=/home/vscode/.config/zsh

USER vscode
WORKDIR /home/vscode

COPY --chown=vscode:vscode post_create.sh /usr/src/
RUN chmod +x /usr/src/post_create.sh
