# Repository Guidelines

## Project Structure & Module Organization
- `main.py` is the primary entry point; `src/` contains the core recording and platform logic.
- `src/spider.py`, `src/stream.py`, and `src/room.py` handle platform discovery, stream URLs, and room metadata.
- `src/javascript/` holds signing and decryption helpers used by some platforms.
- `src/http_clients/` contains sync/async HTTP wrappers used across the app.
- `config/` stores runtime configuration (`config.ini`) and recording targets (`URL_config.ini`).
- `i18n/` holds translation files; `index.html` is a lightweight player page.
- `demo.py` provides example calls for manual checks; `msg_push.py` handles status notifications.

## Build, Test, and Development Commands
- `uv sync` or `pip3 install -r requirements.txt`: install dependencies.
- `python main.py` (or `python3 main.py`): run the recorder locally; `uv run main.py` is also supported.
- `python demo.py`: manual sanity check of stream fetchers using sample URLs.
- `docker-compose up`: run via Docker using the supplied compose file.
- `docker build -t douyin-live-recorder:latest .`: optional local image build for compose.
- `python ffmpeg_install.py`: helper for installing FFmpeg where supported.

## Coding Style & Naming Conventions
- Python is the primary language; use 4-space indentation and PEP 8-style naming.
- Prefer `snake_case` for functions/variables and `PascalCase` for classes.
- Keep platform-specific parsing in `src/spider.py` or `src/stream.py` rather than `main.py`.
- Preserve existing formatting in `src/javascript/*.js` and avoid unnecessary rewrites.

## Testing Guidelines
- No automated test suite is present; validation is primarily manual.
- Use `python demo.py` and a short run of `python main.py` with a known live URL to verify changes.
- If you add tests, document the runner and naming scheme in the README.

## Commit & Pull Request Guidelines
- Recent history favors Conventional Commit-style messages (e.g., `feat: ...`, `fix: ...`, `docs: ...`); follow that format when possible.
- PRs should include a concise summary, test notes (manual steps are fine), and any config changes.
- Call out platform-specific behavior changes and link related issues when available.

## Configuration & Runtime Notes
- Update `config/URL_config.ini` with one live room URL per line; prefix with `#` to disable a line.
- Use `config/config.ini` for global settings (format, proxy, intervals).
- FFmpeg is required for recording; output is written under `downloads/` at runtime.

## Agent-Specific Instructions
- 所有回复请使用中文。
