# Ouvidoria — colisões de `numeroPersonalizado`

Gerado: 2026-08-25T13:54:29.763Z

Estratégia: o **primeiro** registro (createdAt, depois id v1) conserva o `id_personalizado` verbatim. Duplicados seguintes ficam com `numeroPersonalizado` **null** — sem sufixo inventado (`-b`, UUID, etc.).

| numeroPersonalizado | winner v1 | losers v1 |
|---|---|---|
| `2026-1-08-0056` | `10efec8e-0eed-425b-8b9b-dce533041249` | `4135d1ab-bb67-452d-ae8a-36d9358fe402` |
| `2026-1-08-0057` | `791a7c5b-3eed-428e-a7c3-3728798c4319` | `76923247-19bd-4ffd-a203-d812e12f1988` |
| `2026-1-03-0004` | `5aad347a-58d1-45a0-95b1-92f3775d501e` | `5ef5ad91-2841-4b08-ace4-e02e00ad1e07` |
| `2026-1-08-0031` | `db-existing` | `4b44042f-89ac-45c7-b316-115075921037` |
| `2026-1-08-0032` | `db-existing` | `03c315b3-a622-44f7-8647-8f550688ae96` |
| `2026-1-08-0033` | `db-existing` | `ae410b41-d2d1-434b-a2f8-a7868e8ce39b` |
