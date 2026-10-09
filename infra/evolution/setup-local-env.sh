#!/bin/sh

set -eu

usage() {
  echo "Uso: $0 <dominio-ngrok> [--force]" >&2
  echo "O authtoken deve estar em NGROK_AUTHTOKEN ou na area de transferencia do macOS." >&2
  exit 1
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

domain=$1
force=${2:-}

case "$domain" in
  ''|*[!A-Za-z0-9.-]*)
    echo "Dominio ngrok invalido: use somente o host, sem https:// ou caminho." >&2
    exit 1
    ;;
esac

if [ "$force" != "" ] && [ "$force" != "--force" ]; then
  usage
fi

token=${NGROK_AUTHTOKEN:-}
if [ -z "$token" ] && command -v pbpaste >/dev/null 2>&1; then
  token=$(pbpaste)
fi

case "$token" in
  ''|'$YOUR_AUTHTOKEN'|*YOUR_AUTHTOKEN*|*[!A-Za-z0-9_.-]*)
    echo "Authtoken ngrok ausente ou invalido. Copie apenas o token e tente novamente." >&2
    exit 1
    ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target="$script_dir/.env"

if [ -e "$target" ] && [ "$force" != "--force" ]; then
  echo "O arquivo $target ja existe. Use --force somente se quiser substituir os segredos." >&2
  exit 1
fi

command -v openssl >/dev/null 2>&1 || {
  echo "OpenSSL nao encontrado." >&2
  exit 1
}

evolution_key=$(openssl rand -hex 32)
postgres_password=$(openssl rand -hex 32)
redis_password=$(openssl rand -hex 32)

umask 077
temporary=$(mktemp "${TMPDIR:-/tmp}/bitzaap-env.XXXXXX")
trap 'rm -f "$temporary"' EXIT HUP INT TERM

{
  printf 'EVOLUTION_DOMAIN=%s\n' "$domain"
  printf 'BITZAAP_PUBLIC_URL=%s\n' 'https://plataforma-whatsapp-conectado-clone-56e50.goskip.app'
  printf 'EVOLUTION_IMAGE=%s\n' 'evoapicloud/evolution-api:latest'
  printf 'EVOLUTION_API_KEY=%s\n' "$evolution_key"
  printf 'POSTGRES_DATABASE=%s\n' 'evolution'
  printf 'POSTGRES_USERNAME=%s\n' 'evolution'
  printf 'POSTGRES_PASSWORD=%s\n' "$postgres_password"
  printf 'REDIS_PASSWORD=%s\n' "$redis_password"
  printf 'NGROK_DOMAIN=%s\n' "$domain"
  printf 'NGROK_AUTHTOKEN=%s\n' "$token"
} > "$temporary"

mv "$temporary" "$target"
chmod 600 "$target"
trap - EXIT HUP INT TERM

echo "Ambiente local criado com seguranca em $target."
echo "Os valores secretos nao foram exibidos."
