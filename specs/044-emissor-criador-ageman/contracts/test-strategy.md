# Test Strategy — 044 Emissor criador AGEMAN

TDD obrigatório (Constitution II). Prefixo existente `CT-OUV-EMISSOR-*` (API) e `CT-OUV-EMISSOR-CLIENT-*` (web).

## API (Jest) — RED primeiro

| ID | Alvo | Casos |
| --- | --- | --- |
| CT-OUV-EMISSOR-016 | `resolve-emissor-user-id.ts` | operador + request de outro id → autenticado; operador sem request → autenticado; admin + uuid → uuid; admin sem request → `undefined`; `phase: confirmed` → sinal de não aplicar |
| CT-OUV-EMISSOR-017 | `CreateManifestacaoDraftUseCase` | operador com `emissorUserId` de B → persiste A; admin sem id → sem `emissorUserId` + `dadosAdicionais` com `actorId`/`actorRole`; admin com uuid válido → persiste uuid (ainda valida tenant) |
| CT-OUV-EMISSOR-018 | `UpdateManifestacaoDraftUseCase` | draft + operador → recálculo; draft + admin troca → uuid; `in_review` + qualquer emissor no body → update **sem** connect/disconnect de emissor |
| CT-OUV-EMISSOR-019 | `OuvidoriaController.update` | passa `{ userId, role }` ao use-case |
| CT-OUV-EMISSOR-002 | schemas | **permanece**: uuid válido / inválido / omitido. **Não** aceitar `__self__` na API |

Reescrever (não apagar IDs):

- `CT-OUV-EMISSOR-007` / `008`: create deixa de “respeitar o id enviado” para operador — passa a ignorar e gravar o autenticado. `008` (id de outro tenant enviado por **operador**) → sucesso com autenticado, `FindEmissorUser` **não** precisa ser chamado. `008` para **admin** + id de outro tenant → continua `EMISSOR_INVALID`.
- `CT-OUV-EMISSOR-009` / `010`: update draft idem, e novo caso confirmado.

Fluxo público: nenhum teste `CT-OUV-PUB-*` deve quebrar.

## Client (Vitest)

| ID | Alvo | Casos |
| --- | --- | --- |
| CT-OUV-EMISSOR-CLIENT-002 | schema draft | aceita uuid; omitido; `__self__` e `''` → output sem `emissorUserId` |
| CT-OUV-EMISSOR-CLIENT-005 | `ManifestacaoStepOneForm` | operador: **sem** combobox, input readonly com nome; admin: combobox com opção do próprio nome pré-marcada |
| CT-OUV-EMISSOR-CLIENT-006 | wizard | operador: continuar **sem** clicar em emissor; body **sem** `emissorUserId`. admin: continuar sem clique → body sem id; admin troca opção → envia uuid |
| CT-OUV-EMISSOR-CLIENT-007 | identity card | inalterado (Emissor / “—”) |

## Ordem RED → GREEN

1. `resolve-emissor-user-id` (puro)
2. Schema client (`__self__` transform)
3. Create use-case + specs 007/008/017
4. Update use-case + actor no controller
5. Form + wizard (RTL)
6. Fetch de emissores condicional

## E2E

Não obrigatório nesta entrega. Caminho feliz do wizard (operador cria sem tocar emissor) pode entrar depois se o Playwright interno de ouvidoria já estiver verde.
