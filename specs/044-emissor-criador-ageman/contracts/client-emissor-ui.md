# Contrato UI — Emissor no wizard interno

**Telas**: `ManifestacaoWizardPage` + `ManifestacaoStepOneForm` (`apps/web`). Detalhe: `ManifestacaoIdentityCard` já é somente leitura — sem mudança visual.

Paleta Mint. Componentes: `Field` + `Input` (readonly) ou `Combobox` (`@ci/ui`). Sem `npx shadcn add`.

## Decisão de modo

Fonte: `useAuth().user.role` (não `isPlatformAdmin`).

| Condição | Modo |
| --- | --- |
| `role` ∈ {`admin_tenant`, `admin_saas`} **e** criação nova ou `status === 'draft'` | `select` |
| Caso contrário | `readonly` |

## Modo `readonly`

- Label: “Emissor”.
- Controle: `Input` `readOnly` `disabled`, valor = `user.name` na criação; no edit pós-confirmação = `emissorLabel` da API ou “—”.
- Sem `combobox` / sem `aria-label` de lista.
- Hint: “Emissor atribuído automaticamente a quem está registrando.”
- Body: **omite** `emissorUserId`.

## Modo `select`

- `Combobox` com primeira opção `{ value: '__self__', label: user.name }` (ou “Eu mesmo — {nome}”) **pré-selecionada**.
- Demais opções: `GET /ouvidoria/usuarios-emissores`.
- Hint: “Padrão: você. Pode escolher um operador do tenant.”
- Submit: `__self__` / vazio → schema transforma em `undefined` (não envia id). UUID escolhido → envia `emissorUserId`.

## Wizard / edição

- Criação: operador já vê o próprio nome; admin já vê “eu mesmo” marcado — zero clique obrigatório.
- Abrir rascunho existente como admin: se `emissorUserId` da API existir, combobox nessa opção; senão `__self__`.
- Abrir demanda confirmada: sempre `readonly` (mesmo admin).

## Detalhe

`ManifestacaoMetaItem label="Emissor"` permanece. Sem ação de edição inline (já é o caso).

## Acessibilidade

- Readonly: o campo continua associado ao `htmlFor` / `id` do `Field`; não é focável como combobox.
- Select: `aria-label="Emissor"` no trigger (já existe).
- Contraste: texto principal `#090D16` / `#F8FAFC`; muted para hint.
- Sem emoji estrutural; ícones Lucide só se já houver no form.

## Testes de regressão (Vitest)

Ver [test-strategy.md](./test-strategy.md). `CT-OUV-EMISSOR-CLIENT-006` deixa de esperar combobox para operador.
