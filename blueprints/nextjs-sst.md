# Blueprint: Next.js + SST

Full-stack Next.js application deployed with SST (Ion) on AWS. pnpm monorepo with centralized linting, formatting, testing, and CI/CD.

**Reference project**: `guitarizta` (loxosceles/guitarizta)

---

## Prerequisites

- Empty directory (or empty git repo)
- Node.js 22+
- pnpm (via corepack)
- The agent should have access to `execute_bash` and `fs_write`

---

## 1. Project structure

The final project must have this structure:

```
{project}/
├── .devcontainer/           # fragment: devcontainer/*
├── .github/workflows/       # fragment: ci/*
├── .husky/pre-commit        # "pnpm exec lint-staged"
├── .vscode/settings.json    # fragment: editor/vscode-settings.json
├── frontend/                # created by create-next-app
│   ├── app/
│   ├── components/
│   ├── hooks/
│   ├── lib/
│   ├── types/
│   ├── public/
│   ├── vitest.config.ts
│   ├── vitest.setup.ts
│   └── package.json
├── scripts/
│   └── build-open-next.sh
├── docs/
│   ├── architecture/
│   ├── guides/
│   └── reference/
├── eslint.config.mjs        # fragment: linting/eslint.config.mjs
├── .prettierrc.cjs           # fragment: linting/.prettierrc.cjs
├── .prettierignore           # fragment: linting/.prettierignore
├── .gitignore                # fragment: project/.gitignore
├── .npmrc                    # fragment: project/.npmrc
├── .envrc                    # fragment: project/.envrc
├── .env_TEMPLATE             # fragment: project/.env_TEMPLATE
├── package.json
├── pnpm-workspace.yaml
├── sst.config.ts
├── skills-lock.json
└── README.md
```

---

## 2. Initialization steps

Execute in order. If any step fails, stop and present the error with options.

### 2.1 Create Next.js app

```bash
npx create-next-app@latest frontend \
  --typescript --tailwind --app --no-src-dir \
  --import-alias "@/*" --no-git --no-eslint \
  --use-pnpm --skip-install --yes
```

**Post-create cleanup**:
- Remove `frontend/.git` if it exists
- Remove `frontend/pnpm-lock.yaml` if it exists

**Version check**: If `create-next-app` prompts for a version or the latest version is a new major release compared to the reference (Next.js 15.x), ask:
> "Next.js {new_version} is available. The reference project uses {old_version}. Should I evaluate the upgrade or use the reference version?"

### 2.2 Patch frontend/next.config.ts

Replace with (SSR mode, no static export):

```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  images: { unoptimized: true }
};

export default nextConfig;
```

### 2.3 Patch frontend/tsconfig.json

Add `"vitest.config.ts"` and `"vitest.setup.ts"` to the `exclude` array.

### 2.4 Create frontend test infrastructure

Create `frontend/vitest.config.ts`:
```typescript
import react from '@vitejs/plugin-react';
import path from 'path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    globals: true
  },
  resolve: {
    alias: { '@': path.resolve(__dirname, '.') }
  }
});
```

Create `frontend/vitest.setup.ts`:
```typescript
import '@testing-library/jest-dom/vitest';
```

Create `frontend/app/__tests__/page.test.tsx` with a basic smoke test.

### 2.5 Create frontend directories

Create empty directories with `.gitkeep`:
- `frontend/components/`
- `frontend/hooks/`
- `frontend/lib/`
- `frontend/types/`

### 2.6 Add frontend test dependencies

Add to `frontend/package.json` devDependencies:
```json
{
  "@testing-library/jest-dom": "^6",
  "@testing-library/react": "^16",
  "@vitejs/plugin-react": "^5",
  "jsdom": "^26",
  "vitest": "^3"
}
```

Add to `frontend/package.json` scripts:
```json
{
  "test": "vitest run",
  "test:watch": "vitest"
}
```

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
    "dev": "pnpm --filter=frontend run dev",
    "build": "pnpm --filter=frontend run build",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,md,yml}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,md,yml}\"",
    "test": "pnpm --filter=frontend run test",
    "test:frontend": "pnpm --filter=frontend run test",
    "deploy:dev": "sst deploy --stage dev",
    "deploy:prod": "sst deploy --stage prod",
    "destroy:dev": "sst remove --stage dev",
    "prepare": "husky"
  },
  "lint-staged": {
    "**/*.{js,jsx,ts,tsx}": [
      "eslint --fix --no-warn-ignored",
      "prettier --write --end-of-line auto"
    ],
    "*.{json,md,yml}": [
      "prettier --write --end-of-line auto --ignore-path .prettierignore"
    ]
  },
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "@next/eslint-plugin-next": "^15.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint": "^9.0.0",
    "eslint-config-prettier": "^10.0.0",
    "eslint-import-resolver-typescript": "^4.0.0",
    "eslint-plugin-import": "^2.0.0",
    "eslint-plugin-jsx-a11y": "^6.0.0",
    "eslint-plugin-react": "^7.0.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "globals": "^16.0.0",
    "husky": "^9.0.0",
    "lint-staged": "^16.0.0",
    "prettier": "^3.0.0",
    "sst": "^4.0.0",
    "@opennextjs/aws": "^3.9.0",
    "typescript": "^5.0.0",
    "typescript-eslint": "^8.0.0"
  }
}
```

**Important**: Do NOT add `next` to root devDependencies. It must only be in `frontend/package.json` so pnpm keeps it in `frontend/node_modules/`. Hoisting `next` to the root breaks Turbopack's monorepo root detection.

---

## 4. Other root files

### pnpm-workspace.yaml

```yaml
packages:
  - frontend
onlyBuiltDependencies:
  - aws-sdk
  - esbuild
  - sharp
  - unrs-resolver
ignoredBuiltDependencies:
  - aws-crt
```

### sst.config.ts

```typescript
/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
  app(input) {
    if (!process.env.AWS_REGION) {
      throw new Error("AWS_REGION is required. Set in .env.{stage} or shell environment.");
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
    const pkg = await import("./package.json");
    const openNextVersion = pkg.devDependencies["@opennextjs/aws"].replace(/^\^/, "");
    const isProd = $app.stage === "prod";

    const site = new sst.aws.Nextjs("Web", {
      path: "frontend/",
      openNextVersion,
      buildCommand: "bash ../scripts/build-open-next.sh",
      domain:
        isProd && process.env.PROD_DOMAIN_NAME
          ? {
              name: process.env.PROD_DOMAIN_NAME,
              redirects: [`www.${process.env.PROD_DOMAIN_NAME}`],
              cert: process.env.CERTIFICATE_ARN,
            }
          : undefined,
    });

    return { url: site.url };
  },
});
```

### scripts/build-open-next.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Building Next.js for OpenNext..."
cd frontend
npx --yes @opennextjs/aws@"$(node -p "require('../package.json').devDependencies['@opennextjs/aws'].replace(/^\^/,'')")" build
echo "OpenNext build complete"
```

Make executable: `chmod +x scripts/build-open-next.sh`

---

## 5. Fragment files

Copy these verbatim from `fragments/` in this repo:

| Fragment | Destination |
|----------|-------------|
| `devcontainer/Dockerfile.node` | `.devcontainer/Dockerfile` |
| `devcontainer/docker-compose.yml` | `.devcontainer/docker-compose.yml` |
| `devcontainer/devcontainer.json` | `.devcontainer/devcontainer.json` |
| `devcontainer/post_create.sh` | `.devcontainer/post_create.sh` |
| `devcontainer/.env_TEMPLATE` | `.devcontainer/.env_TEMPLATE` |
| `linting/eslint.config.mjs` | `eslint.config.mjs` |
| `linting/.prettierrc.cjs` | `.prettierrc.cjs` |
| `linting/.prettierignore` | `.prettierignore` |
| `ci/deploy.yml` | `.github/workflows/deploy.yml` |
| `ci/lint.yml` | `.github/workflows/lint.yml` |
| `ci/test.yml` | `.github/workflows/test.yml` |
| `ci/validate-version-label.yml` | `.github/workflows/validate-version-label.yml` |
| `ci/version-and-tag.yml` | `.github/workflows/version-and-tag.yml` |
| `editor/vscode-settings.json` | `.vscode/settings.json` |
| `project/.gitignore` | `.gitignore` |
| `project/.npmrc` | `.npmrc` |
| `project/.envrc` | `.envrc` |
| `project/.env_TEMPLATE` | `.env_TEMPLATE` |

**Template variables in fragments**: Replace `{{project_name}}` with the actual project name in all fragment files after copying.

---

## 6. Devcontainer .env

Create `.devcontainer/.env` (not committed, from template):

```
PROJECT_NAME={{project_name}}
GIT_NAME={{git_name}}
GIT_EMAIL={{git_email}}
```

Ask the user for `GIT_NAME` and `GIT_EMAIL` if not known from git config.

---

## 7. Install dependencies and initialize

```bash
pnpm install
git init  # if not already a git repo
npx husky init
echo "pnpm exec lint-staged" > .husky/pre-commit
pnpm format  # normalize files generated by create-next-app to our prettier config
```

---

## 8. Install skills

```bash
npx skills add loxosceles/ai-dev --yes
```

Ask: "Do you want to install any additional third-party skills? (e.g., `anthropics/claude-code`)"

---

## 9. Create docs structure

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

## 10. Create README.md

Generate a project README with:
- Project name and brief description (ask user)
- Tech stack summary
- Getting started (pnpm install, devcontainer, env setup)
- Available scripts
- Deployment info

---

## 11. Verification

Run a final format pass to catch any files created after the initial format (README, skills-lock.json, etc.):

```bash
pnpm format
```

Then run these checks. All must pass before the project is considered complete:

```bash
pnpm lint          # ESLint passes
pnpm format:check  # Prettier passes
pnpm build         # Next.js builds successfully
pnpm test          # Vitest smoke test passes
```

If any check fails, debug and fix. If the fix requires changing a fragment or blueprint spec, present the issue and ask before modifying.

---

## Adaptation rules

- **New major version of a dependency**: Ask before upgrading. Present changelog summary if possible.
- **Deprecated CLI flag**: Find the replacement, present it, ask for confirmation.
- **create-next-app output changed**: Adapt the patches (next.config, tsconfig exclude) to match the new output structure.
- **Fragment file conflicts**: Never silently modify a fragment. If a fragment doesn't work with current tool versions, report the conflict and ask.
