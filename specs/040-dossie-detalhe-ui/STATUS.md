# STATUS — 040 Dossiê de detalhe (design system)

**Status:** Completed — referência canônica  
**Piloto:** `/ouvidoria/manifestacoes/:id`  
**Norma de produto:** `.cursor/docs/regras-plataforma.md` §4.3

## Entrega

A tela de detalhes da Ouvidoria é o **padrão oficial** para novas telas de detalhe operacional (Gabinete, Jurídico, Protocolo, Compras, etc.).

Não é o plano ativo do Spec Kit (039 permanece ativo). Esta pasta é a **norma de UI** do dossiê.

## Checklist visual

- [x] Header com badges (ícone + texto); `in_review` não é destructive
- [x] Relato ~65ch; cards Identidade / Manifestante / Endereço / Anexos / Timeline
- [x] Ações em 3 botões + Dialog
- [x] Documentos no header (PDF/Word)
- [x] Inline edit em texto livre; Relato em textarea
- [x] Sem trilho 8/4; sem card Documentos/Estado redundantes
