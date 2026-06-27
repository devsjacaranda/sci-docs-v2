# Contract: REST API — Global Docs (Central de Documentação)

**Feature**: 023-global-docs  
**Version**: 1.0.0  
**Prefix**: `/global/docs`  
**Guards**: JWT + Tenant + `@RequireLicenca('base')`

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/global/docs`

Lista paginada de artigos da central (FR-005, FR-008, FR-009).

**Query**:

| Param | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `moduleSlug` | `ModuloSlug` | não | Filtra por módulo |
| `type` | `module_usage` \| `process_guide` | não | Filtra por tipo |
| `search` | string | não | ILIKE em `title` e `summary` |
| `page` | number | não | default `1` |
| `pageSize` | number | não | default `24`, max `50` |

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "slug": "compras-etp-guide",
      "title": "Como elaborar um ETP (Estudo Técnico Preliminar)",
      "type": "process_guide",
      "typeLabel": "Guia de processo",
      "moduleSlug": "compras",
      "moduleLabel": "Compras",
      "summary": "Orientações para preenchimento do ETP conforme Lei 14.133/2021...",
      "updatedAt": "2026-06-02T00:00:00.000Z"
    }
  ],
  "total": 14,
  "page": 1,
  "pageSize": 24
}
```

**Response 200 (vazio)**:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "pageSize": 24
}
```

---

## GET `/global/docs/:id`

Detalhe com passos e referências (FR-007, FR-003–004).

**Response 200**:

```json
{
  "id": "uuid",
  "slug": "compras-etp-guide",
  "title": "Como elaborar um ETP (Estudo Técnico Preliminar)",
  "type": "process_guide",
  "typeLabel": "Guia de processo",
  "moduleSlug": "compras",
  "moduleLabel": "Compras",
  "summary": "Orientações para preenchimento do ETP...",
  "updatedAt": "2026-06-02T00:00:00.000Z",
  "steps": [
    {
      "order": 1,
      "title": "Confirmar DFD aprovado",
      "description": "Verifique se a demanda possui DFD concluído...",
      "tip": "Na lista de Demandas, a etapa deve constar como DFD concluída."
    }
  ],
  "references": [
    "Lei 14.133/2021",
    "Modelo ETP — Pau-Brasil",
    "Consulta PNCP — Cedro",
    "Fiscalização etapa ETP — Jatobá"
  ]
}
```

**Response 404**:

```json
{
  "statusCode": 404,
  "message": "Documento não encontrado"
}
```

---

## Errors

| Status | Condição |
|--------|----------|
| 401 | JWT ausente/inválido |
| 403 | Sem licença Base |
| 404 | ID inexistente ou soft-deleted |

---

## Module label map (mapper)

| moduleSlug | moduleLabel |
|------------|-------------|
| `ouvidoria` | Ouvidoria |
| `juridico` | Jurídico |
| `compras` | Compras |
| `contratos` | Contratos |
| `patrimonio` | Patrimônio |
| `protocolo` | Protocolo Virtual |
| `tramitacao` | Tramitação |
| `gabinete` | Gabinete do Presidente |
| `it` | Segurança da Informação |

*(Extensível; seed v1 usa 6 módulos FR-010.)*
