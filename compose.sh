#!/usr/bin/env bash
set -euo pipefail

use_podman=false
if [[ "${1:-}" == "--podman" ]]; then
    use_podman=true
    shift
fi

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

exec "${compose_cmd[@]}" "${compose_files[@]}" "$@"
