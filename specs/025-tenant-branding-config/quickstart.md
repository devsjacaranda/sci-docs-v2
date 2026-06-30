# Quickstart: Identidade visual do tenant

**Feature**: 025-tenant-branding-config  
**Prerequisites**: [plan.md](./plan.md) · [contracts/rest-api-tenant-branding.md](./contracts/rest-api-tenant-branding.md)

## Pré-requisitos

- PostgreSQL local com migration aplicada
- `sci-api-v2` rodando (`npm run start:dev`)
- `sci-client-monorepo` rodando (`npm run dev` → `@ci/web`)
- Usuário **admin da plataforma** (`admin_tenant` ou `admin_plataforma`) no tenant de dev
- `VITE_USE_API=true` (default)

## 1. Aplicar migration

```powershell
cd sci-api-v2
npm run prisma:migrate:dev
```

Verificar colunas `avatarStorageKey` e `bannerStorageKey` em `Tenant`.

## 2. Subir serviços

```powershell
# Terminal A
cd sci-api-v2
npm run start:dev

# Terminal B
cd sci-client-monorepo
npm run dev
```

## 3. Configurar identidade (admin)

1. Login como administrador da plataforma.
2. Navegar **Administração → Administrador Plataforma → Configurações** (`/administracao/plataforma/config`).
3. Enviar foto institucional (JPEG/PNG ≤ 5 MB).
4. Enviar banner (JPEG/PNG ≤ 10 MB).
5. Confirmar mensagem **Identidade visual atualizada.**
6. Recarregar a página — previews devem persistir.

## 4. Verificar boas-vindas global

1. Ir à tela global de boas-vindas (`/global` ou home padrão).
2. Confirmar banner e foto institucional configurados (não imagens Careiro hardcoded).
3. Nome da instituição visível no bloco de branding.

## 5. Testar acesso negado

1. Login como servidor comum (`user` / `chefe_setor` sem platform admin).
2. Acessar `/administracao/plataforma/config` diretamente.
3. Esperar tela de acesso negado — **sem** formulário de upload.

## 6. Testar remoção

1. Como admin, remover banner na tela de configuração.
2. Recarregar boas-vindas — faixa neutra sem imagem quebrada.
3. Remover foto — iniciais do nome da instituição no círculo.

## 7. Testes automatizados

```powershell
cd sci-api-v2
npm test -- tenant-branding

cd sci-client-monorepo/apps/web
npm run test -- tenant
```

Todos devem passar antes de `/speckit-implement` complete.

## 8. Validação API manual (opcional)

```powershell
# Após login, com token e X-Tenant-ID:
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: jacaranda" http://localhost:3000/tenant/branding
```

Resposta 200 com `name`, `avatarUrl`, `bannerUrl` quando configurados.

## Critérios de aceite (spec)

| SC | Como validar |
|----|--------------|
| SC-001 | Fluxo completo config em < 5 min |
| SC-002 | Usuário comum vê branding na boas-vindas |
| SC-003 | Upload válido conclui na 1ª tentativa |
| SC-004 | Non-admin não altera via UI nem API |
| SC-005 | Alteração visível sem re-login |
