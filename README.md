# Project Blueprints

Agent-driven project scaffolding. Blueprints define **what** a project should look like. An AI agent reads the blueprint and builds it, adapting to current tool versions while keeping the result deterministic.

## How it works

1. You tell the agent: "Create a new project using the nextjs-sst blueprint"
2. The agent reads the blueprint (a markdown document with exact specs)
3. It executes each section, using fragment files for configs that must be exact
4. When it detects a version mismatch or deprecation, it pauses and asks
5. It runs verification at the end to confirm everything works

## Structure

```
blueprints/
  nextjs-sst.md              # Full blueprint document
  (future: python-api.md, nextjs-static.md, ...)

fragments/
  devcontainer/               # Exact config files, copied verbatim
    Dockerfile.node
    docker-compose.yml
    devcontainer.json
    post_create.sh
  linting/
    eslint.config.mjs
    .prettierrc.cjs
    .prettierignore
  ci/
    deploy.yml
    lint.yml
    test.yml
    validate-version-label.yml
    version-and-tag.yml
  editor/
    vscode-settings.json
  project/
    .gitignore
    .npmrc
    .envrc
    .env_TEMPLATE
```

## Design principles

- **Deterministic**: Same blueprint → same project. Fragment files are copied exactly.
- **Adaptive**: When a pinned tool has a new major version, the agent asks before upgrading.
- **Simple**: Blueprints are readable markdown. Fragments are real config files. No YAML-interpreting-YAML.
- **Modular**: Fragments are shared across blueprints. Change a Dockerfile once, all blueprints get it.
- **Agent-executed**: No bash scripts. The agent handles errors, asks questions, and verifies.

## Usage

From any AI agent (Kiro, Claude, Copilot):

```
Create a new project using the nextjs-sst blueprint from loxosceles/project-blueprints
```

The agent clones this repo (or reads it via GitHub), follows the blueprint, and builds the project.

## Reference projects

These projects represent the current "gold standard" for each pattern:

| Project | Stack | Reference for |
|---------|-------|---------------|
| guitarizta | Next.js + SST + pnpm | Latest devcontainer, skills setup, CI/CD |
| career-match-engine | Next.js + CDK + pnpm | Backend infra, Lambda patterns, CLI tools |
| ai-portfolio | Next.js + CDK + pnpm | Frontend patterns, static hosting |
