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

1. Ensure a `.env` file exists with your UID/GID/TZ (used by docker-compose):

```bash
cat << EOF > .env
PUID=$(id -u)
PGID=$(id -g)
TZ=$(cat /etc/timezone 2>/dev/null || timedatectl show -p Timezone --value 2>/dev/null || echo UTC)
EOF
```

1. Start the Unmanic container (use `./compose.sh` so GPU passthrough is enabled when available):

```bash
./compose.sh up -d
```

The Unmanic UI will be available on port 7888 (http://localhost:7888).

To stop the stack:

```bash
./compose.sh down
```

`./compose.sh` auto-detects NVIDIA or Intel/AMD (DRI) devices and adds the relevant override file from `./docker/`. If Docker is unavailable, you can use `./compose.sh --podman`. `./compose.sh exec` defaults to the `unmanic-dev` service, so you can run `./compose.sh exec ls -la` without naming the container.

1. Create a plugin:

```bash
PLUGIN_ID="test_plugin"
PLUGIN_NAME="Plugin Name"

./compose.sh exec \
  unmanic --manage-plugins \
  --create-plugin \
  --plugin-id="${PLUGIN_ID:?}" \
  --plugin-name="${PLUGIN_NAME:?}" \
  --plugin-runners="on_worker_process,emit_task_queued"
```

1. Edit the plugin in `./build/plugins/`, then test:

```bash
./compose.sh exec \
  unmanic --manage-plugins --test-plugin=test_plugin
```

## Quick start with AI agents

These guides assume you run the agent from the repo root so it can read `AGENTS.md`,
`docker-compose.yml`, and the `./projects` references. Each agent should be pointed at
`AGENTS.md` for project-specific rules and CLI examples.

### Ensure project references are available before running your agent:

```bash
./clone-projects.sh
```

### Start your agent in this repo (use your normal install/entrypoint):

For Codex:

```bash
codex
```

For Gemini CLI:

```bash
gemini
```

For Claude CLI:

```bash
claude
```

1. Prompt your agent to build you something. Describe what you want it to do. Give it as much detail on how you want the plugin settings to work and how you think the plugin should interact with files.
1. When prompted by your agent, ensure you grant it permissions to access the files it needs to read or write and to execute the commands it needs to execute.

## Directory layout

- `./build` -- Mounted to `/config/.unmanic` in the container; generated config/logs/plugins live here
- `./build/dev/cache` -- Will be set as the cache location when testing plugins
- `./build/dev/library` -- Will be set as the library location when testing plugins
- `./projects` -- Reference repos used by the agent

## Notes

- The docker image uses the Unmanic staging build. Change the tag in `docker-compose.yml` if needed.
