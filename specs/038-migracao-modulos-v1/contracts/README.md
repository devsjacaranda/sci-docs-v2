# Contratos de interface — Spec 038

Contratos das interfaces que esta feature expõe. Não contêm implementação.

| Arquivo | Interface |
|---|---|
| [ouvidoria.md](./ouvidoria.md) | API autenticada da Ouvidoria — operação, painel, catálogos, atendimentos, documentos |
| [ouvidoria-publica.md](./ouvidoria-publica.md) | API pública consumida pelo portal do cidadão |
| [ouvidoria-errors.md](./ouvidoria-errors.md) | Catálogo canônico de erros da Ouvidoria (códigos, HTTP, copy, client) |
| [gabinete.md](./gabinete.md) | API do Gabinete — fluxo de demandas, cadastros, diretorias |
| [diagnostico.md](./diagnostico.md) | API do Diagnóstico — processos, marcadores, painel, documentos institucionais |
| [migracao-cli.md](./migracao-cli.md) | Contrato dos comandos de migração e do relatório de reconciliação |

## Convenções comuns

**Autenticação**: token no cabeçalho `Authorization`, tenant no cabeçalho `X-Tenant-ID`. Endpoints marcados como públicos dispensam token, mas exigem o tenant.

**Validação**: todo corpo, parâmetro de rota e de consulta é validado por schema Zod, com o pipe global. Nenhum endpoint aceita corpo não validado — inclusive os cadastros do Gabinete, que no v1 aceitavam qualquer chave permitida sem verificação de tipo.

**Paginação**: parâmetros de página e limite, com limite máximo declarado por endpoint. A resposta informa total, página e limite. Filtro, ordenação e agregação ocorrem no servidor — nunca sobre uma página já carregada.

**Erros**: código de situação HTTP mais corpo com identificador de erro estável e mensagem. Indisponibilidade de dependência externa é sempre erro explícito, nunca resposta vazia ou degradação silenciosa.

**Exclusão**: exclusão lógica em todos os cadastros. Registro excluído não aparece em listagens nem em contagens.
