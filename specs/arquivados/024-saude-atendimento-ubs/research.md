# Research: Módulo Saúde — Atendimento UBS / e-SUS

**Feature**: 024-saude-atendimento-ubs · **Date**: 2026-06-29

## R1 — Camada de implementação (mock vs API)

**Decision**: Implementação **100% client-side** em `apps/web`; nenhum endpoint NestJS nesta entrega.

**Rationale**: Spec e contrato Careiro exigem demonstração operacional enquanto integração e-SUS tramita; backup PostgreSQL é referência de mapeamento export, não fonte de dados (FR-016).

**Alternatives considered**:
- API + Prisma espelhando `tb_*` e-SUS — rejeitado: escopo inflado, LGPD no backup, spec define mock.
- MSW simulando REST — rejeitado: stores locais são mais simples e alinhados a "controle interno mock".

---

## R2 — Licenciamento

**Decision**: CRUD, relatórios operacionais, fila, conferência, indicadores base e tramitação sob licença **`base`** exclusivamente.

**Rationale**: Correção explícita do stakeholder — sem nova licença-árvore (FR-002).

**Alternatives considered**:
- Nova licença `ipe` — rejeitado pelo stakeholder.
- Gate Cedro/Jatobá em telas P1 — rejeitado: bloquearia demo municipal.

---

## R3 — Modelo de persistência mock

**Decision**: Stores modulares (`consultas-store`, `solicitacoes-store`) com persistência opcional em `localStorage` (`ci:saude:v1:{tenantId}:{entity}`); seed determinístico em boot se store vazio.

**Rationale**: Fila editável e CRUD consulta exigem mutação; padrão similar a drafts/tramitação local; sobrevive refresh sem backend.

**Alternatives considered**:
- Apenas `mock-data.ts` estático — rejeitado: fila e CRUD consulta precisam persistir edições.
- Zustand global — rejeitado: projeto usa stores por domínio + facades `api/*.ts`.

---

## R4 — Agregado Consulta vs CRUDs separados

**Decision**: **Consulta** é agregado raiz (espelha `tb_atend_prof`); cadastros mestres (Cidadão, Profissional, UBS, Medicamento) são entidades referenciadas por ID.

**Rationale**: UX de atendimento UBS é um encontro único com SOAP + procedimentos + receitas; export FAI exige visão agregada; alinhado ao backup e-SUS.

**Alternatives considered**:
- 6 CRUDs independentes sem agregado — rejeitado: quebra export, conferência e indicadores.

---

## R5 — DTOs internos vs export e-SUS

**Decision**: DTOs **camelCase** modernos em `api/types.ts` + Zod; mapeador unidirecional `lib/esus-export.ts` → payload FAI JSON com nomes e-SUS (`nu_cns`, `co_cbo_2002`, `nu_cnes`, etc.).

**Rationale**: Spec: modelo nosso + export no padrão deles; facilita evolução UI sem acoplar telas ao legado.

**Alternatives considered**:
- DTOs verbatim e-SUS na UI — rejeitado: legibilidade ruim para React forms.
- Thrift binário — rejeitado: fora de escopo; JSON suficiente para validação contratual.

---

## R6 — Roteamento e `/validar` público

**Decision**: Rotas autenticadas via `SAUDE_OVERRIDES` + `screens.ts`; rota **`/validar`** registrada **fora** de `RequireAuth` (paralelo a `/login`).

**Rationale**: FR-011 exige validação sem auth; `router.tsx` atual envolve todas as rotas app em `RequireAuth`.

**Alternatives considered**:
- `/validar` dentro do shell autenticado — rejeitado: viola spec.
- Subdomínio separado — rejeitado: complexidade desnecessária.

---

## R7 — Assinatura de receita pública

**Decision**: Código alfanumérico 12 chars derivado de hash determinístico (receitaId + profissionalCns + data + salt fixo demo) via `receita-signature.ts`; validação compara código + lookup no store de receitas.

**Rationale**: Demonstração contratual sem PKI real; testável unitariamente; não expõe dados clínicos na resposta pública.

**Alternatives considered**:
- QR Code real RNDS — rejeitado: integração nacional fora de escopo.
- UUID simples — rejeitado: não simula "assinatura" verificável.

---

## R8 — Tramitação

**Decision**: Reutilizar `TramitarButton` + `buildTramitacaoDraft` com `module: 'saude'`, snapshot JSON da consulta/solicitação.

**Rationale**: FR-014; padrão já usado em outros módulos; tramitação real já desmockada (014).

**Alternatives considered**:
- Fluxo encaminhamento isolado — rejeitado: duplica capacidade Base existente.

---

## R9 — Seed sintético Careiro

**Decision**: 8 UBS com nomes plausíveis de Careiro da Várzea (AM); ~40 consultas seed + derivação de ~400 linhas receita e ~100 exames; médicos vs enfermeiros com CBO distintos (`2251*` vs `2235*`).

**Rationale**: Volumes da spec; regra "só médicos solicitam exames" implementável por filtro CBO no seed e relatório.

**Alternatives considered**:
- Import anonimizado do backup — rejeitado: risco LGPD e complexidade.

---

## R10 — UI architecture

**Decision**: Páginas dedicadas estilo `modules/it/` para fluxos ricos; `ScreenPage` genérico opcional para medicamentos (list/form simples).

**Rationale**: Consulta agregada com abas SOAP não cabe em `MockForm` config-only; IT prova padrão de overrides lazy.

**Alternatives considered**:
- 100% ScreenConfig mock — rejeitado: ConsultaDetail com abas exige componentes custom.
