# Quickstart: Validação da Arquitetura Modular Espelho da API

**Feature**: 004-client-domain-mirror  
**Prerequisites**: Node.js 20+, npm 10+, API opcional (`VITE_USE_API`)  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec 003 ouvidoria](../003-ouvidoria/quickstart.md)

> Executar **após** implementação (`/speckit-implement`). Cenários mapeiam VS-* do data model.

## Setup inicial

```powershell
cd ci-client-v2
npm install
npm run typecheck
npm run lint
```

**Expected**: zero erros; imports `@/modules/*` resolvem; pacotes `@ci/ui` e `@ci/domain` inalterados.

---

## VS-001 — Zero pastas legadas (SC-003)

```powershell
cd ci-client-v2/apps/web
# Após implementação: script de verificação
powershell -File scripts/verify-module-layout.ps1
```

**Expected**:

- Zero arquivos `.ts`/`.tsx` em `src/pages/`, `src/components/`, `src/lib/`, `src/config/`, `src/context/`, `src/data/`, `src/hooks/`
- Pastas legadas removidas ou vazias

**Manual check**:

```powershell
Get-ChildItem -Recurse -Include *.ts,*.tsx src/pages,src/components,src/lib,src/config,src/context,src/data,src/hooks -ErrorAction SilentlyContinue
```

**Expected**: nenhum resultado

---

## VS-002 — Paridade de slugs API ↔ client (SC-002)

Verificar que existem pastas em `apps/web/src/modules/`:

| Slug API (`ci-api-v2/src/modules/`) | Pasta client |
|-------------------------------------|--------------|
| auth | `modules/auth/` |
| address | `modules/address/` |
| ouvidoria | `modules/ouvidoria/` |
| permissao | `modules/permissao/` |
| setor | `modules/setor/` |
| tenant | `modules/tenant/` |
| audit | `modules/audit/` |

Plus: `modules/shell/`, `modules/shared/`

**Expected**: revisor mapeia todos em < 2 minutos (SC-002)

---

## VS-003 — Dev server (SC-001 baseline)

```powershell
cd ci-client-v2
npm run dev
```

**Expected**:

- Vite inicia em `http://localhost:5173`
- Sem erros de resolução `@/modules/*`
- HMR funcional

---

## VS-004 — Fluxos principais (SC-001)

Com dev server ativo:

| Step | Action | Expected |
|------|--------|----------|
| 1 | Abrir `/login` | LoginPage renderiza (`modules/auth/pages/`) |
| 2 | Autenticar | Redirect dashboard |
| 3 | Navegar sidebar (global, licenças) | Rotas carregam; layout shell OK |
| 4 | Alternar tema claro/escuro | Tokens Mint; persistência OK |
| 5 | Filtrar licenças Carvalho/Pau-Brasil/Jatobá/Cedro | Alertas e breadcrumbs corretos |

---

## VS-005 — Ouvidoria (SC-001, spec 003)

| Step | Action | Expected |
|------|--------|----------|
| 1 | `/ouvidoria/manifestacoes` | Lista renderiza |
| 2 | Nova manifestação (wizard 3 etapas) | Form, anexos, revisão OK |
| 3 | Autocomplete município | Usa client `modules/address/` |
| 4 | Detalhe manifestação | Timeline e ações OK |
| 5 | Confirmar envio | Protocolo + chave consulta |

---

## VS-006 — Admin permissão + setor (SC-001)

Via telas admin em ScreenPage:

| Screen | Panel | Module |
|--------|-------|--------|
| platform-sectors | PlatformSectorsPanel | setor |
| platform-users | PlatformUsersPanel | setor |
| members | SectorMembersPanel | setor |
| bindings | ModuleSectorBindingsPanel | permissao |
| notifications | AdminNotificationsPanel | permissao |

**Expected**: CRUD/listagens funcionam; AccessDenied403 de `shared/` em telas sem permissão

---

## VS-007 — Audit mock (Cedro hub)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navegar para hub Cedro global (`global-painel-ia`) | AuditLogsPanel renderiza |
| 2 | Verificar origem | Componente em `modules/audit/components/` |

---

## VS-008 — Build produção (SC-005)

```powershell
cd ci-client-v2
npm run build
```

**Expected**:

- Build conclui sem erros
- Artefato em `apps/web/dist/`
- Variáveis `VITE_*` inalteradas

```powershell
npm run preview
# smoke: abrir preview URL, repetir login + navegação básica
```

---

## VS-009 — Boundaries ESLint (SC-007)

```powershell
cd ci-client-v2
npm run lint
```

**Expected**: zero violations de `no-restricted-imports` (legacy paths, deep cross-module)

**Negative test** (opcional, dev only): adicionar import `@/lib/api-client` temporário → lint MUST fail

---

## VS-010 — Documentação (SC-006)

Abrir `ci-client-v2/README.md` e verificar:

- [ ] Seção layout modular (`modules/shell`, `shared`, domínios)
- [ ] Decision tree shell vs shared vs domínio
- [ ] Checklist adicionar novo domínio

**Expected**: par revisor classifica 3 exemplos (layout global → shell; AccessDenied403 → shared; PlatformUsersPanel → setor) corretamente

---

## Rollback criteria

Abort merge se qualquer VS crítico falhar:

- VS-001 (legado)
- VS-004 (fluxos principais)
- VS-005 (ouvidoria)
- VS-008 (build)
