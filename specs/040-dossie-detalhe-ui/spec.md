# Feature Specification: Dossiê de detalhe — design system canônico

**Feature Branch**: `040-dossie-detalhe-ui`

**Created**: 2026-08-26

**Status**: Completed (referência canônica)

**Input**: A tela de detalhes de manifestação (Ouvidoria) deixa de ser um card único com lista chave-valor e passa a ser o **padrão oficial** de toda tela de detalhe operacional do CI v2.

## Contexto

Operadores de controle interno abrem o detalhe para (1) confirmar o protocolo, (2) ler o relato, (3) agir. A tela antiga empilhava campos em um retângulo único, sem badges, com ações no fim da página. A versão canônica é o **Dossiê operacional**.

**Tela piloto (oficial):** `/ouvidoria/manifestacoes/:id`  
**Norma de produto:** `.cursor/docs/regras-plataforma.md` §4.3

## User Scenarios & Testing

### User Story 1 — Operador identifica o caso em 2 segundos (Priority: P1)

O operador abre o detalhe e vê número institucional, protocolo de sistema, tipo/assunto, badges de prioridade e status (ícone + texto + cor) e ações de chrome (Voltar, Documentos, Editar) sem scroll.

**Acceptance Scenarios**:

1. **Given** uma manifestação com número institucional e protocolo, **When** o detalhe carrega, **Then** o H1 é o número institucional em `font-mono` e o protocolo do sistema aparece menor na linha seguinte.
2. **Given** status `in_review` e prioridade `urgent`, **When** o header renderiza, **Then** os badges mostram ícone + label; `in_review` não é vermelho/`destructive`.
3. **Given** o operador no desktop, **When** clica em Documentos, **Then** um Dialog compacto oferece PDF e Word (mesmo endpoint do download existente).

### User Story 2 — Operador lê o relato e a ficha sem dump de formulário (Priority: P1)

O relato tem coluna de leitura (~65ch). Metadados ficam em cards Identidade / Manifestante / Endereço / Anexos / Timeline. Campos vazios não aparecem como "—".

**Acceptance Scenarios**:

1. **Given** um relato longo, **When** o card Relato renderiza, **Then** o texto usa `max-w-[65ch]` e `whitespace-pre-wrap`.
2. **Given** Documento ou CEP ausentes, **When** a ficha monta, **Then** essas linhas são omitidas (não placeholder "—").

### User Story 3 — Operador age sem formulários eternos na página (Priority: P1)

Encaminhar, Responder e Encerrar são botões compactos no header (abaixo dos badges). Cada um abre um Dialog com o formulário daquela ação.

**Acceptance Scenarios**:

1. **Given** `acoesPermitidas` contém responder e encerrar, **When** o header renderiza, **Then** só esses botões aparecem — sem textareas visíveis na página.
2. **Given** o operador clica Encerrar, **When** o Dialog abre, **Then** o toggle Com/Sem resolução e os campos ficam dentro do modal.

### User Story 4 — Operador edita um campo de texto sem abrir o wizard (Priority: P2)

Campos de **texto livre independente** têm caneta do tamanho da fonte. O controle de edição tem o **mesmo tamanho** do texto (sem input `h-8`). Seletor, catálogo, data e campos dependentes não ganham caneta.

**Acceptance Scenarios**:

1. **Given** o registro é editável e tem Assunto, **When** o operador clica a caneta, **Then** o valor vira input sublinhado no mesmo `text-sm`; Enter/✓ grava PATCH; Esc/X cancela.
2. **Given** o Relato, **When** o operador edita, **Then** abre textarea no mesmo measure; Enter quebra linha; Ctrl+Enter grava.
3. **Given** Tipo, Motivo, Canal, Programa, prazos ou Município, **When** a ficha renderiza, **Then** não há caneta inline.

## Requisitos funcionais

- FR-01: Header de identidade + badges + chrome (Voltar, Documentos, Editar).
- FR-02: Cards empilhados em coluna única (`space-y-4`).
- FR-03: Ações de rito em Dialog; documentos no header.
- FR-04: Inline edit só em texto livre independente, via PATCH já existente (`updateManifestacaoDraft`).
- FR-05: Caneta só se `editable`; campo vazio não materializa linha.
- FR-06: Paleta Mint; sem shell/sidebar redesenhados.

## Fora de escopo

- Novo endpoint de PATCH por campo.
- Regenerar número institucional ao mudar tipo.
- Edição inline de seletor/catálogo/data.
- Redesign da lista, wizard ou sidebar.

## Referência de implementação

| Peça | Caminho |
| --- | --- |
| Página | `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoDetailPage.tsx` |
| Header | `…/components/ManifestacaoDetailHeader.tsx` |
| Identidade | `…/components/ManifestacaoIdentityCard.tsx` |
| Relato | `…/components/ManifestacaoNarrativeCard.tsx` |
| Manifestante | `…/components/ManifestacaoRequesterCard.tsx` |
| Endereço | `…/components/ManifestacaoAddressCard.tsx` |
| Inline texto | `…/components/ManifestacaoInlineTextField.tsx` |
| Ações | `…/components/ManifestacaoActionDialogs.tsx` |
| ViewModel | `…/lib/manifestacao-detail-view.ts` |
