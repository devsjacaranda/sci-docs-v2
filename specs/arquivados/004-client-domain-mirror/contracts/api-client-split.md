# Contract: API Client Split

**Feature**: 004-client-domain-mirror  
**Version**: 1.0.0  
**Scope**: HTTP client modules in `apps/web/src/modules/*/api/`

## Base client (shell)

**File**: `modules/shell/api/api-client.ts`

Exports:

- `apiFetch<T>(path, init?)`
- `getAccessToken()`, `setAccessToken()`
- `AuthMeResponse` type (if used cross-module, re-export from auth barrel instead)

**Rules**:

- MUST inject `X-Tenant-ID` from `VITE_TENANT_ID`
- MUST inject `Authorization` when token present
- MUST NOT contain domain-specific endpoints

---

## auth/api/auth.ts

Migrated from `lib/auth.ts`.

| Function | Method | Path |
|----------|--------|------|
| login | POST | `/auth/login` |
| fetchMe | GET | `/auth/me` |

Imports: `@/modules/shell/api/api-client`

---

## address/api/

### types.ts

```typescript
export interface AddressInput { /* from ouvidoria-api */ }
export interface MunicipioOption { codigoIbge: string; nome: string; uf: string }
```

### municipios.ts

| Function | Method | Path |
|----------|--------|------|
| searchMunicipios | GET | `/address/municipios?q=&uf=` |

**Barrel** (`address/index.ts`): export `searchMunicipios`, types

---

## ouvidoria/api/

Split from `lib/ouvidoria-api.ts` — **exclude** `searchMunicipios`.

Suggested files:

| File | Functions |
|------|-----------|
| `manifestacoes.ts` | create/update draft, list, detail, revisao, confirm |
| `anexos.ts` | presignAnexo, addLinkAnexo |
| `workflow.ts` | encaminhar, responder, encerrar |
| `constants.ts` | TYPE_OPTIONS, etc. |
| `types.ts` | ManifestacaoDraftInput (imports AddressInput from `@/modules/address`) |

**Barrel** (`ouvidoria/index.ts`): re-export public API + page lazy helpers

---

## permissao/api/

Split from `lib/admin-api.ts` — prefix `/permissoes`.

| Function | Method | Path |
|----------|--------|------|
| fetchModuloVinculos | GET | `/permissoes/modulos` |
| replaceModuloVinculos | PUT | `/permissoes/modulos/:slug` |
| fetchNotificacoes | GET | `/permissoes/notificacoes` |
| markNotificacaoRead | PATCH | `/permissoes/notificacoes/:id/read` |

Types: `ApiModuloVinculo`, `ApiNotificacao` → `permissao/api/types.ts`

---

## setor/api/

Split from `lib/admin-api.ts` — prefixes `/setores`, `/users`.

| Function | Method | Path |
|----------|--------|------|
| fetchSetores | GET | `/setores` |
| fetchSetorMembros | GET | `/setores/:id/membros` |
| createSetor | POST | `/setores` |
| updateSetor | PATCH | `/setores/:id` |
| deleteSetor | DELETE | `/setores/:id` |
| fetchUsers | GET | `/users` |
| createUser | POST | `/users` |
| updateUser | PATCH | `/users/:id` |

Types: `ApiSetor`, `ApiUser`, `ApiSetorMembro` → `setor/api/types.ts`

---

## Import migration examples

```typescript
// Before
import { apiFetch } from '@/lib/api-client';
import { fetchSetores } from '@/lib/admin-api';
import { searchMunicipios } from '@/lib/ouvidoria-api';

// After
import { apiFetch } from '@/modules/shell/api/api-client';
import { fetchSetores } from '@/modules/setor/api/setores';
// or via barrel:
import { fetchSetores } from '@/modules/setor';
import { searchMunicipios } from '@/modules/address';
```

---

## Validation

After split:

1. `grep -r "lib/admin-api" apps/web/src` → zero matches
2. `grep -r "lib/ouvidoria-api" apps/web/src` → zero matches
3. `grep -r "lib/api-client" apps/web/src` → zero matches (except migration script)
4. All admin panels typecheck with new import paths
5. `ManifestacaoStepOneForm` municipios autocomplete uses `@/modules/address`
