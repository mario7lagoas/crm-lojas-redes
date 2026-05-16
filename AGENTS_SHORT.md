AGENTS_SHORT.md

# Resumo rápido — o que um agente deve obedecer / evitar

Objetivo: instruções curtas e diretas para agentes automatizados que vão editar `clienteRede.sh`.

Evitar (não faça):
- Não remover, renomear ou reordenar linhas de protocolo enviadas ao host: `EVALUATE`, `ACCEPT`, `COMMAND`, `MENU`.
- Não alterar o comportamento de saída do `sair()` (ele escreve `ERROR=` seguido de `BYE <code>`). Testes e o host dependem desses tokens.
- Não alterar como o `curl` grava respostas: o script usa `-w "%{http_code}\n"` para capturar o código HTTP e escreve o corpo em arquivos (`RetornoCrm.json`, `RetornoSms.json`). Essas rotinas comparam o código como STRING (ex.: `if [ "${OUTPUT}" != "200" ]`).
- Não renomear ou mudar formato das variáveis emissas para o host `GRUPO_REDE1`...`GRUPO_REDE6`.
- Não remover efeitos colaterais baseados em arquivo (ex.: escrita em `/var/venditor/SND/` para contingência) sem atualizar os consumidores.

Deve fazer (o que obedecer):
- Preservar o protocolo stdout/stdin; se for necessário alterar as mensagens ao host, valide com o POS que consome o script.
- Manter o padrão de criação/uso de arquivos temporários (`RetornoCrm.json`, `RetornoSms.json`, `/var/venditor/WRK/*`) ou documentar a mudança.
- Garantir que dependências existam (curl, sed, shuf, ruby) no ambiente onde o script será executado.
- Ao alterar tratamento de erros HTTP, atualize todas as verificações que fazem comparação de string com `200`.
- Ao depurar, se ativar logs em stdout, reverta a alteração depois — o host analisa stdout.

Testes seguros (rápido):
- Use here-docs para simular respostas do host ao executar o script (ex.: `bash clienteRede.sh --action=pre-cadastro <<'EOF' ... EOF`).
- Pré-crie arquivos em `/var/venditor/WRK/` para simular estado do host em cenários locais.

Referências rápidas:
- Inicialização: `evaluate()` (no topo do `clienteRede.sh`).
- Fluxo CRM: `realizarConsulta()`, `sendCadastro()`, `PreCadastro()`.
- Fluxo SMS: `sendMessage()`, `sendToken()`.

-- Fim do resumo

