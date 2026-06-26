# Contract: Módulo Slugs Canônicos

**Feature**: 002-auth-setor-permissao  
**Version**: 1.0.0  
**Source of truth**: `ci-api-v2/CONTEXT.md` + extensões desta feature

## Enum ModuloSlug (Prisma + API)

| Slug | Label UI | Restrição setor | Notas |
|------|----------|-----------------|-------|
| `global` | Global | **Aberto** (FR-009) | Sem vínculos ModuloSetor |
| `tramitacao` | Tramitação | **Aberto** (FR-009) | Sem vínculos ModuloSetor |
| `ouvidoria` | Ouvidoria | Configurável | |
| `juridico` | Jurídico | Configurável | |
| `protocolo` | Protocolo Virtual | Configurável | Exemplo canônico spec |
| `patrimonio` | Patrimônio | Configurável | |
| `gabinete` | Gabinete | Configurável | |
| `compras` | Compras | Configurável | |
| `contratos` | Contratos | Configurável | |
| `administracao` | Administração | Por **papel** (FR-010) | Não usa ModuloSetor; `RolesGuard` |

## Client mapping

`ScreenConfig.module` em `apps/web/src/config/screens.ts` MUST use identical slug strings.

**Validation rule**: API and client MUST reject unknown slugs with 400.

## OPEN_MODULES constant (client + server)

```typescript
const OPEN_MODULES = new Set(['global', 'tramitacao'])
```

## Default seed bindings (demo tenant)

Espelha `admin-mock.ts` — referência para seed e testes:

| moduloSlug | setores (sigla) |
|------------|-----------------|
| ouvidoria | OUV |
| juridico | DEJUR |
| protocolo | GAB, DEJUR |
| patrimonio | DEAE |
| gabinete | GAB |
| compras | DEAE |
| contratos | CONT |
| global | (nenhum) |
| tramitacao | (nenhum) |
| administracao | (nenhum) |
