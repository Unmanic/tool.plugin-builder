# Unmanic Plugin Builder (Agent Workspace)

This repo is a minimal workspace for generating Unmanic plugins with an AI agent. It includes:

- a docker-compose environment for plugin creation/testing
- a `clone-projects.sh` helper to clone or update upstream repos
- an `AGENTS.md` file for your LLM agent of choice to reference

## Quick start for manually creating a plugin

1. Clone source references:

```bash
./clone-projects.sh
```

1. Start the Unmanic container:

```bash
docker compose up -d
```

1. Create a plugin:

```bash
PLUGIN_ID="test_plugin"
PLUGIN_NAME="Plugin Name"

docker compose exec unmanic-dev \
  unmanic --manage-plugins \
  --create-plugin \
  --plugin-id="${PLUGIN_ID:?}" \
  --plugin-name="${PLUGIN_NAME:?}" \
  --plugin-runners="on_worker_process,emit_task_queued"
```

1. Edit the plugin in `./build/plugins/`, then test:

```bash
docker compose exec unmanic-dev unmanic --manage-plugins --test-plugin=test_plugin
```

## Directory layout

- `./build` -- Mounted to `/config/.unmanic` in the container; generated config/logs/plugins live here
- `./projects` -- Reference repos used by the agent

## Notes

- The docker image uses the Unmanic staging build. Change the tag in `docker-compose.yml` if needed.
