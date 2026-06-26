# Quickstart: Módulo IT — Segurança da Informação

**Feature**: 022-it-seguranca-informacao · **Branch**: `022-it-seguranca-informacao`

Guia de validação ponta a ponta. Contratos: [contracts/](./contracts/) · modelo: [data-model.md](./data-model.md).

---

## Pré-requisitos

- Node.js 20 LTS
- PostgreSQL rodando (dev)
- Tenant Jacaranda seedado com módulo IT + setor TI + 4 licenças

```powershell
cd ci-api-v2
npm install
npm run prisma:migrate
npm run prisma:seed    # pós-implementação: inclui ativos IT demo
npm run start:dev

# Terminal separado
cd ci-client-v2
npm install
npm run dev            # → http://localhost:5173
```

Credenciais demo: ver `prisma/seed/seed-jacaranda-tenant.ts`.

Variáveis opcionais:

```env
BACKUP_AUDIT_DAY=5
INSIGHTS_CRON=0 2 * * *
```

---

## Cenário 1 — CRUD ativos TI (P1)

**Objetivo**: FR-002–004, SC-001

1. Autenticar usuário com módulo IT
2. Navegar `/it/ativos`
3. Criar servidor, sistema e banco de dados
4. Vincular servidor → sistema → banco
5. Soft delete servidor → verificar sumiu da lista
6. Restaurar → verificar retorno

**API**:

```powershell
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" -d '{"type":"server","name":"SRV-01","identifier":"10.0.0.1","setorId":"..."}' http://localhost:3000/it/ativos
```

---

## Cenário 2 — Incidente + linha de defesa (P1)

**Objetivo**: FR-005–006

1. Registrar incidente crítico em `/it/incidentes/novo`
2. Resolver informando **Resolvido por** = *Controle Interno*
3. Verificar status **Resolvido** no detalhe

---

## Cenário 3 — Dashboard LGPD (P2)

**Objetivo**: FR-007–008, SC-003

1. Cadastrar sistema sem mapeamento LGPD → dashboard &lt; 100%
2. Em `/it/operadores`, vincular categorias ao sistema
3. **Esperado**: `% LGPD` atualiza em ≤ 2s no `/it`

---

## Cenário 4 — Classificador Cedro + apply (P3)

**Objetivo**: FR-013–014, SC-005, SC-011

1. Cadastrar banco com coluna `cpf_funcionario` no dicionário
2. `/it/insights` → acionar classificação
3. **Esperado**: insight com badge **Somente leitura**; flag **não** alterada
4. Clicar **Aplicar classificação** → confirmar
5. **Esperado**: `containsSensitiveData=true` no ativo

---

## Cenário 5 — Análise config + matriz risco (P3)

**Objetivo**: FR-011–012, FR-015, SC-004, SC-006

1. Upload `.txt` com `port: 21` vinculado a servidor
2. **Esperado**: alerta em ≤ 10s
3. Matriz: Acesso Externo + MFA Não + Dados pessoais
4. **Esperado**: *Risco Alto* instantâneo

---

## Cenário 6 — Backup workflow (P4)

**Objetivo**: FR-017–019, SC-007

1. Simular cron ou `POST /it/fiscalizacao/backup/run`
2. Servidor em **Alerta** na listagem
3. Submeter evidência válida (size &gt; 0 + log)
4. **Esperado**: status **Conforme**, backupAuditStatus `ok`
5. (Dev) Simular D+1 sem evidência → **Vermelho** + notificação

---

## Cenário 7 — Trilha imutável (P4)

**Objetivo**: FR-020–021, SC-008

1. Editar ativo
2. `/it/fiscalizacao` → seção trilha → ver linha com IP e ação
3. Tentar DELETE audit-trail via API → **403/405**

---

## Cenário 8 — ANPD PDF (P4)

**Objetivo**: FR-022, SC-009

1. Incidente **Crítico** → **Gerar notificação ANPD**
2. Revisar campos preenchidos (≥ 90%)
3. Gerar PDF → download `application/pdf`

---

## Cenário 9 — Maturidade Carvalho (P5)

**Objetivo**: FR-024–027, SC-010

1. `/it/maturidade` → gráfico linhas de defesa
2. Marcar 15/20 controles CIS/LGPD concluídos → score 75%
3. Verificar ranking vulnerabilidade por secretaria
4. Sheet **Como calculamos este score?**

---

## Cenário 10 — Governança licenças (P1)

**Objetivo**: FR-031, US14

1. Usuário sem Cedro → `/it/insights` → alerta licença
2. Usuário sem módulo IT → 403 em `/it/*`

---

## Testes automatizados

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=it

cd ci-client-v2/apps/web
npm test -- it
```

---

## Troubleshooting

| Problema | Verificar |
|----------|-----------|
| 403 módulo IT | `ModuloSetor` seed + permissão usuário |
| Insight não aparece | Dicionário vazio ou termos não batem seed |
| Backup não alerta | `BACKUP_AUDIT_DAY` + tipo asset `server` |
| PDF falha | `pdf-lib` instalado; incidente critical |

---

## Próximo passo

`/speckit-tasks` → implementação vertical slice com TDD.
