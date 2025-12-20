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

The Unmanic UI will be available on port 7888 (http://localhost:7888).

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
