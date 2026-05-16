README.md

# clienteRede — instruções rápidas (WSL / Windows) — em português

Este projeto é um script Bash (`clienteRede.sh`) escrito para rodar em Linux. O ambiente de produção alvo é Slackware 15.0. Para desenvolvimento em Windows, recomendamos usar o WSL (Windows Subsystem for Linux) com uma distribuição Ubuntu ou similar para testar localmente.

Checklist antes de rodar localmente
- Ter o WSL instalado e uma distro (ex.: Ubuntu 22.04) configurada.
- Garantir que as ferramentas necessárias estejam instaladas: `curl`, `sed`, `shuf` (coreutils) e `ruby`.

Instalação rápida no WSL (Ubuntu/Debian):

```bash
# atualizar repositórios
sudo apt update

# instalar dependências
sudo apt install -y curl sed coreutils ruby

# garantir permissões do script
chmod +x clienteRede.sh
```

Observação sobre Slackware 15.0 (produção)
- Em produção o script roda em Slackware 15.0. O gerenciamento de pacotes no Slackware difere (use `slackpkg` ou instale os binários/manualmente). Antes de promover mudanças, valide em um sistema Slackware ou container que reproduza a versão 15.0.

Preparar ambiente de teste (diretórios e arquivos esperados)

```bash
# entre no diretório do projeto montado pelo WSL (exemplo quando o repo está em D: do Windows)
cd /mnt/d/rematec/REDE/script/clienteRede

# criar diretórios e arquivos esperados pelo script (pode ser necessário sudo)
sudo mkdir -p /var/venditor/WRK /var/venditor/SND /var/log
sudo touch /var/venditor/WRK/OBLATA.dat /var/venditor/WRK/EXTRA.dat /var/venditor/WRK/VarDoc.txt
sudo chown -R $USER:$USER /var/venditor /var/log
```

Executando exemplos

1) Execução interativa (identificação):

```bash
bash clienteRede.sh --action=identify
```

O script irá emitir várias linhas `EVALUATE {...}` e aguardar que você forneça os valores via stdin (simule as respostas conforme solicitado).

2) Teste não interativo — `pre-cadastro` com here-doc (simula as respostas do host):

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

3) Ver logs de execução (em outra janela WSL):

```bash
sudo tail -F /var/log/clienteRede.log
```

Dicas importantes para desenvolvedores
- Não mude o protocolo stdout (`EVALUATE`, `ACCEPT`, `COMMAND`, `MENU`) sem validar com o POS que consome o script; ele é a API entre o script e o host.
- O script grava respostas HTTP em arquivos (por exemplo `RetornoCrm.json`) e captura o código HTTP usando `curl -w "%{http_code}\n"`; muitas verificações fazem comparação de STRING com "200" — se você alterar o formato, atualize todas as verificações.
- Para testes rápidos, use here-docs para simular o host ou pré-crie arquivos em `/var/venditor/WRK/`.
- Se temporariamente fizer `log()` escrever em stdout para debug, reverta a mudança antes de commitar, pois o host depende do stdout para o protocolo.


