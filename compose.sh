#!/usr/bin/env bash
set -euo pipefail

use_podman=false
EXEC_USER="$(id -u)"
DEFAULT_SERVICE="unmanic-dev"

while [[ "${1:-}" =~ ^-- ]]; do
    case "$1" in
    --podman)
        use_podman=true
        shift
        ;;
    --root)
        EXEC_USER=0
        shift
        ;;
    *)
        break
        ;;
    esac
done

compose_cmd=(docker compose)
if $use_podman; then
    compose_cmd=(podman compose)
fi

compose_files=(-f docker-compose.yml)

# Add support for NVIDIA GPUs
if command -v nvidia-smi >/dev/null 2>&1 || [[ -e /dev/nvidiactl ]]; then
    compose_files+=(-f docker/docker-compose.nvidia.yml)
fi

# Add support for AMD/Intel GPUs
if [[ -e /dev/dri ]]; then
    compose_files+=(-f docker/docker-compose.dri.yml)
fi

cmd="${1:-}"
shift || true

case "$cmd" in
start)
    "${compose_cmd[@]}" "${compose_files[@]}" pull
    exec "${compose_cmd[@]}" "${compose_files[@]}" up -d "$@"
    ;;
stop)
    exec "${compose_cmd[@]}" "${compose_files[@]}" down "$@"
    ;;
ps)
    exec "${compose_cmd[@]}" "${compose_files[@]}" ps "$@"
    ;;
exec)
    exec "${compose_cmd[@]}" "${compose_files[@]}" exec --user="${EXEC_USER:?}" "${DEFAULT_SERVICE}" "$@"
    ;;
*)
    exec "${compose_cmd[@]}" "${compose_files[@]}" "$cmd" "$@"
    ;;
esac
