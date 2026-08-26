# Análise PWA v1 — Atualizações e Cache

> **Objetivo:** documentar como o PWA do client v1 funciona hoje, para paridade 1:1 no v2 (`ci-client-v2/apps/web`).
> **Fonte:** `C:\controle-interno-workspace` · builds de produção gerados em 2026-08-24.
> **v2 ref:** `c:\ci-v2\ci-client-v2\apps\web` — **sem PWA configurado** (apenas `react()` + `tailwindcss()` no `vite.config.ts`).

---

## 1. Escopo — quais apps v1 têm PWA

| App | Caminho | Papel | PWA |
|-----|---------|-------|-----|
| **Client principal** | `controle-interno-client/` | SPA tenant/admin (módulos completos) | Sim |
| **Espaços (agendamento)** | `controle-interno-espacos/` | PWA focado em agendamento de espaços | Sim (ícones oficiais) |
| `controle-interno-frontend/` | — | Não usa `vite-plugin-pwa` | Não |

Ambos os apps PWA compartilham **a mesma implementação** de prompt de atualização (`pwa-update-prompt.tsx`) e **mesma estratégia** `registerType: "prompt"`. Diferem em manifest/ícones, `devOptions` e limite de tamanho de precache.

---

## 2. Stack e dependências

| Item | Valor v1 |
|------|----------|
| Plugin | `vite-plugin-pwa` `^0.21.1` (lock: **0.21.2**) |
| Workbox (transitivo) | **7.4.0** |
| Modo SW | `generateSW` (padrão — Workbox gera `sw.js` no build) |
| Registro React | `useRegisterSW` de `virtual:pwa-register/react` |
| Bundler | Vite **6.x** |
| UI update | Sonner toast + botão shadcn |

**Arquivos gerados no build (`dist/`):**

```
dist/manifest.webmanifest
dist/sw.js
dist/workbox-<hash>.js
dist/assets/workbox-window.prod.es5-<hash>.js   # chunk do registro em runtime
```

Build client (referência):

```
PWA v0.21.2
mode      generateSW
precache  24 entries (10409.44 KiB)
files generated
  dist/sw.js
  dist/workbox-1ef09536.js
```

Build espacos (referência):

```
PWA v0.21.2
mode      generateSW
precache  19 entries (1655.84 KiB)
```

---

## 3. Configuração `vite-plugin-pwa`

### 3.1 Client principal — `controle-interno-client/vite.config.ts`

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
    maximumFileSizeToCacheInBytes: 7 * 1024 * 1024, // 7 MiB
  },
  devOptions: {
    enabled: false,
  },
}),
```

### 3.2 Espaços — `controle-interno-espacos/vite.config.ts`

Mesma base, com diferenças:

| Opção | Client | Espaços |
|-------|--------|---------|
| `manifest.name` | `"Sistema de Controle Interno"` | `"Controle Interno - Espaços"` |
| `manifest.short_name` | `"Controle Interno"` | `"Espaços"` |
| `manifest.description` | gestão/controle interno | gestão de espaços e agendamentos |
| `includeAssets` | `placeholder.svg`, `robots.txt` | `icon-192.png`, `icon-512.png`, `icon-192-maskable.png`, `icon-512-maskable.png`, `robots.txt` |
| `manifest.icons` | `placeholder.svg` (any + maskable) | `pwaManifestIcons` (PNG 192/512) |
| `maximumFileSizeToCacheInBytes` | **7 MiB** | **5 MiB** |
| `devOptions.enabled` | **`false`** | **`true`** |

Ícones extraídos para módulo testável — `controle-interno-espacos/pwa-manifest-icons.ts`:

```typescript
export const pwaManifestIcons: PwaManifestIcon[] = [
  { src: 'icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
  { src: 'icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
  { src: 'icon-192-maskable.png', sizes: '192x192', type: 'image/png', purpose: 'maskable' },
  { src: 'icon-512-maskable.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
];
```

Testes: `controle-interno-espacos/__tests__/pwa-manifest.unit.test.ts` (RF-05 — sem `placeholder.svg`).

### 3.3 Opções **não** configuradas em v1 (defaults do plugin)

| Opção | Comportamento v1 |
|-------|------------------|
| `strategies` | `generateSW` (default) |
| `filename` | `sw.js` (default) |
| `manifestFilename` | `manifest.webmanifest` (default) |
| `injectRegister` | **Desabilitado implicitamente** — app usa `virtual:pwa-register/react` (sem script inline no `index.html`) |
| `workbox.navigateFallback` | `index.html` (default SPA) |
| `workbox.navigateFallbackDenylist` | **Não definido** — fallback SPA para todas as rotas de navegação |
| `workbox.runtimeCaching` | **Não definido** — sem cache de API |
| `workbox.clientsClaim` | **Não definido** — default do generateSW |
| `workbox.skipWaiting` | **Não true** — skipWaiting só via mensagem `SKIP_WAITING` |
| `selfDestroying` | false (default) |
| `lang` no manifest | Omitido no config → build emite `"lang":"en"` |

---

## 4. Manifest — valores literais (produção)

### 4.1 Client (`dist/manifest.webmanifest`)

```json
{
  "name": "Sistema de Controle Interno",
  "short_name": "Controle Interno",
  "description": "Sistema de gestão e controle interno para órgãos públicos",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0f172a",
  "lang": "en",
  "scope": "/",
  "icons": [
    { "src": "placeholder.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any" },
    { "src": "placeholder.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "maskable" }
  ]
}
```

### 4.2 Espaços (`dist/manifest.webmanifest`)

```json
{
  "name": "Controle Interno - Espaços",
  "short_name": "Espaços",
  "description": "Sistema de gestão de espaços e agendamentos para órgãos públicos",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0f172a",
  "lang": "en",
  "scope": "/",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
    { "src": "icon-192-maskable.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icon-512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

### 4.3 Assets públicos

**Client** (`controle-interno-client/public/`):

- `placeholder.svg`
- `robots.txt`
- Logos tenant (precached no build: `ageman-logo-500x500.png`, `LOGOAM.png`, etc.)

**Espaços** (`controle-interno-espacos/public/`):

- `icon-192.png`, `icon-512.png`, `icon-192-maskable.png`, `icon-512-maskable.png`
- `robots.txt`, `placeholder.svg`, `favicon.ico`

### 4.4 `index.html` — meta PWA

**Não há** tags manuais de PWA no source (`manifest`, `theme-color`, `apple-mobile-web-app-*`).

O plugin injeta **somente** no build:

```html
<link rel="manifest" href="/manifest.webmanifest">
```

Tema dark/light usa `localStorage` separado (`controle-interno-theme`) — **não é cache PWA** (ver seção 8).

---

## 5. Service Worker gerado

### 5.1 Estrutura (`dist/sw.js` — client, minificado)

Comportamento equivalente ao código legível abaixo (confirmado também em `controle-interno-espacos/dev-dist/sw.js` em dev):

```javascript
// Listener para ativação sob demanda (registerType: "prompt")
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Precache de todos os assets do build + includeAssets
workbox.precacheAndRoute([/* 24 entries client / 19 espacos */], {});

// Remove caches precache de versões anteriores do Workbox
workbox.cleanupOutdatedCaches();

// SPA fallback: navegação → index.html
workbox.registerRoute(
  new workbox.NavigationRoute(
    workbox.createHandlerBoundToURL('index.html')
  )
);
```

**Produção (client)** — entradas precache incluem:

- `index.html` (revision MD5)
- `manifest.webmanifest` (revision MD5)
- Assets Vite hashed (`revision: null` — hash no filename)
- PNGs/SVGs estáticos em `public/` (revision MD5)
- `robots.txt`, `favicon.ico`, etc.

**Não há** `runtimeCaching` — chamadas `/api` **não** são interceptadas pelo SW.

### 5.2 Nomes de cache (Workbox 7.4)

Padrão interno Workbox (`workbox-core/cacheNames`):

| Componente | Valor base |
|------------|------------|
| prefix | `workbox` |
| precache | `precache-v2` |
| suffix | hash derivado do scope + versão |

Nome efetivo (exemplo): `workbox-precache-v2-<hash>/`

`cleanupOutdatedCaches()` apaga caches cujo nome contém `-precache-` e não corresponde ao precache atual.

### 5.3 Estratégia de versionamento

| Tipo de arquivo | Versionamento |
|-----------------|---------------|
| Chunks Vite (`assets/*.js`, `*.css`) | Hash no filename → `revision: null` no manifest precache |
| Arquivos estáticos (`index.html`, PNGs, SVG) | MD5 em `revision` |
| Novo deploy | Novo `sw.js` + novo manifest precache → SW entra em estado **waiting** |

**Não há** version string manual, localStorage de versão, nem query param em `start_url`.

---

## 6. Fluxo de atualização — passo a passo

```mermaid
sequenceDiagram
  participant User as Usuário
  participant App as React App
  participant WW as workbox-window
  participant SW as Service Worker (waiting)
  participant Cache as Cache Storage

  Note over App: Mount PwaUpdatePrompt → useRegisterSW()
  App->>WW: register('/sw.js')
  WW->>SW: install + precache assets

  Note over User,Cache: Após novo deploy
  WW->>SW: detecta sw.js novo → installing → waiting
  WW->>App: onNeedRefresh → needRefresh = true
  App->>User: toast "Nova versão disponível"

  alt Usuário clica "Atualizar Agora"
    User->>App: updateServiceWorker(true)
    App->>SW: postMessage SKIP_WAITING
    SW->>SW: skipWaiting()
    SW->>Cache: activate → cleanupOutdatedCaches()
    WW->>App: controlling → reload(true)
    App->>User: página recarrega com SW novo
  else Usuário dispensa toast
    User->>App: onDismiss → setNeedRefresh(false)
    Note over SW: SW waiting permanece; aba continua na versão antiga
  end
```

### 6.1 Detalhamento por fase

#### Fase A — Registro (primeira visita / reload)

1. `PwaUpdatePrompt` monta no topo de `App` (antes do router).
2. `useRegisterSW()` (via `virtual:pwa-register/react`) registra `/sw.js` com scope `/`.
3. Callbacks:
   - `onRegistered` → `console.log("[PWA] Service Worker registrado:", r)`
   - `onRegisterError` → `console.error("[PWA] Erro no registro...", error)`
4. SW instala, precacheia assets listados, ativa (primeira instalação não exige prompt).

#### Fase B — Detecção de nova versão

1. Browser refetch `sw.js` (visita, focus, intervalo do browser, ou `registration.update()`).
2. Byte diff no SW → nova instalação entra em **`waiting`** (porque `registerType: "prompt"` **não** chama `skipWaiting()` no install).
3. `workbox-window` dispara callback → `needRefresh = true`.

#### Fase C — UI "Nova versão disponível"

Componente: `controle-interno-client/src/shared/components/pwa-update-prompt.tsx` (cópia idêntica em espacos).

```tsx
export function PwaUpdatePrompt() {
  const {
    needRefresh: [needRefresh, setNeedRefresh],
    updateServiceWorker,
  } = useRegisterSW({
    onRegistered(r) {
      if (r) console.log("[PWA] Service Worker registrado:", r);
    },
    onRegisterError(error) {
      console.error("[PWA] Erro no registro do Service Worker:", error);
    },
  });

  useEffect(() => {
    if (needRefresh) {
      toast.info("Nova versão disponível", {
        description:
          "Atualize o aplicativo para obter as últimas melhorias e correções.",
        duration: Infinity,
        action: (
          <Button
            variant="default"
            size="sm"
            className="flex items-center gap-2"
            onClick={() => updateServiceWorker(true)}
          >
            <RefreshCw className="h-4 w-4" />
            Atualizar Agora
          </Button>
        ),
        onDismiss: () => setNeedRefresh(false),
      });
    }
  }, [needRefresh, updateServiceWorker, setNeedRefresh]);

  return null;
}
```

**Strings literais UI:**

| Elemento | Texto |
|----------|-------|
| Toast title | `Nova versão disponível` |
| Toast description | `Atualize o aplicativo para obter as últimas melhorias e correções.` |
| Botão | `Atualizar Agora` |
| duration | `Infinity` (toast persiste até ação/dismiss) |

#### Fase D — Aplicar atualização (`updateServiceWorker(true)`)

1. `workbox-window` envia `{ type: 'SKIP_WAITING' }` ao SW waiting.
2. SW executa `self.skipWaiting()`.
3. SW novo ativa → `cleanupOutdatedCaches()` remove precaches obsoletos.
4. Argumento `true` → **reload automático** da página quando o SW passa a controlar clients.
5. Próximo load serve HTML/JS/CSS do precache atualizado.

#### Fase E — Quando **não** força reload

- Usuário **dispensa** o toast (`onDismiss` → `setNeedRefresh(false)`): app continua na versão antiga; SW novo fica waiting até próximo refresh manual ou nova tentativa.
- **`registerType: "prompt"`** garante que **nunca** há auto-reload silencioso no deploy.

### 6.2 Montagem no app

**Client** — `controle-interno-client/src/app.tsx`:

```tsx
<PwaUpdatePrompt />
<Toaster />
<Sonner />
```

**Espaços** — `controle-interno-espacos/src/app.tsx` (ordem ligeiramente diferente, mesmo efeito):

```tsx
<Toaster />
<Sonner />
<PwaUpdatePrompt />
```

**`main.tsx`** — sem registro manual; apenas `createRoot(...).render(<App />)`.

---

## 7. Cache — quando limpa, quando persiste

| Evento | Ação |
|--------|------|
| Primeiro install | Precache de todos os assets do build |
| Navegação SPA | `NavigationRoute` → `index.html` do precache (offline shell) |
| Request `/api/*` | Rede direta (sem SW runtime cache) |
| Novo deploy + usuário atualiza | Novo precache; `cleanupOutdatedCaches()` deleta caches `-precache-` antigos |
| Dev client (`devOptions.enabled: false`) | **Sem SW** em `npm run dev` |
| Dev espacos (`devOptions.enabled: true`) | SW em `dev-dist/sw.js`; NavigationRoute com `allowlist: [/^\/$/]` (apenas `/`) |

**Implicação offline v1:** shell SPA e assets estáticos precached funcionam offline; **dados de API falham** normalmente (React Query, etc.) — **não há** banner offline nem retry queue.

---

## 8. localStorage / sessionStorage

### 8.1 Chaves relacionadas a PWA

**Nenhuma.** v1 **não** persiste estado de versão, skip update, nem controle de cache em storage.

### 8.2 Chave presente no `index.html` (não-PWA)

```javascript
const STORAGE_KEY = 'controle-interno-theme';
// valores: 'dark' | 'light'
```

Usada apenas para tema antes do React hidratar. **Não interfere** no ciclo de vida do SW.

---

## 9. O que v1 **não** implementa

| Feature | Status v1 |
|---------|-----------|
| `beforeinstallprompt` / hook de instalação | Ausente |
| Banner offline / `navigator.onLine` | Ausente |
| `runtimeCaching` para API (`NetworkFirst` em `/api`) | Ausente |
| Manifest dinâmico por tenant | Ausente (estático no build) |
| `clientsClaim` explícito | Ausente (default plugin) |
| Meta `theme-color` / Apple touch icon no HTML | Ausente (só manifest link injetado) |
| Service worker manual (`public/sw.js`) | Ausente (generateSW) |
| Testes E2E do fluxo update | Ausente (E2E espacos valida só manifest icons) |

---

## 10. Deploy e servidor

### 10.1 SPA fallback — `controle-interno-client/.htaccess`

```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} -f [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule . /index.html [L]
```

Garante que rotas deep link funcionem **fora** do SW (Apache). O SW duplica fallback via `NavigationRoute`.

### 10.2 Arquivos críticos no deploy

Substituir/atualizar **sempre** juntos:

- `sw.js`
- `workbox-*.js`
- `manifest.webmanifest`
- `index.html`
- `assets/*` (chunks hashed)

Deploy parcial (só JS app sem SW) → risco de mismatch precache / update prompt loop.

---

## 11. Referência v2 (estado atual)

`ci-client-v2/apps/web/vite.config.ts`:

```typescript
plugins: [react(), tailwindcss()],
// sem VitePWA, sem PwaUpdatePrompt, sem virtual:pwa-register
```

**Paridade exige adicionar** plugin + componente + assets de ícone (decidir se espacos-style PNG ou placeholder client).

---

## 12. Checklist de paridade para implementador v2

Copiar 1:1 salvo decisões de produto (ícones/nome):

- [ ] `vite-plugin-pwa` `^0.21.1` (ou compatível 0.21.x)
- [ ] `registerType: "prompt"`
- [ ] `workbox.globPatterns`: `["**/*.{js,css,html,ico,png,svg,woff2}"]`
- [ ] `maximumFileSizeToCacheInBytes`: **7 MiB** (client) ou ajustar se chunks maiores
- [ ] `devOptions.enabled: false` (prod-like dev) — espacos usa `true`; decidir por app
- [ ] Manifest: `theme_color: "#0f172a"`, `background_color: "#ffffff"`, `display: "standalone"`, `scope/start_url: "/"`
- [ ] `PwaUpdatePrompt` com toast Sonner + `updateServiceWorker(true)` + strings PT acima
- [ ] Montar `<PwaUpdatePrompt />` no root do app (nível `App.tsx`)
- [ ] **Não** adicionar runtimeCaching de API (v1 não tem)
- [ ] **Não** usar localStorage para versão SW
- [ ] Garantir `.htaccess` ou equivalente SPA + servir `sw.js` na raiz
- [ ] Ícones: definir se paridade com **client** (`placeholder.svg`) ou **espacos** (PNG 192/512 + maskable)
- [ ] Validar pós-deploy: DevTools → Application → SW waiting → toast → reload

---

## 13. Mapa de arquivos v1

| Arquivo | Propósito |
|---------|-----------|
| `controle-interno-client/vite.config.ts` | Config VitePWA client |
| `controle-interno-espacos/vite.config.ts` | Config VitePWA espacos |
| `controle-interno-espacos/pwa-manifest-icons.ts` | Ícones manifest espacos |
| `controle-interno-espacos/__tests__/pwa-manifest.unit.test.ts` | Testes RF-05 ícones |
| `controle-interno-client/src/shared/components/pwa-update-prompt.tsx` | UI + registro SW |
| `controle-interno-espacos/src/shared/components/pwa-update-prompt.tsx` | Cópia idêntica |
| `controle-interno-client/src/app.tsx` | Mount `PwaUpdatePrompt` |
| `controle-interno-espacos/src/app.tsx` | Mount `PwaUpdatePrompt` |
| `controle-interno-client/index.html` | Sem tags PWA manuais |
| `controle-interno-client/.htaccess` | SPA rewrite Apache |
| `controle-interno-client/dist/sw.js` | SW gerado (produção) |
| `controle-interno-client/dist/manifest.webmanifest` | Manifest gerado |
| `controle-interno-espacos/dev-dist/sw.js` | SW dev (referência legível) |

---

## 14. Notas de produto / docs internas

- FEAT-AGD-002 documenta upgrade de ícones PWA **apenas em espacos** (RF-05); client admin manteve `placeholder.svg`.
- Follow-up operacional: validar "Add to homescreen" em device real (T-017).
- E2E audit: `e2e/helpers/sedel-reuniao.helper.ts` → `auditEspacosManifest()` verifica `icon-192.png` + `icon-512.png` sem `placeholder.svg`.
