# STATUS — 032 Permissão de Telas e De-mock Navegação

**Data**: 2026-07-03 (arquivada)  
**Estado**: Concluída — 86/86 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Módulo `tela-permissao` — catálogo, telas por setor, overrides por usuário, conflitos, telas efetivas
- Endpoints: `GET /screens`, `GET/PUT /setores/:id/telas`, `GET/PUT /users/:id/tela-overrides`, `GET /users/:id/tela-conflicts`, `GET /users/:id/effective-screens`, `GET /me/screens`
- Schema Prisma: `SetorTela`, `UserTelaOverride`, enum `TelaOverrideKind`
- Catálogo `SCREEN_CATALOG` (~128 telas) incluindo módulo **Saúde** (`ModuloSlug.saude` + migration)
- Algoritmo de visibilidade efetiva: baseline setor, módulos abertos, chefia, bypass admin, grant/deny
- CRUD membros setor: `POST/DELETE /setores/:id/membros*`

### Client (`ci-client-v2/apps/web`)

- Painel `/administracao/plataforma/navegacao` — modos **Por usuário** e **Por setor**
- Componentes em `shell/components/permissions/` (`UserPicker`, `SectorPicker`, `NavigationVisibilityPanel`, skeletons)
- Sidebar e mobile nav filtram por `GET /me/screens` com bypass para telas fora do catálogo API (legado)
- Supplement de catálogo Saúde no client quando API ainda não retorna o módulo
- Toggle por agrupamento Saúde independente (Atendimento, Cadastros, Acompanhamento, Controle)
- Toast explicativo ao tentar editar telas não persistíveis
- Layout responsivo otimizado para ~1366px (3 colunas, picker estreito, label TI)

### Testes

- **API**: 28 testes Jest (`--testPathPatterns=tela-permissao`) + `screens.sync.spec.ts`
- **Client**: Vitest — `navigation-visibility-*`, `useMeScreens`, `AppSidebar.permissions`, `screen-catalog-supplement`, `nav-me-screen-filter`

---

## User stories

| US | Descrição | Status |
| --- | --- | --- |
| US1 | Visibilidade por setor | OK |
| US2 | Exceções por usuário + conflitos | OK |
| US3 | Catálogo API de telas | OK |
| US4 | CRUD membros do setor | OK |
| US5 | Sidebar reflete `/me/screens` | OK |
| US6 | Diagnóstico (badges, contadores) | OK |

---

## Validação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=tela-permissao
cd ci-client-v2/apps/web; npm test -- navigation-visibility useMeScreens AppSidebar.permissions screen-catalog-supplement

# Smoke manual (quickstart)
# Login admin@jacaranda.com → /administracao/plataforma/navegacao
# Por setor: toggles persistem via PUT /setores/:id/telas
# Por usuário: exceções, conflitos, save overrides
# Sidebar: itens ocultos conforme /me/screens
```

## Pós-entrega (sessão de polish)

- Cache `/me/screens` por `userId` + reset no login/logout
- Módulo Saúde no catálogo API + supplement client
- Fix toggle Saúde (subgrupos não expandem módulo inteiro)
- Skeleton loading fiel ao layout do painel

## Dívidas / futuro

- Vincular módulo Saúde a setor no seed Jacaranda (ModuloSetor) para baseline real
- Remover supplement client quando todos os ambientes tiverem API ≥ 032
