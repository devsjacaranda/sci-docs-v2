# Quickstart — 044 Emissor criador AGEMAN

Validação ponta a ponta **depois** de `/speckit-implement`. Não é guia de implementação.

## Pré-requisitos

- API: `cd ci-api-v2; npm run start:dev`
- Web: `cd ci-client-v2; npm run dev`
- Seed Jacarandá/AGEMAN: `cd ci-api-v2; npm run prisma:seed`
- Conta **operador** (`user` / `chefe_setor`) e conta **admin da instituição** (`admin_tenant`) no mesmo tenant AGEMAN

## 1. Testes automatizados (prova principal)

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=emissor

cd ci-client-v2/apps/web
npm test -- emissor
```

Esperado: suíte `CT-OUV-EMISSOR-*` / `CT-OUV-EMISSOR-CLIENT-*` verde, incluindo 016–019 e client 005/006 reescritos.

## 2. Operador institucional (SC-001 / SC-002)

1. Login como operador AGEMAN.
2. Ouvidoria → Nova manifestação.
3. Conferir campo **Emissor**: texto somente leitura com o próprio nome; **sem** lista.
4. Preencher o restante e avançar até confirmar — **sem clicar** em Emissor.
5. Abrir o detalhe: Emissor = nome do operador.

## 3. Administrador da instituição (SC-003)

1. Login como `admin_tenant`.
2. Nova manifestação: Emissor é lista, opção do próprio nome **já marcada**.
3. Avançar sem alterar → detalhe: Emissor = “—”.
4. Repetir: trocar a lista para um operador real → detalhe: nome desse operador.

## 4. Imutável após confirmar (SC-005)

1. Com demanda já confirmada, abrir detalhe: Emissor sem controle de edição (já hoje).
2. Se houver rota de wizard/`PATCH` na demanda confirmada, alterar outros campos não muda o Emissor.

## 5. Histórico (SC-006)

Abrir uma demanda **antiga** cujo emissor era outra pessoa: o valor permanece.

## 6. Validação automática (T027)

Validado em **2026-09-14** sem browser (suítes + rastreio de código). Comandos:

```powershell
cd ci-api-v2
npm test -- --testPathPatterns="resolve-emissor|create-manifestacao|update-manifestacao|manifestacao.repositories|ouvidoria.controller"

cd ci-client-v2/apps/web
npm test -- emissor manifestacao-draft.schema ManifestacaoIdentityCard
```

Resultado: API **6** suites / **53** testes OK; web **8** arquivos / **72** testes OK.

| Quickstart | Cobertura automatizada |
| --- | --- |
| §2 Operador (readonly, create sem select, detalhe com nome) | `CT-OUV-EMISSOR-007`/`008`/`017` (create); `CLIENT-005`/`006` (form + wizard operador); `CLIENT-007` + `CLIENT-003` + `CT-OUV-EMISSOR-011` (detalhe/`emissorLabel`) |
| §3 Admin (`__self__`, “—”, troca operador) | `CT-OUV-EMISSOR-017` (admin + `dadosAdicionais`); `CLIENT-005`/`006` (combobox admin + payloads); `CLIENT-003` (label null → “—”) |
| §4 Imutável pós-confirmação | `CT-OUV-EMISSOR-018` (`in_review` → patch **sem** `emissorUserId`); wizard/form admin `in_review` readonly (`ManifestacaoWizardPage.emissor-admin`, `ManifestacaoStepOneForm.emissor-admin`); `CLIENT-007` (card só leitura) |
| §5 Histórico | Sem migration/backfill de emissor; `UpdateManifestacaoDraftUseCase` só recalcula em `draft` — registros já gravados não são alterados por esta feature (sem CT dedicado a dado legado) |

**QA manual recomendado:** §2–4 ponta a ponta com seed AGEMAN + login operador/admin; §5 abrir manifestação migrada/antiga no detalhe e confirmar emissor inalterado.

## Fora deste guia

- Portal público do cidadão.
- Relatórios / listagens (só consomem o valor já gravado).
