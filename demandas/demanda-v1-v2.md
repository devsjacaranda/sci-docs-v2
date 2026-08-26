referencia:
civ2-docs\transcripts\ts01.md
civ2-docs\transcripts\ts03.md
civ2-docs\transcripts\ts02.md

A demanda única consolidando todas as falhas críticas relatadas após a atualização do sistema foi gerada e já está disponível no painel Studio sob o nome demanda_unica_sistema.md.
Este documento técnico organiza formalmente todos os problemas e dados ausentes para ação imediata da equipe de suporte:
Tabela de Motivos (Assuntos) Zerada: A lista de seleção de assuntos está completamente vazia, ocultando todos os 77 motivos previamente catalogados
.
Incompletude na Lista de Bairros: Dos 64 bairros cadastrados na base de dados, apenas 2 estão aparecendo para seleção
.
Divergência Crítica de Perfil de Usuário: O sistema apresenta uma mistura de credenciais, exibindo o nome "Maria Oliveira" (mencionada no áudio como Maria Silva) vinculado diretamente ao e-mail de Gleise (gleisesilva.gs@gmail.com)
.
Ausência de Campo Regulatório (Ageman): Falta a opção obrigatória de manifestação para categorizar a demanda entre Abastecimento, Iluminação Pública ou Estacionamento Rotativo.
Os detalhes de impacto (como o fato de a equipe da Ouvidoria estar paralisada por conta disso)
 e as informações de contato do suporte (Rogério) e do ponto focal na Ouvidoria (Luana) foram devidamente mapeados para viabilizar a resolução rápida
.

## Pontos a confirmar com o cliente

1. **Tipos INFORMAÇÃO e RECURSO.** O enum v2 não tem esses valores. A migração já colapsa ambos em `request` (Solicitação). Confirmar se isso é aceitável ou se o enum precisa crescer.
2. **Contagem de bairros.** O cliente relatou 64; a fonte canônica do v1 (`manaus-zones.ts`) tem **63 bairros oficiais** (mais ~240 sub-bairros usados só para auto-zona). Se existir planilha própria, enviar antes do go-live.
🔄 Se você precisar alterar o formato de exportação deste relatório ou quiser adicionar mais algum detalhe específico para enviar diretamente ao suporte técnico, é só me avisar!