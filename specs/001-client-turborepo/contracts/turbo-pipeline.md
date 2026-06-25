# Contract: Turbo Pipeline

**Feature**: 001-client-turborepo  
**Version**: 1.0.0  
**Scope**: Tarefas orquestradas na raiz de `ci-client-v2/`

## Root scripts (public API)

Comandos expostos na raiz de `ci-client-v2/package.json`:

| Command | Turbo invocation | Purpose |
|---------|------------------|---------|
| `npm run dev` | `turbo run dev --filter=@ci/web` | Dev server SPA |
| `npm run build` | `turbo run build` | Build produção |
| `npm run lint` | `turbo run lint` | ESLint em todos os pacotes |
| `npm run typecheck` | `turbo run typecheck` | TypeScript em todos os pacotes |

## turbo.json schema

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^typecheck"],
      "outputs": ["dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "typecheck": {
      "dependsOn": ["^typecheck"]
    }
  }
}
```

## Execution order guarantees (FR-006)

Para `npm run build`:

```text
1. @ci/typescript-config  (typecheck — leaf)
2. @ci/domain              (typecheck)
3. @ci/ui                  (typecheck)
4. @ci/web                 (typecheck → build → dist/)
```

Upstream packages MUST complete `typecheck` before downstream `build` starts.

## Cache contract (FR-007, SC-004)

| Task | Cached | Invalidation trigger |
|------|--------|---------------------|
| `build` | Yes | Source change in package or dependency |
| `typecheck` | Yes | TS source or tsconfig change |
| `lint` | Yes | Source or eslint config change |
| `dev` | No | N/A (persistent) |

**Cache directory**: `ci-client-v2/.turbo/` (gitignored)

**Verification**: segunda execução de `npm run build` sem alterações MUST reportar cache hits e completar ≥50% mais rápido.

## Failure behavior

- Falha em qualquer pacote MUST abort pipeline com exit code ≠ 0
- Mensagem MUST identificar pacote e task (`@ci/ui#typecheck`)
- Partial `dist/` de build falho MUST NOT ser usado para deploy

## CI integration (future-ready)

Pipeline CI SHOULD executar na raiz de `ci-client-v2`:

```bash
npm ci
npm run typecheck
npm run lint
npm run build
```

Ordem: typecheck → lint → build (build já depende de ^typecheck).
