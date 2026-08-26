# STATUS — PWA v1 → v2 Paridade 1:1

**Data**: 2026-08-25  
**Estado**: **Em curso** — Fases 1–2 implementadas ([Implementar PWA client v2](0653e4aa-d5e5-4879-b5b6-b73fe0888cbc)); Fase 3 (storage-cleanup) pendente.

`/speckit-complete` **não** aplicável até existir `spec.md` formal (opcional). Sem commit.

---

## Veredito

| Trilho | Estado |
|--------|--------|
| Spec (`plan.md`) | **Pronto** |
| Análise v1 (`analysis.md`) | **Pronto** — [Analisar PWA client v1](158e64c3-98fe-4cfa-aa63-d5541d9acbdb) |
| Implementação `@ci/web` (PWA + update prompt) | **Feito** — build + 4 testes Vitest OK |
| `storage-cleanup` logout/401 | **Pendente** (Fase 3) |
| Testes manuais (AC-1–AC-7) | **Não iniciados** |
| Deploy Ageman validado | **Em curso** — commit `3e46ce1` pushed; aguardar CI |

---

## Checklist — Fase 0: Análise v1 (Analisador)

- [ ] Ler repo v1: `C:\controle-interno-workspace\controle-interno-client`
- [ ] Escrever [`analysis.md`](./analysis.md) completo
- [ ] Confirmar bloco `VitePWA` literal (registerType, manifest, workbox, devOptions)
- [ ] Documentar `PwaUpdatePrompt` — hooks, textos, dismiss, updateServiceWorker
- [ ] Documentar `storage-cleanup.ts` + todos os call sites (logout, 401, impersonation)
- [ ] Inventariar assets PWA (`placeholder.svg`, `robots.txt`, ícones)
- [ ] Verificar meta tags PWA em `index.html` v1
- [ ] Inspecionar build output v1 (`sw.js`, `manifest.webmanifest`, workbox chunks)
- [ ] Documentar o que v1 **não** tem (install prompt, offline banner, runtime API cache)
- [ ] Tabela de mapeamento v1 → v2 com deltas de chaves storage e UI toast
- [ ] Validar compatibilidade `vite-plugin-pwa@0.21.x` + Vite 8

**Gate**: Implementador só inicia com todos os itens acima marcados.

---

## Checklist — Fase 1: Scaffold PWA (Implementador)

- [ ] Adicionar `vite-plugin-pwa` em `apps/web/package.json` (versão conforme `analysis.md`)
- [ ] Configurar `VitePWA(...)` em `apps/web/vite.config.ts` — **1:1 com v1**
- [ ] Copiar/criar assets em `apps/web/public/` (`placeholder.svg`, `robots.txt`)
- [ ] Tipos TS: `vite-plugin-pwa/client` se necessário
- [ ] `npm run build` gera `dist/sw.js` + `dist/manifest.webmanifest`
- [ ] `npm run typecheck` verde

---

## Checklist — Fase 2: Update prompt (Implementador)

- [ ] Criar `PwaUpdatePrompt` em `apps/web/src/modules/shell/components/`
- [ ] Usar `useRegisterSW` de `virtual:pwa-register/react`
- [ ] Textos PT idênticos ao v1 ("Nova versão disponível", "Atualizar Agora")
- [ ] Toast persistente até dismiss ou update (adaptar `ToastContext` se necessário)
- [ ] Montar `<PwaUpdatePrompt />` em `App.tsx` (root, como v1)
- [ ] T2 update flow manual — verde

---

## Checklist — Fase 3: Storage cleanup (Implementador)

- [ ] Portar `storage-cleanup.ts` → `apps/web/src/modules/shell/lib/`
- [ ] Adaptar chaves v2 (`ci-access-token`, session keys, etc.) — mapa em `analysis.md`
- [ ] Integrar `clearAllStorage` + `clearQueryCache` no logout (`AuthContext`)
- [ ] Integrar cleanup no session-lost handler (401)
- [ ] T4 logout cleanup manual — verde

---

## Checklist — Fase 4: Deploy & cache bust (Implementador)

- [ ] Confirmar `.htaccess` com `no-cache` em `index.html` (já existe em `public/`)
- [ ] Build zip compatível com `deploy-client-ageman.php`
- [ ] Pós-deploy: `sw.js` e manifest na raiz do subdomínio Ageman
- [ ] T3 cache bust simulado — verde

---

## Checklist — Fase 5: Testes de aceite

### AC-1 Installability
- [ ] Manifest válido (DevTools / Lighthouse)
- [ ] SW registrado em HTTPS/preview

### AC-2 Update flow
- [ ] `registerType: 'prompt'` — sem auto-reload
- [ ] Toast update após segundo build
- [ ] "Atualizar Agora" aplica nova versão

### AC-3 Cache bust
- [ ] `index.html` no-cache
- [ ] Hashed assets atualizam precache

### AC-4 Storage cleanup
- [ ] Logout limpa tokens + query cache + cookies
- [ ] Session lost limpa antes de redirect

### AC-5 Offline mínimo
- [ ] Shell carrega offline
- [ ] API falha graciosamente offline

### AC-6 Install prompt
- [ ] Confirmado N/A (v1 não tem) — ou implementado se análise encontrar

### AC-7 Regressão
- [ ] `npm test` verde em `apps/web`
- [ ] Deploy script inalterado funcionalmente

---

## Agentes

| Agente | Próxima ação | Bloqueio |
|--------|--------------|----------|
| **Analisador** | Produzir `analysis.md` | — |
| **Implementador** | Aguardar Fase 0 | Sem `analysis.md` |
| **Orquestrador PWA** | Revisar `analysis.md` quando pronto | — |

---

## Estado atual do v2 (baseline)

| Item | v2 hoje |
|------|---------|
| `vite-plugin-pwa` | **Ausente** |
| Service Worker | **Ausente** |
| Manifest | **Ausente** |
| Update prompt | **Ausente** |
| `storage-cleanup` | **Ausente** (logout só remove token + mock session) |
| `.htaccess` no-cache index | **Presente** (`apps/web/public/.htaccess`) |
| Toast UI | `ToastContext` (não Sonner) |

---

## Estado conhecido do v1 (pré-análise — confirmar em `analysis.md`)

| Item | v1 |
|------|-----|
| Plugin | `vite-plugin-pwa@^0.21.1` |
| registerType | `prompt` |
| Update UI | `PwaUpdatePrompt` + Sonner toast |
| Workbox | Precache only; `maxFileSize` 7 MiB; `devOptions.enabled: false` |
| Install prompt | **Provavelmente ausente** |
| Offline banner | **Provavelmente ausente** |
| Storage cleanup | `clearAllStorage` + `clearQueryCache` no logout |

---

## Histórico

| Data | Evento |
|------|--------|
| 2026-08-24 | Orquestrador PWA criou `plan.md` + `STATUS.md`; mapeamento inicial v1→v2 |
| 2026-08-25 | Implementador: `vite-plugin-pwa`, `PwaUpdatePrompt`, ícones, `robots.txt`; build OK |
| 2026-08-25 | Analisador: `analysis.md` — fluxo update, Workbox, diferenças client vs espacos |
