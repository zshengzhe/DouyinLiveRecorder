#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="DouyinLiveRecorder"

if [[ $# -ne 0 ]]; then
  echo "This script auto-detects the platform and does not accept arguments." >&2
  exit 1
fi

OS_NAME="$(uname -s)"
if [[ "$OS_NAME" != "Darwin" ]]; then
  echo "Unsupported host OS for release packaging: $OS_NAME" >&2
  echo "release.sh only supports macOS." >&2
  exit 1
fi

TARGET=""
ZIP_SUFFIX=""
TARGET_ARCH=""

ARCH="$(uname -m)"
if [[ "$ARCH" == "x86_64" ]]; then
  TARGET="mac64"
  ZIP_SUFFIX="mac_64"
  TARGET_ARCH="x86_64"
elif [[ "$ARCH" == "arm64" ]]; then
  TARGET="mac"
  ZIP_SUFFIX="mac"
  TARGET_ARCH="arm64"
else
  echo "Unsupported macOS architecture: $ARCH" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "Python not found in PATH." >&2
  exit 1
fi

VERSION="$(awk -F= '/^version[[:space:]]*=/{gsub(/[[:space:]]*/, "", $2); gsub(/["'"'"']/, "", $2); print $2; exit}' "$ROOT/main.py")"
if [[ -z "$VERSION" ]]; then
  echo "version not found in main.py" >&2
  exit 1
fi

if ! "$PYTHON_BIN" -m PyInstaller --version >/dev/null 2>&1; then
  echo "PyInstaller not installed. Run: $PYTHON_BIN -m pip install pyinstaller" >&2
  exit 1
fi

DATA_SEP=":"

DIST_ROOT="$ROOT/dist/${TARGET}"
BUILD_ROOT="$ROOT/build/${TARGET}"
SPEC_ROOT="$ROOT/build/${TARGET}/spec"

DATA_I18N="$ROOT/i18n"
DATA_JS="$ROOT/src/javascript"

PYINSTALLER_ARGS=(
  --noconfirm
  --clean
  --name "$APP_NAME"
  --onedir
  --distpath "$DIST_ROOT"
  --workpath "$BUILD_ROOT"
  --specpath "$SPEC_ROOT"
  --add-data "${DATA_I18N}${DATA_SEP}i18n"
  --add-data "${DATA_JS}${DATA_SEP}src/javascript"
)

if [[ -n "$TARGET_ARCH" ]]; then
  PYINSTALLER_ARGS+=(--target-arch "$TARGET_ARCH")
fi

if [[ "$TARGET" == "mac64" && "$(uname -m)" != "x86_64" ]]; then
  echo "Note: building x86_64 on Apple Silicon requires an x86_64 Python (Rosetta)." >&2
fi

"$PYTHON_BIN" -m PyInstaller "${PYINSTALLER_ARGS[@]}" "$ROOT/main.py"

APP_DIR="$DIST_ROOT/$APP_NAME"
if [[ ! -d "$APP_DIR" ]]; then
  echo "Build output not found: $APP_DIR" >&2
  exit 1
fi

if [[ -d "$ROOT/config" ]]; then
  cp -R "$ROOT/config" "$APP_DIR/"
fi

if [[ -d "$ROOT/backup_config" ]]; then
  cp -R "$ROOT/backup_config" "$APP_DIR/"
else
  mkdir -p "$APP_DIR/backup_config"
fi

if [[ -f "$ROOT/README.md" ]]; then
  cp "$ROOT/README.md" "$APP_DIR/"
fi

if [[ -f "$ROOT/StopRecording.sh" ]]; then
  cp "$ROOT/StopRecording.sh" "$APP_DIR/"
  chmod +x "$APP_DIR/StopRecording.sh"
fi
if [[ -f "$ROOT/StopRecording.command" ]]; then
  cp "$ROOT/StopRecording.command" "$APP_DIR/"
  chmod +x "$APP_DIR/StopRecording.command"
fi

DEPS_ROOT="$ROOT/packaging/deps/mac"
FFMPEG_SRC="$DEPS_ROOT/ffmpeg"
EXTRAS_SRC="$DEPS_ROOT/extras"

if [[ -d "$FFMPEG_SRC" ]]; then
  cp -R "$FFMPEG_SRC" "$APP_DIR/"
else
  echo "Warning: missing ffmpeg directory: $FFMPEG_SRC" >&2
fi

if [[ -d "$EXTRAS_SRC" ]]; then
  cp -R "$EXTRAS_SRC/." "$APP_DIR/"
fi

rm -f "$APP_DIR/StopRecording.vbs"

OUTPUT_NAME="${APP_NAME}_${ZIP_SUFFIX}_${VERSION}"
OUTPUT_DIR="$DIST_ROOT/$OUTPUT_NAME"
if [[ -e "$OUTPUT_DIR" ]]; then
  echo "Output directory already exists: $OUTPUT_DIR" >&2
  echo "Please remove it before packaging again." >&2
  exit 1
fi
mv "$APP_DIR" "$OUTPUT_DIR"

RELEASE_DIR="$ROOT/release"
ZIP_PATH="$RELEASE_DIR/${OUTPUT_NAME}.zip"
mkdir -p "$RELEASE_DIR"

"$PYTHON_BIN" - <<PY
import pathlib
import zipfile

app_dir = pathlib.Path("$OUTPUT_DIR").resolve()
zip_path = pathlib.Path("$ZIP_PATH").resolve()

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in app_dir.rglob("*"):
        zf.write(path, path.relative_to(app_dir.parent))
print(f"Created: {zip_path}")
PY
