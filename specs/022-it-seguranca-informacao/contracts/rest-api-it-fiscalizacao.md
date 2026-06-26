# Contract: REST API — IT Fiscalização (Jatobá)

**Feature**: 022-it-seguranca-informacao  
**Version**: 1.0.0  
**Prefix**: `/it/fiscalizacao`  
**Guards**: `@RequireModulo('it')` + `@RequireLicenca('jatoba')`

Jatobá **sinaliza** conformidade — **não** altera ativos/incidentes (R-20).

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/it/fiscalizacao`

Painel — backup audit runs, stats conformidade, trilha resumo.

**Response 200**:

```json
{
  "backupAudit": {
    "currentRun": {
      "id": "uuid",
      "scheduledDay": 5,
      "startedAt": "2026-06-05T06:00:00Z",
      "serversInAlerta": 4,
      "serversInVermelho": 1
    },
    "stats": {
      "conforme": 8,
      "nonConforme": 1,
      "partial": 0,
      "pending": 3
    }
  },
  "recentFindings": [
    {
      "id": "uuid",
      "title": "Backup não evidenciado",
      "assetName": "SRV-FIN-02",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme"
    }
  ],
  "readOnly": true
}
```

---

## Workflow backup

### GET `/it/fiscalizacao/backup/pending`

Servidores em `alerta` ou `vermelho` exigindo evidência.

### POST `/it/fiscalizacao/backup/evidence/presign`

**Body**: `{ assetId, fileName, contentType, sizeBytes }`  
**Response**: `{ uploadUrl, storageKey, expiresIn }`

### POST `/it/fiscalizacao/backup/evidence`

**Body**:

```json
{
  "assetId": "uuid",
  "runId": "uuid",
  "backupSizeBytes": 1073741824,
  "restoreDate": "2026-06-04",
  "logStorageKey": "tenant/it/backup/..."
}
```

Validação: size > 0, log presente → conformidade **Conforme**; atualiza `backupAuditStatus=ok`.

### POST `/it/fiscalizacao/backup/run` (manual/admin)

Dispara ciclo fora do cron (dev/test).

---

## Trilha de auditoria (append-only)

### GET `/it/fiscalizacao/audit-trail`

Query: `entityType`, `entityId`, `userId`, `from`, `to`, `page`, `pageSize`.

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "userId": "uuid",
      "userName": "Ana Silva",
      "action": "update",
      "actionLabel": "Edição",
      "ipAddress": "192.168.1.10",
      "entityType": "asset",
      "entityId": "uuid",
      "summary": { "fields": ["name"] },
      "createdAt": "2026-06-25T09:00:00Z"
    }
  ],
  "total": 120,
  "readOnly": true,
  "immutable": true
}
```

**Não existem** endpoints DELETE/PATCH para audit-trail.

---

## Notificação ANPD

### POST `/it/fiscalizacao/incidentes/:id/anpd/preview`

Somente incidentes `severity=critical`. Retorna template preenchido editável.

**Response 200**:

```json
{
  "incidentId": "uuid",
  "fields": {
    "systemName": "Sistema RH",
    "dataCategories": ["CPF", "Dados financeiros"],
    "occurredAt": "2026-06-25T14:00:00Z",
    "descriptionSummary": "..."
  },
  "editableFields": ["descriptionSummary", "dataCategories"]
}
```

### POST `/it/fiscalizacao/incidentes/:id/anpd/generate`

**Body**: `{ fields: { ... } }` (override opcional)  
**Response 200**: `Content-Type: application/pdf` + `ItAnpdNotification` metadata header ou JSON com `{ downloadUrl, notificationId }`.

---

## Rastreabilidade Jatobá

### GET `/it/fiscalizacao/backup/:assetId/trace`

Sheet *Por que esta checagem deu este resultado*.

### GET `/it/fiscalizacao/findings/:id/trace`

Sheet *O que gerou este achado*.

---

## Jobs (interno)

| Job | Cron | Ação |
|-----|------|------|
| `BackupAuditScheduledJob` | `0 6 ${BACKUP_AUDIT_DAY:-5} * *` | alerta servidores |
| `BackupAuditOverdueJob` | `0 7 ${BACKUP_AUDIT_DAY+1:-6} * *` | vermelho + notify |

## Erros

| Code | Quando |
|------|--------|
| 403 | Sem licença Jatobá |
| 404 | Incidente não crítico (ANPD) |
| 422 | Evidência inválida (size=0, log ausente) |
