# Quickstart: Validação — Tramitação como Protocolo

**Pré-requisitos**:
- `ci-api-v2`: migration `tramitacao_protocolo_reset` aplicada (`npx prisma migrate dev`), `npx prisma generate`, dependência `jszip` instalada.
- `ci-api-v2` rodando: `cd ci-api-v2; npm run start:dev`
- `ci-client-v2`: `cd ci-client-v2; npm install; npm run dev` (turbo → `@ci/web`)
- Seed com ao menos 2 setores e 3 usuários em setores distintos, mais um usuário `admin_tenant`. Usar seed existente (`npm run prisma:seed`) ou massa de teste manual.
- Tenant com licença **Base** ativa (Tramitação não exige licença adicional).

## Cenário 1 — Abrir protocolo setorial e colaborar (US1 + US2, P1)

1. Login como Usuário A (Setor 1). Acessar `/tramitacao/protocolos/novo`.
2. Abrir protocolo com assunto "Solicitação de material" incluindo Setor 1 e Setor 2.
3. **Validar**: protocolo criado com `protocolNumber`, status "Aberto"; evento `aberto` na timeline.
4. Login como Usuário B (Setor 2, sem ter sido convidado individualmente). **Validar**: protocolo aparece em "Meus protocolos" de B (porque Setor 2 foi incluído).
5. Usuário B adiciona uma atualização (mensagem + anexo). **Validar**: evento `atualizacao` visível para A e B; `updatedAt` do protocolo atualizado; protocolo sobe ao topo da lista de ambos.
6. Login como Usuário C (Setor 3, não incluído). **Validar**: protocolo **não** aparece em "Meus protocolos" de C; acesso direto por URL retorna `403`.

## Cenário 2 — Incluir novo setor e permissão de gestão (US2 + US8, P1/P3)

1. Como Usuário A (autor, gestor implícito) do protocolo do Cenário 1, incluir Setor 3.
2. **Validar**: evento `setor_incluido`; Usuário C (Setor 3) passa a ver o protocolo e pode adicionar atualização.
3. Login como Usuário B (participante sem gestão). Tentar incluir um 4º setor. **Validar**: `403 FORBIDDEN_NOT_MANAGER`.
4. Como Usuário A, conceder gestão a Usuário B (`POST /tramitacao/protocolos/:id/gestores`).
5. Login como Usuário B; incluir um 4º setor. **Validar**: sucesso agora.

## Cenário 3 — Lista única, filtros e busca (US3, P1)

1. Ter ao menos 2 protocolos (1 aberto, 1 encerrado) para o mesmo usuário.
2. Acessar `/tramitacao/protocolos`. **Validar**: lista única, sem abas Recebidas/Enviadas/Arquivadas.
3. Aplicar filtro `status=encerrado`. **Validar**: só o protocolo encerrado aparece.
4. Buscar por `protocolNumber` exato e por trecho do assunto. **Validar**: ambos retornam o protocolo correto.

## Cenário 4 — Tramitar dados de outro módulo (US4, P2)

1. Em Ouvidoria, abrir uma manifestação e escolher "Tramitar dados" → "Abrir novo protocolo".
2. **Validar**: protocolo criado com `sourceModule: 'ouvidoria'`, `sourceSnapshot` preenchido; evento `aberto` reflete a origem.
3. Repetir a partir de outra manifestação, escolhendo "Entranhar em protocolo existente" e buscando o protocolo criado no Cenário 1.
4. **Validar**: novo evento `vinculo_anexado` no protocolo do Cenário 1, sem criar um protocolo novo.
5. Tentar entranhar em um protocolo **encerrado**. **Validar**: `409 PROTOCOLO_ENCERRADO`, opção de abrir novo protocolo oferecida na UI.

## Cenário 5 — Baixar o dossiê (US5, P2)

1. No protocolo do Cenário 1 (com atualizações e anexos, incluindo 1 anexo confidencial visível só ao autor), acionar "Baixar" como Usuário A.
2. **Validar**: download de um `.zip` contendo `dossie.pdf` (com assunto, participantes, linha do tempo) e pasta `anexos/` com todos os arquivos que A pode acessar (incluindo o confidencial, pois A é o autor).
3. Repetir como Usuário C (sem acesso ao anexo confidencial). **Validar**: `dossie.pdf` presente, mas `anexos/` **sem** o arquivo confidencial.
4. Encerrar o protocolo e repetir "Baixar". **Validar**: exportação funciona normalmente (independe de encerramento).

## Cenário 6 — Encerrar (US6, P2)

1. Como gestor, encerrar o protocolo do Cenário 1 (motivo opcional).
2. **Validar**: `status = encerrado`; evento `encerrado` na timeline; UI não oferece mais "Adicionar atualização", "Incluir setor" ou "Entranhar".
3. Tentar adicionar atualização via API diretamente. **Validar**: `409 PROTOCOLO_ENCERRADO`.
4. Tentar encerrar novamente (2 requisições concorrentes simuladas). **Validar**: só a primeira retorna `200`; a segunda retorna `409 ALREADY_ENCERRADO`.
5. **Validar**: não existe nenhuma ação de "reabrir" na UI ou na API.

## Cenário 7 — Protocolo pessoal (US7, P3)

1. Usuário A abre protocolo pessoal para Usuário D (`tipo: pessoal`).
2. **Validar**: aparece em "Meus protocolos" apenas de A e D; tentativa de incluir setor não é oferecida na UI e retorna `400 PERSONAL_NO_SECTOR` via API.
3. Usuário D adiciona atualização. **Validar**: visível para ambos.
4. Baixar e encerrar seguem os mesmos passos dos Cenários 5 e 6.

## Cenário 8 — Desentranhamento reconciliado (compatibilidade com 034)

1. No protocolo do Cenário 2 (3 setores participantes), Usuário B anexa um documento.
2. Usuário B (autor do anexo) solicita desentranhamento.
3. **Validar**: aprovadores elegíveis = A e C (todos os demais participantes, não só "um lado"); qualquer um deles pode aprovar/rejeitar; primeira decisão vale.
4. Repetir com Usuário C (não autor) solicitando desentranhamento do mesmo tipo de anexo enviado por B.
5. **Validar**: aprovador elegível = apenas B (autor do anexo).

## Comandos de verificação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=tramitacao
cd ci-api-v2; npm run build
cd ci-client-v2/apps/web; npm test -- --run Tramitacao
```

## Cobertura automatizada (T109)

Os cenários abaixo têm cobertura via testes de integração (API) e Vitest (client). Smoke manual no browser permanece recomendado para fluxos cross-módulo na UI (ex.: Ouvidoria → "Tramitar dados").

| Cenário | Testes API | Testes client |
| --- | --- | --- |
| 1 | `abrir-protocolo-setorial`, `adicionar-atualizacao` | `TramitacaoAbrirProtocoloForm`, `TramitacaoProtocolosPage` |
| 2 | `incluir-setor`, `conceder-gestor` | `TramitacaoParticipantesPanel` |
| 3 | `listar-protocolos` | `TramitacaoProtocolosPage` |
| 4 | `abrir-protocolo-linked`, `entranhar-protocolo`, `entranhar-protocolo-encerrado` | `TramitacaoEntranharDialog`, `LinkedRecordPanel.*` |
| 5 | `baixar-protocolo`, `download-anexo` | `TramitacaoBaixarButton`, `TramitacaoAnexoList` |
| 6 | `encerrar-protocolo`, `encerrar-protocolo-concorrencia`, `protocolo-encerrado-bloqueia-escrita` | `TramitacaoEncerrarDialog` |
| 7 | `abrir-protocolo-pessoal`, `acesso-protocolo-pessoal` | `TramitacaoAbrirProtocoloForm` |
| 8 | `desentranhamento-author-approve/reject`, `desentranhamento-recipient-approve` | — |

## Critérios de aceite (ligação com Success Criteria da spec)

| Cenário | SC |
|---|---|
| 1, 2 | SC-001, SC-002 |
| 3 | SC-003 |
| 5 | SC-004, SC-006 |
| 4, 6 | SC-005 |
| 6 | SC-007 |
