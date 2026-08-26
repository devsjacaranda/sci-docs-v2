# Implementation Plan: PWA v1 → v2 Paridade 1:1 (`@ci/web`)

**Branch sugerida**: `pwa-v1-paridade` | **Date**: 2026-08-24 | **Spec**: *(sem `spec.md` formal — escopo definido por este plano)*

**Input**: Paridade PWA do client legado (`controle-interno-client`) para `@ci/web` em `ci-client-v2/apps/web`.

**Artefatos**:

| Arquivo | Responsável | Estado |
|---------|-------------|--------|
| [analysis.md](./analysis.md) | **Analisador** | Pendente |
| [plan.md](./plan.md) | Orquestrador PWA | Este documento |
| [STATUS.md](./STATUS.md) | Orquestrador + agentes | Checklist vivo |

**Skills obrigatórias**:

- `.cursor/skills/pwa-expert/SKILL.md` (+ `references/vite-react-integration.md`, `update-flow.md`)
- `vite-react-best-practices` — build/deploy SPA Ageman
- `ui-ux-pro-max` — apenas se ícones/branding precisarem ajuste (paleta Mint)

---

## Summary

Transformar `@ci/web` em PWA instalável com **mesmas configurações do v1 (1:1)**, priorizando:

1. **`registerType: 'prompt'`** — atualização controlada pelo usuário (não auto-reload)
2. **Toast/banner de nova versão** com botão "Atualizar Agora"
3. **Limpeza de storage local controlável** no logout/sessão (padrão v1 `storage-cleanup.ts`)
4. **Precache Workbox** de assets estáticos (sem inventar runtime caching que o v1 não tem)

O v2 **não tem PWA hoje** (`vite.config.ts` sem `vite-plugin-pwa`; `package.json` sem dependência). O v1 tem implementação mínima mas funcional centrada em `vite-plugin-pwa` + `PwaUpdatePrompt`.

**Princípio de paridade**: copiar comportamento v1; adaptar apenas o que for **impossível** manter igual por diferença de stack (Sonner → `ToastContext`, chaves de token v2, monorepo paths). Não adicionar features v1 não possui (install prompt UI, offline banner, runtime API cache) salvo decisão explícita pós-paridade.

---

## Contrato entre agentes

### Agente **Analisador**

**Entrada**: repositório v1 em `C:\controle-interno-workspace\controle-interno-client`

**Saída**: [`analysis.md`](./analysis.md) — documento canônico, bloqueante para implementação.

**Deve conter**:

| Seção | Conteúdo |
|-------|----------|
| Inventário de arquivos | Todos os arquivos v1 relacionados a PWA (ver lista esperada abaixo) |
| `vite.config.ts` | Bloco `VitePWA` completo — valores literais copiáveis |
| Manifest | Campos, ícones, cores, `display`, `scope`, `start_url` |
| Workbox | `globPatterns`, `maximumFileSizeToCacheInBytes`, runtime caching (se houver), `devOptions` |
| Registro SW | Como o SW é registrado (`injectRegister` default vs manual) |
| UI de update | `PwaUpdatePrompt` — hooks, textos PT, dismiss, `updateServiceWorker(true)` |
| Storage cleanup | `storage-cleanup.ts` — chaves removidas, integração logout/401 |
| `index.html` | Meta tags PWA (se existirem — v1 pode depender só do plugin) |
| Build output | Nomes gerados (`sw.js`, `manifest.webmanifest`, workbox precache) |
| Deploy prod | Headers, `.htaccess`, cache bust pós-deploy |
| O que v1 **não** tem | Install prompt, offline banner, background sync, etc. |
| Deltas v2 | Tabela arquivo-a-arquivo v1 → v2 com notas de adaptação |

**Critério de done (Analisador)**: Implementador consegue portar sem reler o repo v1.

### Agente **Implementador**

**Entrada**: `analysis.md` (obrigatório) + este `plan.md`

**Saída**: código em `ci-client-v2/apps/web/` espelhando v1 1:1.

**Regras**:

1. **Não improvisar** config Workbox/manifest além do documentado em `analysis.md`
2. Copiar textos PT do toast de update verbatim (salvo ajuste de componente UI)
3. Montar `PwaUpdatePrompt` no root de `App.tsx` (equivalente v1 linha ~129)
4. Portar `storage-cleanup.ts` adaptando chaves v2 (`ci-access-token`, etc.)
5. Integrar cleanup no fluxo de logout e session-lost (como v1 faz em `use-auth.ts` + `client.ts`)
6. Adicionar `vite-plugin-pwa` devDependency — preferir mesma major do v1 (`^0.21.x`) salvo incompatibilidade Vite 8 documentada
7. Tipos TS: `vite-plugin-pwa/client` em `tsconfig.app.json` se necessário
8. **Não** alterar `@ci/admin-saas` nesta feature
9. Rodar `npm run build` em `apps/web` e validar artefatos SW no `dist/`

**Critério de done (Implementador)**: todos os itens de aceite em [STATUS.md](./STATUS.md) marcáveis como verificados.

---

## Inventário de arquivos v1 esperados

O Analisador deve confirmar existência e conteúdo. Caminhos relativos ao root de `controle-interno-client`:

| # | Arquivo v1 | Papel |
|---|------------|-------|
| 1 | `vite.config.ts` | Plugin `VitePWA` — manifest, workbox, `registerType`, `devOptions` |
| 2 | `package.json` | Dependência `vite-plugin-pwa` (versão exata) |
| 3 | `src/shared/components/pwa-update-prompt.tsx` | UI de update via `useRegisterSW` |
| 4 | `src/app.tsx` | Montagem de `<PwaUpdatePrompt />` no root |
| 5 | `src/shared/utils/storage-cleanup.ts` | Limpeza localStorage/sessionStorage/cookies/React Query |
| 6 | `src/modules/auth/hooks/use-auth.ts` | Logout chama `clearAllStorage` + `clearQueryCache` |
| 7 | `src/shared/api/client.ts` | Import de `clearAllStorage` (401 / session lost) |
| 8 | `src/shared/components/impersonation-banner.tsx` | Possível uso de cleanup |
| 9 | `public/placeholder.svg` | Ícone manifest (v1 usa SVG placeholder) |
| 10 | `public/robots.txt` | Listado em `includeAssets` |
| 11 | `index.html` | Meta PWA (verificar se plugin injeta ou manual) |
| 12 | *(build)* `dist/sw.js` | Service worker gerado |
| 13 | *(build)* `dist/manifest.webmanifest` | Manifest gerado |
| 14 | *(build)* `dist/workbox-*.js` | Runtime Workbox (se gerado) |

**Arquivos v1 provavelmente ausentes** (Analisador confirma):

- Hook `beforeinstallprompt` / install banner
- Banner offline / `useOnlineStatus`
- SW manual em `public/sw.js`
- Runtime caching de API no Workbox

---

## Mapeamento v1 → v2 (alvo)

| v1 | v2 (`@ci/web`) | Notas |
|----|----------------|-------|
| `vite.config.ts` → `VitePWA(...)` | `apps/web/vite.config.ts` | Mesmo bloco; manter proxy/server v2 intacto |
| `pwa-update-prompt.tsx` | `apps/web/src/modules/shell/components/PwaUpdatePrompt.tsx` | Usar `ToastContext` em vez de Sonner |
| `storage-cleanup.ts` | `apps/web/src/modules/shell/lib/storage-cleanup.ts` | Chaves v2: `ci-access-token`, `ci-theme`, `ci-mock-session`, etc. |
| `app.tsx` mount | `apps/web/src/App.tsx` | Dentro de providers, antes do router |
| `public/placeholder.svg` | `apps/web/public/placeholder.svg` | Ou ícones Mint se branding exigir |
| `public/robots.txt` | `apps/web/public/robots.txt` | Criar se ausente |
| Logout cleanup | `AuthContext.tsx` + `auth.ts` | Chamar cleanup síncrono antes de redirect |
| Session lost | `api-client` handler em `AuthContext` | Espelhar v1 `client.ts` |
| `.htaccess` | `apps/web/public/.htaccess` | v2 já tem `no-cache` em `index.html` — Analisador valida suficiente para SW update |

---

## Pré-análise rápida (Orquestrador — sujeita a confirmação do Analisador)

Valores v1 já identificados em `controle-interno-client/vite.config.ts`:

```typescript
VitePWA({
  registerType: "prompt",
  includeAssets: ["placeholder.svg", "robots.txt"],
  manifest: {
    name: "Sistema de Controle Interno",
    short_name: "Controle Interno",
    description: "Sistema de gestão e controle interno para órgãos públicos",
    theme_color: "#0f172a",
    background_color: "#ffffff",
    display: "standalone",
    scope: "/",
    start_url: "/",
    icons: [
      { src: "placeholder.svg", sizes: "any", type: "image/svg+xml", purpose: "any" },
      { src: "placeholder.svg", sizes: "any", type: "image/svg+xml", purpose: "maskable" },
    ],
  },
  workbox: {
    globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2}"],
    maximumFileSizeToCacheInBytes: 7 * 1024 * 1024,
  },
  devOptions: { enabled: false },
})
```

`PwaUpdatePrompt` v1 usa `virtual:pwa-register/react` + Sonner toast infinito + botão "Atualizar Agora".

**Delta arquitetural v2**: API em origin separado (`VITE_API_URL=https://api-v2.controleinterno.org`) — v1 usava proxy `/api` no Vite dev; **não** implica runtime caching no SW (v1 também não tinha). Paridade mantida.

---

## Fases e dependências

```
Fase 0 — Análise v1          →  analysis.md
         ↓ (bloqueante)
Fase 1 — Scaffold PWA        →  vite-plugin-pwa, manifest, build SW
         ↓
Fase 2 — Update prompt       →  PwaUpdatePrompt + App.tsx
         ↓
Fase 3 — Storage cleanup     →  storage-cleanup + auth/logout/session-lost
         ↓
Fase 4 — Deploy & cache bust →  dist/, .htaccess, deploy Ageman
         ↓
Fase 5 — Testes de aceite    →  manual + checklist STATUS
```

| Fase | Depende de | Entregável |
|------|------------|------------|
| 0 | — | `analysis.md` completo |
| 1 | Fase 0 | `npm run build` gera `sw.js` + manifest |
| 2 | Fase 1 | Toast update funcional em dev/preview |
| 3 | Fase 0, 1 | Logout limpa storage + query cache |
| 4 | Fases 1–3 | Deploy zip Ageman; SW servido na raiz |
| 5 | Fases 1–4 | Checklist STATUS verde |

---

## Critérios de aceite

### AC-1 — Installability (mínimo)

- [ ] Lighthouse PWA (ou DevTools → Application → Manifest) reporta manifest válido
- [ ] Ícones 192+ presentes (v1 usa SVG `any` — manter paridade)
- [ ] `display: standalone`, HTTPS em produção Ageman
- [ ] Service Worker registrado após load em produção

### AC-2 — Update flow (crítico — paridade v1)

- [ ] `registerType: 'prompt'` — **sem** auto-reload silencioso
- [ ] Após deploy simulado (dois builds consecutivos), SW entra estado `waiting`
- [ ] Toast "Nova versão disponível" com descrição PT e botão "Atualizar Agora"
- [ ] Clicar "Atualizar Agora" chama `updateServiceWorker(true)` e recarrega com nova versão
- [ ] Dismiss do toast não aplica update imediato (`setNeedRefresh(false)`)

### AC-3 — Cache bust / deploy

- [ ] `index.html` servido com `Cache-Control: no-cache` (`.htaccess` v2 já prevê)
- [ ] Assets hashed (`assets/*.js`) atualizam precache no novo SW
- [ ] Segundo deploy substitui SW antigo; usuário vê prompt (não fica preso em versão stale)
- [ ] `sw.js` e `manifest.webmanifest` acessíveis na raiz pós-deploy Ageman

### AC-4 — Limpeza storage local (controlável)

- [ ] Logout remove tokens e dados de sessão v2 (equivalente v1 `clearAllStorage`)
- [ ] Logout limpa React Query cache (`clearQueryCache`)
- [ ] Session lost (401) também dispara cleanup antes de redirect login
- [ ] Cookies do domínio limpos (mesma estratégia v1 `clearAllCookies`)

### AC-5 — Offline mínimo

- [ ] Com rede offline, shell SPA carrega (precache JS/CSS/HTML)
- [ ] Rotas client-side navegam dentro do shell cacheado
- [ ] Chamadas API falham graciosamente (erro de rede na UI — comportamento atual v2)
- [ ] **Não** exigir offline de dados autenticados (v1 não tinha)

### AC-6 — Install prompt (escopo v1)

- [ ] **N/A se v1 não implementa** — Analisador documenta ausência
- [ ] Se ausente no v1: não implementar install banner nesta feature

### AC-7 — Build & regressão

- [ ] `npm run build` em `apps/web` passa
- [ ] `npm run typecheck` passa
- [ ] `npm test` em `apps/web` passa (sem regressão)
- [ ] Bundle não quebra deploy existente `deploy-client-ageman.php`

---

## Testes de aceite (roteiro manual)

### T1 — Registro SW (preview/prod)

1. `cd ci-client-v2/apps/web && npm run build && npm run preview`
2. Chrome DevTools → Application → Service Workers → SW ativo
3. Manifest exibe name/short_name/theme_color do v1

### T2 — Update flow

1. Build v1 (`npm run build`) — anotar hash de `dist/sw.js`
2. Servir preview, abrir app, confirmar SW controller
3. Alterar string visível (ex. título toast), rebuild
4. Recarregar página — deve aparecer toast update **sem** reload automático
5. Clicar "Atualizar Agora" — reload + nova versão ativa

### T3 — Cache bust pós-deploy

1. Simular deploy: zip `dist/` → extrair como Ageman
2. Verificar `index.html` headers no-cache
3. Segundo zip com asset hash diferente → prompt update

### T4 — Logout cleanup

1. Login, navegar (popular query cache)
2. Logout
3. DevTools → Application → Local Storage / Session Storage vazios das chaves de auth
4. Voltar à app → redireciona login sem token residual

### T5 — Offline mínimo

1. DevTools → Network → Offline
2. Recarregar — shell carrega (login ou última rota cacheada)
3. Tentar ação API — erro de rede explícito, sem crash

---

## Riscos e decisões

| Risco | Mitigação |
|-------|-----------|
| `vite-plugin-pwa@0.21` vs Vite 8 | Analisador testa compat; bump minor se necessário, documentar em `analysis.md` |
| Sonner → ToastContext | Toast v2 auto-dismiss 5s com action — **Implementador** deve manter toast persistente até dismiss/update (adaptar `ToastProvider` ou estado local) |
| Chaves storage v1 ≠ v2 | `analysis.md` lista mapa completo de chaves |
| Chunk > 5 MiB | v1 já usa `maximumFileSizeToCacheInBytes: 7 MiB` — manter |
| API cross-origin | Sem runtime cache — paridade v1; dados sempre via rede |

---

## Fora de escopo (nesta feature)

- Install prompt UI (`beforeinstallprompt`)
- Offline banner dedicado
- Background sync / push notifications
- PWA em `@ci/admin-saas` ou `@ci/publico`
- Ícones branding tenant-specific (usar placeholder v1 salvo pedido UX)
- Runtime caching `/v1` ou `/api` (v1 não tem; skill pwa-expert sugere mas **não** aplica aqui)

---

## Referências

- v1 repo: `C:\controle-interno-workspace\controle-interno-client`
- v2 app: `ci-client-v2/apps/web`
- Deploy Ageman: `ci-client-v2/scripts/deploy/deploy-client-ageman.php`
- Skill: `.cursor/skills/pwa-expert/SKILL.md`
- Paleta (se ícones): `.cursor/rules/mint-palette.mdc`
