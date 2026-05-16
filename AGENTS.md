
AGENTS.md

# Guia para agentes — clienteRede

Resumo curto: este repositório contém um único script Bash cliente ("`clienteRede.sh`") que implementa um protocolo interativo em terminal com um host estilo POS e integra-se com dois serviços HTTP externos (CRM e SMS). Um agente de codificação precisa entender rapidamente o protocolo de I/O, os pontos de integração e os fluxos principais para fazer alterações seguras e direcionadas.

Essenciais
- Ponto de entrada: `clienteRede.sh` (arquivo único). Principais flags CLI: `--action=identify|clear|pre-cadastro` e `--type=menu|bar-pin|...` (veja o fim do script onde os args são parseados e o case final).
- Propósito: fornecer identificação do cliente e interações leves com CRM/SMS para gestão de campanhas no ponto de venda.
- Linguagem/execução: Bash (estilo POSIX, usa ferramentas GNU: curl, sed, shuf, ruby). Plataforma alvo: Linux (caminhos em `/var/...`).

Visão geral (o que ler junto)
- `evaluate()` (topo do script) — inicialização central: define `logdir`, `OBLATA`, `GERENCIAL`, `varDoc`, `prefixoGrupo` e garante entrada no logrotate. Leia esta função primeiro para entender o estado global.
- Protocolo de I/O (muitas funções) — o script conversa com o host via linhas escritas em stdout como `EVALUATE {...}`, `ACCEPT ...`, `COMMAND ...`, `MENU ...` e depois usa `read` para receber respostas do host. Busque por `echo "EVALUATE` / `ACCEPT` / `COMMAND` no arquivo para ver todos os padrões.
- Fluxo CRM: `realizarConsulta()`, `sendCadastro()` e `PreCadastro()` implementam as interações HTTP com o endpoint CRM (`server_crm` + `customer`). Respostas são gravadas em arquivos como `RetornoCrm.json` e, em outros pontos, interpretadas como campos separados por `|`.
- Fluxo SMS: `sendMessage()` e `sendToken()` usam as variáveis `sms_rede`, `apiKey`, `xApiKey` (obtidas via `EVALUATE`) para chamar um gateway SMS. Arquivo de resposta: `RetornoSms.json`.

Arquivos-chave e locais com estado
- /var/log/clienteRede.log — log principal (escrito por `log()`).
- /var/venditor/WRK/ (OBLATA.dat, EXTRA.dat, VarDoc.txt, CHANGELST.ctl) — arquivos de trabalho usados pela integração com o host.
- /var/venditor/SND/ — XMLs enfileirados para contingência (ex.: PRE_CADASTRO_CONT_*.xml).
- JSONs temporários no diretório do script: `RetornoCrm.json`, `RetornoSms.json` (criadas e lidas pelo script).

Variáveis importantes & fontes de configuração
- Variáveis fornecidas pelo host são solicitadas via `EVALUATE {NAME}` e então lidas do stdin (o host fornece os valores). Exemplos: `SRV_CRM`, `MAXTIMEOUT`, `MINTIMEOUT`, `SMS_REDE`, `API_KEY_REDE`, `X_API_KEY_REDE`.
- Timeouts de execução: `MAXTIMEOUT` / `MINTIMEOUT` afetam `--max-time` e `--connect-timeout` do `curl`.
- Chaves de API: `API_KEY_REDE` e `X_API_KEY_REDE` são obrigatórias para envio de SMS; o script valida e mostra um `MESSAGE_BOX` se faltar.

Convenções e padrões que o agente deve respeitar
- Protocolo interativo em stdout: não remova nem reordene linhas `EVALUATE`, `ACCEPT`, `COMMAND`, `MENU` sem validar com o host que as consome — elas são a API entre o script e o POS.
- Sinalização de saída/erro: o script usa `sair()` que escreve `ERROR=` e `BYE <code>`; testes ou chamadores podem depender desses tokens exatos.
- Chamadas de rede gravam o corpo da resposta em arquivos e retornam o código HTTP com `curl -w "%{http_code}\n"` — outras partes do script comparam a string do código (ex.: `if [ "${OUTPUT}" != "200" ]`). Mudar esse comportamento exige atualizar todos os pontos dependentes.
- Variáveis de grupo são emitidas como `GRUPO_REDE1=...` até `GRUPO_REDE6=` — o host espera esses nomes literais.

Dependências externas
- curl, sed, shuf, ruby (ruby é usado para extrair `id` do JSON em `sendToken`). Garanta que essas ferramentas existam no ambiente de desenvolvimento/teste.
- O script assume paths e ambiente Linux; em Windows use WSL, Git Bash ou um container Linux para executar testes.

Fluxos de desenvolvimento & comandos úteis
- Executar interativamente (recomendado):
  - Abra um shell Linux e execute:

```bash
bash clienteRede.sh --action=identify
```

  O script solicitará via stdin os valores esperados pelo `EVALUATE`.
- Executar `pre-cadastro` em modo não interativo (teste) fornecendo respostas via here-doc (exemplo):

```bash
bash clienteRede.sh --action=pre-cadastro <<'EOF'
127.0.0.1
80
LOJA
POS
CUPOM
STATUS
STATE
https://crm.example.com/
30
5
EOF
```

- Inspecionar logs em execução: `sudo tail -F /var/log/clienteRede.log` e verificar arquivos temporários: `RetornoCrm.json`, `RetornoSms.json`, e conteúdo de `/var/venditor/WRK`.

Dicas de teste & depuração específicas
- Para testar pequenas alterações, não mude o protocolo em stdout — em vez disso, simule respostas do host via here-doc ou pré-crie os arquivos esperados em `/var/venditor/WRK/`.
- Ao alterar tratamento de erros HTTP, observe que o script usa comparações de string para o código HTTP; migrar para comparações numéricas exige mudança em todos os locais que dependem disso.
- Para logs mais verbosos durante depuração, edite temporariamente `log()` para também escrever em stdout (lembre-se de reverter, pois o host analisa stdout).

Onde procurar exemplos importantes no script
- Inicialização: `evaluate()` (linhas ~44–75)
- Chamadas CRM: `PreCadastro()` (linhas ~146–191), `sendCadastro()` (248–284), `realizarConsulta()` (442–510)
- SMS: `sendMessage()` / `sendToken()` (233–241, 324–342)
- Exemplos do protocolo I/O aparecem por todo o arquivo onde `echo "ACCEPT ..."`, `echo "COMMAND ..."`, `read ...` são usados.

Se precisar alterar o comportamento
- Sempre execute cenários interativos após alterações para confirmar que as linhas do protocolo permanecem corretas.
- Preserve efeitos colaterais baseados em arquivo (JSONs temporários, XMLs em `/var/venditor/SND/`) ou atualize os consumidores desses arquivos.

Pontos de contato (para automação futura)
- Protocolo host <-> script (stdout/stdin) — fronteira de integração principal; qualquer agente que modifique saídas deve validar o comportamento junto ao host POS.

-- Fim do AGENTS.md

