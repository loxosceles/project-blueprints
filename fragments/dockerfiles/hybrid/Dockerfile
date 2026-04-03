FROM mcr.microsoft.com/devcontainers/base:bookworm

# ─── Python 3.12 ─────────────────────────────────────────────────────────────
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    python3.11 python3.11-venv python3.11-dev \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── uv (Python package manager) ─────────────────────────────────────────────
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# ─── Node.js 22 + pnpm ───────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && corepack enable && corepack prepare pnpm@latest --activate

# ─── Dev tooling ─────────────────────────────────────────────────────────────
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    neovim ranger tmux direnv fzf less ripgrep unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── AWS CLI v2 ──────────────────────────────────────────────────────────────
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# ─── GitHub CLI ──────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get -y install --no-install-recommends gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Kiro CLI ────────────────────────────────────────────────────────────────
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        KIRO_URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-aarch64-linux.tar.gz"; \
    else \
        KIRO_URL="https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.tar.gz"; \
    fi \
    && curl -fsSL "$KIRO_URL" | tar -xz -C /tmp \
    && mv /tmp/kirocli/bin/* /usr/local/bin/ \
    && rm -rf /tmp/kirocli

# ─── Claude Code CLI ────────────────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ─── Ruff (Python linter/formatter) ─────────────────────────────────────────
RUN curl -LsSf https://astral.sh/ruff/install.sh | sh \
    && mv /root/.local/bin/ruff /usr/local/bin/ruff

# ─── Environment ─────────────────────────────────────────────────────────────
ENV PYTHONDONTWRITEBYTECODE=1
ENV ZDOTDIR=/home/vscode/.config/zsh

COPY post_create.sh /usr/src/
RUN chmod +x /usr/src/post_create.sh

USER vscode
WORKDIR /home/vscode
