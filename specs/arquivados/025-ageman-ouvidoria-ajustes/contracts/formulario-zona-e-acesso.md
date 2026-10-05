# Contract: Zona do formulário e Quem tem acesso

## Nova manifestação — zona

No formulário de nova manifestação:

- o campo Zona mostra o valor e não aceita digitação nem cola;
- bairro de Manaus reconhecido preenche a zona correspondente;
- trocar o bairro troca a zona;
- bairro sem zona conhecida deixa o campo vazio e não bloqueia o salvamento;
- a zona anterior não permanece quando o bairro novo não tem zona.

Na ficha de uma manifestação já salva, a zona continua editável.

## Quem tem acesso

O bloco “Quem tem acesso” aparece somente se todas forem verdadeiras:

1. o usuário da sessão é super administrador (`admin_saas`);
2. o nome da sessão, comparado sem acento, em minúsculas e com espaços simples, é `romulo gabriel pinheiro pereira`.

| Sessão | Bloco |
|--------|-------|
| Super administrador com esse nome | visível |
| Outro super administrador | ausente |
| Administrador do tenant | ausente |
| Usuário comum | ausente |
| Sem sessão | ausente |

Quando o bloco está ausente, a tela não chama a listagem de acessos da manifestação.
