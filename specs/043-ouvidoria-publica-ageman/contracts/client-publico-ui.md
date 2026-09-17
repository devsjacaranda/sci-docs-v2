# Client UI Contract — Ouvidoria Pública AGEMAN (043)

**App**: `ci-client-v2/apps/publico` (`@ci/publico`) — SPA de página única, sem `react-router`
**Tenant**: só AGEMAN nesta etapa (`VITE_TENANT_ID=ageman`, build `--mode ageman`)
**Identidade visual**: paleta própria emerald/teal/blue da v1 — **não** a paleta Mint do workspace (ver Constitution Check / research R6)

## Composição (`main.tsx`)

Espelha `PublicApp.tsx` da v1: `QueryClientProvider` + `AccessibilityProvider` envolvendo um componente raiz com estado `screen: 'welcome' | 'chatbot' | 'consulta'`.

```text
window.dispatchEvent(new CustomEvent('start-manifestation'))   # welcome → chatbot
window.dispatchEvent(new CustomEvent('open-review-modal'))     # abre ReviewFormModal sobre o chatbot
window.dispatchEvent(new CustomEvent('reset-chatbot'))         # chatbot/consulta → welcome
window.dispatchEvent(new CustomEvent('open-consulta'))         # welcome → consulta (tela nova)
```

Sem Redux/Zustand — estado de tela é local ao componente raiz (mesmo padrão da v1).

## Telas

### 1. `WelcomePage` (landing institucional)

Portada 1:1 da v1: hero, 5 cards de serviço, seção do assistente AGE (player de áudio), seções institucionais, cartões de contato/localização. Novo: um ponto de entrada adicional para a tela de **Consulta de Protocolo** (capacidade sem equivalente na v1 — FR-014).

### 2. `PublicChatbotForm` (assistente conversacional)

Máquina de estado de perguntas portada da v1, com os ajustes de contrato:

- Opções de categoria (`SELECT_OPTIONS.manifestationCode` na v1) passam de 5 para **6** — nova opção "Assuntos institucionais da AGEMAN" sem sub-lista de motivos (campo de texto livre em vez de seleção).
- Nova pergunta de **tipo** da manifestação (`TIPO_MANIFESTACAO_OPTIONS`: Reclamação/Sugestão/Elogio/Denúncia/Solicitação) — client traduz para o enum inglês da API (ver `constants/manifestation-options.ts`, research R1).
- Pergunta de e-mail passa a ser **sempre obrigatória** (antes só telefone/e-mail eram alternativos) — mesmo em fluxo anônimo.
- CEP/endereço, matrícula (água), protocolo+poste (iluminação), reconhecimento de voz, comandos de voz ("pare"/"enviar"/"apague texto"/"apague parte"/seleção numérica) — portados sem alteração de comportamento.
- Catálogo de motivos por programa vem de `GET /ouvidoria/publico/programas` (não mais hardcoded no client como na v1).

### 3. `ReviewFormModal` (revisão + confirmação)

`react-hook-form` + `@hookform/resolvers/zod` + `public-manifestacao.schema.ts` (espelha o contrato v2 expandido). `useMutation` (`@tanstack/react-query`) chamando `api/public-manifestacao.ts` → `POST /ouvidoria/publico/manifestacoes`, com `executeRecaptcha('submit_manifestation')` (`hooks/use-recaptcha.ts`, portado sem alteração) gerando o `challengeToken`.

Ao confirmar com sucesso: exibe `protocol` + `chaveConsulta` retornados — **única vez** que a chave é mostrada (FR-013). Copy explícita: "guarde esta chave, ela não será exibida novamente".

### 4. `PublicAttachmentsInput`

Tabs arquivo/link portadas; **link externo fica fora do escopo desta entrega** (só arquivo — ver data-model.md §2 `ManifestacaoAnexo.kind`). Fluxo de arquivo muda de transporte: seleciona arquivo → `POST /ouvidoria/publico/anexos` (obtém `tempId` + `uploadUrl`) → `PUT` direto em `uploadUrl` com o binário → guarda `tempId` no estado do formulário → enviado em `anexoTempIds[]` no submit final. UI de arrastar/soltar e barra de progresso inalteradas.

Limites exibidos ao cidadão: 30MB, lista de tipos do padrão interno (não os 50MB/lista mais ampla da v1 — research R5).

### 5. `FloatingAgeWidget` (dúvidas frequentes, persona "Tucaninho")

Portado sem alteração de lógica (FAQ hardcoded, sem IA externa — assunção da spec). Disponível em qualquer tela via `open-age-chat`.

### 6. `ConsultaProtocoloPage` (NOVA — sem equivalente na v1)

Formulário simples: `protocol` + `chave`. `useQuery` chamando `GET /ouvidoria/consulta`. Estados:

| Estado | UI |
| --- | --- |
| Antes de consultar | formulário vazio + instrução de onde encontrar protocolo/chave |
| Loading | spinner no botão |
| 404 (`OUVIDORIA_PUBLIC_NOT_FOUND`) | mensagem genérica — nunca revela se foi o protocolo ou a chave que errou (FR-016) |
| 429 | mensagem de limite de tentativas + tempo de espera |
| 200 | card com `statusLabel`, `assunto`, `resposta` (se houver), linha do tempo de `marcos[]` |

Visual consistente com o restante do portal AGEMAN (mesma paleta emerald/teal).

## Acessibilidade (`AccessibilityContext` + `AccessibilityWidget`)

Portados sem alteração: tamanho de fonte (persistido em `localStorage`), modos de contraste para daltonismo (filtros SVG), leitura em voz alta (Web Speech Synthesis, pt-BR, leitura ao passar o foco). Disponível em **todas** as telas, inclusive na nova `ConsultaProtocoloPage`.

## Cliente HTTP

`@ci/shared` (`createApiClient`) configurado **sem** `setAccessToken`/sessão (research R7):

```typescript
const api = createApiClient({
  tokenKey: 'unused-publico', // nunca setado; nenhuma tela de login neste app
  apiBase: import.meta.env.VITE_API_BASE_URL,
  tenantId: import.meta.env.VITE_TENANT_ID, // 'ageman'
})
```

Erros (400/404/429) tratados como erro de request normal — mensagem inline no formulário/tela, nunca redirecionamento (não há sessão para "perder").

## Variáveis de ambiente (`.env.ageman.example`)

```text
VITE_API_BASE_URL=
VITE_TENANT_ID=ageman
VITE_TENANT_NAME=
VITE_ASSISTANT_NAME=
VITE_TENANT_LOGO=
VITE_TENANT_WEBSITE_URL=
VITE_TENANT_PROTOCOL_SUFFIX=
VITE_RECAPTCHA_SITE_KEY=          # NOVO — vazio em dev (use-recaptcha.ts já trata ausência)
```

## Tokens visuais

Paleta própria do tenant (emerald/teal/blue), Tailwind v4, sem shadcn/`@ci/ui` obrigatório (a v1 não usa shadcn — `@ci/ui` já é dependência do app hoje, mas seu uso é opcional/pontual, não a base do design system desta tela pública). Alvos de clique ≥ 44px, contraste 4.5:1 (mesma exigência de acessibilidade da spec, independente da paleta). Ícones Lucide (`lucide-react`, já dependência).
