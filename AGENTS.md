# AGENT

This repository is a starter workspace for generating Unmanic plugins with an AI agent (like Codex).
It provides local source references, a docker-compose environment for plugin development/testing,
and command examples for creating and validating plugins.

## What is Unmanic?

Unmanic is a media processing automation tool. It watches libraries and runs tasks on worker
processes using plugins. Plugins define the logic for tasks (scan, queue, process, etc).

## Local source references

The `./projects` directory includes cloned projects that can be used as source code references:

- `./projects/unmanic` -- The core Unmanic application (CLI, server, docker files).
- `./projects/unmanic-frontend` -- The UI that ships with Unmanic.
- `./projects/unmanic-plugins` -- Official plugins; look here for patterns and examples.
- `./projects/unmanic-documentation` -- The docs site, including plugin authoring guides.

Use `./clone-projects.sh` to clone or update sources into `./projects`.

## Plugin generation workflow

Use the docker-compose environment to create and test plugins. The compose file mounts:

- `./build` -> `/config/.unmanic`

Inside this `./build` directory will be a directory structure like this

```text
./build/
├── config
│   ├── unmanic.db
│   ├── unmanic.db-shm
│   └── unmanic.db-wal
├── logs
│   ├── tornado.log
│   └── unmanic.log
└── plugins
```

### Start the container

```bash
docker compose up -d
```

### Create a plugin

First start the container, then run a command like the example below. Always execute Unmanic commands via
`docker compose exec` (or `podman compose exec` if that is what you use). Running inside the container ensures
the Ubuntu-based image has access to the required dependencies for Unmanic and plugins.

```bash
docker compose exec unmanic-dev \
  unmanic --manage-plugins \
  --create-plugin \
  --plugin-id=test_plugin \
  --plugin-name="Plugin Name" \
  --plugin-runners="on_worker_process,emit_task_queued"
```

The plugin will be generated under `./build/plugins/test_plugin`.

Arguments:

- `--plugin-id`: Unique plugin identifier (recommended snake_case).
- `--plugin-name`: User-facing label; keep it reasonably short (~35 characters soft limit).
- `--plugin-runners`: Comma-separated list of plugin runner types to scaffold into `plugin.py`.
  See `./projects/unmanic-documentation/docs/development/writing_plugins/plugin_runner_types.mdx` or
  browse `./projects/unmanic/unmanic/libs/unplugins/plugin_types/` for available runners.

Tip: `test_plugin` is just an example; pick a real ID/name for your plugin.
You can review the current CLI options in `./projects/unmanic/unmanic/service.py`.

### Reload plugins

```bash
docker compose exec unmanic-dev \
  unmanic --manage-plugins --reload-plugins
```

### Test a plugin

```bash
docker compose exec unmanic-dev \
  unmanic --manage-plugins --test-plugin=test_plugin
```

## Agent expectations

When asked to build a plugin, use the CLI to scaffold it, then fill in metadata and logic.
Reference the local `./projects` repositories for code patterns and API usage.

## Dependencies inside the container

If a plugin needs dependencies (apt or pip), create an installer script under its `init.d/` directory.
Example: `./projects/unmanic-plugins/source/auto_rotate_images/init.d/install-jhead-jpegtran.sh`.
If using apt, guard `apt-get update` to only run once:

```bash
[[ "${__apt_updated:-false}" == 'false' ]] && apt-get update && __apt_updated=true
```

Example pip install script (create something like `init.d/install-python-deps.sh`):

```bash
python3 -m pip install --cache-dir /config/.cache/pip -r requirements.txt
```

Note: `init.d` scripts are sourced at container startup.

## Useful source references

- Plugin runner contracts live in `./projects/unmanic/unmanic/libs/unplugins/plugin_types/`. Each runner lists
  required fields in `data_schema` and sample `test_data`. These are used by the CLI `--test-plugin` validator.
- Common runner types:
  - Library scan filter: `on_library_management_file_test`
  - Worker processing: `on_worker_process`
  - Post-processor: `on_postprocessor_file_movement`, `on_postprocessor_task_results`
  - Event hooks: `emit_*` (see `./projects/unmanic/unmanic/libs/unplugins/plugin_types/events/`)
  - Frontend: `render_frontend_panel`, `render_plugin_api`
- Worker runners can either set `data["exec_command"]` and `data["command_progress_parser"]` for external tools
  (FFmpeg, etc.) or run a Python-only child process via `PluginChildProcess` (see
  `./projects/unmanic/unmanic/libs/unplugins/plugin_types/worker/process.py`).
- Shared task state is supported via `TaskDataStore` (documented in the worker runner docstring above). Use it
  when multiple plugin runners need to share data across stages.
- Plugin settings are provided by `PluginSettings` (`./projects/unmanic/unmanic/libs/unplugins/settings.py`).
  Settings are persisted to `settings.json` (or `settings.<library_id>.json`) in the plugin profile directory.
- Plugin metadata (`info.json`) supports a `priorities` map keyed by runner names to influence execution order.
  See `./projects/unmanic-plugins/source/video_transcoder/info.json` for an example.
- Frontend panel/plugin API requests are wired through `./projects/unmanic/unmanic/webserver/plugins.py`.
  The `file_size_metrics` plugin shows a full panel + static assets pattern and uses `package.json` for
  frontend dependencies (`./projects/unmanic-plugins/source/file_size_metrics/`).

## Plugin pattern examples

- Processing/FFmpeg style: `./projects/unmanic-plugins/source/video_transcoder/`,
  `./projects/unmanic-plugins/source/video_remuxer/`, `./projects/unmanic-plugins/source/remove_all_subtitles/`.
- Scan filters: `./projects/unmanic-plugins/source/ignore_*`, `./projects/unmanic-plugins/source/limit_library_search_*`.
- Notifications/webhooks: `./projects/unmanic-plugins/source/discord_webhook/`, `./projects/unmanic-plugins/source/notify_*`.
