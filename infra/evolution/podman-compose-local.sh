#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -z "${PODMAN_COMPOSE_PROVIDER:-}" ]; then
  if command -v podman-compose >/dev/null 2>&1; then
    PODMAN_COMPOSE_PROVIDER=$(command -v podman-compose)
  elif [ -x "$HOME/Library/Python/3.13/bin/podman-compose" ]; then
    PODMAN_COMPOSE_PROVIDER="$HOME/Library/Python/3.13/bin/podman-compose"
  else
    echo "podman-compose nao encontrado. Instale com: pip3 install --user podman-compose" >&2
    exit 1
  fi
fi

export PODMAN_COMPOSE_PROVIDER

exec podman compose \
  -f "$script_dir/compose.yaml" \
  -f "$script_dir/compose.local.yaml" \
  "$@"
