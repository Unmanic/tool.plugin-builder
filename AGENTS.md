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

### Ensure PUID/PGID are set for docker compose

Before running any `docker compose` commands, ensure a `.env` file exists with your UID/GID/TZ.
With this file in place, you do not need to prefix compose commands with `PUID=... PGID=...`.

```bash
cat << EOF > .env
PUID=$(id -u)
PGID=$(id -g)
TZ=$(cat /etc/timezone 2>/dev/null || timedatectl show -p Timezone --value 2>/dev/null || echo UTC)
EOF
```

If this file needed to be created, you will need to restart the docker compose stack.

### Start the container

Use `./compose.sh` to start/stop the stack. It detects GPU hardware and automatically includes the appropriate override file from `./docker/`:

- NVIDIA: uses `./docker/docker-compose.nvidia.yml` when `nvidia-smi` or `/dev/nvidiactl` is present.
- Intel/AMD (DRI): uses `./docker/docker-compose.dri.yml` when `/dev/dri` exists.

> Note:
> Always execute commands inside the `unmanic-dev` container via `./compose.sh exec` (or `./compose.sh --podman exec`). This includes downloading files (`curl`/`wget`), running `ffmpeg`, and using other tools. The only exception is creating or patching files, which the agent can do outside the container without extra permissions. `./compose.sh exec` defaults to the `unmanic-dev` service, so `./compose.sh exec ls -la` runs inside that container.

> Note:
> Always use the `./compose.sh` wrapper for all `docker compose` or `podman compose` commands (including `exec`); if you see raw compose commands in examples, replace them with `./compose.sh` or `./compose.sh --podman`.

> Note:
> `./compose.sh` defaults `exec` to `--user=$(id -u)`. Use `./compose.sh --root exec ...` if you need root. Example:

```bash
./compose.sh exec unmanic --manage-plugins --reload-plugins
```

```bash
./compose.sh start
```

The Unmanic UI will be available on port 7888 (http://localhost:7888).

To stop the stack:

```bash
./compose.sh stop
```

Podman fallback:

```bash
./compose.sh --podman start
```

Warning: the stack exposes port 7888. If Docker already started the stack, Podman will fail to bind the same port (and vice versa). Stop the existing stack before switching runtimes. If Podman is used to start the stack, then all subsequent commands must also be run with Podman.

### Create a plugin

First start the container, then run a command like the example below. Always execute Unmanic commands via `./compose.sh exec` (or `./compose.sh --podman exec` if that is what you use).
Running inside the container ensures the Ubuntu-based image has access to the required dependencies for Unmanic and plugins.

```bash
./compose.sh exec \
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

After scaffolding, ensure the plugin includes the standard metadata files:

1. Add a license file by copying this repo's `LICENSE` into the plugin:

```bash
cp ./LICENSE ./build/plugins/<plugin_id>/LICENSE
```

1. Create `./build/plugins/<plugin_id>/changelog.md` and
   `./build/plugins/<plugin_id>/description.md`. Use
   `./projects/unmanic-plugins/source/limit_library_search_by_ffprobe_data/changelog.md` and
   `./projects/unmanic-plugins/source/limit_library_search_by_ffprobe_data/description.md` as
   formatting/content references.

Example `changelog.md`:

```ini
**<span style="color:#56adda">0.0.1</span>**
- Initial version
```

`description.md` should explain what the plugin does and how it can be configured, optionally including links to related docs or tools. It should always start with:

```markdown
---

<detailed explanation on the plugin, what it does, etc.>
```

The `description.md` file should not start with a header. just a HR (---).

After scaffolding, update `./build/plugins/<plugin_id>/info.json` so the plugin is correctly identified
in the UI and metadata is accurate. Agents (Gemini, Codex, Claude, etc) should not leave the placeholder
`Plugin Name` in place. Fields to review and update:

- `id` (must match `--plugin-id`)
- `name` (user-facing label, not the placeholder "Plugin Name")
- `description` (short summary of what the plugin does)
- `author` (name/handle -- the agent can infer this from git settings; try `git config user.name` and
  `git config user.email` in the repo first, then fall back to `git config --global user.name` /
  `git config --global user.email` if needed)
- `version` (start at 0.0.1 or match your release if editing or creating an update to an existing plugin)
- `tags` (comma-separated keywords. See existing plugins in `./projects/unmanic-plugins/source/` for examples)
- `icon` (URL or a local file path, if used)
- `compatibility` (Unmanic major versions, usually `[2]`)
- `priorities` (optional; map of runner names to execution order)

Example `info.json`:

```json
{
  "author": "Your Name",
  "compatibility": [2],
  "description": "Transcode the video streams of a video file",
  "icon": "https://raw.githubusercontent.com/Unmanic/plugin.video_transcoder/master/icon.png",
  "id": "video_transcoder",
  "name": "Transcode Video Files",
  "priorities": {
    "on_library_management_file_test": 10,
    "on_worker_process": 1
  },
  "tags": "video,ffmpeg",
  "version": "0.1.13"
}
```

Icon tip: if you need an icon, agents can search for a suitable `icon.png` (for example `"githubusercontent <service name> icon png"`), download it with `curl` into the plugin root, and set `icon` in `info.json` to the raw GitHub URL, e.g.
`https://raw.githubusercontent.com/<GITHUB_ORG>/<REPO>/master/icon.png`.

### Update an existing plugin

When modifying an existing plugin, follow a short release checklist so the UI and metadata stay accurate:

1. Implement the feature or fix in `./build/plugins/<plugin_id>`.
1. Update the plugin changelog. Use `./projects/unmanic-plugins/source/video_transcoder/changelog.md`
   as a formatting reference.
1. Bump the `version` field in `./build/plugins/<plugin_id>/info.json` to match the changelog entry.
1. Reload plugins with `--reload-plugins` so the UI picks up the changes, then test with `--test-plugin`.

### Reload plugins

```bash
./compose.sh exec \
  unmanic --manage-plugins --reload-plugins
```

After creating or editing a plugin, it will not appear in the Unmanic UI (http://localhost:7888) until you reload plugins with the command above.

### Test a plugin

```bash
./compose.sh exec \
  unmanic --manage-plugins --test-plugin=test_plugin
```

You can override the test input/output filenames with `--test-file-in` and `--test-file-out`. These are
just the filenames located under `./build/dev/library` (not full paths). Use them when you want a specific media file for validation.

```bash
./compose.sh exec \
  unmanic --manage-plugins \
  --test-plugin=test_plugin \
  --test-file-in="source.mkv" \
  --test-file-out="expected-output.mkv"
```

Files must exists in that `./build/dev/library` which is mounted into the unmanic-dev container as `/config/.unmanic/dev/library`.

### Plugin test settings (CLI + API)

When asked to test a plugin against a file under specific conditions, use the Swagger docs and API to determine the current plugin settings, then configure the plugin settings through the API. The Unmanic CLI `--test-plugin` command always tests against the settings applied to library 1. If global settings are set but library 1 has a per-library override, CLI tests will use the override and may fail. It is best to test plugins when there are no libraries configured with the plugin and only global settings are configured. You can also edit settings directly in `./build/userdata/<plugin_id>`:

- `settings.json` is the current global settings.
- `settings.1.json` is the settings for the library with ID "1".

Editing these JSON files directly is valid and will be picked up by CLI tests.

### Install sample test data

Unmanic can install sample media for testing via `--install-test-data` (see `./projects/unmanic/unmanic/libs/unplugins/pluginscli.py`).
This creates the directories `./build/dev/cache` and `./build/dev/library` on the host (container paths `/config/.unmanic/dev/cache` and `/config/.unmanic/dev/library`) and downloads example files into them.

```bash
./compose.sh exec \
  unmanic --manage-plugins --install-test-data
```

Current samples include:

- `Big_Buck_Bunny_1080_10s_30MB_h264.mkv`
- `Big_Buck_Bunny_1080_10s_30MB_h264.mp4`
- `Big_Buck_Bunny_1080_10s_30MB_av1.mp4`
- `Big_Buck_Bunny_360_10s_1MB_h264.mp4`
- `sample-12s.mp3`

You can also download additional test files by running `curl` inside the container and saving into `/config/.unmanic/dev/library` (host path `./build/dev/library`), then use `--test-file-in`/`--test-file-out` to target them.

### Manipulate sample files for plugin testing

Agents should identify the specific media characteristics needed to test a plugin (codec, duration, resolution, audio presence, etc.) and create those files from the existing samples in `./build/dev/library`. Use `ffprobe` inside the container to inspect source media and choose appropriate `ffmpeg` arguments for transcoding, trimming, or scaling.

Agents are free to run commands inside the container to install any dependencies required to generate sample/test files (before running `--test-plugin`). Keep generated files in `./build/dev/library` so they are available to `--test-file-in`/`--test-file-out`.

### Validate with the Unmanic API (curl/wget)

After CLI tests, you can query the running Unmanic API to verify plugin install/status, settings, and
library configuration. Always run `curl` or `wget` inside the container to hit the service directly:

```bash
./compose.sh exec \
  curl -sS http://localhost:7888/unmanic/swagger/swagger.json > /tmp/unmanic-swagger.json
```

Use the Swagger JSON to discover all endpoints.

> Note:
> The `servers` list inside the Swagger file may still reference port 8888, but this dev container runs on 7888. Always send requests to
> `http://localhost:7888/unmanic/api/v2/`.

Common API calls (examples):

```bash
# List installed plugins (table-style request body).
./compose.sh exec \
  curl -sS -X POST http://localhost:7888/unmanic/api/v2/plugins/installed \
  -H 'Content-Type: application/json' \
  -d '{"start":0,"length":200,"search_value":"","status":"all","order_by":"name","order_direction":"asc"}'

# Read plugin info/settings (prefer local plugin by ID).
./compose.sh exec \
  curl -sS -X POST http://localhost:7888/unmanic/api/v2/plugins/info \
  -H 'Content-Type: application/json' \
  -d '{"plugin_id":"test_plugin","prefer_local":true}'

# Worker status.
./compose.sh exec \
  curl -sS http://localhost:7888/unmanic/api/v2/workers/status

# List libraries, read one, then write it back (edit JSON as needed).
./compose.sh exec \
  curl -sS http://localhost:7888/unmanic/api/v2/settings/libraries

./compose.sh exec \
  curl -sS -X POST http://localhost:7888/unmanic/api/v2/settings/library/read \
  -H 'Content-Type: application/json' \
  -d '{"id":1}'

./compose.sh exec \
  curl -sS -X POST http://localhost:7888/unmanic/api/v2/settings/library/write \
  -H 'Content-Type: application/json' \
  -d '{"library_config":{"id":1,"name":"Default","path":"/config/.unmanic/dev/library","enable_scanner":true,"enable_inotify":false,"priority_score":0,"tags":[]},"plugins":{"enabled_plugins":[{"library_id":1,"plugin_id":"test_plugin"}]}}'

# Enable debug logging. This will enable more verbose logging in `./build/logs/unmanic.log`
./compose.sh exec \
  curl -sS -X POST http://localhost:7888/unmanic/api/v2/settings/write \
  -H 'Content-Type: application/json' \
  -d '{"settings":{"debugging":true}}'
```

### API-driven testing workflow (optional)

To validate worker plugins against real files:

1. Place media files under `./build/dev/library` on the host (container path:
   `/config/.unmanic/dev/library`).
1. Use `/settings/libraries` and `/settings/library/read` to locate your library ID.
1. Use `/settings/library/write` to enable the new plugin for that library.
1. Trigger a scan with `/pending/library/update` or `/pending/rescan` and monitor progress via
   `/workers/status`.
1. Tail `./build/logs/unmanic.log` on the host to observe worker execution.

Example scan trigger:

```bash
./compose.sh exec \
  curl -sS -X POST http://localhost:7888/unmanic/api/v2/pending/library/update \
  -H 'Content-Type: application/json' \
  -d '{"id_list":[1],"library_name":"Default"}'
```

## Agent expectations

When asked to build a plugin, use the CLI to scaffold it, then fill in metadata and logic.
Reference the local `./projects` repositories for code patterns and API usage.

## FFmpeg helper submodule (default)

Unless explicitly told not to, wrap FFmpeg/FFprobe usage with the helper library at
https://github.com/Josh5/unmanic.plugin.helpers.ffmpeg. Add it to each plugin that needs to use `ffmpeg` or `ffprobe` as a submodule:

```bash
git submodule add https://github.com/Josh5/unmanic.plugin.helpers.ffmpeg.git ./lib/ffmpeg
```

> Note:
> `./projects/unmanic-plugins/source/` is a published source mirror and does not include submodules.
> For example, `./projects/unmanic-plugins/source/video_transcoder/` exists here, but the original repo at https://github.com/Unmanic/plugin.video_transcoder includes the FFmpeg helper submodule under `./lib/ffmpeg`.

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
- For worker process plugins, perform all temporary work in the cache path. The current task cache path is the directory name of the `file_out` value provided in the `on_worker_process` data payload.
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
