# Blueprint: SST + Python (Hybrid)

SST v3 (Ion) infrastructure with Python Lambda functions. TypeScript for SST config, Python for business logic. pnpm monorepo with uv workspace for Python, centralized linting (ESLint + Ruff), formatting (Prettier + Ruff), and CI/CD.

**Base image**: `mcr.microsoft.com/devcontainers/base:bookworm` — generic Debian with Node 22 + Python 3.12 + uv + pnpm installed on top.

---

## Prerequisites

- Empty directory (or empty git repo)
- The agent should have access to `execute_bash` and `fs_write`

---

## 1. Project structure

The final project must have this structure:

```
{project}/
├── .devcontainer/              # fragment: common/* + dockerfiles/hybrid/*
├── .github/workflows/          # fragment: ci/*
├── .vscode/settings.json       # fragment: editor/vscode-settings.json (merged)
├── functions/                  # Python uv workspace (Lambda handlers)
│   ├── pyproject.toml
│   └── src/
│       └── functions/
│           ├── __init__.py
│           └── hello.py        # smoke test handler
├── scripts/
│   └── .gitkeep
├── docs/
│   ├── architecture/
│   ├── guides/
│   └── reference/
├── sst.config.ts
├── package.json
├── pyproject.toml              # root uv workspace
├── pnpm-workspace.yaml
├── eslint.config.mjs           # fragment: linting/eslint.config.hybrid.mjs
├── ruff.toml                   # fragment: linting/ruff.toml
├── .prettierrc.cjs             # fragment: linting/.prettierrc.cjs
├── .prettierignore             # fragment: linting/.prettierignore (extended)
├── .gitignore                  # fragment: project/.gitignore (extended)
├── .npmrc                      # fragment: project/.npmrc
├── .env_TEMPLATE               # fragment: project/.env_TEMPLATE
├── skills-lock.json
└── README.md
```

---

## 2. Initialization steps

Execute in order. If any step fails, stop and present the error with options.

### 2.1 Create Python function workspace

Create `functions/pyproject.toml`:

```toml
[project]
name = "functions"
version = "0.0.1"
requires-python = "==3.12.*"
dependencies = [
    "boto3>=1.35",
]

[tool.uv.sources]
sst = { git = "https://github.com/sst/sst.git", subdirectory = "sdk/python", branch = "dev" }

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Create `functions/src/functions/__init__.py` (empty).

Create `functions/src/functions/hello.py`:

```python
def handler(event, context):
    return {"statusCode": 200, "body": "ok"}
```

### 2.2 Create root uv workspace

Create `pyproject.toml` (root):

```toml
[project]
name = "{{project_name}}"
version = "0.0.1"
requires-python = "==3.12.*"

[tool.uv.workspace]
members = ["functions"]
```

### 2.3 Sync Python dependencies

```bash
uv sync
```

This creates the `.venv/` and resolves all Python dependencies.

---

## 3. Root package.json

Create `package.json`:

```json
{
  "name": "{{project_name}}",
  "version": "0.0.0",
  "private": true,
  "packageManager": "pnpm@10.6.0",
  "scripts": {
    "lint": "eslint . && ruff check functions/",
    "lint:fix": "eslint . --fix && ruff check --fix functions/",
    "format": "prettier --write \"**/*.{ts,js,json,md,yml}\" && ruff format functions/",
    "format:check": "prettier --check \"**/*.{ts,js,json,md,yml}\" && ruff format --check functions/",
    "test": "cd functions && uv run python -m pytest",
    "deploy:dev": "pnpm sst deploy --stage dev",
    "deploy:prod": "pnpm sst deploy --stage prod",
    "destroy:dev": "pnpm sst remove --stage dev",
    "prepare": "husky"
  },
  "lint-staged": {
    "**/*.{js,ts,mjs,cjs}": [
      "eslint --fix --no-warn-ignored",
      "prettier --write --end-of-line auto"
    ],
    "*.{json,md,yml}": [
      "prettier --write --end-of-line auto --ignore-path .prettierignore"
    ],
    "functions/**/*.py": [
      "ruff check --fix",
      "ruff format"
    ]
  },
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint": "^9.0.0",
    "eslint-config-prettier": "^10.0.0",
    "globals": "^16.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^16.0.0",
    "prettier": "^3.0.0",
    "sst": "^4.0.0",
    "typescript": "^5.0.0",
    "typescript-eslint": "^8.0.0"
  }
}
```

**Note**: Next.js-related ESLint plugins are NOT included by default. When a `frontend/` workspace is added later, add `@next/eslint-plugin-next`, `eslint-plugin-import`, `eslint-import-resolver-typescript`, `eslint-plugin-jsx-a11y`, `eslint-plugin-react`, and `eslint-plugin-react-hooks` to devDependencies. The ESLint config will auto-detect the frontend.

---

## 4. Other root files

### pnpm-workspace.yaml

```yaml
onlyBuiltDependencies:
  - aws-sdk
  - esbuild
ignoredBuiltDependencies:
  - aws-crt
```

**Note**: No `packages:` key needed initially. When a `frontend/` workspace is added, add `packages: ["frontend"]`.

### sst.config.ts

```typescript
/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
  app(input) {
    if (!process.env.AWS_REGION) {
      throw new Error("AWS_REGION is required. Set in .env or shell environment.");
    }
    return {
      name: "{{project_name}}",
      home: "aws",
      providers: {
        aws: { region: process.env.AWS_REGION },
      },
      removal: input.stage === "prod" ? "retain" : "remove",
      protect: input.stage === "prod",
    };
  },
  async run() {
    // Infrastructure defined here
  },
});
```

---

## 5. Fragment files

Copy these verbatim from `fragments/` in this repo:

| Fragment | Destination |
|----------|-------------|
| `dockerfiles/hybrid/Dockerfile` | `.devcontainer/Dockerfile` |
| `common/docker-compose.yml` | `.devcontainer/docker-compose.yml` |
| `common/devcontainer.json` | `.devcontainer/devcontainer.json` |
| `common/post_create.sh` | `.devcontainer/post_create.sh` |
| `common/.env_TEMPLATE` | `.devcontainer/.env_TEMPLATE` |
| `linting/eslint.config.hybrid.mjs` | `eslint.config.mjs` |
| `linting/ruff.toml` | `ruff.toml` |
| `linting/.prettierrc.cjs` | `.prettierrc.cjs` |
| `linting/.prettierignore.hybrid` | `.prettierignore` |
| `ci/deploy.yml` | `.github/workflows/deploy.yml` |
| `ci/lint.yml` | `.github/workflows/lint.yml` |
| `ci/test.yml` | `.github/workflows/test.yml` |
| `ci/validate-version-label.yml` | `.github/workflows/validate-version-label.yml` |
| `ci/version-and-tag.yml` | `.github/workflows/version-and-tag.yml` |
| `editor/vscode-settings.json` | `.vscode/settings.json` |
| `project/.gitignore.hybrid` | `.gitignore` |
| `project/.npmrc` | `.npmrc` |
| `project/.env_TEMPLATE` | `.env_TEMPLATE` |

**After copying `vscode-settings.json`**: Replace the `statusBar.background` color with a random hex color. Set `statusBar.foreground` to whichever of `#000000` or `#ffffff` has better contrast.

**Template variables in fragments**: Replace `{{project_name}}` with the actual project name in all fragment files after copying.

---

## 6. Post-copy modifications

### 6.1 Merge devcontainer.json injections

The base `devcontainer.json` from `common/` needs language-specific extensions and settings merged in. Read both injection fragments and merge their `extensions` and `settings` into the `customizations.vscode` section:

- `injections/node/devcontainer.json` — TypeScript extensions + settings
- `injections/python/devcontainer.json` — Python extensions + settings

**Remove** `bradlc.vscode-tailwindcss` from the node injection (not needed until frontend is added).

The merged `customizations.vscode` should contain all extensions and settings from the base + both injections.

### 6.2 Merge vscode-settings.json

Merge the Python injection settings into `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "/usr/local/bin/python",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit",
      "source.fixAll": "explicit"
    }
  }
}
```

---

## 7. Devcontainer .env

Create `.devcontainer/.env` (not committed, from template):

```
PROJECT_NAME={{project_name}}
GIT_NAME={{git_name}}
GIT_EMAIL={{git_email}}
```

Ask the user for `GIT_NAME` and `GIT_EMAIL` if not known from git config.

---

## 8. Install dependencies and initialize

```bash
pnpm install
git init   # if not already a git repo
npx husky init
echo "pnpm exec lint-staged" > .husky/pre-commit
pnpm format
```

---

## 9. Pre-create host mount targets

Docker creates missing mount sources as root-owned directories, which breaks permissions. After creating devcontainer files, run:

```bash
PROJECT={{project_name}}
mkdir -p ~/.devcontainer-state/cache/${PROJECT}/claude
mkdir -p ~/.devcontainer-state/cache/${PROJECT}/kiro
mkdir -p ~/.devcontainer-state/data
touch ~/.devcontainer-state/data/zsh_history_tmux
```

---

## 10. Install skills

```bash
npx skills add loxosceles/ai-dev --yes
```

Ask: "Do you want to install any additional third-party skills?"

---

## 11. Create docs structure

```
docs/
  architecture/
    .gitkeep
  guides/
    .gitkeep
  reference/
    .gitkeep
```

---

## 12. Copy agent configs

Copy all files from `fragments/agents/kiro/` to `.kiro/agents/`:

| Fragment | Destination |
|----------|-------------|
| `agents/kiro/lead-dev.json` | `.kiro/agents/lead-dev.json` |
| `agents/kiro/commit-helper.json` | `.kiro/agents/commit-helper.json` |
| `agents/kiro/code-reviewer.json` | `.kiro/agents/code-reviewer.json` |
| `agents/kiro/linting-setup.json` | `.kiro/agents/linting-setup.json` |

---

## 13. Create README.md

Generate a project README with:
- Project name and brief description (ask user)
- Tech stack summary (SST v3, Python 3.12, TypeScript, uv, pnpm)
- Getting started (devcontainer, env setup, pnpm install, uv sync)
- Available scripts
- Deployment info

---

## 14. Verification

Run a final format pass:

```bash
pnpm format
```

Then run these checks. All must pass:

```bash
pnpm lint           # ESLint + Ruff pass
pnpm format:check   # Prettier + Ruff format pass
```

If any check fails, debug and fix. If the fix requires changing a fragment, present the issue and ask.

---

## 15. Adding a frontend later

When the project needs a Next.js frontend:

1. Run `npx create-next-app@latest frontend --typescript --tailwind --app --no-src-dir --import-alias "@/*" --no-git --no-eslint --use-pnpm --skip-install --yes`
2. Add `packages: ["frontend"]` to `pnpm-workspace.yaml`
3. Add Next.js ESLint plugins to root `devDependencies` (see note in section 3)
4. The ESLint config auto-detects `frontend/tsconfig.json` and activates Next.js rules
5. Add frontend scripts to root `package.json`

---

## Adaptation rules

- **New major version of a dependency**: Ask before upgrading.
- **Deprecated CLI flag**: Find the replacement, present it, ask for confirmation.
- **Fragment file conflicts**: Never silently modify a fragment. Report and ask.
- **Python version**: If `python3.12` is not available in bookworm repos, use the `deadsnakes` PPA or adjust the Dockerfile.
