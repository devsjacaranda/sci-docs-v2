# Plan — 040 Dossiê de detalhe UI

**Status:** Completed (já implementado no piloto Ouvidoria)

## Stack

React 19 + Vite 8 + Tailwind v4 + shadcn (`@ci/ui`) + paleta Mint. Sem lib nova.

## Anatomia (desktop e mobile)

```
Header (card)
  eyebrow · H1 nº institucional · protocolo sistema
  badges prioridade + status
  botões compactos Encaminhar / Responder / Encerrar
  chrome à direita: Voltar · Documentos · Editar

Identidade   — Tipo/Motivo/Canal/Programa só leitura; Assunto inline
Relato       — textarea inline se editável
Manifestante — textos livres inline; anônima/restrita sem caneta
Endereço     — textos livres inline; Município só leitura
Anexos
Linha do tempo
```

## PATCH

Reusar `PATCH /ouvidoria/manifestacoes/:id` (`updateManifestacaoDraft`). Um campo por save. Não enviar bloco `concessionaria` só com `ordemServico` (zera prazos).

## Aplicar em outro módulo

1. Copiar a anatomia (não o dump de formulário).
2. Reusar o padrão visual; extrair para `@ci/ui` só se o segundo módulo precisar do mesmo componente.
3. Inline edit: texto livre independente apenas.
4. Conferir `.cursor/docs/regras-plataforma.md` §4.3.
