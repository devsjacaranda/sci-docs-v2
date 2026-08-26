# Contract: Client UI — Tramitação Documentos Confidenciais

**Feature**: 033-tramitacao-docs-confidenciais  
**App**: `@ci/web` — `apps/web/src/modules/tramitacao/`

## Componentes novos/alterados

| Componente | Caminho | Responsabilidade |
|------------|---------|------------------|
| `TramitacaoAnexoUploadZone` | `components/TramitacaoAnexoUploadZone.tsx` | Upload arquivo + link; toggle confidencial por item staged |
| `ConfidentialAccessPicker` | `components/ConfidentialAccessPicker.tsx` | Multi-setor + multi-usuário por setor |
| `TramitacaoAnexoList` | `components/TramitacaoAnexoList.tsx` | Lista na timeline: full vs placeholder |
| `TramitacaoInboxWorkspace` | `components/TramitacaoInboxWorkspace.tsx` | Integrar zona upload em compose/reply/forward sheets |
| `api/anexos.ts` | `api/anexos.ts` | presign, confirm, addLink, download |

## UX — Compose / Reply / Forward

### Upload zone

1. Área de arquivos (input multiple) + seção link externo (título + URL)
2. Cada item staged exibe:
   - Nome/tipo/tamanho
   - Switch **Documento confidencial**
   - Se confidencial ON → `ConfidentialAccessPicker` abaixo do item

### ConfidentialAccessPicker

1. Botão **Adicionar setor** → `Select` setores (`fetchSetores`)
2. Por setor adicionado:
   - Chip do setor com remover
   - Checkbox list de usuários ativos do setor (`fetchUsers` filtrado por `sectorId`)
   - Validação inline: ≥1 usuário selecionado
3. Adicionar segundo setor → nova seção independente de usuários

### Envio (orquestração client)

```text
[Enviar mensagem]
  → POST create/reply/forward (texto)
  → para cada anexo staged:
      presign → upload S3 → confirm(isConfidential, access)
  → refresh detail / toast sucesso
```

Bloqueio client: confidencial sem usuário por setor → desabilitar Enviar + mensagem FR-006.

## UX — Detalhe / Timeline

### Anexo full

- Ícone por MIME
- Nome arquivo ou título link
- Badge **Confidencial** (opcional, se `isConfidential`)
- Botão **Baixar** / **Abrir link** → chama `download` API

### Anexo placeholder

- Ícone cadeado (`Lock` Lucide)
- Texto: **Documento confidencial**
- Subtexto: tipo/tamanho se disponível (sem nome real se política omitir)
- Sem botão download; sem link

### Timeline

Anexos agrupados no evento correspondente (`evento.anexos[]`), abaixo do texto do evento.

## Copy (PT-BR — regras-plataforma)

| Chave | Texto |
|-------|-------|
| `confidential.toggle` | Documento confidencial |
| `confidential.hint` | Apenas os usuários selecionados poderão ver este documento. A mensagem permanece visível ao setor. |
| `confidential.addSector` | Adicionar setor |
| `confidential.selectUsers` | Selecione quem pode ver |
| `confidential.validation` | Selecione ao menos um usuário em cada setor marcado |
| `confidential.placeholder` | Documento confidencial |
| `confidential.placeholderHint` | Você não tem permissão para visualizar este arquivo |

## Paleta (mint-palette)

- Badge confidencial: `bg-slate-200/80 dark:bg-slate-800` + ícone `text-teal-600 dark:text-teal-400`
- Placeholder card: borda tracejada `border-slate-200/50 dark:border-slate-700`
- CTA download autorizado: primário teal conforme modo

## APIs client (`api/anexos.ts`)

```typescript
presignAnexo(demandaId, file, eventoId?)
confirmAnexo(demandaId, anexoId, { isConfidential, access? })
addLinkAnexo(demandaId, { title, url, eventoId?, isConfidential, access? })
getAnexoDownloadUrl(demandaId, anexoId)
```

Tipos Zod espelho API em `lib/anexo-schemas.ts` (parse resposta detail).

## Escopo UI v1

- Inclui: compose setorial, reply, forward setor, compose/resposta pessoal, promote (sem reconfig ACL)
- Fora: encaminhar múltiplos setores simultâneos; edição de ACL pós-envio
