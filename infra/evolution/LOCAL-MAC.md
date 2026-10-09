# Execução gratuita no Mac

Este modo executa a Evolution API no próprio Mac e publica somente a porta HTTP da API por um
túnel HTTPS do ngrok. Ele não exige servidor em nuvem nem alteração no DNS do domínio.

## Quando usar

- Homologação e primeiros testes com um número de WhatsApp.
- Operação inicial com baixo volume, enquanto o Mac puder permanecer ligado.
- Validação completa da BitZaap antes da contratação de uma VPS.

Não é indicado como hospedagem definitiva: se o Mac desligar, suspender ou perder internet, o
WhatsApp ficará temporariamente indisponível.

## Pré-requisitos gratuitos

1. Podman Desktop para macOS, com Podman e Compose configurados.
2. Uma conta gratuita no ngrok.
3. O domínio de desenvolvimento e o authtoken exibidos no painel do ngrok.

O plano gratuito do ngrok possui limites mensais de tráfego e requisições. Ele é adequado para
homologação, não para uma operação comercial de alto volume.

## Configuração

No painel do ngrok, copie somente o valor de **Your Authtoken**. Depois, dentro de
`infra/evolution`, execute:

```bash
./setup-local-env.sh seu-dominio-gratuito.ngrok-free.dev
```

O script lê o authtoken da área de transferência do macOS, gera chaves aleatórias diferentes e
grava o `.env` com permissão `600`. Os segredos não são exibidos no terminal. Como alternativa,
forneça o token somente para o processo:

```bash
NGROK_AUTHTOKEN='seu-token' ./setup-local-env.sh seu-dominio-gratuito.ngrok-free.dev
```

O script se recusa a sobrescrever um `.env` existente. Use `--force` apenas em uma rotação
intencional de todos os segredos.

## Inicialização

O comando abaixo inicia apenas os serviços locais; o proxy Caddy usado em VPS não será iniciado.

```bash
./podman-compose-local.sh up -d postgres redis evolution ngrok
```

Valide o estado:

```bash
./podman-compose-local.sh ps
curl --fail --show-error http://127.0.0.1:8080
curl --fail --show-error "https://${NGROK_DOMAIN}"
```

O inspetor local do ngrok fica disponível em `http://127.0.0.1:4040`.

## Conexão com o Skip

Configure no gerenciador de segredos da BitZaap:

- `EVOLUTION_API_URL`: `https://<NGROK_DOMAIN>`
- `EVOLUTION_API_KEY`: o mesmo valor salvo no `.env`

Depois, abra a tela de conexão da BitZaap e gere o QR Code.

## Parada e reinicialização

```bash
# Parar sem apagar os dados
./podman-compose-local.sh stop

# Iniciar novamente
./podman-compose-local.sh start
```

Não use `down -v`: a opção `-v` remove volumes e pode apagar banco, cache e credenciais da sessão
do WhatsApp.
