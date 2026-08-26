# Test Strategy: Documentos confidenciais na Tramitação

**Feature**: 033-tramitacao-docs-confidenciais  
**API**: Jest (`ci-api-v2`) · **Client**: Vitest/RTL (`ci-client-v2/apps/web`)

## Conventions

- TDD RED → GREEN → REFACTOR
- Integration specs em `ci-api-v2/src/modules/tramitacao/test/`
- Fixtures: tenant Jacaranda; Operadores A, B, C em setores distintos; admin_tenant
- Mock `StorageService` em unit; MinIO/Wasabi stub em integration
- Assert placeholder nunca contém `downloadUrl`, `url`, `storageKey`

---

## API — CT-DC-001..018

### Upload baseline (P1 US1)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-DC-001 | presign → confirm público; anexo em timeline evento created | integration |
| CT-DC-002 | add-link público vinculado a evento reply | integration |
| CT-DC-003 | presign arquivo >30MB → 400 FILE_TOO_LARGE | unit |
| CT-DC-004 | presign MIME inválido → 400 FILE_TYPE_NOT_ALLOWED | unit |
| CT-DC-005 | presign demanda arquivada → 409 DEMANDA_ARCHIVED | integration |

### Confidencialidade ACL (P1 US2–US3)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-DC-006 | confirm confidencial multi-setor; Access rows persistidas | integration |
| CT-DC-007 | confirm confidencial sem access → 400 CONFIDENTIAL_ACCESS_REQUIRED | integration |
| CT-DC-008 | setor com userIds vazio → 400 EMPTY_SECTOR_USERS | integration |
| CT-DC-009 | userId fora do sectorId → 400 USER_NOT_IN_SECTOR | integration |
| CT-DC-010 | autorizado GET detail accessLevel=full + download 200 | integration |
| CT-DC-011 | não autorizado mesmo setor → placeholder sem url | integration |
| CT-DC-012 | autor do anexo sempre full mesmo fora da access list | integration |
| CT-DC-013 | admin_tenant detail → todos anexos full | integration |
| CT-DC-014 | download não autorizado → 403 ANEXO_ACCESS_DENIED | integration |

### Forward / promote (P2 US5–US6)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-DC-015 | forward setor; ACL anexo antigo inalterada; novo membro setor placeholder | integration |
| CT-DC-016 | forward com novo anexo público; antigo confidencial mantém ACL | integration |
| CT-DC-017 | promote personal→sector; colega setor placeholder; autorizado full | integration |

### Caixa pessoal (P2 US4)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-DC-018 | mensagem pessoal A→B; confidencial autoriza C; B placeholder C full | integration |

### Unit

| ID | Descrição | Arquivo |
|----|-----------|---------|
| CT-DC-U01 | `resolveAnexoAccessLevel` matrix | `resolve-anexo-access.spec.ts` |
| CT-DC-U02 | `toAnexoDto` full vs placeholder | `tramitacao.mapper.spec.ts` |
| CT-DC-U03 | `confidentialAccessSchema` Zod refine | `tramitacao.schemas.spec.ts` |
| CT-DC-U04 | `validateUsersBelongToSectors` | `validate-anexo-access.spec.ts` |

---

## Client — CT-DC-019..022

| ID | Descrição | Arquivo |
|----|-----------|---------|
| CT-DC-019 | ConfidentialAccessPicker exige ≥1 user/setor | `ConfidentialAccessPicker.test.tsx` |
| CT-DC-020 | TramitacaoAnexoList render placeholder vs download | `TramitacaoAnexoList.test.tsx` |
| CT-DC-021 | Compose bloqueia envio se confidencial inválido | `TramitacaoInboxWorkspace.anexos.test.tsx` |
| CT-DC-022 | MSW handlers anexos tramitacao | `handlers/tramitacao.ts` |

---

## Coverage gates

- API: todos CT-DC-001..018 verdes antes merge
- Client: CT-DC-019..022 verdes
- SC-002: teste integração CT-DC-011 + CT-DC-014 obrigatório em CI
