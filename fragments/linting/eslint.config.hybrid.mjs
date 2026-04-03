import js from '@eslint/js';
import typescriptEslint from '@typescript-eslint/eslint-plugin';
import typescriptParser from '@typescript-eslint/parser';
import globals from 'globals';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const IGNORE_PATTERNS = [
  '**/node_modules/**',
  '**/.next/**',
  '**/out/**',
  '**/dist/**',
  '**/.sst/**',
  '**/*.d.ts',
  '**/__bak__*/**',
  '**/vitest.config.ts',
  '**/vitest.setup.ts',
  '**/.venv/**',
  '**/__pycache__/**',
];

const SHARED_RULES = {
  'eol-last': ['error', 'always'],
  'no-console': ['warn', { allow: ['error', 'warn'] }],
  'no-unused-vars': 'off',
};

const config = [
  { ignores: IGNORE_PATTERNS },

  // SST config + root TypeScript
  {
    files: ['sst.config.ts', 'scripts/**/*.ts'],
    languageOptions: {
      parser: typescriptParser,
      parserOptions: { ecmaVersion: 'latest', sourceType: 'module' },
    },
    plugins: { '@typescript-eslint': typescriptEslint },
    rules: {
      ...SHARED_RULES,
      'no-console': 'off',
      '@typescript-eslint/no-unused-vars': 'warn',
      '@typescript-eslint/no-explicit-any': 'error',
    },
  },

  // Plain JS (configs, scripts)
  {
    files: ['**/*.js', '**/*.mjs', '**/*.cjs'],
    ...js.configs.recommended,
    languageOptions: { globals: { ...globals.node } },
    rules: { ...SHARED_RULES },
  },
];

// ─── Optional: Frontend TypeScript (activated when frontend/ exists) ────────
const frontendTsconfig = path.join(__dirname, 'frontend/tsconfig.json');
if (fs.existsSync(frontendTsconfig)) {
  let importPlugin;
  let nextPlugin;

  try {
    importPlugin = (await import('eslint-plugin-import')).default;
    nextPlugin = (await import('@next/eslint-plugin-next')).default;
  } catch {
    // Next.js plugins not installed yet — skip frontend rules
  }

  if (importPlugin && nextPlugin) {
    config.splice(1, 0, {
      files: ['frontend/**/*.{ts,tsx}'],
      languageOptions: {
        parser: typescriptParser,
        parserOptions: {
          project: frontendTsconfig,
          ecmaVersion: 'latest',
          sourceType: 'module',
        },
      },
      plugins: {
        '@next/next': nextPlugin,
        '@typescript-eslint': typescriptEslint,
        import: importPlugin,
      },
      settings: {
        next: { rootDir: path.join(__dirname, 'frontend') },
        'import/resolver': {
          typescript: {
            alwaysTryTypes: true,
            project: frontendTsconfig,
          },
        },
      },
      rules: {
        ...SHARED_RULES,
        '@typescript-eslint/no-unused-vars': 'warn',
        '@typescript-eslint/no-explicit-any': 'error',
      },
    });
  }
}

export default config;
