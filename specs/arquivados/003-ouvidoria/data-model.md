# Data Model: Ouvidoria Interna (v2)

**Feature**: 003-ouvidoria · **Reset**: 2026-06-06

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper.

## Manifestacao

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `type` | Tipo | yes (enum) |
| `serviceMode` | Forma de atendimento | no (text) |
| `category` | Categoria | no (text) |
| `subject` | Assunto | yes |
| `description` | Descrição | yes |
| `priority` | Prioridade | yes (enum, default `medium`) |
| `replyEmail` | E-mail para resposta | no |
| `isAnonymous` | Anônimo / Identificar | yes (default `true`) |
| `requesterFullName` | Nome completo | if identified |
| `requesterDocument` | CPF/CNPJ | optional |
| `holderName` | Titular | optional (text) |
| `registrationNumber` | Matrícula | optional |
| `requesterHomePhone` | Tel. Residencial | optional |
| `requesterMobilePhone` | Tel. Celular | optional |
| `requesterBusinessPhone` | Tel. Comercial | optional |

Workflow: `protocol`, `queryKeyHash`, `status`, timeline (`ManifestacaoEvento`), anexos file/link.

## Address

| Field EN | UI PT-BR |
|----------|----------|
| `postalCode` | CEP |
| `street` | Logradouro |
| `number` | Número |
| `complement` | Complemento |
| `landmark` | Ponto de referência |
| `neighborhood` | Bairro |
| `zone` | Zona |

## Enums

- **ManifestacaoTipo**: `complaint`, `request`, `whistleblower`, `praise`, `suggestion`, `simplify`
- **ManifestacaoPriority**: `low`, `medium`, `high`, `urgent`
- **ManifestacaoStatus**: `draft`, `in_review`, `forwarding`, `answered`, `closed`
- **ManifestacaoAttachmentKind**: `file`, `link`

## Removed (v1)

`esfera`, `origem`, `canal`, `prazoResposta`, `sigilo`, `relato`, `manifestante*` flat fields, `descricaoLocal`.
